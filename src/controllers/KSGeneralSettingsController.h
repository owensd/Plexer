//
//  KSGeneralSettingsController.h
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BWToolkitFramework/BWToolkitFramework.h>
#import "KSAppController.h"


@interface KSGeneralSettingsController : NSWindowController {
    IBOutlet KSAppController* appController;
}

-(IBAction)changeShowInMenuBar:(id)sender;

@end
