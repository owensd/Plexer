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
@property (assign) IBOutlet NSPopover *characterSettingsPopover;
@property (assign) IBOutlet PXTeamDocumentController *teamDocumentController;

@property (assign) IBOutlet NSButton *applicationButton;
@property (assign) IBOutlet NSButton *teamMemberSlot1Button;
@property (assign) IBOutlet NSButton *teamMemberSlot2Button;
@property (assign) IBOutlet NSButton *teamMemberSlot3Button;
@property (assign) IBOutlet NSButton *teamMemberSlot4Button;
@property (assign) IBOutlet NSButton *teamMemberSlot5Button;

@property (assign) IBOutlet NSImageView *characterPortraitView;
@property (assign) IBOutlet NSTextField *characterNameField;
@property (assign) IBOutlet NSButton *virtualizeCharacterCheckBox;
@property (assign) IBOutlet NSButton *characterSettingsActionButton;

- (IBAction)chooseApplication:(id)sender;
- (IBAction)showCharacterSettingsPopover:(id)sender;

- (IBAction)changeVirtualizationSettingForCharacter:(id)sender;
- (IBAction)changeCharacterName:(id)sender;

- (IBAction)characterSettingsAction:(id)sender;

- (void)changeApplicationForTeam:(PXApplication *)application;

- (void)updateWithTeam:(PXTeam *)team;

@end