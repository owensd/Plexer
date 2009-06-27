//
//  KSUserSettings.h
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KSUserSettings : NSObject {
    NSInteger       toggleBroadcastingKeyCode;
    NSInteger       quitAppKeyCode;
    NSInteger       switchBetweenAppsKeyCode;
    NSInteger       switchToAppKeyCode;
    BOOL            automaticallyCheckForUpdates;
    NSArray*        configurations;
}

@property NSInteger toggleBroadcastingKeyCode;
@property NSInteger quitAppKeyCode;
@property NSInteger switchBetweenAppsKeyCode;
@property NSInteger switchToAppKeyCode;
@property BOOL automaticallyCheckForUpdates;
@property NSArray* configurations;

-(void)saveData;
-(void)loadData;

@end
