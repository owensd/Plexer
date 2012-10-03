//
//  PXMainWindow.m
//  Playground
//
//  Created by David Owens II on 10/3/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXMainWindow.h"
#import <Carbon/Carbon.h>

NSString *NSStringFromKeyboardEvent(NSEvent *event)
{
    NSMutableString *modifierString = [[NSMutableString alloc] init];    
    if ((event.modifierFlags & kCGEventFlagMaskControl) == kCGEventFlagMaskControl)
        [modifierString appendString:@"⌃"];
    if ((event.modifierFlags & kCGEventFlagMaskShift) == kCGEventFlagMaskShift)
        [modifierString appendString:@"⇧"];
    if ((event.modifierFlags & kCGEventFlagMaskAlternate) == kCGEventFlagMaskAlternate)
        [modifierString appendString:@"⌥"];
    if ((event.modifierFlags & kCGEventFlagMaskCommand) == kCGEventFlagMaskCommand)
        [modifierString appendString:@"⌘"];
    if ((event.modifierFlags & kCGEventFlagMaskAlphaShift) == kCGEventFlagMaskAlphaShift)
        [modifierString appendString:@"⇪"];
    
    //
    // There is an entire class of virtual key codes that are layout independent.
    //
    unsigned short keyCode = event.keyCode;
    NSString *keyString = nil;
    if (event.type == NSKeyDown || event.type == NSKeyUp) {
        if (keyCode == kVK_F1)
            keyString = @"F1";
        else if (keyCode == kVK_F2)
            keyString = @"F2";
        else if (keyCode == kVK_F3)
            keyString = @"F3";
        else if (keyCode == kVK_F4)
            keyString = @"F4";
        else if (keyCode == kVK_F5)
            keyString = @"F5";
        else if (keyCode == kVK_F6)
            keyString = @"F6";
        else if (keyCode == kVK_F7)
            keyString = @"F7";
        else if (keyCode == kVK_F8)
            keyString = @"F8";
        else if (keyCode == kVK_F9)
            keyString = @"F9";
        else if (keyCode == kVK_F10)
            keyString = @"F10";
        else if (keyCode == kVK_F11)
            keyString = @"F11";
        else if (keyCode == kVK_F12)
            keyString = @"F12";
        else if (keyCode == kVK_F13)
            keyString = @"F13";
        else if (keyCode == kVK_F14)
            keyString = @"F14";
        else if (keyCode == kVK_F15)
            keyString = @"F15";
        else if (keyCode == kVK_F16)
            keyString = @"F16";
        else if (keyCode == kVK_F17)
            keyString = @"F17";
        else if (keyCode == kVK_F18)
            keyString = @"F18";
        else if (keyCode == kVK_F19)
            keyString = @"F19";
        else if (keyCode == kVK_F20)
            keyString = @"F20";
        else if (keyCode == kVK_Escape)
            keyString = @"⎋";
        else if (keyCode == kVK_Return)
            keyString = @"↩";
        else if (keyCode == kVK_Delete)
            keyString = @"⌫";
        else if (keyCode == kVK_ForwardDelete)
            keyString = @"⌦";
        else if (keyCode == kVK_Tab)
            keyString = @"⇥";
        else if (keyCode == kVK_PageUp)
            keyString = @"⇞";
        else if (keyCode == kVK_PageDown)
            keyString = @"⇟";
        else if (keyCode == kVK_Home)
            keyString = @"↖";
        else if (keyCode == kVK_End)
            keyString = @"↘";
        else if (keyCode == kVK_ANSI_KeypadClear)
            keyString = @"clear";
        else if (keyCode == kVK_Space)
            keyString = @"space";
    }
    
    //
    // Lastly, attempt to get the proper string representation for the character pressed by the user.
    //
    if (keyString == nil) {
        TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
        CFDataRef uchr = (CFDataRef)TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
        const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout*)CFDataGetBytePtr(uchr);
        
        if (keyboardLayout) {
            UInt32 deadKeyState = 0;
            UniCharCount maxStringLength = 255;
            UniCharCount actualStringLength = 0;
            UniChar unicodeString[maxStringLength];
            
            OSStatus status = UCKeyTranslate(keyboardLayout,
                                             event.keyCode, kUCKeyActionDown, 0,
                                             LMGetKbdType(), 0,
                                             &deadKeyState,
                                             maxStringLength,
                                             &actualStringLength, unicodeString);
            
            NSLog(@"deadKeyState = %d", deadKeyState);
            if (actualStringLength == 0 && deadKeyState) {
                status = UCKeyTranslate(keyboardLayout,
                                        kVK_Space, kUCKeyActionDown, 0,
                                        LMGetKbdType(), 0,
                                        &deadKeyState,
                                        maxStringLength,
                                        &actualStringLength, unicodeString);
            }
            if (actualStringLength > 0 && status == noErr) {
                keyString = [[NSString stringWithCharacters:unicodeString length:(NSUInteger)actualStringLength] uppercaseString];
            }
        }
    }
    
    return [NSString stringWithFormat:@"%@%@", modifierString, keyString == nil ? @"" : keyString];
}

@implementation PXMainWindow

- (void)keyDown:(NSEvent *)theEvent
{
    self.label.stringValue = NSStringFromKeyboardEvent(theEvent);
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    self.label.stringValue = NSStringFromKeyboardEvent(theEvent);
}

@end
