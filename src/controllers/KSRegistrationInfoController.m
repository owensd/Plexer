//
//  KSRegistrationInfoController.m
//  Plexer
//
//  Created by David Owens II on 7/20/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSRegistrationInfoController.h"


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
        // validate the serial number.
        
        [userSettings setSerialNumber:[serialNumberField stringValue]];
    }
    [sheet orderOut:registrationPanel];
}


@end
