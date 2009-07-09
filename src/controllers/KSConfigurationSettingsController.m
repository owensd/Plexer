//
//  KSConfigurationController.m
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSConfigurationSettingsController.h"
#import "KSConfiguration.h"
#import <Carbon/Carbon.h>
#import "System Events.h"

@implementation KSConfigurationSettingsController
@synthesize userSettings, configurationName, configurationsPopUp, applicationsTableView, keyOptionsPopUp, keyOptionsTableView;

EventHandlerRef AddApplicationEventHandlerRef;

CFMachPortRef configKeyEventTapRef = NULL;
CFRunLoopSourceRef configRunLoopSourceRef = NULL;
CFRunLoopRef configRunLoopRef = NULL;
CGEventRef ConfigKeyEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);


-(BOOL)configurationSelected {
    return ([configurationsPopUp selectedTag] >= 0);
}

-(void)loadConfigurations {
    [userSettings load];
    for (KSConfiguration* config in [[userSettings configurations] allValues]) {
        [configurationsPopUp insertItemWithTitle:[config name] atIndex:([configurationsPopUp numberOfItems] - 2)];
    }
    [configurationsPopUp selectItemAtIndex:0];

    [self willChangeValueForKey:@"configurationSelected"];
    [self didChangeValueForKey:@"configurationSelected"];
}

// ----------------------------------------------------
// Configuration panel methods
// ----------------------------------------------------

-(IBAction)createNewConfiguration:(id)sender {
    self.configurationName = @"";
    
    [configurationNamePanel setTitle:@"Create New Configuration"];
    [NSApp beginSheet:configurationNamePanel
       modalForWindow:preferencesPanel
        modalDelegate:self
       didEndSelector:@selector(didEndNewConfiguration:code:context:)
          contextInfo:NULL];
}

-(void)didEndNewConfiguration:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:configurationNamePanel];
    
    if (choice == kConfigOk) {
        [userSettings addConfigurationWithName:configurationName];
    }
}

-(void)didEndRenameConfiguration:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:configurationNamePanel];
    
    if (choice == kConfigOk) {
        [userSettings renameConfigurationWithName:(NSString*)v toName:configurationName];
        [configurationsPopUp removeItemWithTitle:(NSString*)v];
    }
}


-(IBAction)changeSelectedConfiguration:(id)sender {
    [self willChangeValueForKey:@"configurationSelected"];
    [self didChangeValueForKey:@"configurationSelected"];
    [applicationsTableView reloadData];
    [keyOptionsTableView reloadData];
}

-(IBAction)renameSelectedConfiguration:(id)sender {
    self.configurationName = [configurationsPopUp titleOfSelectedItem];
    
    [configurationNamePanel setTitle:@"Rename Configuration"];
    [NSApp beginSheet:configurationNamePanel
       modalForWindow:preferencesPanel
        modalDelegate:self
       didEndSelector:@selector(didEndRenameConfiguration:code:context:)
          contextInfo:[configurationsPopUp titleOfSelectedItem]];
}

-(IBAction)removeSelectedConfiguration:(id)sender {
    [userSettings removeConfigurationWithName:[[configurationsPopUp selectedItem] title]];
    [configurationsPopUp removeItemAtIndex:[configurationsPopUp indexOfSelectedItem]];
    [configurationsPopUp selectItemAtIndex:0];
    
    [self willChangeValueForKey:@"configurationSelected"];
    [self didChangeValueForKey:@"configurationSelected"];
}

-(IBAction)cancelConfiguration:(id)sender {
    [NSApp endSheet:configurationNamePanel returnCode:kConfigCancel];
    [configurationsPopUp selectItemWithTag:-1];
    self.configurationName = @"";
}

-(IBAction)okConfiguration:(id)sender {
    NSError* error = nil;
    if ([self validateConfigurationName:&configurationName error:&error] == NO) {
        [NSApp endSheet:configurationNamePanel];
        
        NSString* message = [error domain];
        if ([[error domain] isEqualTo:@"KS_DUPLICATE_CONFIGURATION_NAME"] == YES)
            message = @"A configuration with this name already exists.";
        else if ([[error domain] isEqualTo:@"KS_CONFIGURATION_NAME_EMPTY"] == YES)
            message = @"A configuration name cannot be empty.";
        
        void* data = NULL;
        if ([[configurationNamePanel title] hasPrefix:@"Rename"])
            data = [configurationsPopUp titleOfSelectedItem];
        [infoPanelController showPanelWithTitle:@"Invalid Configuration Name"
                                        message:message
                                     buttonText:@"OK"
                                       delegate:self
                                 didEndSelector:@selector(invalidConfigurationSheetDidEnd:code:context:)
                                    contextInfo:data];
        return;
    }
    
    [configurationsPopUp insertItemWithTitle:configurationName atIndex:([configurationsPopUp numberOfItems] - 2)];
    [configurationsPopUp selectItemWithTitle:configurationName];
    
    [self willChangeValueForKey:@"configurationSelected"];
    [self didChangeValueForKey:@"configurationSelected"];
    
    [NSApp endSheet:configurationNamePanel returnCode:kConfigOk];
}

-(void)invalidConfigurationSheetDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:[infoPanelController window]];
    
    SEL selector = @selector(didEndNewConfiguration:code:context:);
    if (v != NULL)
        selector = @selector(didEndRenameConfiguration:code:context:);
    
    [NSApp beginSheet:configurationNamePanel
       modalForWindow:preferencesPanel
        modalDelegate:self
       didEndSelector:selector
          contextInfo:v];
}

-(BOOL)validateConfigurationName:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return YES;
    }
    
    // Remove the beginning and trailing whitespace.
    NSString *name = [*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    *ioValue = name;
    
    if ([name length] == 0) {
        *outError = [[NSError alloc] initWithDomain:@"KS_CONFIGURATION_NAME_EMPTY" code:-101 userInfo:nil];
        return NO;
    }
    
    // Validate that the configuration name doesn't already exist.
    for (KSConfiguration* config in [userSettings configurations]) {
        if ([[config name] isEqualToString:name] == YES) {
            *outError = [[NSError alloc] initWithDomain:@"KS_DUPLICATE_CONFIGURATION_NAME" code:-100 userInfo:nil];
            return NO;
        }
    }
    
    return YES;
}




// ----------------------------------------------------
// Configuration panel delegate methods
// ----------------------------------------------------

// Handle this so that the window isn't actually closed. Errors occur if this isn't handled this way.
-(BOOL)windowShouldClose:(id)window {
    [self cancelConfiguration:self];
    return NO;
}




-(IBAction)changeSaveWindowPositionAndLayoutSetting:(id)sender {
}

-(IBAction)changeToggleDockHidingSetting:(id)sedner {
}

-(IBAction)changeMoveWindowsNearMenuBarSetting:(id)sender {
}


-(IBAction)addApplication:(id)sender {
    [self registerApplicationEventHandler];
    [infoPanelController showPanelWithTitle:@"Add Application"
                                    message:@"Bring the applications you wish to add to the foreground. When you are finished, press the 'Done' button."
                                 buttonText:@"Done"
                                   delegate:self
                             didEndSelector:@selector(addApplicationsSheetDidEnd:code:context:)
                                contextInfo:NULL];
}

-(void)addApplicationsSheetDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:[infoPanelController window]];
    [self unregisterApplicationEventHandler];
}

-(IBAction)removeApplication:(id)sender {
    [userSettings removeApplicationAtIndex:[applicationsTableView selectedRow] forConfiguration:[configurationsPopUp titleOfSelectedItem]];
    [applicationsTableView reloadData];
}

-(IBAction)launchApplications:(id)sender {
}


-(IBAction)changeSelectedKeyOption:(id)sender {
    [keyOptionsTableView reloadData];
}

-(IBAction)addKeyOptionKey:(id)sender {
    [self registerKeyboardEventTap];
    [infoPanelController showPanelWithTitle:@"Add Key"
                                    message:@"Press the keys you whish to add to the key options list. When you are finished, press the 'Done' button."
                                 buttonText:@"Done"
                                   delegate:self
                             didEndSelector:@selector(addKeySheetDidEnd:code:context:)
                                contextInfo:NULL];    
}

-(void)addKeySheetDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:[infoPanelController window]];
    [self unregisterKeyboardEventTap];
}

-(void)registerKeyboardEventTap {
    configKeyEventTapRef = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged), ConfigKeyEventTapCallback, self);
    
    if (configKeyEventTapRef == NULL) {
        NSLog(@"There was an error creating the event tap.");
        exit(1);
    }
    
    configRunLoopSourceRef = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, configKeyEventTapRef, 0);
    if (configRunLoopSourceRef == NULL) {
        NSLog(@"There was an error creating the run loop source.");
        exit(1);
    }
    
    configRunLoopRef = [[NSRunLoop currentRunLoop] getCFRunLoop];
    if (configRunLoopRef == NULL) {
        NSLog(@"There was an error retrieving the current run loop.");
        exit(1);
    }
    
    CFRunLoopAddSource(configRunLoopRef, configRunLoopSourceRef, kCFRunLoopDefaultMode);
}

-(void)unregisterKeyboardEventTap {
    CFMachPortInvalidate(configKeyEventTapRef);
    CFRelease(configKeyEventTapRef);
    CFRelease(configRunLoopSourceRef);
}

CGEventRef ConfigKeyEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    static CGKeyCode modifiers = 0;
    
    KSConfigurationSettingsController* controller = (KSConfigurationSettingsController*)refcon;
    
    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    
    if (type == kCGEventKeyUp) {
        NSLog(@"The %d key was released.", keyCode);
    }
    else if (type == kCGEventKeyDown) {
        NSLog(@"The %d key was pressed.", keyCode);
        
        if ([[[controller keyOptionsPopUp] titleOfSelectedItem] isEqualToString:@"Blacklist"] == YES) {
            [[controller userSettings] addBlackListKey:((modifiers << 16) | keyCode) forConfiguration:[[controller configurationsPopUp] titleOfSelectedItem]];
            [[controller keyOptionsTableView] reloadData];
        }
    }
    else if (type == kCGEventFlagsChanged) {
        NSLog(@"The %d flags changed.", keyCode);
        modifiers = keyCode;
    }
    
    if (keyCode == kVK_Escape)
        return event;
    else
        return NULL;
}


-(IBAction)removeKeyOptionKey:(id)sender {
    if ([[keyOptionsPopUp titleOfSelectedItem] isEqualToString:@"Blacklist"] == YES) {
        [userSettings removeBlackListKeyAtIndex:[keyOptionsTableView selectedRow] forConfiguration:[configurationsPopUp titleOfSelectedItem]];
        [keyOptionsTableView reloadData];
    }
}


// ------------------------------------------------------
// Application event handlers and related methods
// ------------------------------------------------------

static OSStatus AddApplicationEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon) {
    NSLog(@"Application switched to foreground.");
    KSConfigurationSettingsController* controller = (KSConfigurationSettingsController*)inRefcon;
    
    ProcessSerialNumber psn;
    GetEventParameter(inEvent, kEventParamProcessID, typeProcessSerialNumber, NULL, sizeof(ProcessSerialNumber), NULL, &psn);
    [[controller userSettings] addApplication:&psn forConfiguration:[[controller configurationsPopUp] titleOfSelectedItem]];
    
    [[controller applicationsTableView] reloadData];

    return noErr;
}

-(void)registerApplicationEventHandler {
    EventTypeSpec kAppEvents[] = {
        { kEventClassApplication, kEventAppFrontSwitched },
    };
    
    InstallApplicationEventHandler(AddApplicationEventHandler, GetEventTypeCount(kAppEvents), kAppEvents, self, &AddApplicationEventHandlerRef);
}

-(void)unregisterApplicationEventHandler {
    RemoveEventHandler(AddApplicationEventHandlerRef);
}

@end
