//
//  PXTeamView.m
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamTableCellView.h"

@implementation PXTeamTableCellView

- (void)start:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(teamView:willStartPlexingWithTeam:)]) {
        PXTeamTableCellView *teamView = (PXTeamTableCellView *)[sender superview];
        PXTeam *team = teamView.team;
        
        [self.delegate teamView:teamView willStartPlexingWithTeam:team];
    }
}

- (void)remove:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(teamView:willRemoveTeam:)]) {
        PXTeamTableCellView *teamView = (PXTeamTableCellView *)[sender superview];
        PXTeam *team = teamView.team;
        
        [self.delegate teamView:teamView willRemoveTeam:team];
    }
}

- (void)configure:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(teamView:willConfigureTeam:)]) {
        PXTeamTableCellView *teamView = (PXTeamTableCellView *)[sender superview];
        PXTeam *team = teamView.team;
        
        [self.delegate teamView:teamView willConfigureTeam:team];
    }

}

@end
