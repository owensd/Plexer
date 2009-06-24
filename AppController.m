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

-(IBAction)renameCurrentConfiguration:(id)sender {
    if (([configurationsPopUp numberOfItems] - [configurationsPopUp indexOfSelectedItem]) > 2) {
        [configurationNameField setStringValue:[[configurationsPopUp selectedItem] title]];
        [NSApp beginSheet:configurationNamePanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(configurationNameEnded:code:context:) contextInfo:NULL];
    }
}

-(IBAction)addNewConfiguration:(id)sender {
    [NSApp beginSheet:configurationNamePanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(configurationNameEnded:code:context:) contextInfo:NULL];
}

-(void)configurationNameEnded:(NSPanel*)sheet code:(int)choice context:(void*)v {
    NSString* configurationName = [configurationNameField stringValue];
    [configurationNameField setStringValue:@""];
    [sheet orderOut:self];
    
    if (choice == 1) {
        [configurationsPopUp insertItemWithTitle:configurationName atIndex:([configurationsPopUp numberOfItems] - 2)];
        [configurationsPopUp selectItemAtIndex:([configurationsPopUp numberOfItems] - 3)];
    }
    else if (choice == 2) {
        [[configurationsPopUp selectedItem] setTitle:configurationName];
    }
    else {
        [configurationsPopUp selectItemAtIndex:([configurationsPopUp numberOfItems] - 2)];
    }
}

-(IBAction)cancelConfigurationNameSheet:(id)sender {
    [NSApp endSheet:configurationNamePanel returnCode:-1];
}

-(IBAction)closeConfigurationNameSheet:(id)sender {
    if (([configurationsPopUp numberOfItems] - [configurationsPopUp indexOfSelectedItem]) > 2)
        [NSApp endSheet:configurationNamePanel returnCode:2];
    else
        [NSApp endSheet:configurationNamePanel returnCode:1];
}

@end
