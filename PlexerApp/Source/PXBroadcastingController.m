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

#pragma mark - Event Tap Handlers

CGEventRef KeyBindEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    PXBroadcastingController *controller = (__bridge PXBroadcastingController *)refcon;
    
    switch (type) {
        case kCGEventLeftMouseDown:
        case kCGEventLeftMouseUp:
            PXLog(@"Left mouse button event.");
            break;
            
        case kCGEventRightMouseDown:
        case kCGEventRightMouseUp:
            PXLog(@"Right mouse button event.");
            break;

        case kCGEventOtherMouseDown:
        case kCGEventOtherMouseUp:
            PXLog(@"Other mouse button event.");
            break;
            
        case kCGEventKeyDown: {
            CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
            PXLog(@"keyDown, keyCode: %d", keyCode);
            
            if (keyCode == kVK_F10) {
                switch (controller.broadcastingState) {
                    case PXBroadcastingDisabled:
                        controller.broadcastingState = PXBroadcastingAllKeys;
                        break;
                        
                    case PXBroadcastingAllKeys:
                        controller.broadcastingState = PXBroadcastingMappedKeys;
                        break;
                        
                    case PXBroadcastingMappedKeys:
                        controller.broadcastingState = PXBroadcastingDisabled;
                        break;
                }
            }
            
            break;
        }
        case kCGEventKeyUp: {
            CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
            PXLog(@"keyUp, keyCode: %d", keyCode);
            break;
        }

        case kCGEventScrollWheel:
            PXLog(@"Scroll wheel event.");
            break;
            
        default:
            PXLog(@"Unknown event type: %u", type);
    }
    
    return event;
}

@end
