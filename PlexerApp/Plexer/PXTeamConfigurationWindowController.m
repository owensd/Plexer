//
//  PXTeamConfigurationWindowController.m
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamConfigurationWindowController.h"
#import "PXTeamDocument.h"

#define PXAddCharacter      0
#define PXRemoveCharacter   1

@implementation PXTeamConfigurationWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {

    }
    
    return self;
}

- (IBAction)chooseApplication:(id)sender
{
    [self.applicationListPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (IBAction)showCharacterSettingsPopover:(id)sender
{
    PXTeam *team = [(PXTeamDocument *)self.teamDocumentController.currentDocument team];
    NSInteger slotMinus1 = [sender tag] - 1; // make the slot counting zero-based.

    if (slotMinus1 < team.teamMembers.count) {
        PXTeamMember *teamMember = team.teamMembers[slotMinus1];
        
        self.characterPortraitView.image = teamMember.characterPortrait;
        self.characterPortraitView.tag = slotMinus1;

        self.virtualizeCharacterCheckBox.state = teamMember.virtualizeGameInstance;
        self.virtualizeCharacterCheckBox.tag = slotMinus1;

        self.characterNameField.stringValue = teamMember.characterName;
        self.characterNameField.tag = slotMinus1;
        
        self.characterSettingsActionButton.title = @"Remove";
        self.characterSettingsActionButton.tag = PXRemoveCharacter;
    }
    else {
        self.characterPortraitView.image = nil;
        self.characterPortraitView.tag = -1;

        self.virtualizeCharacterCheckBox.state = NSOnState;
        self.virtualizeCharacterCheckBox.tag = -1;

        self.characterNameField.stringValue = @"";
        self.characterNameField.tag = -1;

        self.characterSettingsActionButton.title = @"Add";
        self.characterSettingsActionButton.tag = PXAddCharacter;
    }
    
    [self.characterSettingsPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (IBAction)characterSettingsAction:(id)sender
{
    PXTeam *team = [(PXTeamDocument *)self.teamDocumentController.currentDocument team];

    if ([sender tag] == PXAddCharacter) {
        PXTeamMember *teamMember = [[PXTeamMember alloc] init];
        teamMember.characterName = self.characterNameField.stringValue;
        teamMember.virtualizeGameInstance = self.virtualizeCharacterCheckBox.state == NSOnState;
        teamMember.slotNumber = team.teamMembers.count + 1;
        
        [team addTeamMember:teamMember];
        [self.teamDocumentController.currentDocument updateChangeCount:NSChangeDone];
    }
    else {
        [team removeTeamMemberAtIndex:self.characterNameField.tag];
        [self.teamDocumentController.currentDocument updateChangeCount:NSChangeDone];
        
        //
        // Invalidate the tag for the character name field so that the name doesn't get
        // updated on us when the popover closes.
        //
        self.characterNameField.tag = -1;
    }
    
    [self.characterSettingsPopover close];
    [self updateCharacterSlotsWithTeam:team];
}


- (void)changeApplicationForTeam:(PXApplication *)application
{
    PXTeam *team = [(PXTeamDocument *)self.teamDocumentController.currentDocument team];
    team.application = application;
    [self updateApplicationButtonWithTeam:team];
    [self.teamDocumentController.currentDocument updateChangeCount:NSChangeDone];
}

- (void)updateCharacterSlotsWithTeam:(PXTeam *)team
{
    self.teamMemberSlot1Button.title = team.teamMembers.count > 0 ? [team.teamMembers[0] characterName] : @"Slot1";
    self.teamMemberSlot2Button.title = team.teamMembers.count > 1 ? [team.teamMembers[1] characterName] : @"Slot2";
    self.teamMemberSlot3Button.title = team.teamMembers.count > 2 ? [team.teamMembers[2] characterName] : @"Slot3";
    self.teamMemberSlot4Button.title = team.teamMembers.count > 3 ? [team.teamMembers[3] characterName] : @"Slot4";
    self.teamMemberSlot5Button.title = team.teamMembers.count > 4 ? [team.teamMembers[4] characterName] : @"Slot5";
}

- (IBAction)changeVirtualizationSettingForCharacter:(id)sender
{
    NSInteger tag = [sender tag];
    if (tag != -1) {
        PXTeam *team = [(PXTeamDocument *)self.teamDocumentController.currentDocument team];
        if (tag < team.teamMembers.count) {
            [(PXTeamMember *)team.teamMembers[tag] setVirtualizeGameInstance:([sender state] == NSOnState)];
            [self.teamDocumentController.currentDocument updateChangeCount:NSChangeDone];
        }
    }
}

- (IBAction)changeCharacterName:(id)sender
{
    NSInteger tag = [sender tag];
    if (tag != -1) {
        PXTeam *team = [(PXTeamDocument *)self.teamDocumentController.currentDocument team];
        if (tag < team.teamMembers.count) {
            [(PXTeamMember *)team.teamMembers[tag] setCharacterName:[sender stringValue]];
            [self updateCharacterSlotsWithTeam:team];
            [self.teamDocumentController.currentDocument updateChangeCount:NSChangeDone];
        }
    }
}

- (void)updateApplicationButtonWithTeam:(PXTeam *)team
{
    if (team.application == nil) {
        self.applicationButton.title = @"App";
        self.applicationButton.image = nil;
    }
    else {
        self.applicationButton.title = @"";
        self.applicationButton.image = [[NSWorkspace sharedWorkspace] iconForFile:team.application.launchPath];
    }
}

- (void)updateWithTeam:(PXTeam *)team
{
    [self updateApplicationButtonWithTeam:team];
    [self updateCharacterSlotsWithTeam:team];
}


#pragma mark - NSWindowDelegate methods

//
// These are necessary because of the HACK! in PXTeamConfigurationWindow and the performClose: action handler.
// If this is not done, then the document is never saved when a team is closed.
//
- (BOOL)windowShouldClose:(id)sender
{
    [self.teamDocumentController.currentDocument canCloseDocumentWithDelegate:self
                                                          shouldCloseSelector:@selector(document:shouldClose:contextInfo:)
                                                                  contextInfo:nil];
    
    // Always return NO as the window will be closed in the document:shouldClose:contextInfo: selector, when appropriate.
    return NO;
}

- (void)document:(NSDocument *)doc shouldClose:(BOOL)shouldClose contextInfo:(void *)contextInfo
{
    if (shouldClose) {
        [self close];
    }
}



@end
