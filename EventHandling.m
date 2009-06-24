/*
 *  EventHandling.c
 *  Plexer
 *
 *  Created by David Owens II on 6/13/09.
 *  Copyright 2009 Kiad Software. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>
#include "EventHandling.h"

bool IsBroadcasting = false;
CFMutableArrayRef ProcessList;

void KSChangeBroadcastingTo(bool broadcast) {
    IsBroadcasting = broadcast;
}

void KSChangeOnlyProcessKeysWhenAppIsFocusedTo(bool process) {
    [[NSUserDefaults standardUserDefaults] setBool:process forKey:@"OnlyProcessKeysWhenAppIsFocused"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

OSStatus GetProcessForUIElementRef(AXUIElementRef elementRef, ProcessSerialNumber* psn) {
    pid_t pid;
    
    AXUIElementGetPid(elementRef, &pid);
    return GetProcessForPID(pid, psn);
}


static OSStatus KeyboardEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon) {
    // We need this so we know what the previous modifier key(s) were already down.
    static UInt32 lastModifierKeyCode = 0;

    UInt32 eventKind = GetEventKind(inEvent);
    
    UInt32 keyCode;
    GetEventParameter(inEvent, kEventParamKeyCode, typeUInt32, NULL, sizeof(UInt32), NULL, &keyCode);
    
    // We only handle key events when we are broadcasting or it is the hotkey that is pressed.
    if (!IsBroadcasting && eventKind != kEventHotKeyPressed) {
        return noErr;
    }
    
    ProcessSerialNumber focusedPSN;
    GetFrontProcess(&focusedPSN);
    
    // Determine if the key being pressed is on the 'do-not-pass' list.
    CFStringRef processName = NULL;
    CopyProcessName(&focusedPSN, &processName);
    NSDictionary* blacklistSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"BlackList"];
    NSString* blacklistKeys = [blacklistSettings objectForKey:(NSString*)processName];
    NSArray* keyCodes = [blacklistKeys componentsSeparatedByString:@" "];
    for (NSString* str in keyCodes) {
        int blacklistKeyCode = [str intValue];
        if (keyCode == blacklistKeyCode)
            return noErr;
    }
    
    
    // TODO: Add the code to handle the 'OnlyProcessKeysWhenAppIsFocused' user preference.
    
    CFIndex countOfProcessList = CFArrayGetCount(ProcessList);
    for (CFIndex idx = 0; idx < countOfProcessList; ++idx) {
        AXUIElementRef app = CFArrayGetValueAtIndex(ProcessList, idx);
        ProcessSerialNumber psn;
        GetProcessForUIElementRef(app, &psn);
        
        Boolean isSameProcess;
        SameProcess(&focusedPSN, &psn, &isSameProcess);
        
        // Don't send the keys to the focused application again. If we don't do this, we get
        // doubled up on the items in the other applications.
        if (isSameProcess)
            continue;
        
        UInt32 modifiers = 0;
        GetEventParameter(inEvent, kEventParamKeyModifiers, typeUInt32, NULL, sizeof(UInt32), NULL, &modifiers);
        
        switch (eventKind) {
            case kEventRawKeyDown:
            case kEventRawKeyRepeat:
                KSSendModifierKeys(app, modifiers, true);
                KSPostKeyboardEvent(app, keyCode, true);
                //CGEventPostToPSN(&psn, CGEventCreateKeyboardEvent(NULL, keyCode, true));
                break;
                
            case kEventRawKeyUp:
                // Maybe need to add a short pause to fix the keys not always going through??
                // http://lists.apple.com/archives/quartz-dev/2009/Jan/msg00015.html
                KSPostKeyboardEvent(app, keyCode, false);
                KSSendModifierKeys(app, modifiers, false);

                break;

            case kEventRawKeyModifiersChanged:
                GetEventParameter(inEvent, kEventParamKeyModifiers, typeUInt32, NULL, sizeof(UInt32), NULL, &keyCode);

                lastModifierKeyCode = keyCode;
                break;                
        }
    }
    
    return noErr;
}


static OSStatus ApplicationEventHandler(EventHandlerCallRef inRef, EventRef inEvent, void* inRefcon) {
    Boolean autoAdd;
    CFPreferencesGetAppBooleanValue(CFSTR("AutoAdd"), kCFPreferencesCurrentApplication, &autoAdd);
    
    if (autoAdd) {
        UInt32 eventKind = GetEventKind(inEvent);
        ProcessSerialNumber psn;
        CFStringRef processName = NULL;
        pid_t pid = 0;
               
        GetEventParameter(inEvent, kEventParamProcessID, typeProcessSerialNumber, NULL, sizeof(ProcessSerialNumber), NULL, &psn);
        CopyProcessName(&psn, &processName);
        
        // Getting an error, so let's test something out.
        if (processName == NULL)
            return noErr;
        
        CFArrayRef applications = CFPreferencesCopyAppValue(CFSTR("Applications"), kCFPreferencesCurrentApplication);
        CFIndex applicationsCount = CFArrayGetCount(applications);
        for (CFIndex idx = 0; idx < applicationsCount; ++idx) {
            CFStringRef name = CFArrayGetValueAtIndex(applications, idx);
            if (CFStringCompare(processName, name, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                GetProcessPID(&psn, &pid);
                break;
            }
        }
        
        if (pid != 0) {
            AXUIElementRef elementRef = AXUIElementCreateApplication(pid);
            
            // Only add the app if it's not already in the list.
            CFIndex processCount = CFArrayGetCount(ProcessList);
            
            Boolean isSame = false;
            for (CFIndex idx = 0; idx < processCount; ++idx) {
                AXUIElementRef processRef = CFArrayGetValueAtIndex(ProcessList, idx);
                
                ProcessSerialNumber processPSN;
                GetProcessForUIElementRef(processRef, &processPSN);
                
                SameProcess(&psn, &processPSN, &isSame);
                if (isSame)
                    break;
                
                pid_t pid;
                GetProcessPID(&processPSN, &pid);
                KSFocusFirstWindowOfPid(pid);
                
    // Resize the window the first time.
    //    CGSize size;
    //    size.width = 1200;
    //    size.height = 800;
    //    CFTypeRef cfSize = AXValueCreate(kAXValueCGSizeType, &size);
    //    AXUIElementSetAttributeValue(appRef, kAXSizeAttribute, cfSize);
    //    CGPoint pos;
    //    pos.x = 0;
    //    pos.y = 0;
    //    CFTypeRef cfPos = AXValueCreate(kAXValueCGPointType, &pos);
    //    AXUIElementSetAttributeValue(winRef, kAXPositionAttribute, (CFTypeRef)cfPos);
            }
            
            if (!isSame || eventKind == kEventAppLaunched) {
                CFArrayAppendValue(ProcessList, elementRef);
            }
            
        }
        
        CFRelease(applications);
    }
    
    return noErr;
}


void KSRegisterEventHandlers(void) {
    EventTypeSpec kEvents[] = {
        { kEventClassKeyboard, kEventRawKeyDown },
        { kEventClassKeyboard, kEventRawKeyUp },
        { kEventClassKeyboard, kEventRawKeyRepeat },
        { kEventClassKeyboard, kEventRawKeyModifiersChanged },
    };
    
    EventTypeSpec kAppEvents[] = {
        { kEventClassApplication, kEventAppFrontSwitched },
        { kEventClassApplication, kEventAppLaunched },
        { kEventClassApplication, kEventAppTerminated },
    };
    
    InstallEventHandler(GetEventMonitorTarget(), KeyboardEventHandler, GetEventTypeCount(kEvents), kEvents, 0, NULL);
    InstallApplicationEventHandler(ApplicationEventHandler, GetEventTypeCount(kAppEvents), kAppEvents, 0, NULL);

    ProcessList = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
}

void KSCleanUp() {
    CFRelease(ProcessList);
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

void KSPostKeyboardEvent(AXUIElementRef app, UInt32 keyCode, bool keydown) {
    AXUIElementPostKeyboardEvent(app, 0, keyCode, keydown);
}

void KSSendModifierKeys(AXUIElementRef app, UInt32 modifiers, bool keydown) {
    if ((modifiers & shiftKey) == shiftKey)
        AXUIElementPostKeyboardEvent(app, 0, (UInt32)kVK_Shift, keydown);
    if ((modifiers & cmdKey) == cmdKey)
        AXUIElementPostKeyboardEvent(app, 0, (UInt32)kVK_Command, keydown);
    if ((modifiers & optionKey) == optionKey)
        AXUIElementPostKeyboardEvent(app, 0, (UInt32)kVK_Option, keydown);
    if ((modifiers & controlKey) == controlKey)
        AXUIElementPostKeyboardEvent(app, 0, (UInt32)kVK_Control, keydown);
}
