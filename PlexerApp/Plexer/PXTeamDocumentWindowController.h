//
//  PXTeamDocumentWindowController.h
//  Plexer
//
//  Created by David Owens II on 10/4/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PXTeamDocumentWindowController : NSWindowController

@property (assign) IBOutlet NSTextField *debugInfoField;
@property (strong) NSXPCConnection *xpcConnection;

- (IBAction)configureTeam:(id)sender;
- (IBAction)launchTeam:(id)sender;

@end
