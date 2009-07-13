//
//  AppController.m
//  Plexer
//
//  Created by David Owens II on 6/10/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSAppController.h"
#import "System Events.h"
#import <Carbon/Carbon.h>

static OSStatus AddApplicationEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon);

@implementation KSAppController

CFMachPortRef keyEventTapRef = NULL;
CFRunLoopSourceRef runLoopSourceRef = NULL;
CFRunLoopRef runLoopRef = NULL;

EventHandlerRef AddApplicationEventHandlerRef;

CGEventRef KeyEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);

NSStatusItem* statusItem = nil;
NSImage* statusImageOn = nil;
NSImage* statusImageOff = nil;

BOOL dockAutoHide;


@synthesize broadcasting, applications, configurationsController;
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
    // Save the user's dock state.
    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
    dockAutoHide = [dockPreferences autohide];
    
    // Sparkle doesn't automatically check for updates on startup so we manually do it here.
    if ([userSettings automaticallyCheckForUpdates] == YES)
        [updater checkForUpdatesInBackground];

    self.broadcasting = false;
    
    [configurationsController loadConfigurations];

    [self createStatusItemWithPathForImage:@"Plexer_ON.png" pathForOffImage:@"Plexer_OFF.png"];
    [self registerEventTaps];    
}

-(void)applicationWillTerminate:(NSNotification*)aNotification {
    CFMachPortInvalidate(keyEventTapRef);
    CFRelease(keyEventTapRef);
    CFRelease(runLoopSourceRef);

    SystemEventsApplication* systemEventsApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
    SystemEventsDockPreferencesObject* dockPreferences = [systemEventsApplication dockPreferences];
    [dockPreferences setAutohide:dockAutoHide];
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

-(void)registerEventTaps {
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


    EventTypeSpec kAppEvents[] = {
        { kEventClassApplication, kEventAppFrontSwitched },
        { kEventClassApplication, kEventAppLaunched },
    };
    
    InstallApplicationEventHandler(AddApplicationEventHandler, GetEventTypeCount(kAppEvents), kAppEvents, self, &AddApplicationEventHandlerRef);
}

CGEventRef KeyEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    KSAppController* controller = (KSAppController*)refcon;
    
    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    if (type == kCGEventKeyDown) {
        NSLog(@"The %d key was pressed.", keyCode);

        if (keyCode == [[controller userSettings] toggleBroadcastingKeyCode]) {
            controller.broadcasting = !controller.broadcasting;
            return NULL;
        }
        if (keyCode == [[controller userSettings] quitAppKeyCode]) {
            [[NSApplication sharedApplication] terminate:nil];
            return NULL;
        }
    }
        
    if ([controller isBroadcasting] == NO)
        return event;
    
    CGEventFlags flags = CGEventGetFlags(event);

   // NSArray* blackListKeys = [[[[controller userSettings] configurations] valueForKey:[[[controller configurationsController] configurationsPopUp] titleOfSelectedItem]] blackListKeys];
//    for (NSDictionary* key in blackListKeys) {
//        if ([[key valueForKey:@"KeyCode"] intValue] == keyCode &&
//            [[key valueForKey:@"Modifiers"] intValue] == flags)
//            return event;
//    }
    
    // We have the key so let's broadcast it to all of our applications!
    ProcessSerialNumber currentPSN;
    pid_t currentPID;
    GetCurrentProcess(&currentPSN);
    GetProcessPID(&currentPSN, &currentPID);
    
    
    for (NSApplication* app in [controller applications]) {
        pid_t pid = [[app valueForKey:@"NSApplicationProcessIdentifier"] intValue];
        AXUIElementRef appRef = AXUIElementCreateApplication(pid);
        if (currentPID != pid) {
            switch (type) {
                case kCGEventKeyDown:
                    //CGEventPostToPSN(&psn, CGEventCreateKeyboardEvent(NULL, flags, true));
                    //CGEventPostToPSN(&psn, CGEventCreateKeyboardEvent(NULL, keyCode, true));
                    AXUIElementPostKeyboardEvent(appRef, 0, flags, true);
                    AXUIElementPostKeyboardEvent(appRef, 0, keyCode, true);
                    //[app sendEvent:[NSEvent eventWithCGEvent:event]];
                    break;
                    
                case kEventRawKeyUp:
                    //CGEventPostToPSN(&psn, CGEventCreateKeyboardEvent(NULL, keyCode, false));
                    //CGEventPostToPSN(&psn, CGEventCreateKeyboardEvent(NULL, flags, false));
//                    [app sendEvent:[NSEvent eventWithCGEvent:event]];
                    AXUIElementPostKeyboardEvent(appRef, 0, keyCode, false);
                    AXUIElementPostKeyboardEvent(appRef, 0, flags, false);
                  break;
            }
        }
    }
    
    return event;
}


static OSStatus AddApplicationEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon) {
    KSAppController* controller = (KSAppController*)inRefcon;

    ProcessSerialNumber psn;
    
    GetEventParameter(inEvent, kEventParamProcessID, typeProcessSerialNumber, NULL, sizeof(ProcessSerialNumber), NULL, &psn);
    
    NSMutableArray* apps = ([controller applications] == nil) ? [[NSMutableArray alloc] init] : [[controller applications] mutableCopy];
    KSConfiguration* config = [[[[controller configurationsController] userSettings] configurations] valueForKey:[[[controller configurationsController] configurationsPopUp] titleOfSelectedItem]];
    for (NSApplication* app in [[NSWorkspace sharedWorkspace] launchedApplications]) {
        NSString* appPath = [app valueForKey:@"NSApplicationPath"];
        if ([[config applications] containsObject:appPath] == YES && [apps containsObject:app] == NO) {
            [apps addObject:app];
            NSLog(@"Application added on startup: %@", app);
            break;
        }
    }
    
    [controller setApplications:apps];
    NSLog(@"There are now %d apps being watched.", [apps count]);
    NSLog(@"The applications are %@", apps);

    return noErr;
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

