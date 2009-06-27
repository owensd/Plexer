//
//  KSConfigurationController.h
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KSConfigurationSettingsController : NSWindowController {

}

-(IBAction)changeSelectedConfiguration:(id)sender;
-(IBAction)renameSelectedConfiguration:(id)sender;
-(IBAction)removeSelectedConfiguration:(id)sender;

-(IBAction)changeSaveWindowPositionAndLayoutSetting:(id)sender;
-(IBAction)changeToggleDockHidingSetting:(id)sedner;
-(IBAction)changeMoveWindowsNearMenuBarSetting:(id)sender;

-(IBAction)addApplication:(id)sender;
-(IBAction)removeApplication:(id)sender;
-(IBAction)launchApplications:(id)sender;

-(IBAction)changeSelectedKeyOption:(id)sender;
-(IBAction)addKeyOptionKey:(id)sender;
-(IBAction)removeKeyOptionKey:(id)sender;

@end
