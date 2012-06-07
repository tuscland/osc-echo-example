//
//  OSCTCPConnection.m
//  osc-tcp-example
//
//  Created by Camille Troillard on 07/06/12.
//  Copyright 2012 Wildora. All rights reserved.
//

#import "OSCTCPConnection.h"
#import "OSCServerRequest.h"


@implementation OSCTCPConnection

@synthesize delegate, server, peerAddress, isValid;

- initWithPeerAddress:(NSData *)addr
		  inputStream:(NSInputStream *)istr
		 outputStream:(NSOutputStream *)ostr
			forServer:(OSCTCPServer *)serv {
	self = [super init];
	
	if (self) {
		peerAddress = [addr copy];
		server = serv;
		istream = [istr retain];
		ostream = [ostr retain];
		[istream setDelegate:self];
		[ostream setDelegate:self];
		[istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
		[ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
		[istream open];
		[ostream open];
		isValid = YES;	
	}

	return self;
}

- (void)dealloc {
    [self invalidate];
    [peerAddress release];
	[super dealloc];
}

- (OSCServerRequest *)nextRequest {
    NSUInteger idx, cnt = requests ? [requests count] : 0;
    for (idx = 0; idx < cnt; idx++) {
        id obj = [requests objectAtIndex:idx];
        if ([obj response] == nil) {
            return obj;
        }
    }
    return nil;
}

- (void)invalidate {
    if (isValid) {
        isValid = NO;
        [istream close];
        [ostream close];
        [istream release];
        [ostream release];
        istream = nil;
        ostream = nil;
        [ibuffer release];
        [obuffer release];
        ibuffer = nil;
        obuffer = nil;
        [requests release];
        requests = nil;
        [self release];
        // This last line removes the implicit retain the OSCTCPConnection
        // has on itself, given by the OSCTCPServer when it abandoned the
        // new connection.
    }
}

static size_t OSCHeaderSize = sizeof(unsigned int);

// YES return means that a complete request was parsed, and the caller
// should call again as the buffered bytes may have another complete
// request available.
- (BOOL)processIncomingBytes {
	NSData *messageData = nil;
	
	// we know that the input buffer must start with the length of the next OSC message
	if (ibuffer.length >= OSCHeaderSize) {
		unsigned int length = 0;
		unsigned int tmp = 0;
		[ibuffer getBytes:&tmp range:NSMakeRange(0, OSCHeaderSize)];
		length = ntohl(tmp);
				
		if (length > 0 &&
			(ibuffer.length + OSCHeaderSize) >= length) {
			messageData = [ibuffer subdataWithRange:NSMakeRange(OSCHeaderSize, length)];

			// move the remaining data to the beginning of the buffer, and trim it
			unsigned int rlen = OSCHeaderSize + length;
			unsigned int ilen = ibuffer.length;
			memmove([ibuffer mutableBytes], [ibuffer mutableBytes] + rlen, ilen - rlen);
			[ibuffer setLength:ilen - rlen];
		} else {
			return NO;
		}
	} else {
		return NO;
	}

	OSCMessage *message = [OSCMessage parseRawBuffer:(unsigned char *) messageData.bytes ofMaxLength:messageData.length fromAddr:0 port:0];
			
	OSCServerRequest *request = [[OSCServerRequest alloc] initWithMessage:message connection:self];
	if (!requests) {
		requests = [[NSMutableArray alloc] init];
	}
	[requests addObject:request];
	if (delegate && [delegate respondsToSelector:@selector(OSCTCPConnection:didReceiveRequest:)]) { 
		[delegate OSCTCPConnection:self didReceiveRequest:request];
	}

	return YES;
}

- (void)processOutgoingBytes {
    // Write as many bytes as possible, from buffered bytes, response
    // headers and body, and response stream.
	
    if (![ostream hasSpaceAvailable]) {
        return;
    }
	
    unsigned olen = [obuffer length];
    if (0 < olen) {
        int writ = [ostream write:[obuffer bytes] maxLength:olen];
        // buffer any unwritten bytes for later writing
        if (writ < olen) {
            memmove([obuffer mutableBytes], [obuffer mutableBytes] + writ, olen - writ);
            [obuffer setLength:olen - writ];
            return;
        }
        [obuffer setLength:0];
    }
	
    NSUInteger cnt = requests ? [requests count] : 0;
    OSCServerRequest *req = (0 < cnt) ? [requests objectAtIndex:0] : nil;
	
	OSCMessage *resp = req ? req.response : nil;
    if (!resp)
		return;
    
    if (!obuffer) {
        obuffer = [[NSMutableData alloc] init];
    }
	
    if (!firstResponseDone) {
        firstResponseDone = YES;
		
		OSCPacket *packet = [OSCPacket createWithContent:resp];
		NSMutableData *serialized = [NSMutableData data];
		unsigned int length = htonl(packet.bufferLength);
		[serialized appendBytes:&length length:OSCHeaderSize];
        [serialized appendBytes:packet.payload length:packet.bufferLength];
		
        unsigned olen = serialized.length;
        if (0 < olen) {
            int writ = [ostream write:serialized.bytes maxLength:olen];
            if (writ < olen) {
                // buffer any unwritten bytes for later writing
                [obuffer setLength:(olen - writ)];
                memmove([obuffer mutableBytes], [serialized bytes] + writ, olen - writ);
                return;
            }
        }
    }
	
    if (0 == [obuffer length]) {
		// When we get to this point with an empty buffer, then the 
		// processing of the response is done. If the input stream
		// is closed or at EOF, then no more requests are coming in.
		if (delegate && [delegate respondsToSelector:@selector(OSCTCPConnection:didSendResponse:)]) { 
			[delegate OSCTCPConnection:self didSendResponse:req];
		}
        [requests removeObjectAtIndex:0];
        firstResponseDone = NO;
        if ([istream streamStatus] == NSStreamStatusAtEnd && [requests count] == 0) {
            [self invalidate];
        }

        return;
    }
    
    olen = [obuffer length];
    if (0 < olen) {
        int writ = [ostream write:[obuffer bytes] maxLength:olen];
        // buffer any unwritten bytes for later writing
        if (writ < olen) {
            memmove([obuffer mutableBytes], [obuffer mutableBytes] + writ, olen - writ);
        }
        [obuffer setLength:olen - writ];
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent {
    switch(streamEvent) {
		case NSStreamEventHasBytesAvailable:;
			uint8_t buf[16 * 1024];
			uint8_t *buffer = NULL;
			NSUInteger len = 0;

			if (![istream getBuffer:&buffer length:&len]) {
				int amount = [istream read:buf maxLength:sizeof(buf)];
				buffer = buf;
				len = amount;
			}
			
			if (0 < len) {
				if (!ibuffer) {
					ibuffer = [[NSMutableData alloc] init];
				}
				[ibuffer appendBytes:buffer length:len];
			}
			
			do {} while ([self processIncomingBytes]);
			break;

		case NSStreamEventHasSpaceAvailable:;
			[self processOutgoingBytes];
			break;
		
		case NSStreamEventEndEncountered:;
			[self processIncomingBytes];
			if (stream == ostream) {
				// When the output stream is closed, no more writing will succeed and
				// will abandon the processing of any pending requests and further
				// incoming bytes.
				[self invalidate];
			}
			break;

		case NSStreamEventErrorOccurred:;
			NSLog(@"OSCTCPServer stream error: %@", [stream streamError]);
			break;
		
		default:
			break;
    }
}

@end
