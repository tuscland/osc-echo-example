//
//  osc-echo-example.m
//  osc-tcp-example
//
//  Created by Camille Troillard on 05/06/12.
//  Copyright 2012 Wildora. All rights reserved.
//

#import "OSCTCPServer.h"


@interface MyController : NSObject {
	OSCTCPServer *server;
}

@end



@implementation MyController

- (id) init {
	self = [super init];
	
	if (self) {
		server = [[OSCTCPServer alloc] init];
		server.delegate = self;
		
		NSError *error = nil;
		if ([server start:&error] == NO) {
			NSLog(@"Error starting OSC server: %@", error);
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (void)OSCTCPServer:(OSCTCPServer *)serv didMakeNewConnection:(OSCTCPConnection *)conn {
	NSLog(@"ACCEPT");
}

- (void)OSCTCPConnection:(OSCTCPConnection *)conn didReceiveRequest:(OSCServerRequest *)request {
	NSString *address = request.message.address;
	NSLog(@"REQUEST: %@", address);

	OSCMessage *response = [OSCMessage createWithAddress:@"/echo"];

	[response addString:address];
	
	for (int i = 0; i < request.message.valueCount; i++) {
		[response addValue:[request.message valueAtIndex:i]];		
	}
		
	request.response = response;
}

- (void)OSCTCPConnection:(OSCTCPConnection *)conn didSendResponse:(OSCServerRequest *)request {
	NSLog(@"RESPONSE: %@", request.response.address);
}


@end


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    MyController *controller = [[MyController alloc] init];
	
	[[NSRunLoop currentRunLoop] run];
	
	[controller release];
	[pool drain];
	
    return 0;
}
