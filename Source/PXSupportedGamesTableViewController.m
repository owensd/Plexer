//
//  PXSupportedGamesTableViewController.m
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXSupportedGamesTableViewController.h"
#import "PXGameTableCellView.h"
#import "PXAppDelegate.h"
#import "PXTeam.h"

@implementation PXSupportedGamesTableViewController


#pragma mark NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    static NSPredicate *onlyInstalledGames = nil;
    if (onlyInstalledGames == nil) {
        onlyInstalledGames = [NSPredicate predicateWithFormat:@"%K == YES", @"isInstalled"];
    }
    
    PXAppDelegate *appDelegate = (PXAppDelegate *)[[NSApplication sharedApplication] delegate];
    _filteredApplications = [appDelegate.supportedGames filteredArrayUsingPredicate:onlyInstalledGames];

    return [_filteredApplications count];
}

#pragma mark NSTableViewDelegate Methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString * const PXApplicationTableCellViewIdentifier = @"PXGameTableCellView";
    
    PXGame *game = _filteredApplications[row];
    PXGameTableCellView *applicationView = [tableView makeViewWithIdentifier:PXApplicationTableCellViewIdentifier owner:self];
    applicationView.gameNameField.stringValue = game.name;
    applicationView.gameNameField.toolTip = game.applicationPath;
    applicationView.gameIconView.image = game.icon;
    
    return applicationView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    PXGame *game = _filteredApplications[tableView.selectedRow];
    [self.popover close];
    
    PXTeam *team = [[PXTeam alloc] init];
    team.game = game;
    team.name = @"New Team";
    [self.teamListTableViewController addTeam:team];
    
    // 2. Start Configuring the game
    NSLog(@"Start to configure team: %@", team.name);
}

@end
