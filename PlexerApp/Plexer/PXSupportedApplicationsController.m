//
//  PXSupportedApplicationsController.m
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXSupportedApplicationsController.h"
#import "PXApplication.h"

@implementation PXSupportedApplicationsController

- (IBAction)didSelectRowForSupportedApplicationsTableView:(id)sender
{
    PXApplication *application = [PXApplication supportedApplications][self.supportedApplicationsTableView.selectedRow];
    [self.teamConfigurationWindowController changeApplicationForTeam:application];
    
    [self.supportedApplicationsPopover close];
    [self.supportedApplicationsTableView deselectAll:self];
}

#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [PXApplication supportedApplications].count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [PXApplication supportedApplications][row];
}

#pragma mark - NSTableViewDelegate methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    PXApplication *application = [tableView.dataSource tableView:tableView objectValueForTableColumn:tableColumn row:row];
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];
    [cellView.textField setStringValue:application.displayName];
    cellView.imageView.image = [[NSWorkspace sharedWorkspace] iconForFile:application.launchPath];
    
    return cellView;
}

@end
