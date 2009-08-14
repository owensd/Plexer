//
//  KSRegistrationInfoController.m
//  Plexer
//
//  Created by David Owens II on 7/20/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSRegistrationInfoController.h"
#import "KSRegistration.h"


@implementation KSRegistrationInfoController

-(IBAction)okClicked:(id)sender {
    [NSApp endSheet:registrationPanel returnCode:1];
}

-(IBAction)cancelClicked:(id)sender {
    [NSApp endSheet:registrationPanel returnCode:0];
}

-(void)showRegistrationPanel {
    [NSApp beginSheet:registrationPanel
       modalForWindow:parentWindow
        modalDelegate:self
       didEndSelector:@selector(registrationPanelDidEnd:code:context:)
          contextInfo:NULL];
}

-(void)registrationPanelDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)context {
    if (choice == 1) {
        NSString* serialNumber = [serialNumberField stringValue];
        if (isValidSerialNumber([serialNumber cStringUsingEncoding:NSASCIIStringEncoding]) == 0) {
            [userSettings setSerialNumber:[serialNumberField stringValue]];
            
            [appController applicationDidFinishLaunching:nil];
        }
    }
    [sheet orderOut:registrationPanel];
}

-(void)controlTextDidChange:(NSNotification*)aNotification {
    NSString* serialNumber = [serialNumberField stringValue];
    if (isValidSerialNumber([serialNumber cStringUsingEncoding:NSASCIIStringEncoding]) == 0)
        [okButton setEnabled:YES];
    else
        [okButton setEnabled:NO];
}

// Handle this so that the window isn't actually closed. Errors occur if this isn't handled this way.
-(BOOL)windowShouldClose:(id)window {
    [NSApp endSheet:registrationPanel];
    return NO;
}

@end
