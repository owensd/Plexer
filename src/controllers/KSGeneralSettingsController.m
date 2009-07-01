//
//  KSGeneralSettingsController.m
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSGeneralSettingsController.h"


@implementation KSGeneralSettingsController

-(IBAction)changeShowInMenuBar:(id)sender {
    if ([sender state] == NSOnState)
        [appController showStatusItem];
    else
        [appController hideStatusItem];
}

@end
