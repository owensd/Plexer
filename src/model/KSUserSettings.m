//
//  KSUserSettings.m
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSUserSettings.h"


@implementation KSUserSettings

NSString* ToggleBroadcastingKeyCode = @"ToggleBroadcastingKeyCode";
NSString* QuitAppKeyCode = @"QuitAppKeyCode";
NSString* SwitchBetweenAppsKeyCode = @"SwitchBetweenAppsKeyCode";
NSString* SwitchToAppKeyCode = @"SwitchToAppKeyCode";
NSString* AutomaticallyCheckForUpdates = @"SUEnableAutomaticChecks";
NSString* ShowInMenuBar = @"ShowInMenuBar";

@synthesize configurations;

-(id)init {
    if (self = [super init]) {
        toggleBroadcastingKeyCode = -1;
        quitAppKeyCode = -1;
        switchBetweenAppsKeyCode = -1;
        switchToAppKeyCode = -1;
    }
    return self;
}

-(NSInteger)toggleBroadcastingKeyCode {
    if (toggleBroadcastingKeyCode == -1)
        toggleBroadcastingKeyCode = [[NSUserDefaults standardUserDefaults] integerForKey:ToggleBroadcastingKeyCode];
    return toggleBroadcastingKeyCode;
}
-(void)setToggleBroadcastingKeyCode:(NSInteger)keyCode {
    toggleBroadcastingKeyCode = keyCode;
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:ToggleBroadcastingKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)quitAppKeyCode {
    if (quitAppKeyCode == -1)
        quitAppKeyCode = [[NSUserDefaults standardUserDefaults] integerForKey:QuitAppKeyCode];
    return quitAppKeyCode;
}
-(void)setQuitAppKeyCode:(NSInteger)keyCode {
    quitAppKeyCode = keyCode;
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:QuitAppKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)switchBetweenAppsKeyCode {
    if (switchBetweenAppsKeyCode == -1)
        switchBetweenAppsKeyCode = [[NSUserDefaults standardUserDefaults] integerForKey:SwitchBetweenAppsKeyCode];
    return switchBetweenAppsKeyCode;
}
-(void)setSwitchBetweenAppsKeyCode:(NSInteger)keyCode {
    switchBetweenAppsKeyCode = keyCode;
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:SwitchBetweenAppsKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)switchToAppKeyCode {
    if (switchToAppKeyCode == -1)
        switchToAppKeyCode = [[NSUserDefaults standardUserDefaults] integerForKey:SwitchToAppKeyCode];
    return switchToAppKeyCode;
}
-(void)setSwitchToAppKeyCode:(NSInteger)keyCode {
    switchToAppKeyCode = keyCode;
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:SwitchToAppKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)automaticallyCheckForUpdates {
    return [[NSUserDefaults standardUserDefaults] boolForKey:AutomaticallyCheckForUpdates];
}
-(void)setAutomaticallyCheckForUpdates:(BOOL)keyCode {
    [[NSUserDefaults standardUserDefaults] setBool:keyCode forKey:AutomaticallyCheckForUpdates];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)showInMenuBar {
    return [[NSUserDefaults standardUserDefaults] boolForKey:ShowInMenuBar];
}
-(void)setShowInMenuBar:(BOOL)showInMenu {
    [[NSUserDefaults standardUserDefaults] setBool:showInMenu forKey:ShowInMenuBar];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
