//
//  KSGeneralSettingsController.h
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BWToolkitFramework/BWToolkitFramework.h>
#import "KSUserSettings.h"


@interface KSGeneralSettingsController : NSWindowController {
    IBOutlet KSUserSettings* userSettings;
}

-(IBAction)changeBroadcastingKey:(id)sender;
-(IBAction)changeSwitchBetweenApplicationsModifier:(id)sender;
-(IBAction)changeQuitAppKey:(id)sender;
-(IBAction)changeSwitchToAppModifier:(id)sender;
-(IBAction)changeAutomaticallyCheckForUpdatesSetting:(id)sender;

@end
