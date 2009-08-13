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
NSString* Configurations = @"Configurations";
NSString* KeyCode = @"KeyCode";
NSString* Modifiers = @"Modifiers";
NSString* SerialNumber = @"SerialNumber";
NSString* UserName = @"UserName";
NSString* FirstLaunch = @"FirstLaunch";

-(id)init {
    if (self = [super init]) {
        toggleBroadcastingKeyCode = -1;
        quitAppKeyCode = -1;
        switchBetweenAppsKeyCode = -1;
        switchToAppKeyCode = -1;
        configurations = [[[NSMutableDictionary alloc] init] retain];
    }
    return self;
}

-(NSInteger)toggleBroadcastingKeyCode {
    if (toggleBroadcastingKeyCode == -1 && [[NSUserDefaults standardUserDefaults] objectForKey:ToggleBroadcastingKeyCode] != nil)
        toggleBroadcastingKeyCode = [[NSUserDefaults standardUserDefaults] integerForKey:ToggleBroadcastingKeyCode];
    return toggleBroadcastingKeyCode;
}
-(void)setToggleBroadcastingKeyCode:(NSInteger)keyCode {
    toggleBroadcastingKeyCode = keyCode;
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:ToggleBroadcastingKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)quitAppKeyCode {
    if (quitAppKeyCode == -1 && [[NSUserDefaults standardUserDefaults] objectForKey:QuitAppKeyCode] != nil)
        quitAppKeyCode = [[NSUserDefaults standardUserDefaults] integerForKey:QuitAppKeyCode];
    return quitAppKeyCode;
}
-(void)setQuitAppKeyCode:(NSInteger)keyCode {
    quitAppKeyCode = keyCode;
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:QuitAppKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)switchBetweenAppsKeyCode {
    if (switchBetweenAppsKeyCode == -1 && [[NSUserDefaults standardUserDefaults] objectForKey:SwitchBetweenAppsKeyCode] != nil)
        switchBetweenAppsKeyCode = [[NSUserDefaults standardUserDefaults] integerForKey:SwitchBetweenAppsKeyCode];
    return switchBetweenAppsKeyCode;
}
-(void)setSwitchBetweenAppsKeyCode:(NSInteger)keyCode {
    switchBetweenAppsKeyCode = keyCode;
    [[NSUserDefaults standardUserDefaults] setInteger:keyCode forKey:SwitchBetweenAppsKeyCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)switchToAppKeyCode {
    if (switchToAppKeyCode == -1 && [[NSUserDefaults standardUserDefaults] objectForKey:SwitchToAppKeyCode] != nil)
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

-(NSString*)firstLaunch {
    return [[NSUserDefaults standardUserDefaults] valueForKey:FirstLaunch];
}
-(void)setFirstLaunch:(NSString*)date {
    [[NSUserDefaults standardUserDefaults] setValue:date forKey:FirstLaunch];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)serialize {
    NSDictionary* configData = [[NSMutableDictionary alloc] init];
    for (KSConfiguration* config in [configurations allValues]) {
        [configData setValue:[config configurationAsDictionary] forKey:[config name]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:configData forKey:Configurations];
    [[NSUserDefaults standardUserDefaults] synchronize];    
}

-(void)addConfigurationWithName:(NSString*)name {
    [configurations setValue:[KSConfiguration withName:name] forKey:name];
    [self serialize];
}

-(void)removeConfigurationWithName:(NSString*)name {
    [configurations removeObjectForKey:name];
    [self serialize];
}

-(void)renameConfigurationWithName:(NSString*)oldName toName:(NSString*)newName {
    KSConfiguration* config = [configurations valueForKey:oldName];
    [config setName:newName];
    
    [configurations removeObjectForKey:oldName];
    [configurations setValue:config forKey:newName];
    [self serialize];
}

-(NSDictionary*)configurations {
    return configurations;
}

-(NSString*)userName {
    return [[[NSUserDefaults standardUserDefaults] stringForKey:UserName] autorelease];
}
-(void)setUserName:(NSString*)name {
    [[NSUserDefaults standardUserDefaults] setValue:name forKey:UserName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString*)serialNumber {
    return [[[NSUserDefaults standardUserDefaults] stringForKey:SerialNumber] autorelease];
}
-(void)setSerialNumber:(NSString*)serial {
    [[NSUserDefaults standardUserDefaults] setValue:serial forKey:SerialNumber];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)load {
    [configurations release];
    configurations = [[[NSMutableDictionary alloc] init] retain];
    
    NSDictionary* data = [[NSUserDefaults standardUserDefaults] dictionaryForKey:Configurations];
    for (NSDictionary* configData in [data allValues]) {
        KSConfiguration* config = [KSConfiguration fromDictionary:configData]; 
        [configurations setValue:config forKey:[config name]];
    }
}

-(void)addApplication:(ProcessSerialNumber*)psn forConfiguration:(NSString*)name {
    FSRef fsRef;
    GetProcessBundleLocation(psn, &fsRef);
    
    CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsRef);
    NSString* path = (NSString*)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    CFRelease(url);
    
    ProcessSerialNumber currentPSN;
    GetCurrentProcess(&currentPSN);
    GetProcessBundleLocation(&currentPSN, &fsRef);
    url = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsRef);
    NSString* currentPath = (NSString*)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    CFRelease(url);
    
    // Don't add ourself to the list.
    if ([path isEqualToString:currentPath] == YES)
        return;
    
    KSConfiguration* config = [configurations valueForKey:name];
    for (NSString* appPath in [config applications]) {
        if ([path isEqualToString:appPath] == YES)
            return;     // That application already exists - DON'T ADD IT!.
    }
    NSMutableArray* newApplications = [NSMutableArray arrayWithArray:[config applications]];
    [newApplications addObject:path];
    config.applications = newApplications;
    
    [self serialize];
    
    NSLog(@"Application '%@' was added.", path);
}

-(void)removeApplicationAtIndex:(NSInteger)idx forConfiguration:(NSString*)name {
    KSConfiguration* config = [configurations valueForKey:name];
    NSMutableArray* newApplications = [NSMutableArray arrayWithArray:[config applications]];
    
    // Make sure that 'Applications' doesn't end up being an empty string. That will cause an
    // empty item to be loaded.
    if ([newApplications count] == 1)
        config.applications = nil;
    else {
        [newApplications removeObjectAtIndex:idx];
        config.applications = newApplications;
    }
    
    [self serialize];
}

-(void)addBlackListKey:(NSInteger)keyCode withModifiers:(NSInteger)flags forConfiguration:(NSString*)name {
    KSConfiguration* config = [configurations valueForKey:name];
    for (NSDictionary* aKeyCode in [config blackListKeys]) {
        if ([[aKeyCode valueForKey:KeyCode] integerValue] == keyCode &&
            [[aKeyCode valueForKey:Modifiers] integerValue] == flags)
            return;     // That key code already exists - DON'T ADD IT!.
    }
    NSMutableArray* newKeyCodes = [NSMutableArray arrayWithArray:[config blackListKeys]];
    NSDictionary* theKeyCode = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:keyCode], KeyCode,
                                                                          [NSNumber numberWithInt:flags], Modifiers, nil];
    [newKeyCodes addObject:theKeyCode];
    config.blackListKeys = newKeyCodes;
    
    [self serialize];
    
    NSLog(@"Black list key code '%d' was added.", keyCode);    
}

-(void)removeBlackListKeyAtIndex:(NSInteger)idx forConfiguration:(NSString*)name {
    KSConfiguration* config = [configurations valueForKey:name];
    NSMutableArray* newKeyCodes = [NSMutableArray arrayWithArray:[config blackListKeys]];
    
    // Make sure that 'BlackListKeys' doesn't end up being an empty string. That will cause an
    // empty item to be loaded.
    if ([newKeyCodes count] == 1)
        config.blackListKeys = nil;
    else {
        [newKeyCodes removeObjectAtIndex:idx];
        config.blackListKeys = newKeyCodes;
    }
    
    [self serialize];
}

-(void)setDockHidingEnabled:(BOOL)enabled forConfiguration:(NSString*)name {
    KSConfiguration* config = [configurations valueForKey:name];
    [config setDockHidingEnabled:enabled];
    [self serialize];
}

-(BOOL)dockHidingEnabledForConfiguration:(NSString*)name {
    KSConfiguration* config = [configurations valueForKey:name];
    return [config dockHidingEnabled];
}

@end
