//
//  PXTeamConfigurationWindowController.m
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamConfigurationWindowController.h"

@implementation PXTeamConfigurationWindowController

- (IBAction)chooseApplication:(id)sender
{
//    PXLog(@"Show application list popover.");
    [self.applicationListPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

@end
