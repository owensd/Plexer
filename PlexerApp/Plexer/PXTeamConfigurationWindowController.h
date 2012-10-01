//
//  PXTeamConfigurationWindowController.h
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXTeamDocumentController.h"
#import "PXApplication.h"
#import "PXTeam.h"

@interface PXTeamConfigurationWindowController : NSWindowController

@property (assign) IBOutlet NSPopover *applicationListPopover;
@property (assign) IBOutlet PXTeamDocumentController *teamDocumentController;

@property (assign) IBOutlet NSButton *applicationButton;
@property (assign) IBOutlet NSButton *teamMemberSlot1Button;
@property (assign) IBOutlet NSButton *teamMemberSlot2Button;
@property (assign) IBOutlet NSButton *teamMemberSlot3Button;
@property (assign) IBOutlet NSButton *teamMemberSlot4Button;
@property (assign) IBOutlet NSButton *teamMemberSlot5Button;

- (IBAction)chooseApplication:(id)sender;

- (void)changeApplicationForTeam:(PXApplication *)application;

- (void)updateWithTeam:(PXTeam *)team;

@end