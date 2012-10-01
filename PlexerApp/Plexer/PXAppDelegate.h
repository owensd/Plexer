//
//  PXAppDelegate.h
//  Plexer
//
//  Created by David Owens II on 9/6/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXBroadcastingController.h"
#import "PXTeamConfigurationWindowController.h"
#import "PXTeamDocumentController.h"

#ifdef DEBUG
    #define PXLog(MESSAGE, ...) do{\
        NSString *__message = [NSString stringWithFormat:MESSAGE, ##__VA_ARGS__];\
        [[(PXAppDelegate *)[[NSApplication sharedApplication] delegate] debugLogController] addObject:__message];\
    }while(0);
#else
    #define PXLog(MESSAGE)
#endif


@interface PXAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet PXTeamConfigurationWindowController *teamConfigurationWindowController;
@property (assign) IBOutlet PXTeamDocumentController *teamDocumentController;

@property (assign) IBOutlet NSWindow *debugLogWindow;
@property (assign) IBOutlet NSArrayController *debugLogController;

@property (strong) PXBroadcastingController *broadcastingController;

- (IBAction)launchApplications:(id)sender;

- (IBAction)createNewTeam:(id)sender;

@end
