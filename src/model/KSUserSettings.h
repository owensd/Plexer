//
//  KSUserSettings.h
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KSConfiguration.h"


@interface KSUserSettings : NSObject {
    NSInteger toggleBroadcastingKeyCode;
    NSInteger quitAppKeyCode;
    NSInteger switchBetweenAppsKeyCode;
    NSInteger switchToAppKeyCode;
    NSMutableDictionary* configurations;
    NSString* serialNumber;
    NSString* userName;
}

@property (assign) NSInteger toggleBroadcastingKeyCode;
@property (assign) NSInteger quitAppKeyCode;
@property (assign) NSInteger switchBetweenAppsKeyCode;
@property (assign) NSInteger switchToAppKeyCode;
@property (assign) BOOL automaticallyCheckForUpdates;
@property (assign) BOOL showInMenuBar;
@property (retain) NSString* serialNumber;
@property (retain) NSString* userName;

-(void)addConfigurationWithName:(NSString*)name;
-(void)removeConfigurationWithName:(NSString*)name;
-(void)renameConfigurationWithName:(NSString*)oldName toName:(NSString*)newName;
-(NSDictionary*)configurations;

-(void)addApplication:(ProcessSerialNumber*)psn forConfiguration:(NSString*)name;
-(void)removeApplicationAtIndex:(NSInteger)idx forConfiguration:(NSString*)name;

-(void)addBlackListKey:(NSInteger)keyCode withModifiers:(NSInteger)flags forConfiguration:(NSString*)name;
-(void)removeBlackListKeyAtIndex:(NSInteger)idx forConfiguration:(NSString*)name;

-(void)load;
-(void)serialize;

-(void)setDockHidingEnabled:(BOOL)enabled forConfiguration:(NSString*)name;
-(BOOL)dockHidingEnabledForConfiguration:(NSString*)name;

@end
