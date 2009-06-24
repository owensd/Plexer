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
}

-(IBAction)changeQuitAppHotKey:(id)sender {
    UnregisterEventHotKey(QuitAppHotKeyRef);
    int quitKeyCode = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"QuitPlexerKeyCode"] intValue];
    RegisterEventHotKey(quitKeyCode, 0, QuitHotKey, GetApplicationEventTarget(), 0, &QuitAppHotKeyRef);
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

    BOOL hideDock = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"HideDock"] boolValue];

    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
    previousDockState = [dockPreferences autohide];

    if (hideDock == YES) {
        [dockPreferences setAutohide:YES];
    }
    
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
    if (([configurationsPopUp numberOfItems] - [configurationsPopUp indexOfSelectedItem]) <= 2)
        return YES;
    else
        return NO;
}

-(IBAction)renameCurrentConfiguration:(id)sender {
    if ([self configurationsPopUpIsEmpty] == NO) {
        [configurationNameField setStringValue:[[configurationsPopUp selectedItem] title]];
        [NSApp beginSheet:configurationNamePanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(configurationNameEnded:code:context:) contextInfo:NULL];
    }
}

-(IBAction)removeCurrentConfiguration:(id)sender {
    if ([self configurationsPopUpIsEmpty] == NO) {
        NSMutableArray* configurations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"] mutableCopy];
        [configurations removeObject:[configurationsPopUp titleOfSelectedItem]];
        [[NSUserDefaults standardUserDefaults] setObject:configurations forKey:@"Configurations"];
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

-(void)configurationNameEnded:(NSPanel*)sheet code:(int)choice context:(void*)v {
    NSString* configurationName = [configurationNameField stringValue];
    [configurationNameField setStringValue:@""];
    [sheet orderOut:self];
    
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
        NSMutableArray* configurations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"] mutableCopy];
        [configurations removeObject:[[configurationsPopUp selectedItem] title]];
        [configurations addObject:configurationName];
        [[NSUserDefaults standardUserDefaults] setObject:configurations forKey:@"Configurations"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[configurationsPopUp selectedItem] setTitle:configurationName];
    }
    else if (choice == kConfigCancel) {
        // If there aren't any items in the list, then we want to remove selection from 'New...'
        if ([self configurationsPopUpIsEmpty] == YES)
            [configurationsPopUp selectItemAtIndex:0];
    }
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
    NSDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] objectForKey:[configurationsPopUp titleOfSelectedItem]];
    
    [autoHideDockBox setState:(int)[settings objectForKey:@"AutoHideDock"]];
    [saveWindowSizeBox setState:(int)[settings objectForKey:@"SaveWindowPositions"]];
    [moveWindowsNearMenuBarBox setState:(int)[settings objectForKey:@"AdjustWindowsNearMenuBar"]];
}

-(IBAction)toggleAutoHideDock:(id)sender {
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
}

-(IBAction)toggleSaveWindowPositions:(id)sender {
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


@end
