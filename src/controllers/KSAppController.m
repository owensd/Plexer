//
//  AppController.m
//  Plexer
//
//  Created by David Owens II on 6/10/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSAppController.h"
#import "System Events.h"

static OSStatus AddApplicationEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon);
void KSFocusFirstWindowOfPid(pid_t pid);


// Valid key is taken from the date: 10.28.2008
// 0x7D8 -> 2008 (12 bits)
// 0x1C  -> 28   (6 bits)
// 0x0A  -> 10   (4 bits)
// 0x1F670A  -> 2057994
// Basically, the first 22 bits MUST match the above in order to be a valid response.
#define IsValidSerial(x) ((((x) & (~((~0) << 22))) & 0x1F670A) == 0x1F670A)

// Valid key is taken from the data: 8.6.2004
// 0x1F5188 -> 2052488
#define IsInTrialMode(x) ((((x) & (~((~0) << 22))) & 0x1F5188) == 0x1F5188)

@implementation KSAppController

BOOL isTrialExpired = NO;

CFMachPortRef keyEventTapRef = NULL;
CFRunLoopSourceRef runLoopSourceRef = NULL;
CFRunLoopRef runLoopRef = NULL;

EventHandlerRef AddApplicationEventHandlerRef;

CGEventRef KeyEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);

NSStatusItem* statusItem = nil;
NSImage* statusImageOn = nil;
NSImage* statusImageOff = nil;

BOOL dockAutoHide;

ProcessSerialNumber currentPSN;
pid_t currentPID = -1;


@synthesize broadcasting, applications, configurationsController;

+ (id)stringWithMachineSerialNumber
{
    NSString* result = nil;
    CFStringRef serialNumber = NULL;
    
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    
    if (platformExpert) {
        CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0);
        serialNumber = (CFStringRef)serialNumberAsCFString;
        IOObjectRelease(platformExpert);
    }
    
    if (serialNumber)
        result = [(NSString*)serialNumber autorelease];
    else
        result = @"unknown";
    
    return result;
}

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
    
    self.broadcasting = false;
    
    [configurationsController loadConfigurations];

    [self createStatusItemWithPathForImage:@"Plexer_ON.png" pathForOffImage:@"Plexer_OFF.png"];
    [self registerEventTaps];    
}

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    // Let's assume they are not until 'proven' they are... =)
    BOOL attemptingToPirate = NO;
    
    // First step to validating the serial number is to ensure that the
    // server is not being redirected to a different IP.
    NSHost* host1 = [NSHost hostWithName:@"kiadsoftware.com"];
    NSHost* host2 = [NSHost hostWithName:@"kiad.nfshost.com"];
    
    if (host1 == nil && host2 == nil && [NSHost hostWithName:@"worldofwarcraft.com"] == nil) {
        // OK... it appears we cannot actually get to the internet...
        // TODO: Do we want to allow users to continue to run the program?
    }
    else {    
        NSArray* hostIP1 = [[host1 address] componentsSeparatedByString:@"."];
        NSArray* hostIP2 = [[host2 address] componentsSeparatedByString:@"."];
        NSLog(@"host1 = %@ (%@)", [host1 name], [host1 address]);
        NSLog(@"host2 = %@ (%@)", [host2 name], [host2 address]);
        
        // Validate that first two components of the IPs match.
        if ([[hostIP1 objectAtIndex:0] isEqualToString:[hostIP2 objectAtIndex:0]] == NO &&
            [[hostIP1 objectAtIndex:1] isEqualToString:[hostIP2 objectAtIndex:1]] == NO)
        {
            // Hmm... we have some suspicious behavior...
            if ([[host1 address] isEqualToString:@"127.0.0.1"] == YES ||
                [[host1 address] hasSuffix:@"nearlyfreespeech.net"] == NO)
            {
                // This is most definitly an attempt to pirate our software.
                attemptingToPirate = YES;
            }
        }
    }
    
    // ok, so here we send our serial key and our computer's serial number
    NSLog(@"computer serial number: %@", [KSAppController stringWithMachineSerialNumber]);
    
    // this will be the string response from the server
    NSString* serialNumber = @"1679779593";
    NSString* inTrialMode = @"20524889";
    
    // TODO: Validate the user's serial number.
    if (IsValidSerial([serialNumber intValue])) {
        [demoImage setHidden:YES];
        [registerPlexerMenuItem setHidden:YES];
    }
    else if (!IsInTrialMode([inTrialMode intValue])) {
        NSLog(@"Serial number: %@", [userSettings serialNumber]);
        if ([userSettings serialNumber] == nil || [[userSettings serialNumber] isEqualToString:@""] == YES) {
            // Trial mode has expired, you need to register.
            isTrialExpired = YES;
            [infoPanelController showPanelWithTitle:@"Trial Expired"
                                            message:@"Your trial of Plexer has expired. If you wish to continue to use Plexer, you must purchase it."
                                         buttonText:@"OK"
                                           delegate:self
                                     didEndSelector:@selector(trialExpiredSheetDidEnd:code:context:)
                                        contextInfo:nil];
        }
        else {
            isTrialExpired = YES;
            // hmm... invalid serial number. possible pirate attempt?
            [infoPanelController showPanelWithTitle:@"Invalid Serial Number"
                                            message:@"The serial number is invalid. Please enter a valid serial number."
                                         buttonText:@"OK"
                                           delegate:self
                                     didEndSelector:@selector(invalidSerialNumberOnLoadSheetDidEnd:code:context:)
                                        contextInfo:nil];
        }
        
    }
    
    if (attemptingToPirate == YES) {
        // TODO: Notify the main server?
        exit(-911);
    }
    
    // Sparkle doesn't automatically check for updates on startup so we manually do it here.
    if ([userSettings automaticallyCheckForUpdates] == YES)
        [updater checkForUpdatesInBackground];
}

-(void)invalidSerialNumberOnLoadSheetDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:[infoPanelController window]];
    // TODO: Show the registration information page.
}

-(void)trialExpiredSheetDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:[infoPanelController window]];
    // TODO: Show the registration information page.
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
    if (isTrialExpired) return;
    
    self.broadcasting = !self.broadcasting;
}

-(IBAction)stopBroadcasting:(id)sender {
    if (isTrialExpired) return;

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
    if (isTrialExpired) return event;

    KSAppController* controller = (KSAppController*)refcon;
    
    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags flags = CGEventGetFlags(event);

    if (type == kCGEventKeyDown) {
        if (keyCode == [[controller userSettings] toggleBroadcastingKeyCode]) {
            controller.broadcasting = !controller.broadcasting;
            return NULL;
        }
        if (keyCode == [[controller userSettings] quitAppKeyCode]) {
            [[NSApplication sharedApplication] terminate:nil];
            return NULL;
        }
    }
    
    // We only broadcast keys if one of our apps is focused. Otherwise we'd get silly things like
    // keys being sent to the game when we are typing in skype, for example.
    // This is denoted by the currentPID being equal to -1; this is set in the app handler.
    NSLog(@"currentPID = %d", currentPID);
    if (currentPID == -1)
        return event;
    
    // NOTE: Is this too slow? May need to optimize this section of code.
    NSArray* blackListKeys = [[[[controller userSettings] configurations] valueForKey:[[[controller configurationsController] configurationsPopUp] titleOfSelectedItem]] blackListKeys];
    for (NSDictionary* key in blackListKeys) {
        if ([[key valueForKey:@"KeyCode"] intValue] == keyCode &&
            [[key valueForKey:@"Modifiers"] intValue] == flags)
            return event;
    }
    
    // Broacast the keys to our apps, but be sure not to send it to ourself!
    for (NSApplication* app in [controller applications]) {
        pid_t pid = [[app valueForKey:@"NSApplicationProcessIdentifier"] intValue];
        ProcessSerialNumber psn;
        GetProcessForPID(pid, &psn);

        if (currentPID != pid) {
            CGEventPostToPSN(&psn, event);
        }
    }
        
    return event;
}


static OSStatus AddApplicationEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon) {
    KSAppController* controller = (KSAppController*)inRefcon;

    // cache this for faster lookup in our keyboard tap.
    GetFrontProcess(&currentPSN);
    
    // cache this for faster lookup in our keyboard tap. However, set the
    // currentPID to -1 until we know that one of our apps being watched is focused.
    pid_t frontPID;
    GetProcessPID(&currentPSN, &frontPID);
    currentPID = -1;
    
    ProcessSerialNumber psn;
    GetEventParameter(inEvent, kEventParamProcessID, typeProcessSerialNumber, NULL, sizeof(ProcessSerialNumber), NULL, &psn);
    
    NSMutableArray* apps = ([controller applications] == nil) ? [[NSMutableArray alloc] init] : [[controller applications] mutableCopy];
    KSConfiguration* config = [[[[controller configurationsController] userSettings] configurations] valueForKey:[[[controller configurationsController] configurationsPopUp] titleOfSelectedItem]];
    for (NSApplication* app in [[NSWorkspace sharedWorkspace] launchedApplications]) {
        NSString* appPath = [app valueForKey:@"NSApplicationPath"];
        if ([[config applications] containsObject:appPath] == YES) {
            pid_t pid = [[app valueForKey:@"NSApplicationProcessIdentifier"] intValue];
            KSFocusFirstWindowOfPid(pid);
            
            if (frontPID == pid)
                currentPID = pid;
            
            if ([apps containsObject:app] == NO) {
                [apps addObject:app];
                NSLog(@"Application added on startup: %@", app);
                break;
            }
        }
    }
    
    [controller setApplications:apps];
    NSLog(@"There are now %d apps being watched.", [apps count]);
    NSLog(@"The applications are %@", apps);

    return noErr;
}

// There is a bug that stops keystrokes from getting to the window
// on OS X 10.5.6+.
void KSFocusFirstWindowOfPid(pid_t pid) {
	AXUIElementRef appRef = AXUIElementCreateApplication(pid);
	
	CFArrayRef windowRefs;
	AXUIElementCopyAttributeValues(appRef, kAXWindowsAttribute, 0, 255, &windowRefs);
	if (!windowRefs) return;
	
	for (int idx = 0; idx < CFArrayGetCount(windowRefs); ++idx) {
		AXUIElementRef windowRef = (AXUIElementRef)CFArrayGetValueAtIndex(windowRefs, idx);
		CFStringRef title = NULL;
		AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, (const void**)&title);
		
        if (CFStringGetLength(title) != 0) {
            AXUIElementSetAttributeValue(windowRef, kAXFocusedAttribute, kCFBooleanTrue);
            break;
        }
        
        CFRelease(title);
	}    
    
	AXUIElementSetAttributeValue(appRef, kAXFocusedApplicationAttribute, kCFBooleanTrue);
	CFRelease(windowRefs);
	CFRelease(appRef);
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

