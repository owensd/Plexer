//
//  AppController.m
//  Plexer
//
//  Created by David Owens II on 6/10/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSAppController.h"
#import "System Events.h"
#import "KSRegistration.h"

static OSStatus AddApplicationEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon);
void KSFocusFirstWindowOfPid(pid_t pid);


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


@synthesize broadcasting, applications, configurationsController, inTrialMode;

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
    
    if ([userSettings firstLaunch] == nil)
        [userSettings setFirstLaunch:[[NSDate date] description]];
    
    self.broadcasting = false;
    [demoImage setHidden:NO];

    [configurationsController loadConfigurations];

    [self createStatusItemWithPathForImage:@"Plexer_ON.png" pathForOffImage:@"Plexer_OFF.png"];
    [self registerEventTaps];    
}

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    // Let's assume they are not until 'proven' they are... =)
    BOOL attemptingToPirate = NO;
    
    // First step to validating the serial number is to ensure that the
    // server is not being redirected to a different IP.
    //NSHost* host1 = [NSHost hostWithName:@"kiadsoftware.com"];
//    NSHost* host2 = [NSHost hostWithName:@"kiad.nfshost.com"];
//    
//    if (host1 == nil && host2 == nil && [NSHost hostWithName:@"worldofwarcraft.com"] == nil) {
//        // OK... it appears we cannot actually get to the internet...
//        // TODO: Do we want to allow users to continue to run the program?
//    }
//    else {    
//        NSArray* hostIP1 = [[host1 address] componentsSeparatedByString:@"."];
//        NSArray* hostIP2 = [[host2 address] componentsSeparatedByString:@"."];
//        NSLog(@"host1 = %@ (%@)", [host1 name], [host1 address]);
//        NSLog(@"host2 = %@ (%@)", [host2 name], [host2 address]);
//        
//        // Validate that first two components of the IPs match.
//        if ([[hostIP1 objectAtIndex:0] isEqualToString:[hostIP2 objectAtIndex:0]] == NO &&
//            [[hostIP1 objectAtIndex:1] isEqualToString:[hostIP2 objectAtIndex:1]] == NO)
//        {
//            // Hmm... we have some suspicious behavior...
//            if ([[host1 address] isEqualToString:@"127.0.0.1"] == YES ||
//                [[host1 address] hasSuffix:@"nearlyfreespeech.net"] == NO)
//            {
//                // This is most definitly an attempt to pirate our software.
//                attemptingToPirate = YES;
//            }
//        }
//    }
//    
//    // ok, so here we send our serial key and our computer's serial number
//    NSLog(@"computer serial number: %@", [KSAppController stringWithMachineSerialNumber]);
//    
//    // this will be the string response from the server
//    NSString* inTrialMode = @"2052488";
    
    NSString* serialNumber = [userSettings serialNumber];

    char serialNumberCString[21];
    [serialNumber getCString:serialNumberCString maxLength:20 encoding:NSASCIIStringEncoding];
    if (isValidSerialNumber(serialNumberCString) == 0) {
        [registerPlexerMenuItem setHidden:YES];
        inTrialMode = NO;
    }
    else {
        NSLog(@"Serial number: %@", [userSettings serialNumber]);
        inTrialMode = YES;
        [demoImage setHidden:NO];

        NSDate* firstLaunch = [NSDate dateWithString:[userSettings firstLaunch]];
        NSTimeInterval interval = [firstLaunch timeIntervalSinceNow];
        if (-interval > 60.0 /*seconds*/ * 60.0 /*minutes*/ * 24.0 /*hours*/ * 15.0 /*days*/) {
            isTrialExpired = YES;
        
            if ([userSettings serialNumber] == nil || [[userSettings serialNumber] isEqualToString:@""] == YES) {
                [infoPanelController showPanelWithTitle:@"Trial Expired"
                                                message:@"Your trial of Plexer has expired. If you wish to continue to use Plexer, you must purchase it."
                                             buttonText:@"OK"
                                               delegate:self
                                         didEndSelector:@selector(trialExpiredSheetDidEnd:code:context:)
                                            contextInfo:nil];
            }
            else {
                // hmm... invalid serial number. possible pirate attempt?
                [infoPanelController showPanelWithTitle:@"Invalid Serial Number"
                                                message:@"The serial number is invalid. Please enter a valid serial number."
                                             buttonText:@"OK"
                                               delegate:self
                                         didEndSelector:@selector(invalidSerialNumberOnLoadSheetDidEnd:code:context:)
                                            contextInfo:nil];
            }
        }
        else if (interval > 0) {
            [infoPanelController showPanelWithTitle:@"Trial Expired"
                                            message:@"Your trial of Plexer has expired. If you wish to continue to use Plexer, you must purchase it."
                                         buttonText:@"OK"
                                           delegate:self
                                     didEndSelector:@selector(trialExpiredSheetDidEnd:code:context:)
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

-(IBAction)registerSoftware:(id)sender {
    [registrationPanelController showRegistrationPanel];
}

// ------------------------------------------------------
// Event tap methods
// ------------------------------------------------------

-(void)registerEventTaps {
    keyEventTapRef = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged), KeyEventTapCallback, self);
    
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
                // NOTE: Trial mode is limited to two apps that can be plexed.
                if ([controller isInTrialMode] == NO || [apps count] < 2) {
                    [apps addObject:app];
                    NSLog(@"Application added on startup: %@", app);
                }
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


