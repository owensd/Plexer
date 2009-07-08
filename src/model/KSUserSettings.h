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
}

@property (assign) NSInteger toggleBroadcastingKeyCode;
@property (assign) NSInteger quitAppKeyCode;
@property (assign) NSInteger switchBetweenAppsKeyCode;
@property (assign) NSInteger switchToAppKeyCode;
@property (assign) BOOL automaticallyCheckForUpdates;
@property (assign) BOOL showInMenuBar;

-(void)addConfigurationWithName:(NSString*)name;
-(void)removeConfigurationWithName:(NSString*)name;
-(void)renameConfigurationWithName:(NSString*)oldName toName:(NSString*)newName;
-(NSDictionary*)configurations;

-(void)addApplication:(NSString*)processName forConfiguration:(NSString*)config;
-(void)removeApplication:(NSString*)processName forConfiguration:(NSString*)config;

-(void)load;
-(void)serialize;

@end
