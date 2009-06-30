//
//  KSConfigurationController.m
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSConfigurationSettingsController.h"


@implementation KSConfigurationSettingsController
@synthesize userSettings, configurationSelected;


-(IBAction)changeSelectedConfiguration:(id)sender {
    NSLog(@"changeSelectedConfiguration action called.");

    self.configurationSelected = [configurationsPopUp selectedTag] > 0;
}

-(IBAction)renameSelectedConfiguration:(id)sender {
}

-(IBAction)removeSelectedConfiguration:(id)sender {
}

-(IBAction)changeSaveWindowPositionAndLayoutSetting:(id)sender {
}

-(IBAction)changeToggleDockHidingSetting:(id)sedner {
}

-(IBAction)changeMoveWindowsNearMenuBarSetting:(id)sender {
}


-(IBAction)addApplication:(id)sender {
}

-(IBAction)removeApplication:(id)sender {
}

-(IBAction)launchApplications:(id)sender {
}


-(IBAction)changeSelectedKeyOption:(id)sender {
}

-(IBAction)addKeyOptionKey:(id)sender {
}

-(IBAction)removeKeyOptionKey:(id)sender {
}


@end
