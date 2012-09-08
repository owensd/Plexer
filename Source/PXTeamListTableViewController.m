//
//  PXTeamListController.m
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamListTableViewController.h"
#import "PXPlexerController.h"
#import "PXAppDelegate.h"

@implementation PXTeamListTableViewController

@synthesize teamListView = _teamListView;
@synthesize teamList = _teamList;

- (id)init
{
    self = [super init];
    if (self) {
        _teamList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)loadData
{
    PXAppDelegate *appDelegate = (PXAppDelegate *)[[NSApplication sharedApplication] delegate];
    for (NSUInteger count = 0; count < 3; count++) {
        PXTeam *team = [[PXTeam alloc] init];
        team.name = [NSString stringWithFormat:@"Team%lu", count];
        team.game = appDelegate.supportedGames[0];
        [_teamList addObject:team];
        [self.teamListView reloadData];
    }
}

- (void)addTeam:(PXTeam *)team
{
    [_teamList addObject:team];
    [self.teamListView reloadData];
}


#pragma mark NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_teamList count];
}

#pragma mark NSTableViewDelegate Methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString * const PXTeamViewIdentifier = @"PXTeamTableCellView";
    
    PXTeamTableCellView *teamView = [tableView makeViewWithIdentifier:PXTeamViewIdentifier owner:self];
    teamView.team = _teamList[row];
    teamView.delegate = self;
    teamView.teamNameField.stringValue = teamView.team.name;
    teamView.applicationImageView.image = teamView.team.game.icon;
//    teamView.gameNameField.stringValue = teamView.team.game.name;
    
    return teamView;
}

#pragma mark PXTeamViewDelegate Methods

- (void)teamView:(PXTeamTableCellView *)teamView willStartPlexingWithTeam:(PXTeam *)team
{
    PXPlexerController *plexer = [[PXPlexerController alloc] init];
    [plexer startPlexingWithTeam:team];
}

- (void)teamView:(PXTeamTableCellView *)teamView willRemoveTeam:(PXTeam *)team
{
    NSLog(@"I am no longer of use.");
}

- (void)teamView:(PXTeamTableCellView *)teamView willConfigureTeam:(PXTeam *)team
{
    NSLog(@"I am in great need of modifications.");
}

@end
