//
//  PXTeam.h
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PXTeamMember.h"
#import "PXApplication.h"

@interface PXTeam : NSObject<NSCoding> {
    NSMutableArray *_teamMembers;
}

@property (weak) PXApplication *application;
@property (strong) NSArray *teamMembers;

- (void)addTeamMember:(PXTeamMember *)teamMember;

- (void)removeTeamMember:(PXTeamMember *)teamMember;
- (void)removeTeamMemberAtIndex:(NSInteger)index;

@end
