//
//  KSRegistrationInfoController.h
//  Plexer
//
//  Created by David Owens II on 7/20/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KSUserSettings.h"
#import <BWToolkitFramework/BWToolkitFramework.h>


@interface KSRegistrationInfoController : NSObject {
    IBOutlet NSTextField* serialNumberField;
    IBOutlet BWTransparentButton* okButton;
    IBOutlet NSWindow* registrationPanel;
    IBOutlet NSWindow* parentWindow;
    IBOutlet KSUserSettings* userSettings;
    
    IBOutlet id appController;
}

-(IBAction)okClicked:(id)sender;
-(IBAction)cancelClicked:(id)sender;

-(void)showRegistrationPanel;

@end
