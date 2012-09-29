//
//  PXBroadcastingController.h
//  PlexerHelper
//
//  Created by David Owens II on 9/28/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>

OBJC_EXPORT NSString * const PXBroadcastingDidChangeNotification;

@interface PXBroadcastingController : NSObject

@property (strong) NSDictionary *settings;

@property (nonatomic, assign, getter=isBroadcasting) BOOL broadcasting;
@property (nonatomic, assign, getter=isBroadcastingMappedKeys) BOOL broadcastingMappedKeys;


@end
