//
//  PXAppDelegate.h
//  Plexer
//
//  Created by David Owens II on 9/6/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXTeamDocumentWindowController.h"


@interface PXAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet PXTeamDocumentWindowController *teamDocumentWindowController;

- (IBAction)launchApplications:(id)sender;

- (IBAction)createNewTeam:(id)sender;

@end
