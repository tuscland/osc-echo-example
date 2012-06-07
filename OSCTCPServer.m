//
//  OSCServer.m
//  osc-tcp-example
//
//  Created by Camille Troillard on 07/06/12.
//  Copyright 2012 Wildora. All rights reserved.
//

#import "OSCTCPServer.h"
#import "OSCTCPConnection.h"

@implementation OSCTCPServer

@synthesize connectionClass;

- init {
	self = [super init];
	
	if (self) {
		connectionClass = [OSCTCPConnection self];		
		self.type = @"_osc._tcp";
	}

    return self;
}

- (void)dealloc {
    [super dealloc];
}

// Converts the TCPServer delegate notification into the OSCTCPServer delegate method.
- (void)handleNewConnectionFromAddress:(NSData *)addr
						   inputStream:(NSInputStream *)istr
						  outputStream:(NSOutputStream *)ostr {
    OSCTCPConnection *connection = [[connectionClass alloc] initWithPeerAddress:addr
																	inputStream:istr
																   outputStream:ostr
																	  forServer:self];
    connection.delegate = self.delegate;

    if (self.delegate && [self.delegate respondsToSelector:@selector(OSCTCPServer:didMakeNewConnection:)]) { 
        [self.delegate OSCTCPServer:self didMakeNewConnection:connection];
    }
    // The connection at this point is turned loose to exist on its
    // own, and not released or autoreleased.  Alternatively, the
    // OSCTCPServer could keep a list of connections, and OSCTCPConnection
    // would have to tell the server to delete one at invalidation
    // time.  This would perhaps be more correct and ensure no
    // spurious leaks get reported by the tools, but OSCTCPServer
    // has nothing further it wants to do with the OSCTCPConnections,
    // and would just be "owning" the connections for form.
}

@end
