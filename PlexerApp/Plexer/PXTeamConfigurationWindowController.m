//
//  PXTeamConfigurationWindowController.m
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamConfigurationWindowController.h"
#import "PXTeamDocument.h"

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

- (void)changeApplicationForTeam:(PXApplication *)application
{
    PXTeam *team = [(PXTeamDocument *)self.teamDocumentController.currentDocument team];
    team.application = application;
    [self updateApplicationButtonWithTeam:team];
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
    PXLog(@"Application = %@", team.application.displayName);
    
    [self updateApplicationButtonWithTeam:team];
}

@end
