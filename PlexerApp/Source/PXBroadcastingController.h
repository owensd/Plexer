//
//  PXBroadcastingController.h
//  PlexerHelper
//
//  Created by David Owens II on 9/28/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>

OBJC_EXPORT NSString * const PXBroadcastingDidChangeNotification;

typedef enum {
    PXBroadcastingDisabled = 0,
    PXBroadcastingMappedKeys,
    PXBroadcastingAllKeys
} PXBroadcastingState;

@interface PXBroadcastingController : NSObject {
    CFRunLoopSourceRef _keybindRunLoopSourceRef;
    CFMachPortRef _keybindEventTapRef;
    
}

@property (strong) NSDictionary *settings;

@property (nonatomic, assign) PXBroadcastingState broadcastingState;


@end
