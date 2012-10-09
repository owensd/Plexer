//
//  PXBroadcastController.m
//  Plexer
//
//  Created by David Owens II on 10/4/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXBroadcastController.h"
#import "PXMappedKeyStore.h"
#import <PlexerLib/PlexerLib.h>

#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>


NSString * const PXBroadcastingDidChangeNotification = @"PXBroadcastingDidChangeNotification";

CGEventRef KeyBindEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);

@implementation PXBroadcastControllerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PXBroadcastController)];

    PXBroadcastController *exportedObject = [[PXBroadcastController alloc] init];
    newConnection.exportedObject = exportedObject;
    exportedObject.xpcConnection = newConnection;
    
    [newConnection resume];
    
    return YES;
}

@end

@implementation PXBroadcastController {
    CFRunLoopSourceRef _keybindRunLoopSourceRef;
    CFMachPortRef _keybindEventTapRef;
    PXMappedKeyStore *_mappedKeyStore;
    NSMutableArray *_runningApplications;
    NSDictionary *_teamConfiguration;
}

- (id)init
{
    self = [super init];
    if (self) {
        _keybindEventTapRef = NULL;
        _keybindRunLoopSourceRef = NULL;
        _runningApplications = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if (_keybindEventTapRef != NULL) { CFRelease(_keybindEventTapRef); }
    if (_keybindRunLoopSourceRef != NULL) { CFRelease(_keybindRunLoopSourceRef); }
}

- (void)playTeam:(NSDictionary *)team
{
    _teamConfiguration = team;
    
    _mappedKeyStore = [[PXMappedKeyStore alloc] initWithDictionary:team];
    [self installEventTaps];
    [self launchApplications];
}

- (void)closeApplications
{
    for (NSRunningApplication *app in _runningApplications) {
        [app terminate];
    }
}

- (void)installEventTaps
{
    if (_keybindEventTapRef == NULL) {
        CGEventMask keybindEventMask = CGEventMaskBit(kCGEventLeftMouseDown)  | CGEventMaskBit(kCGEventLeftMouseUp)  |
                                       CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseUp) |
                                       CGEventMaskBit(kCGEventOtherMouseDown) | CGEventMaskBit(kCGEventOtherMouseUp) |
                                       CGEventMaskBit(kCGEventKeyDown)        | CGEventMaskBit(kCGEventKeyUp)        |
                                       CGEventMaskBit(kCGEventFlagsChanged)   | CGEventMaskBit(kCGEventScrollWheel);
        
        _keybindEventTapRef = CGEventTapCreate(kCGHIDEventTap,
                                               kCGHeadInsertEventTap,
                                               kCGEventTapOptionDefault,
                                               keybindEventMask,
                                               KeyBindEventTapCallback,
                                               (__bridge void *)(self));
        
        if (_keybindEventTapRef == NULL) {
            NSLog(@"Unable to create the keyboard event tap.");
        }
        else {
            _keybindRunLoopSourceRef = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _keybindEventTapRef, 0);
            CFRunLoopAddSource(CFRunLoopGetMain(), _keybindRunLoopSourceRef, kCFRunLoopCommonModes);
            CGEventTapEnable(_keybindEventTapRef, true);
        }
        
        self.broadcastingState = PXBroadcastingDisabled;
    }
}

- (void)launchApplications
{
    NSLog(@"launching applications");
    
    NSString *applicationName = _teamConfiguration[@"PXApplicationKey"];
    PXApplication *application = [PXApplication applicationWithName:applicationName];
    if (application == nil) {
        NSLog(@"Unable to find application.");
    }

    NSArray *teamMembers = _teamConfiguration[@"PXTeamMembersKey"];
    for (NSDictionary *player in teamMembers) {
        NSRunningApplication *runningApplication = [application launchWithOptions:player[@"PXApplicationLaunchOptionsKey"]];
        if (runningApplication != nil) {
            [_runningApplications addObject:runningApplication];
        }
//        NSString *windowBounds = player[@"PXApplicationLaunchOptionsKey"][@"PXApplicationWindowBoundsKey"];
//        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[ @"-n", path, @"--args", @"-windowBounds", windowBounds ]];
    }
//    
//    [NSThread sleepForTimeInterval:1];
//    
//    for (NSRunningApplication *runningApplication in [[NSWorkspace sharedWorkspace] runningApplications]) {
//        if ([runningApplication.bundleIdentifier isEqualToString:@"com.kiadsoftware.plexer.Playground"] == YES) {
//            [_runningApplications addObject:runningApplication];
//        }
//    }
}


#pragma mark - Re-routed event handlers

- (CGEventRef)handleMouseEvent:(CGEventRef)event ofType:(CGEventType)type
{
    return event;
}

- (CGEventRef)handleKeyboardEvent:(CGEventRef)event ofType:(CGEventType)type
{
    NSRunningApplication *frontMostApplication = [[NSWorkspace sharedWorkspace] frontmostApplication];

    //
    // UNDONE: Need to get the proper application name to be looking for.
    //
    if ([frontMostApplication.bundleURL.lastPathComponent isEqualToString:[_runningApplications[0] bundleURL].lastPathComponent] == NO) { return event; }
    if ([self handleSpecialApplicationFunctionalityForEvent:event ofType:type] == NULL) { return NULL; }
    if (self.broadcastingState == PXBroadcastingDisabled) { return event; }
    
    switch (self.broadcastingState) {
        case PXBroadcastingDisabled:
            return event;
            
        case PXBroadcastingAllKeys:
            for (NSRunningApplication *application in _runningApplications) {
                ProcessSerialNumber teamMemberPSN;
                GetProcessForPID(application.processIdentifier, &teamMemberPSN);
                CGEventPostToPSN(&teamMemberPSN, event);
            }
            return NULL;
            
        case PXBroadcastingMappedKeys:
            return [_mappedKeyStore handleMappedKeyEvent:event applications:_runningApplications];
            break;
            
        default:
            NSLog(@"Invalidate broadcasting state: %d", self.broadcastingState);
    }

    return NULL;
}

- (CGEventRef)handleSpecialApplicationFunctionalityForEvent:(CGEventRef)event ofType:(CGEventType)type
{
    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    if (type == kCGEventKeyDown) {
    #ifdef DEBUG
        // Fail safe if I ever screw up the event handling so that I can always kill Plexer.
        CGEventFlags __eventFlags = CGEventGetFlags(event);
        
        if (keyCode == kVK_F10 && (__eventFlags & (kCGEventFlagMaskShift | kCGEventFlagMaskCommand)) == (kCGEventFlagMaskShift | kCGEventFlagMaskCommand)) {
            exit(911);
        }
    #endif
        
        if (keyCode == kVK_F10) {
            if (self.broadcastingState == PXBroadcastingDisabled) {
                self.broadcastingState = PXBroadcastingAllKeys;
                NSLog(@"now broadcasting all keys");
            }
            else if (self.broadcastingState == PXBroadcastingAllKeys) {
                self.broadcastingState = PXBroadcastingMappedKeys;
                NSLog(@"now broadcasting mapped keys only");
            }
            else if (self.broadcastingState == PXBroadcastingMappedKeys) {
                self.broadcastingState = PXBroadcastingDisabled;
                NSLog(@"broadcasting disabled");
            }
            
            return NULL;
        }
    }
    
    return event;
}

@end

CGEventRef KeyBindEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    PXBroadcastController *controller = (__bridge PXBroadcastController *)refcon;
    
    switch (type) {
        case kCGEventLeftMouseDown:
        case kCGEventLeftMouseUp:
        case kCGEventRightMouseDown:
        case kCGEventRightMouseUp:
        case kCGEventOtherMouseDown:
        case kCGEventOtherMouseUp:
        case kCGEventScrollWheel:
            return [controller handleMouseEvent:event ofType:type];
            
        case kCGEventKeyDown:
        case kCGEventKeyUp:
            return [controller handleKeyboardEvent:event ofType:type];
            
        default:
            NSLog(@"Unknown event type: %u", type);
    }
    
    return event;
}

//PXMappedKey *PXMappedKeyCreate(NSDictionary *mappedKeyDict)
//{
//    PXMappedKey *mappedKey = malloc(sizeof(PXMappedKey));
//    mappedKey->inputKeyCode = [mappedKeyDict[@"PXMappedKeyInputKeyCodeKey"] unsignedShortValue];
//    mappedKey->inputFlags = [mappedKeyDict[@"PXMappedKeyInputFlagsKey"] integerValue];
//    mappedKey->outputKeyCode = [mappedKeyDict[@"PXMappedKeyOutputKeyCodeKey"] unsignedShortValue];
//    mappedKey->outputFlags = [mappedKeyDict[@"PXMappedKeyOutputFlagsKey"] integerValue];
//    mappedKey->targetType = [mappedKeyDict[@"PXMappedKeyTargetWindowKey"] intValue];
//    
//    for (NSUInteger idx = 0; idx < PXMaximumNumberOfTeamMembers; idx++) {
//        mappedKey->teamMembers[idx] = YES;
//    }
//
//    return mappedKey;
//}

