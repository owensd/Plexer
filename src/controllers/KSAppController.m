//
//  AppController.m
//  Plexer
//
//  Created by David Owens II on 6/10/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSAppController.h"
#import "System Events.h"

CFMachPortRef keyEventTapRef = NULL;
CFMachPortRef appEventTapRef = NULL;
CFRunLoopSourceRef runLoopSourceRef = NULL;
CFRunLoopRef runLoopRef = NULL;

CGEventRef KeyEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);

@implementation KSAppController

NSStatusItem* statusItem = nil;
NSImage* statusImageOn = nil;
NSImage* statusImageOff = nil;


@synthesize broadcasting;
-(void)setBroadcasting:(BOOL)broadcast {
    broadcasting = broadcast;
    if (broadcasting == YES)
        [statusItem setImage:statusImageOn];
    else
        [statusItem setImage:statusImageOff];
}

-(KSUserSettings*)userSettings {
    return userSettings;
}

-(void)createStatusItem {   
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    
    [statusItem setImage:statusImageOff];
    [statusItem setMenu:statusItemMenu];
    [statusItem setHighlightMode:YES];
}

-(void)createStatusItemWithPathForImage:(NSString*)onImagePath pathForOffImage:(NSString*)offImagePath {
    NSBundle* bundle = [NSBundle mainBundle];
    statusImageOn = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:onImagePath]] retain];
    statusImageOff = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:offImagePath]] retain];
    
    if ([userSettings showInMenuBar] == YES)
        [self createStatusItem];
}

-(void)awakeFromNib {
    // Sparkle doesn't automatically check for updates on startup so we manually do it here.
    if ([userSettings automaticallyCheckForUpdates] == YES)
        [updater checkForUpdatesInBackground];

    self.broadcasting = false;
    
    [self createStatusItemWithPathForImage:@"Plexer_ON.png" pathForOffImage:@"Plexer_OFF.png"];
    [self createEventTaps];
}

-(void)applicationWillTerminate:(NSNotification*)aNotification {
    CFMachPortInvalidate(keyEventTapRef);
//    CFMachPortInvalidate(appEventTapRef);
    CFRelease(keyEventTapRef);
//    CFRelease(appEventTapRef);
    CFRelease(runLoopSourceRef);
}

-(IBAction)showPreferences:(id)sender {
    [preferencesWindow makeKeyAndOrderFront:self];
}

-(IBAction)startBroadcasting:(id)sender {
    self.broadcasting = !self.broadcasting;
}

-(IBAction)stopBroadcasting:(id)sender {
    self.broadcasting = !self.broadcasting;
}

-(void)showStatusItem {
    [self createStatusItem];
}

-(void)hideStatusItem {
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    [statusItem release];
}


// ------------------------------------------------------
// Event tap methods
// ------------------------------------------------------

-(void)createEventTaps {
    keyEventTapRef = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged), KeyEventTapCallback, self);
    
    if (keyEventTapRef == NULL) {
        NSLog(@"There was an error creating the event tap.");
        exit(1);
    }
    
    runLoopSourceRef = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, keyEventTapRef, 0);
    if (runLoopSourceRef == NULL) {
        NSLog(@"There was an error creating the run loop source.");
        exit(1);
    }
    
    runLoopRef = [[NSRunLoop currentRunLoop] getCFRunLoop];
    if (runLoopRef == NULL) {
        NSLog(@"There was an error retrieving the current run loop.");
        exit(1);
    }
    
    CFRunLoopAddSource(runLoopRef, runLoopSourceRef, kCFRunLoopDefaultMode);
}

CGEventRef KeyEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    KSAppController* controller = (KSAppController*)refcon;
    
    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    if (type == kCGEventKeyUp) {
        NSLog(@"The %d key was released.", keyCode);
    }
    else if (type == kCGEventKeyDown) {
        NSLog(@"The %d key was pressed.", keyCode);

        if (keyCode == [[controller userSettings] toggleBroadcastingKeyCode])
            controller.broadcasting = !controller.broadcasting;
        if (keyCode == [[controller userSettings] quitAppKeyCode])
            [[NSApplication sharedApplication] terminate:nil];
    }
    else if (type == kCGEventFlagsChanged) {
        NSLog(@"The %d flags changed.", keyCode);
    }
    
    return event;
}

CGEventRef AppEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    return event;
}

// ------------------------------------------------------
// Sparkle delegate methods
// ------------------------------------------------------

// We never want the user to be prompted by the Sparkle UI to automatically check for updates.
-(BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater*)bundle {
    return NO;
}

@end


//struct KSApplication {
//    AXUIElementRef elementRef;
//    ProcessSerialNumber psn;
//};
//
//enum KSConfigurationNameOptions {
//    kConfigNew      = 1,
//    kConfigRename   = 2,
//    kConfigCancel   = -1,
//    kConfigAddApp   = -100,
//};
//
//EventHotKeyRef ToggleBroadcastingHotKeyRef;
//EventHotKeyRef QuitAppHotKeyRef;
//
//EventHotKeyID ToggleBroadcastingHotKey = { 'kiad', 1 };
//EventHotKeyID QuitHotKey = { 'kiad', 2 };
//
//EventHandlerRef AddApplicationEventHandlerRef;
//
//CFMachPortRef AddKeyEventTap;
//
//OSStatus HotKeyEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon) {
//    AppController* controller = (AppController*)inRefcon;
//    
//    EventHotKeyID hotKeyPressed;
//    GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(EventHotKeyID), NULL, &hotKeyPressed);
//    
//    switch (hotKeyPressed.id) {
//        case 1:
//            if ([controller broadcasting] == YES)
//                [controller stopPlexing:controller];
//            else
//                [controller startPlexing:controller];
//            break;
//        case 2:
//            [[NSApplication sharedApplication] terminate:nil];
//            break;
//    }
//    
//    return noErr;
//}
//
//CGEventRef AddKeyEventHandler(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
//    NSLog(@"in the key tap.");
//    
//    return NULL;
//}
//
//
//static OSStatus AddApplicationEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon) {
//    AppController* controller = (AppController*)inRefcon;
//
//    ProcessSerialNumber psn;
//    CFStringRef processName = NULL;
//    
//    GetEventParameter(inEvent, kEventParamProcessID, typeProcessSerialNumber, NULL, sizeof(ProcessSerialNumber), NULL, &psn);
//    CopyProcessName(&psn, &processName);
//    
//    [controller insertApplication:&psn];
//
//    return noErr;
//}
//
//@implementation AppController
//BOOL previousDockState;
//
//@synthesize broadcasting, applications, applicationConfigurationEnabled;
//
//-(void)setBroadcasting:(BOOL)isBroadcasting {
//    broadcasting = isBroadcasting;
//}
//
//-(IBAction)changeTogglePlexingHotKey:(id)sender {
//    UnregisterEventHotKey(ToggleBroadcastingHotKeyRef);
//    int togglePlexingKeyCode = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"TogglePlexingKeyCode"] intValue];
//    if (togglePlexingKeyCode != -1)
//        RegisterEventHotKey(togglePlexingKeyCode, 0, ToggleBroadcastingHotKey, GetApplicationEventTarget(), 0, &ToggleBroadcastingHotKeyRef);
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}
//
//-(IBAction)changeQuitAppHotKey:(id)sender {
//    UnregisterEventHotKey(QuitAppHotKeyRef);
//    int quitKeyCode = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"QuitPlexerKeyCode"] intValue];
//    if (quitKeyCode != -1)
//        RegisterEventHotKey(quitKeyCode, 0, QuitHotKey, GetApplicationEventTarget(), 0, &QuitAppHotKeyRef);
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}
//
//-(IBAction)changeSwitchBetweenAppsKey:(id)sender {
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}
//
//-(IBAction)changeSwitchToAppKey:(id)sender {
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}
//
//-(void)awakeFromNib {
//    if ([updater automaticallyChecksForUpdates] == YES)
//        [updater checkForUpdatesInBackground];
//    
//    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
//    
//    NSBundle* bundle = [NSBundle mainBundle];
//    statusImageOn = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"Plexer_ON.png"]];
//    statusImageOff = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"Plexer_OFF.png"]];
//    
//    [statusItem setImage:statusImageOff];
//    [statusItem setMenu:statusMenu];
//    [statusItem setHighlightMode:YES];
//    
//    KSRegisterEventHandlers();
//    
//    EventTypeSpec kHotKeyEvent = { kEventClassKeyboard, kEventHotKeyPressed };
//    InstallApplicationEventHandler(HotKeyEventHandler, 1, &kHotKeyEvent, self, NULL);
//
//    // Setup the hotkeys.
//    [self changeTogglePlexingHotKey:self];
//    [self changeQuitAppHotKey:self];
//
//    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
//    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
//    previousDockState = [dockPreferences autohide];
//    
//    NSArray* configurations = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"];
//    int idx = 0;
//    for (NSString* config in configurations) {
//        [configurationsPopUp insertItemWithTitle:config atIndex:idx];
//        [configurationsPopUp itemAtIndex:idx].tag = 1;
//        ++idx;
//    }
//    [configurationsPopUp selectItemAtIndex:0];
//    [self configurationSelectionChanged:self];
//    
//    //[applicationsTableView registerForDraggedTypes:[NSArray arrayWithObject:@"NSString"]];
//}
//
//- (void)applicationWillTerminate:(NSNotification *)aNotification {
//    // be sure that any changes are written out.
//    [[NSUserDefaults standardUserDefaults] synchronize];
//
//    // Make sure that we always restore the user's dock state.
//    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
//    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
//    [dockPreferences setAutohide:previousDockState];
//    
//    KSCleanUp();
//    UnregisterEventHotKey(ToggleBroadcastingHotKeyRef);
//    UnregisterEventHotKey(QuitAppHotKeyRef);
//    
//    [statusItem release];
//    
//    // Shutdown the application.
//    [[NSApplication sharedApplication] stop:[NSApplication sharedApplication]];
//    
//    [super dealloc];
//}
//
//-(IBAction)startPlexing:(id)sender {
//    [statusItem setImage:statusImageOn];
//    [startPlexingItem setHidden:YES];
//    [stopPlexingItem setHidden:NO];
//    [self setBroadcasting:YES];
//    KSChangeBroadcastingTo(true);
//}
//
//-(IBAction)stopPlexing:(id)sender {
//    [statusItem setImage:statusImageOff];
//    [startPlexingItem setHidden:NO];
//    [stopPlexingItem setHidden:YES];
//    [self setBroadcasting:NO];
//    KSChangeBroadcastingTo(false);
//}
//
//-(BOOL)configurationsPopUpIsEmpty {
//    // The two items are: the seperator and 'New...'
//    if ([configurationsPopUp numberOfItems] == 2)
//        return YES;
//    else
//        return NO;
//}
//
//-(IBAction)renameCurrentConfiguration:(id)sender {
//    NSLog(@"Configuration being renamed from '%@'", [configurationsPopUp titleOfSelectedItem]);
//    if ([self configurationsPopUpIsEmpty] == NO) {
//        [configurationNameField setStringValue:[configurationsPopUp titleOfSelectedItem]];
//        [NSApp beginSheet:configurationNamePanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(configurationNameEnded:code:context:) contextInfo:NULL];
//    }
//}
//
//-(IBAction)removeCurrentConfiguration:(id)sender {
//    if ([self configurationsPopUpIsEmpty] == NO) {
//        NSString* configurationName = [configurationsPopUp titleOfSelectedItem];
//        NSMutableArray* configurations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"] mutableCopy];
//        [configurations removeObject:configurationName];
//        [[NSUserDefaults standardUserDefaults] setObject:configurations forKey:@"Configurations"];
//
//        NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
//        [settings removeObjectForKey:configurationName];
//        [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
//
//        [[NSUserDefaults standardUserDefaults] synchronize];
//
//        int idx = [configurationsPopUp indexOfSelectedItem];
//        [configurationsPopUp removeItemAtIndex:idx];
//        --idx;
//        if (idx < 0) idx = 0;
//        [configurationsPopUp selectItemAtIndex:idx];
//    }
//}
//
//-(IBAction)addNewConfiguration:(id)sender {
//    [NSApp beginSheet:configurationNamePanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(configurationNameEnded:code:context:) contextInfo:NULL];
//}
//
//-(void)infoPanelEnded:(NSPanel*)sheet code:(int)choice context:(void*)v {
//    [sheet orderOut:self];
//    [NSApp beginSheet:configurationNamePanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(configurationNameEnded:code:context:) contextInfo:NULL];
//}
//
//-(void)configurationNameEnded:(NSPanel*)sheet code:(int)choice context:(void*)v {
//    if (choice == kConfigCancel) {
//        // If there aren't any items in the list, then we want to remove selection from 'New...'
//        if ([self configurationsPopUpIsEmpty] == YES)
//            [configurationsPopUp selectItemAtIndex:0];
//
//        [sheet orderOut:self];
//        return;
//    }
//    
//    NSString* configurationName = [configurationNameField stringValue];
//    
//    // Determine if the name already exists.
//    for (NSString* name in [[NSUserDefaults standardUserDefaults] stringArrayForKey:@"Configurations"]) {
//        if ([name isEqualToString:configurationName]) {
//            [infoPanel setTitle:@"Invalid Name"];
//            [infoPanelMessage setStringValue:@"There is already a configuration with this name!"];
//            [infoPanelButton setTitle:@"OK"];
//            
//            [sheet orderOut:self];
//            [NSApp beginSheet:infoPanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(infoPanelEnded:code:context:) contextInfo:NULL];
//            
//            return;
//        }
//    }
//    
//    if (choice == kConfigNew) {
//        [configurationsPopUp insertItemWithTitle:configurationName atIndex:([configurationsPopUp numberOfItems] - 2)];
//        [configurationsPopUp selectItemAtIndex:([configurationsPopUp numberOfItems] - 3)];
//        [configurationsPopUp selectedItem].tag = 1;
//        
//        NSArray* theArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"];
//        NSMutableArray* configurations = [[NSMutableArray alloc] init];
//        [configurations addObjectsFromArray:theArray];
//        [configurations addObject:configurationName];
//        [[NSUserDefaults standardUserDefaults] setObject:configurations forKey:@"Configurations"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
//    else if (choice == kConfigRename) {
//        NSString* originalName = [configurationsPopUp titleOfSelectedItem];
//        
//        NSMutableArray* configurations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"Configurations"] mutableCopy];
//        [configurations removeObject:originalName];
//        [configurations addObject:configurationName];
//        [[NSUserDefaults standardUserDefaults] setObject:configurations forKey:@"Configurations"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//        
//        [[configurationsPopUp selectedItem] setTitle:configurationName];
//        NSLog(@"Configuration renamed from '%@' to '%@'", originalName, [configurationsPopUp titleOfSelectedItem]);
//
//        NSLog(@"Resetting all of the configuration values for the new key.");
//        NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
//        NSDictionary* config = [settings objectForKey:originalName];
//        
//        [settings removeObjectForKey:originalName];
//        [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
//        NSLog(@"Adding the config settings for '%@'", [configurationsPopUp titleOfSelectedItem]);
//        [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
//     
//    
//    [configurationNameField setStringValue:@""];
//    [sheet orderOut:self];
//}
//
//-(IBAction)cancelConfigurationNameSheet:(id)sender {
//    [NSApp endSheet:configurationNamePanel returnCode:kConfigCancel];
//}
//
//-(IBAction)closeConfigurationNameSheet:(id)sender {
//    if ([[configurationNameField stringValue] isEqualToString:@""])
//        return;
//    
//    if ([self configurationsPopUpIsEmpty] == NO)
//        [NSApp endSheet:configurationNamePanel returnCode:kConfigRename];
//    else
//        [NSApp endSheet:configurationNamePanel returnCode:kConfigNew];
//}
//
//-(IBAction)configurationSelectionChanged:(id)sender {
//    NSLog(@"Title of selected item is: '%@'", [configurationsPopUp titleOfSelectedItem]);
//    NSDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] objectForKey:[configurationsPopUp titleOfSelectedItem]];
//    
//    [autoHideDockBox setState:[[settings objectForKey:@"AutoHideDock"] intValue]];
//    [saveWindowSizeBox setState:[[settings objectForKey:@"SaveWindowPositions"] intValue]];
//    [moveWindowsNearMenuBarBox setState:[[settings objectForKey:@"AdjustWindowsNearMenuBar"] intValue]];
//    
//    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
//    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
//    [dockPreferences setAutohide:[autoHideDockBox state]];
//    
//    [applications release];
//    applications = [[[NSMutableArray alloc] initWithArray:[[settings objectForKey:@"Applications"] componentsSeparatedByString:@":"]] retain];
//    [applicationsTableView reloadData];
//    
//    applicationConfigurationEnabled = [self configurationsPopUpIsEmpty];
//}
//
//-(IBAction)toggleAutoHideDock:(id)sender {
//    NSLog(@"Toggling autohide for '%@'", [configurationsPopUp titleOfSelectedItem]);
//    NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
//    if (settings == nil)
//        settings = [[NSMutableDictionary alloc] init];
//    NSMutableDictionary* config = [[settings objectForKey:[configurationsPopUp titleOfSelectedItem]] mutableCopy];
//    if (config == nil)
//        config = [[NSMutableDictionary alloc] init];
//
//    [config setValue:[NSNumber numberWithInt:[autoHideDockBox state]] forKey:@"AutoHideDock"];
//    [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
//    [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    
//    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
//    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
//    [dockPreferences setAutohide:[autoHideDockBox state]];
//}
//
//-(IBAction)toggleSaveWindowPositions:(id)sender {
//    NSLog(@"Toggling save window position for '%@'", [configurationsPopUp titleOfSelectedItem]);
//    NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
//    if (settings == nil)
//        settings = [[NSMutableDictionary alloc] init];
//    NSMutableDictionary* config = [[settings objectForKey:[configurationsPopUp titleOfSelectedItem]] mutableCopy];
//    if (config == nil)
//        config = [[NSMutableDictionary alloc] init];
//    
//    [config setValue:[NSNumber numberWithInt:[saveWindowSizeBox state]] forKey:@"SaveWindowPositions"];
//    [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
//    [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}
//
//-(IBAction)toggleMoveWindowNearMenuBar:(id)sender {
//    NSLog(@"Toggling move window near menu bar for '%@'", [configurationsPopUp titleOfSelectedItem]);
//    NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
//    if (settings == nil)
//        settings = [[NSMutableDictionary alloc] init];
//    NSMutableDictionary* config = [[settings objectForKey:[configurationsPopUp titleOfSelectedItem]] mutableCopy];
//    if (config == nil)
//        config = [[NSMutableDictionary alloc] init];
//    
//    [config setValue:[NSNumber numberWithInt:[moveWindowsNearMenuBarBox state]] forKey:@"AdjustWindowsNearMenuBar"];
//    [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
//    [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}
//
//-(IBAction)dismissInfoPanel:(id)sender {
//    [NSApp endSheet:infoPanel returnCode:0];
//}
//
//-(IBAction)addApplication:(id)sender {
//    [infoPanelMessage setStringValue:@"Please click on the application(s) you wish to add."];
//    [infoPanelButton setTitle:@"Done"];
//    [NSApp beginSheet:infoPanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(addApplicationDidEnd:code:context:) contextInfo:NULL];
//    
//    EventTypeSpec kAppEvents[] = {
//        { kEventClassApplication, kEventAppFrontSwitched },
//    };
//    
//    InstallApplicationEventHandler(AddApplicationEventHandler, GetEventTypeCount(kAppEvents), kAppEvents, self, &AddApplicationEventHandlerRef);
//}
//
//-(IBAction)removeApplication:(id)sender {
//    int idx = [applicationsTableView selectedRow];
//    if (idx >= 0) {
//        [applications removeObjectAtIndex:idx];
//        [applicationsTableView reloadData];
//        
//        --idx;
//        if (idx < 0) idx = 0;
//        [applicationsTableView selectRow:idx byExtendingSelection:NO];
//        
//        NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
//        NSMutableDictionary* config = [[settings objectForKey:[configurationsPopUp titleOfSelectedItem]] mutableCopy];
//        if (config == nil) config = [[NSMutableDictionary alloc] init];
//        
//        NSString* appSetting = [applications componentsJoinedByString:@":"];
//        [config setValue:appSetting forKey:@"Applications"];
//        [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
//        [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
//}
//
//-(void)addApplicationDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)v {
//    [sheet orderOut:self];
//    RemoveEventHandler(AddApplicationEventHandlerRef);
//}
//
//-(void)insertApplication:(ProcessSerialNumber*)psn {
//    FSRef fsRef;
//    GetProcessBundleLocation(psn, &fsRef);
//    
//    CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsRef);
//    NSString* path = (NSString*)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
//    CFRelease(url);
//    
//    ProcessSerialNumber currentPSN;
//    GetCurrentProcess(&currentPSN);
//    GetProcessBundleLocation(&currentPSN, &fsRef);
//    url = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsRef);
//    NSString* currentPath = (NSString*)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
//    CFRelease(url);
//    
//    // Don't add ourself or any duplicates.
//    if ([path isEqualToString:currentPath] == YES)
//        return;
//    
//    if (applications == nil)
//        applications = [[[NSMutableArray alloc] init] retain];
//    
//    for (NSString* str in applications) {
//        if ([str isEqualToString:path] == YES)
//            return;
//    }
//    
//    [applications addObject:(NSString*)path];
//    [applicationsTableView reloadData];
//    
//    NSMutableDictionary* settings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ConfigurationSettings"] mutableCopy];
//    NSMutableDictionary* config = [[settings objectForKey:[configurationsPopUp titleOfSelectedItem]] mutableCopy];
//    if (config == nil) config = [[NSMutableDictionary alloc] init];
//    
//    NSString* appSetting = [applications componentsJoinedByString:@":"];
//    [config setValue:appSetting forKey:@"Applications"];
//    [settings setValue:config forKey:[configurationsPopUp titleOfSelectedItem]];
//    [[NSUserDefaults standardUserDefaults] setValue:settings forKey:@"ConfigurationSettings"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}
//
//-(IBAction)addKeys:(id)sender {
//    [infoPanelMessage setStringValue:@"Press the key with any modifier you wish to add."];
//    [infoPanelButton setTitle:@"Done"];
//    [NSApp beginSheet:infoPanel modalForWindow:plexerPanel modalDelegate:self didEndSelector:@selector(addKeyDidEnd:code:context:) contextInfo:NULL];
//
//    ProcessSerialNumber psn;
//    GetCurrentProcess(&psn);
//    
//    AddKeyEventTap = CGEventTapCreateForPSN(&psn, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, kCGEventKeyDown, AddKeyEventHandler, self);
//}
//
//-(void)addKeyDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)v {
//    [sheet orderOut:self];
//    CFRelease(AddKeyEventTap);
//}
//
//-(IBAction)removeKeys:(id)sender {
//}
//
//-(IBAction)changeKeyOptionSelected:(id)sender {
//}
//
//
//// ---------------------------------------------------------------
//// Data source methods for the table views.
//
//-(NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView {
//    if ([aTableView isEqual:applicationsTableView] == YES) {
//        return [applications count];
//    }
//    
//    return 0;
//}
//
//-(id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex {
//    if ([aTableView isEqual:applicationsTableView] == YES) {
//        if ([[aTableColumn identifier] isEqualToString:@"position"] == YES)
//            return [NSString stringWithFormat:@"%d", (rowIndex + 1)];
//        else if ([[aTableColumn identifier] isEqualToString:@"title"] == YES) {
//            NSLog(@"Returning friendly name for '@'", [applications objectAtIndex:rowIndex]);
//            NSString* str = [[applications objectAtIndex:rowIndex] stringByDeletingPathExtension];            
//            return  [[str pathComponents] lastObject];
//        }
//        else
//            return [applications objectAtIndex:rowIndex];
//    }
//    
//    return nil;
//}

//-(BOOL)tableView:(NSTableView*)aTableView writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard {
//    if ([aTableView isEqual:applicationsTableView] == YES) {
//        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
//        [pboard declareTypes:[NSArray arrayWithObject:@"NSString"] owner:self];
//        [pboard setData:data forType:@"NSString"];
//        
//        return YES;
//    }
//    
//    return NO;
//}
//
//-(NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
//    NSLog(@"validate Drop");
//    return NSDragOperationEvery;
//}
//
//- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
//{
//    NSPasteboard* pboard = [info draggingPasteboard];
//    NSData* rowData = [pboard dataForType:@"NSString"];
//    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
//    int dragRow = [rowIndexes firstIndex];
//    
//    [applications insertObject:(NSString*)rowData atIndex:row];
//    [aTableView reloadData];
//    
//    return YES;
//}

