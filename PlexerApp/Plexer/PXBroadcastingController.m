//
//  PXBroadcastingController.m
//  PlexerHelper
//
//  Created by David Owens II on 9/28/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXBroadcastingController.h"
#import <Carbon/Carbon.h>

NSString * const PXBroadcastingDidChangeNotification = @"PXBroadcastingDidChangeNotification";


CGEventRef KeyBindEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);


@implementation PXBroadcastingController

- (id)init
{
    self = [super init];
    if (self) {
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
        
        _keybindRunLoopSourceRef = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _keybindEventTapRef, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), _keybindRunLoopSourceRef, kCFRunLoopCommonModes);
        CGEventTapEnable(_keybindEventTapRef, true);
        
        self.broadcastingState = PXBroadcastingDisabled;
    }

    return self;
}

- (void)dealloc
{
    if (_keybindEventTapRef != NULL) { CFRelease(_keybindEventTapRef); }
    if (_keybindRunLoopSourceRef != NULL) { CFRelease(_keybindRunLoopSourceRef); }
}

- (void)setBroadcastingState:(PXBroadcastingState)broadcastingState
{
    _broadcastingState = broadcastingState;
    [[NSNotificationCenter defaultCenter] postNotificationName:PXBroadcastingDidChangeNotification object:self userInfo:nil];
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
    if ([frontMostApplication.bundleURL.lastPathComponent isEqualToString:@"World of Warcraft-64.app"] == NO) {
        return YES;
    }

    if (type == kCGEventKeyDown) {
        CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        PXLog(@"keyDown, keyCode: %d", keyCode);
        
        if (keyCode == kVK_F10) {
            switch (self.broadcastingState) {
                case PXBroadcastingDisabled:
                    self.broadcastingState = PXBroadcastingAllKeys;
                    break;
                    
                case PXBroadcastingAllKeys:
                    self.broadcastingState = PXBroadcastingMappedKeys;
                    break;
                    
                case PXBroadcastingMappedKeys:
                    self.broadcastingState = PXBroadcastingDisabled;
                    break;
            }
        }
        
//        for (NSRunningApplication *application in self.gameController.runningApplications) {
//            ProcessSerialNumber psn;
//            GetProcessForPID(application.processIdentifier, &psn);
//            CGEventPostToPSN(&psn, event);
//        }
    }
    else if (type == kCGEventKeyUp) {
//        for (NSRunningApplication *application in self.gameController.runningApplications) {
//            ProcessSerialNumber psn;
//            GetProcessForPID(application.processIdentifier, &psn);
//            CGEventPostToPSN(&psn, event);
//        }
    }
    
    return NO;
}

#pragma mark - Event Tap Handlers

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

    PXBroadcastingController *controller = (__bridge PXBroadcastingController *)refcon;
    
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
            PXLog(@"Unknown event type: %u", type);
    }
    
    return event;
}

@end
