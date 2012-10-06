//
//  main.m
//  PlexerHelper
//
//  Created by David Owens II on 10/4/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#include <xpc/xpc.h>
#include <Foundation/Foundation.h>
#import "PXBroadcastController.h"


int main(int argc, const char *argv[])
{
    // Get the singleton service listener and configure it with our delegate.
    NSXPCListener *listener = [NSXPCListener serviceListener];
    
    PXBroadcastControllerDelegate *delegate = [[PXBroadcastControllerDelegate alloc] init];
    listener.delegate = delegate;
    
    [listener resume];
    
	return EXIT_FAILURE;
}
