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

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self.supportedApplicationsPopover close];
    [self.supportedApplicationsTableView deselectAll:self];
}

@end
