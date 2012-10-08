//
//  PXBroadcastController.h
//  Plexer
//
//  Created by David Owens II on 10/4/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>

OBJC_EXPORT NSString * const PXBroadcastingDidChangeNotification;

typedef enum {
    PXBroadcastingDisabled      = 0,
    PXBroadcastingMappedKeys    = 1,
    PXBroadcastingAllKeys       = 2
} PXBroadcastingState;


@interface PXBroadcastControllerDelegate : NSObject<NSXPCListenerDelegate>

@end

@protocol PXBroadcastController <NSObject>
- (void)playTeam:(NSDictionary *)team;
- (void)closeApplications;
@end

@interface PXBroadcastController : NSObject<PXBroadcastController>

@property (assign) PXBroadcastingState broadcastingState;
@property (weak) NSXPCConnection *xpcConnection;

@end
