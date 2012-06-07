//
//  OSCServer.h
//  osc-tcp-example
//
//  Created by Camille Troillard on 07/06/12.
//  Copyright 2012 Wildora. All rights reserved.
//

#import "TCPServer.h"
#import "OSCTCPConnection.h"
#import "OSCServerRequest.h"


@class OSCTCPConnection;

@interface OSCTCPServer : TCPServer {
	Class connectionClass;
}

@property (readwrite, assign) Class connectionClass;

@end



@interface OSCTCPServer (OSCTCPServerDelegation)

- (void)OSCTCPServer:(OSCTCPServer *)serv didMakeNewConnection:(OSCTCPConnection *)conn;

@end
