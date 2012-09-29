//
//  PXBroadcastingController.m
//  PlexerHelper
//
//  Created by David Owens II on 9/28/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXBroadcastingController.h"

NSString * const PXBroadcastingDidChangeNotification = @"PXBroadcastingDidChangeNotification";

@implementation PXBroadcastingController

- (void)setBroadcastingMappedKeys:(BOOL)broadcastingMappedKeys
{
    _broadcastingMappedKeys = broadcastingMappedKeys;
    [[NSNotificationCenter defaultCenter] postNotificationName:PXBroadcastingDidChangeNotification object:self userInfo:nil];
}

- (void)setBroadcasting:(BOOL)broadcasting
{
    _broadcasting = broadcasting;
    [[NSNotificationCenter defaultCenter] postNotificationName:PXBroadcastingDidChangeNotification object:self userInfo:nil];
}

@end
