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

@synthesize configurations;

-(NSInteger)toggleBroadcastingKeyCode {
    return [[NSUserDefaults standardUserDefaults] integerForKey:ToggleBroadcastingKeyCode];
}
-(void)setToggleBroadcastingKeyCode:(NSInteger)keyCode {
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:ToggleBroadcastingKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)quitAppKeyCode {
    return [[NSUserDefaults standardUserDefaults] integerForKey:QuitAppKeyCode];
}
-(void)setQuitAppKeyCode:(NSInteger)keyCode {
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:QuitAppKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)switchBetweenAppsKeyCode {
    return [[NSUserDefaults standardUserDefaults] integerForKey:SwitchBetweenAppsKeyCode];
}
-(void)setSwitchBetweenAppsKeyCode:(NSInteger)keyCode {
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:SwitchBetweenAppsKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)switchToAppKeyCode {
    return [[NSUserDefaults standardUserDefaults] integerForKey:SwitchToAppKeyCode];
}
-(void)setSwitchToAppKeyCode:(NSInteger)keyCode {
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:SwitchToAppKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)automaticallyCheckForUpdates {
    return [[NSUserDefaults standardUserDefaults] boolForKey:SwitchToAppKeyCode];
}
-(void)setAutomaticallyCheckForUpdates:(BOOL)keyCode {
    [[NSUserDefaults standardUserDefaults] setBool:keyCode forKey:AutomaticallyCheckForUpdates];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
