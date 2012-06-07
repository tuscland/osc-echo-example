//
//  OSCServerRequest.h
//  osc-tcp-example
//
//  Created by Camille Troillard on 07/06/12.
//  Copyright 2012 Wildora. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class OSCTCPConnection;

@interface OSCServerRequest : NSObject {
	OSCMessage *message;
	OSCTCPConnection *connection;
}

@property (readonly) OSCMessage *message;
@property (readonly) OSCTCPConnection *connection;
@property (readwrite, retain) OSCMessage *response;

- initWithMessage:(OSCMessage *)message connection:(OSCTCPConnection *)connection;

@end
