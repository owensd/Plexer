//
//  PXTeamListController.m
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamListController.h"

@implementation PXTeamListController

@synthesize teamList = _teamList;

- (id)init
{
    self = [super init];
    if (self) {
        // load my data!
        _teamList = [[NSMutableArray alloc] init];

        for (NSUInteger count = 0; count < 3; count++) {
            PXTeam *team = [[PXTeam alloc] init];
            team.teamName = [NSString stringWithFormat:@"Team%lu", count];
            team.gameName = @"World of Warcraft";
            [_teamList addObject:team];
        }
    }
    
    return self;
}


#pragma mark NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_teamList count];
}

#pragma mark NSTableViewDelegate Methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString * const PXTeamViewIdentifier = @"PXTeamView";
    
    PXTeamView *teamView = [tableView makeViewWithIdentifier:PXTeamViewIdentifier owner:self];
    teamView.team = _teamList[row];
    teamView.delegate = self;
    teamView.teamNameField.stringValue = teamView.team.teamName;
    teamView.gameNameField.stringValue = teamView.team.gameName;
    
    return teamView;
}

#pragma mark PXTeamViewDelegate Methods

- (void)teamView:(PXTeamView *)teamView shouldStartPlexingForTeam:(PXTeam *)team
{
    NSLog(@"Start Plexing: %@", team.teamName);
}

@end
