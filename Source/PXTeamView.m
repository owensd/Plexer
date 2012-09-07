//
//  PXTeamView.m
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamView.h"

@implementation PXTeamView

- (void)start:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(teamView:shouldStartPlexingForTeam:)]) {
        PXTeamView *teamView = (PXTeamView *)[sender superview];
        PXTeam *team = teamView.team;
        
        [self.delegate teamView:teamView shouldStartPlexingForTeam:team];
    }
}

@end
