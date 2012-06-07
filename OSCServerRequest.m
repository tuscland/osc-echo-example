//
//  OSCServerRequest.m
//  osc-tcp-example
//
//  Created by Camille Troillard on 07/06/12.
//  Copyright 2012 Wildora. All rights reserved.
//

#import "OSCServerRequest.h"
#import "OSCTCPConnection.h"


@implementation OSCServerRequest

@synthesize message, connection, response;

+ requestWithMessage:(OSCMessage *)aMessage connection:(OSCTCPConnection *)aConnection {
	OSCServerRequest *request = [[OSCServerRequest alloc] initWithMessage:aMessage connection:aConnection];
	return [request autorelease];
}

- initWithMessage:(OSCMessage *)aMessage connection:(OSCTCPConnection *)aConnection {
	self = [super init];
	
	if (self) {
		message = [aMessage retain];
		connection = [aConnection retain];
	}

	return self;
}

- (void)dealloc {
	[message release];
	[connection release];
	[super dealloc];
}

- (void)setResponse:(OSCMessage *)aMessage {
    if (aMessage != response) {
		[response release];
		response = [aMessage retain];
        if (response) {
            // check to see if the response can now be sent out
            [connection processOutgoingBytes];
        }
    }
}

@end
