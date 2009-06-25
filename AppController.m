//
//  AppController.m
//  Plexer
//
//  Created by David Owens II on 6/10/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "AppController.h"
#import <Carbon/Carbon.h>
#import "EventHandling.h"
#import "System Events.h"

struct KSApplication {
    AXUIElementRef elementRef;
    ProcessSerialNumber psn;
};

enum KSConfigurationNameOptions {
    kConfigNew      = 1,
    kConfigRename   = 2,
    kConfigCancel   = -1,
    kConfigAddApp   = -100,
};

EventHotKeyRef ToggleBroadcastingHotKeyRef;
EventHotKeyRef QuitAppHotKeyRef;

EventHotKeyID ToggleBroadcastingHotKey = { 'kiad', 1 };
EventHotKeyID QuitHotKey = { 'kiad', 2 };


OSStatus HotKeyEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon) {
    AppController* controller = (AppController*)inRefcon;
    
    EventHotKeyID hotKeyPressed;
    GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(EventHotKeyID), NULL, &hotKeyPressed);
    
    switch (hotKeyPressed.id) {
        case 1:
            if ([controller broadcasting] == YES)
                [controller stopPlexing:controller];
            else
                [controller startPlexing:controller];
            break;
        case 2:
            [[NSApplication sharedApplication] terminate:nil];
            break;
    }
    
    return noErr;
}

@implementation AppController
BOOL previousDockState;

@synthesize broadcasting;

-(void)setBroadcasting:(BOOL)isBroadcasting {
    broadcasting = isBroadcasting;
}

-(IBAction)changeTogglePlexingHotKey:(id)sender {
    UnregisterEventHotKey(ToggleBroadcastingHotKeyRef);
    int togglePlexingKeyCode = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"TogglePlexingKeyCode"] intValue];
    RegisterEventHotKey(togglePlexingKeyCode, 0, ToggleBroadcastingHotKey, GetApplicationEventTarget(), 0, &ToggleBroadcastingHotKeyRef);
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)changeQuitAppHotKey:(id)sender {
    UnregisterEventHotKey(QuitAppHotKeyRef);
    int quitKeyCode = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"QuitPlexerKeyCode"] intValue];
    RegisterEventHotKey(quitKeyCode, 0, QuitHotKey, GetApplicationEventTarget(), 0, &QuitAppHotKeyRef);
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)changeSwitchBetweenAppsKey:(id)sender {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)changeSwitchToAppKey:(id)sender {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)awakeFromNib {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    
    NSBundle* bundle = [NSBundle mainBundle];
    statusImageOn = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"Plexer_ON.png"]];
    statusImageOff = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"Plexer_OFF.png"]];
    
    [statusItem setImage:statusImageOff];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
    
    KSRegisterEventHandlers();
    
    EventTypeSpec kHotKeyEvent = { kEventClassKeyboard, kEventHotKeyPressed };
    InstallApplicationEventHandler(HotKeyEventHandler, 1, &kHotKeyEvent, self, NULL);

    // Setup the hotkeys.
    [self changeTogglePlexingHotKey:self];
    [self changeQuitAppHotKey:self];

    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
    previousDockState = [dockPreferences autohide];
    
    NSArray* configurations = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"];
    int idx = 0;
    for (NSString* config in configurations) {
        [configurationsPopUp insertItemWithTitle:config atIndex:idx];
        ++idx;
    }
    [configurationsPopUp selectItemAtIndex:0];
    [self configurationSelectionChanged:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // be sure that any changes are written out.
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Make sure that we always restore the user's dock state.
    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
    [dockPreferences setAutohide:previousDockState];
    
    KSCleanUp();
    UnregisterEventHotKey(ToggleBroadcastingHotKeyRef);
    UnregisterEventHotKey(QuitAppHotKeyRef);
    
    [statusItem release];
    
    // Shutdown the application.
    [[NSApplication sharedApplication] stop:[NSApplication sharedApplication]];
    
    [super dealloc];
}

-(IBAction)startPlexing:(id)sender {
    [statusItem setImage:statusImageOn];
    [startPlexingItem setHidden:YES];
    [stopPlexingItem setHidden:NO];
    [self setBroadcasting:YES];
    KSChangeBroadcastingTo(true);
}

-(IBAction)stopPlexing:(id)sender {
    [statusItem setImage:statusImageOff];
    [startPlexingItem setHidden:NO];
    [stopPlexingItem setHidden:YES];
    [self setBroadcasting:NO];
    KSChangeBroadcastingTo(false);
}

-(BOOL)configurationsPopUpIsEmpty {
    // The two items are: the seperator and 'New...'
    if ([configurationsPopUp numberOfItems] == 2)
        return YES;
    else
        return NO;
}

-(IBAction)renameCurrentConfiguration:(id)sender {
    NSLog(@"Configuration being renamed from '%@'", [configurationsPopUp titleOfSelectedItem]);
    if ([self configurationsPopUpIsEmpty] == NO) {
        [configurationNameField setStringValue:[configurationsPopUp titleOfSelectedItem]];
        [NSApp beginSheet:configurationNamePanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(configurationNameEnded:code:context:) contextInfo:NULL];
    }
}

-(IBAction)removeCurrentConfiguration:(id)sender {
    if ([self configurationsPopUpIsEmpty] == NO) {
        NSString* configurationName = [configurationsPopUp titleOfSelectedItem];
        NSMutableArray* configurations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"] mutableCopy];
        [configurations removeObject:configurationName];
        [[NSUserDefaults standardUserDefaults] setObject:configurations forKey:@"Configurations"];

        NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
        [settings removeObjectForKey:configurationName];
        [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];

        [[NSUserDefaults standardUserDefaults] synchronize];

        int idx = [configurationsPopUp indexOfSelectedItem];
        [configurationsPopUp removeItemAtIndex:idx];
        --idx;
        if (idx < 0) idx = 0;
        [configurationsPopUp selectItemAtIndex:idx];
    }
}

-(IBAction)addNewConfiguration:(id)sender {
    [NSApp beginSheet:configurationNamePanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(configurationNameEnded:code:context:) contextInfo:NULL];
}

-(void)infoPanelEnded:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:self];
    [NSApp beginSheet:configurationNamePanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(configurationNameEnded:code:context:) contextInfo:NULL];
}

-(void)configurationNameEnded:(NSPanel*)sheet code:(int)choice context:(void*)v {
    if (choice == kConfigCancel) {
        // If there aren't any items in the list, then we want to remove selection from 'New...'
        if ([self configurationsPopUpIsEmpty] == YES)
            [configurationsPopUp selectItemAtIndex:0];

        [sheet orderOut:self];
        return;
    }
    
    NSString* configurationName = [configurationNameField stringValue];
    
    // Determine if the name already exists.
    for (NSString* name in [[NSUserDefaults standardUserDefaults] stringArrayForKey:@"Configurations"]) {
        if ([name isEqualToString:configurationName]) {
            [infoPanel setTitle:@"Invalid Name"];
            [infoPanelMessage setStringValue:@"There is already a configuration with this name!"];
            
            [sheet orderOut:self];
            [NSApp beginSheet:infoPanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(infoPanelEnded:code:context:) contextInfo:NULL];
            
            return;
        }
    }
    
    if (choice == kConfigNew) {
        [configurationsPopUp insertItemWithTitle:configurationName atIndex:([configurationsPopUp numberOfItems] - 2)];
        [configurationsPopUp selectItemAtIndex:([configurationsPopUp numberOfItems] - 3)];
        
        NSArray* theArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"];
        NSMutableArray* configurations = [[NSMutableArray alloc] init];
        [configurations addObjectsFromArray:theArray];
        [configurations addObject:configurationName];
        [[NSUserDefaults standardUserDefaults] setObject:configurations forKey:@"Configurations"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if (choice == kConfigRename) {
        NSString* originalName = [configurationsPopUp titleOfSelectedItem];
        
        NSMutableArray* configurations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"] mutableCopy];
        [configurations removeObject:originalName];
        [configurations addObject:configurationName];
        [[NSUserDefaults standardUserDefaults] setObject:configurations forKey:@"Configurations"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[configurationsPopUp selectedItem] setTitle:configurationName];
        NSLog(@"Configuration renamed from '%@' to '%@'", originalName, [configurationsPopUp titleOfSelectedItem]);

        NSLog(@"Resetting all of the configuration values for the new key.");
        NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
        NSDictionary* config = [settings objectForKey:originalName];
        
        [settings removeObjectForKey:originalName];
        [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
        NSLog(@"Adding the config settings for '%@'", [configurationsPopUp titleOfSelectedItem]);
        [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
     
    
    [configurationNameField setStringValue:@""];
    [sheet orderOut:self];
}

-(IBAction)cancelConfigurationNameSheet:(id)sender {
    [NSApp endSheet:configurationNamePanel returnCode:kConfigCancel];
}

-(IBAction)closeConfigurationNameSheet:(id)sender {
    if ([[configurationNameField stringValue] isEqualToString:@""])
        return;
    
    if ([self configurationsPopUpIsEmpty] == NO)
        [NSApp endSheet:configurationNamePanel returnCode:kConfigRename];
    else
        [NSApp endSheet:configurationNamePanel returnCode:kConfigNew];
}

-(IBAction)configurationSelectionChanged:(id)sender {
    NSLog(@"Title of selected item is: '%@'", [configurationsPopUp titleOfSelectedItem]);
    NSDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] objectForKey:[configurationsPopUp titleOfSelectedItem]];
    
    [autoHideDockBox setState:[[settings objectForKey:@"AutoHideDock"] intValue]];
    [saveWindowSizeBox setState:[[settings objectForKey:@"SaveWindowPositions"] intValue]];
    [moveWindowsNearMenuBarBox setState:[[settings objectForKey:@"AdjustWindowsNearMenuBar"] intValue]];
    
    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
    [dockPreferences setAutohide:[autoHideDockBox state]];    
}

-(IBAction)toggleAutoHideDock:(id)sender {
    NSLog(@"Toggling autohide for '%@'", [configurationsPopUp titleOfSelectedItem]);
    NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
    if (settings == nil)
        settings = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* config = [[settings objectForKey:[configurationsPopUp titleOfSelectedItem]] mutableCopy];
    if (config == nil)
        config = [[NSMutableDictionary alloc] init];

    [config setValue:[NSNumber numberWithInt:[autoHideDockBox state]] forKey:@"AutoHideDock"];
    [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
    [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
    [dockPreferences setAutohide:[autoHideDockBox state]];
}

-(IBAction)toggleSaveWindowPositions:(id)sender {
    NSLog(@"Toggling save window position for '%@'", [configurationsPopUp titleOfSelectedItem]);
    NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
    if (settings == nil)
        settings = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* config = [[settings objectForKey:[configurationsPopUp titleOfSelectedItem]] mutableCopy];
    if (config == nil)
        config = [[NSMutableDictionary alloc] init];
    
    [config setValue:[NSNumber numberWithInt:[saveWindowSizeBox state]] forKey:@"SaveWindowPositions"];
    [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
    [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)toggleMoveWindowNearMenuBar:(id)sender {
    NSLog(@"Toggling move window near menu bar for '%@'", [configurationsPopUp titleOfSelectedItem]);
    NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
    if (settings == nil)
        settings = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* config = [[settings objectForKey:[configurationsPopUp titleOfSelectedItem]] mutableCopy];
    if (config == nil)
        config = [[NSMutableDictionary alloc] init];
    
    [config setValue:[NSNumber numberWithInt:[moveWindowsNearMenuBarBox state]] forKey:@"AdjustWindowsNearMenuBar"];
    [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
    [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)dismissInfoPanel:(id)sender {
    [NSApp endSheet:infoPanel returnCode:0];
}

-(IBAction)addApplication:(id)sender {
    [infoPanelMessage setStringValue:@"Please click on the application you wish to add."];
    [NSApp beginSheet:infoPanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(addApplicationDidEnd:code:context:) contextInfo:NULL];
}

-(void)addApplicationDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:self];
}

@end
