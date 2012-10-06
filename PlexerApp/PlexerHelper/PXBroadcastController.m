//
//  PXBroadcastController.m
//  Plexer
//
//  Created by David Owens II on 10/4/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXBroadcastController.h"
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import "PXMappedKeyStore.h"


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
        [app forceTerminate];
    }
}

- (void)installEventTaps
{
    if (_keybindEventTapRef == NULL) {
        CGEventMask keybindEventMask = CGEventMaskBit(kCGEventLeftMouseDown)  | CGEventMaskBit(kCGEventLeftMouseUp)  |
                                       CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseUp) |
                                       CGEventMaskBit(kCGEventOtherMouseDown) | CGEventMaskBit(kCGEventOtherMouseUp) |
                                       CGEventMaskBit(kCGEventKeyDown)        | CGEventMaskBit(kCGEventKeyUp)        |
                                       CGEventMaskBit(kCGEventScrollWheel);
        
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

    NSString *path = @"/Users/dowens/Library/Developer/Xcode/DerivedData/Plexer-dukidxnvzvpnsocmqemwyegjsswa/Build/Products/Debug/Playground.app";

    NSArray *teamMembers = _teamConfiguration[@"PXTeamMembersKey"];
    for (NSDictionary *player in teamMembers) {
        NSString *windowBounds = player[@"PXApplicationLaunchOptionsKey"][@"PXApplicationWindowBoundsKey"];
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[ @"-n", path, @"--args", @"-windowBounds", windowBounds ]];
    }
    
    [NSThread sleepForTimeInterval:1];
    
    for (NSRunningApplication *runningApplication in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([runningApplication.bundleIdentifier isEqualToString:@"com.kiadsoftware.plexer.Playground"] == YES) {
            [_runningApplications addObject:runningApplication];
        }
    }
}

- (void)setBroadcastingState:(PXBroadcastingState)broadcastingState
{
    _broadcastingState = broadcastingState;
//    [[NSNotificationCenter defaultCenter] postNotificationName:PXBroadcastingDidChangeNotification object:self userInfo:nil];
}

#pragma mark - Re-routed event handlers

- (BOOL)handleMouseEvent:(CGEventRef)event ofType:(CGEventType)type
{
    return YES;
}

- (BOOL)handleKeyboardEvent:(CGEventRef)event ofType:(CGEventType)type
{
    //
    // UNDONE: Need to get the proper application name to be looking for.
    //
    NSRunningApplication *frontMostApplication = [[NSWorkspace sharedWorkspace] frontmostApplication];
//    if ([frontMostApplication.bundleURL.lastPathComponent isEqualToString:@"World of Warcraft-64.app"] == NO) {
    if ([frontMostApplication.bundleURL.lastPathComponent isEqualToString:@"Playground.app"] == NO) {
        return YES;
    }
    
    //
    // Handle special key's for the application.
    //
    if (type == kCGEventKeyDown) {
        CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        NSLog(@"keyDown, keyCode: %d", keyCode);
        
        if (keyCode == kVK_F10) {
            switch (self.broadcastingState) {
                case PXBroadcastingDisabled:
                    self.broadcastingState = PXBroadcastingAllKeys;
                    NSLog(@"now broadcasting all keys");
                    break;
                    
                case PXBroadcastingAllKeys:
                    self.broadcastingState = PXBroadcastingMappedKeys;
                    NSLog(@"now broadcasting mapped keys only");
                    break;
                    
                case PXBroadcastingMappedKeys:
                    self.broadcastingState = PXBroadcastingDisabled;
                    NSLog(@"broadcasting disabled");
                    break;
            }
            
            return NO;
        }
        
    }
    
    if (self.broadcastingState == PXBroadcastingDisabled) {
        return YES;
    }
    

    ProcessSerialNumber currentPSN;
    GetFrontProcess(&currentPSN);
    
    //
    // Pass through as appropriate.
    //
    NSUInteger idx = 0;
    for (NSRunningApplication *application in _runningApplications) {
        ProcessSerialNumber psn;
        GetProcessForPID(application.processIdentifier, &psn);

        CGEventRef eventToSend = event;
        if (self.broadcastingState == PXBroadcastingMappedKeys) {
            eventToSend = [_mappedKeyStore processEvent:event forPlayerAtIndex:idx currentPSN:&currentPSN playerPSN:&psn];
        }
        
        if (eventToSend != NULL) {
            CGEventPostToPSN(&psn, eventToSend);
        }

        idx++;
    }
    
    return NO;
}

@end

CGEventRef KeyBindEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
#ifdef DEBUG
    // Fail safe if I ever screw up the event handling so that I can always kill Plexer.
    CGKeyCode __keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags __eventFlags = CGEventGetFlags(event);
    
    if (__keyCode == kVK_F10 && (__eventFlags & (kCGEventFlagMaskShift | kCGEventFlagMaskCommand)) == (kCGEventFlagMaskShift | kCGEventFlagMaskCommand)) {
        exit(911);
    }
#endif
    PXBroadcastController *controller = (__bridge PXBroadcastController *)refcon;
    
    switch (type) {
        case kCGEventLeftMouseDown:
        case kCGEventLeftMouseUp:
        case kCGEventRightMouseDown:
        case kCGEventRightMouseUp:
        case kCGEventOtherMouseDown:
        case kCGEventOtherMouseUp:
        case kCGEventScrollWheel:
            return ([controller handleMouseEvent:event ofType:type] == YES) ? event : NULL;
            
        case kCGEventKeyDown:
        case kCGEventKeyUp:
            return ([controller handleKeyboardEvent:event ofType:type] == YES) ? event : NULL;
            
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

