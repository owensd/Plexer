//
//  PXTeam.m
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeam.h"

NSString * const PXTeamApplicationKey = @"PXTeamApplicationKey";
NSString * const PXTeamMembersKey = @"PXTeamMembersKey";

@implementation PXTeam

- (void)addTeamMember:(PXTeamMember *)teamMember
{
    if ([_teamMembers containsObject:teamMember] == NO) {
        [_teamMembers addObject:teamMember];
    }
}

- (void)removeTeamMember:(PXTeamMember *)teamMember
{
    [_teamMembers removeObject:teamMember];
}


#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder
{
    PXTeam *team = [[PXTeam alloc] init];
    if (team != nil) {
        team.application = [decoder decodeObjectForKey:PXTeamApplicationKey];
        team.teamMembers = [decoder decodeObjectForKey:PXTeamMembersKey];
    }
    
    return team;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.application forKey:PXTeamApplicationKey];
    [encoder encodeObject:self.teamMembers forKey:PXTeamMembersKey];
}

@end
