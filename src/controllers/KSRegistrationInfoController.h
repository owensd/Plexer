//
//  KSRegistrationInfoController.h
//  Plexer
//
//  Created by David Owens II on 7/20/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KSUserSettings.h"


@interface KSRegistrationInfoController : NSObject {
    IBOutlet NSTextField* serialNumberField;
    IBOutlet NSWindow* registrationPanel;
    IBOutlet NSWindow* parentWindow;
    IBOutlet KSUserSettings* userSettings;
}

-(IBAction)okClicked:(id)sender;
-(IBAction)cancelClicked:(id)sender;

-(void)showRegistrationPanel;

@end
