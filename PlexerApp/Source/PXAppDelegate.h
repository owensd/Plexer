//
//  PXAppDelegate.h
//  Plexer
//
//  Created by David Owens II on 9/6/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXTeamConfigurationWindowController.h"
#import "PXBroadcastingController.h"

@interface PXAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet PXTeamConfigurationWindowController *teamConfigurationWindowController;

@property (assign) IBOutlet NSMenu *statusItemMenu;
@property (assign) IBOutlet NSMenuItem *toggleBroadcastingStatusMenuItem;
@property (assign) IBOutlet NSMenuItem *toggleBroadcastingMappedKeysStatusMenuItem;
@property (assign) IBOutlet NSMenuItem *showDebugLogMenuItem;

@property (assign) IBOutlet NSWindow *debugLogWindow;
@property (assign) IBOutlet NSArrayController *debugLogController;

@property (strong) NSImage *statusOnImage;
@property (strong) NSImage *statusOffImage;
@property (strong) NSImage *statusMixedImage;
@property (strong) NSStatusItem *statusItem;

@property (strong) PXBroadcastingController *broadcastingController;

- (IBAction)togglePlexingStatus:(id)sender;
- (IBAction)togglePlexingMappedKeysStatus:(id)sender;
- (IBAction)quit:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)showDebugLog:(id)sender;

- (IBAction)createNewTeam:(id)sender;

@end
