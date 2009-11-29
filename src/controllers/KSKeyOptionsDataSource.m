//
//  KSKeyOptionsDataSource.m
//  Plexer
//
//  Created by David Owens II on 7/9/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSKeyOptionsDataSource.h"


@implementation KSKeyOptionsDataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView {
    if ([configurationController configurationSelected] == NO)
        return 0;
    
    NSString* configurationName = [[configurationController configurationsPopUp] titleOfSelectedItem];
    KSConfiguration* config = [[userSettings configurations] valueForKey:configurationName];
    
    return [[config blackListKeys] count];
    
    return 0;
}

-(id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex {
    NSString* configurationName = [[configurationController configurationsPopUp] titleOfSelectedItem];
    KSConfiguration* config = [[userSettings configurations] valueForKey:configurationName];
    
    NSDictionary* keyCodeInfo = [[config blackListKeys] objectAtIndex:rowIndex];
    NSInteger keyCode = [[keyCodeInfo valueForKey:@"KeyCode"] integerValue];
    NSInteger modifier = [[keyCodeInfo valueForKey:@"Modifiers"] integerValue];
    
    NSMutableString* modifierString = [[NSMutableString alloc] init];
    if ((modifier & kCGEventFlagMaskControl) == kCGEventFlagMaskControl)
        [modifierString appendString:@"⌃"];
    if ((modifier & kCGEventFlagMaskShift) == kCGEventFlagMaskShift)
        [modifierString appendString:@"⇧"];
    if ((modifier & kCGEventFlagMaskAlternate) == kCGEventFlagMaskAlternate)
        [modifierString appendString:@"⌥"];
    if ((modifier & kCGEventFlagMaskCommand) == kCGEventFlagMaskCommand)
        [modifierString appendString:@"⌘"];
    
    // We need to handle a small subset of the keys to get the 'printable' version.
    NSString* keyString = @"";
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
    else {
        UInt32 deadKeyState = 0;
        UniCharCount actualCount = 0;
        UniChar keyCodeChar[1];
        TISInputSourceRef sourceRef = TISCopyCurrentKeyboardLayoutInputSource();
        CFDataRef keyLayoutPtr = (CFDataRef)TISGetInputSourceProperty(sourceRef, kTISPropertyUnicodeKeyLayoutData);
        CFRelease(sourceRef);
        UCKeyTranslate((UCKeyboardLayout*)CFDataGetBytePtr(keyLayoutPtr), keyCode, kUCKeyActionDown, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, 1, &actualCount, keyCodeChar);
        
        // If the item is equal to 20 then there is some error so only show the key code value.
        if (keyCodeChar[0] == 20)
            keyString = [NSString stringWithFormat:@"VK:%d",keyCode];
        else
            keyString = [[NSString stringWithCharacters:keyCodeChar length:1] uppercaseString];
    }
    
    return [NSString stringWithFormat:@"%@%@", modifierString, keyString];
}

@end
