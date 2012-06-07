//
//  OSCTCPConnection.h
//  osc-tcp-example
//
//  Created by Camille Troillard on 07/06/12.
//  Copyright 2012 Wildora. All rights reserved.
//

@class OSCTCPServer;
@class OSCServerRequest;
@protocol OSCTCPConnectionDelegate;


@interface OSCTCPConnection : NSObject {
@private
    id delegate;
    NSData *peerAddress;
    OSCTCPServer *server;
    NSMutableArray *requests;
    NSInputStream *istream;
    NSOutputStream *ostream;
    NSMutableData *ibuffer;
    NSMutableData *obuffer;
    BOOL isValid;
    BOOL firstResponseDone;	
}

@property (readwrite, assign) id delegate;
@property (readonly) OSCTCPServer *server;
@property (readonly) NSData *peerAddress;
@property (readonly) BOOL isValid;

- (id)initWithPeerAddress:(NSData *)addr
			  inputStream:(NSInputStream *)istr
			 outputStream:(NSOutputStream *)ostr
				forServer:(OSCTCPServer *)serv;

- (OSCServerRequest *) nextRequest;

- (void)invalidate;
// shut down the connection

@end



@interface OSCTCPConnection (OSCTCPConnectionDelegation)

- (void)OSCTCPConnection:(OSCTCPConnection *)conn didReceiveRequest:(OSCServerRequest *)mess;
- (void)OSCTCPConnection:(OSCTCPConnection *)conn didSendResponse:(OSCServerRequest *)mess;

@end


@interface OSCTCPConnection (OSCServerRequestFriend)

- (void)processOutgoingBytes;

@end
