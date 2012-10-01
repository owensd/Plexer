//
//  PXTeamMember.m
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamMember.h"

NSString * const PXTeamMemberSlotNumberKey              = @"PXTeamMemberSlotNumberKey";
NSString * const PXTeamMemberCharacterNameKey           = @"PXTeamMemberCharacterNameKey";
NSString * const PXTeamMemberVirtualizeGameInstanceKey  = @"PXTeamMemberVirtualizeGameInstanceKey";

@implementation PXTeamMember


#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [[PXTeamMember alloc] init];
    if (self) {
        self.characterName = [decoder decodeObjectForKey:PXTeamMemberCharacterNameKey];
        self.virtualizeGameInstance = [decoder decodeBoolForKey:PXTeamMemberVirtualizeGameInstanceKey];
        self.slotNumber = [decoder decodeIntegerForKey:PXTeamMemberSlotNumberKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.characterName forKey:PXTeamMemberCharacterNameKey];
    [encoder encodeBool:self.virtualizeGameInstance forKey:PXTeamMemberVirtualizeGameInstanceKey];
    [encoder encodeInteger:self.slotNumber forKey:PXTeamMemberSlotNumberKey];
}

@end
