//
//  AppController.h
//  Plexer
//
//  Created by David Owens II on 6/10/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BWToolkitFramework/BWToolkitFramework.h>
#import <Sparkle/Sparkle.h>
#import "KSUserSettings.h"
#import "KSConfigurationSettingsController.h"
#import <Carbon/Carbon.h>
#import "KSInfoPanelController.h"
#import "KSRegistrationInfoController.h"


@interface KSAppController : NSObject {
    IBOutlet NSWindow* preferencesWindow;
    IBOutlet NSMenu* statusItemMenu;
    IBOutlet KSUserSettings* userSettings;
    IBOutlet SUUpdater* updater;
    IBOutlet KSConfigurationSettingsController* configurationsController;
    IBOutlet NSImageView* demoImage;
    IBOutlet KSInfoPanelController* infoPanelController;
    IBOutlet NSMenuItem* registerPlexerMenuItem;
    IBOutlet KSRegistrationInfoController* registrationPanelController;
    
    BOOL broadcasting;
    BOOL inTrialMode;
    NSArray* applications;
}

@property (assign, getter=isBroadcasting) BOOL broadcasting;
@property (assign, readonly, getter=isInTrialMode) BOOL inTrialMode;
@property (retain) NSArray* applications;
@property (retain) KSConfigurationSettingsController* configurationsController;

-(IBAction)showPreferences:(id)sender;
-(IBAction)startBroadcasting:(id)sender;
-(IBAction)stopBroadcasting:(id)sender;

-(IBAction)registerSoftware:(id)sender;

-(void)showStatusItem;
-(void)hideStatusItem;

-(void)registerEventTaps;
-(KSUserSettings*)userSettings;

@end
