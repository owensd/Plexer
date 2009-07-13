//
//  KSKeyOptionsDataSource.h
//  Plexer
//
//  Created by David Owens II on 7/9/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KSUserSettings.h"
#import "KSConfigurationSettingsController.h"

@interface KSKeyOptionsDataSource : NSObject {
    IBOutlet KSUserSettings* userSettings;
    IBOutlet KSConfigurationSettingsController* configurationController;
}

@end
