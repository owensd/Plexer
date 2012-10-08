//
//  PXMappedKeyStore.m
//  Plexer
//
//  Created by David Owens II on 10/5/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXMappedKeyStore.h"
#import <PlexerLib/PlexerLib.h>

#import <Carbon/Carbon.h>


NSString *CGEventToNSString(CGEventRef event)
{
    CGKeyCode keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags flags = CGEventGetFlags(event);

    return [NSString stringWithFormat:@"%d_%llu", keyCode, flags];
}


@interface PXMappedKeyStoreTeamMember : NSObject

- (id)initWithMappedKey:(PXMappedKey *)mappedKey;

@property (assign) NSInteger playerIndex;
@property (strong) PXMappedKey *mappedKey;

@end

@implementation PXMappedKeyStoreTeamMember

- (id)initWithMappedKey:(PXMappedKey *)mappedKey
{
    self = [super init];
    if (self) {
        self.mappedKey = mappedKey;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"index: %ld, mapped key: %@", self.playerIndex, self.mappedKey];
}

@end


@interface PXMappedKeyCache : NSObject

- (id)initWithMappedKey:(PXMappedKey *)mappedKey;

- (NSString *)key;

@property (strong) PXMappedKey *mappedKey;
@property (strong) NSMutableArray *teamMembers;
@property (assign) NSUInteger nextIndexInTeamMembers;

@end

@implementation PXMappedKeyCache

- (id)init
{
    self = [super init];
    if (self) {
        _teamMembers = [[NSMutableArray alloc] init];
        self.nextIndexInTeamMembers = 0;
    }
    return self;
}

- (id)initWithMappedKey:(PXMappedKey *)mappedKey
{
    self = [self init];
    if (self) {
        self.mappedKey = mappedKey;
    }
    return self;
}

- (NSString *)key
{
    return [NSString stringWithFormat:@"%d_%llu", self.mappedKey.keyCode, self.mappedKey.flags];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"key: %@, mapped key: %@, team: %@", self.key, self.mappedKey, self.teamMembers];
}

@end



@implementation PXMappedKeyStore {
    NSMutableDictionary *_mappedKeyKeyCodeLookup;
    NSMutableDictionary *_mappedKeyNameLookup;
    NSUInteger _numberOfTeamMembers;
}

- (id)initWithDictionary:(NSDictionary *)teamConfiguration
{
    self = [super init];
    if (self) {
        [self buildMappedKeyStoreCacheWithDictionary:teamConfiguration];
    }
    return self;
}

- (CGEventRef)handleMappedKeyEvent:(CGEventRef)event applications:(NSArray *)runningApplications
{
    PXMappedKeyCache *mappedKeyCache = [self mappedKeyCacheForEvent:event];
    if (mappedKeyCache == nil) {
        NSLog(@"no mappedKeyCache for event: %@", CGEventToNSString(event));
        return event;
    }
    
    NSLog(@"mapped key cache: %@", mappedKeyCache);
    
    switch (mappedKeyCache.mappedKey.broadcastType) {
        case PXAllWindows:
        case PXAllWindowsButCurrent: {
            ProcessSerialNumber currentPSN;
            GetFrontProcess(&currentPSN);

            //
            // UNDONE: There is not good correlation between team member and the running application.
            //
            NSUInteger teamMemberIndex = 0;
            for (NSRunningApplication *application in runningApplications) {
                ProcessSerialNumber teamMemberPSN;
                GetProcessForPID(application.processIdentifier, &teamMemberPSN);
                
                BOOL samePSN = (currentPSN.highLongOfPSN == teamMemberPSN.highLongOfPSN && currentPSN.lowLongOfPSN == teamMemberPSN.lowLongOfPSN);
                if (mappedKeyCache.mappedKey.broadcastType == PXAllWindowsButCurrent && samePSN == YES) { teamMemberIndex++; continue; }
                
                CGEventRef eventToSend = [self eventFromMappedKeyCache:mappedKeyCache forPlayerIndex:teamMemberIndex fromEvent:event];
                if (eventToSend != NULL) {
                    CGEventPostToPSN(&teamMemberPSN, eventToSend);
                }
                
                teamMemberIndex++;
            }
        }
            
        case PXRoundRobin:
            for (PXMappedKeyStoreTeamMember *teamMember in mappedKeyCache.teamMembers) {
                if (teamMember.playerIndex == [mappedKeyCache.teamMembers[mappedKeyCache.nextIndexInTeamMembers] playerIndex]) {
                    ProcessSerialNumber teamMemberPSN;
                    GetProcessForPID([runningApplications[teamMember.playerIndex] processIdentifier], &teamMemberPSN);
                    
                    CGEventRef eventToSend = [self eventFromMappedKeyCache:mappedKeyCache forPlayerIndex:teamMember.playerIndex fromEvent:event];
                    if (eventToSend != NULL) {
                        CGEventPostToPSN(&teamMemberPSN, eventToSend);
                    }
                    
                    mappedKeyCache.nextIndexInTeamMembers = (mappedKeyCache.nextIndexInTeamMembers + 1) % mappedKeyCache.teamMembers.count;
                    
                    break;
                }
            }
            break;
    }
    
    return NULL;
}

- (CGEventRef)eventFromMappedKeyCache:(PXMappedKeyCache *)mappedKeyCache forPlayerIndex:(NSUInteger)playerIndex fromEvent:(CGEventRef)event
{
    for (PXMappedKeyStoreTeamMember *teamMember in mappedKeyCache.teamMembers) {
        if (teamMember.playerIndex == playerIndex) {
            CGEventRef copyOfEvent = CGEventCreateCopy(event);
            CGEventSetIntegerValueField(copyOfEvent, kCGKeyboardEventKeycode, teamMember.mappedKey.keyCode);
            CGEventSetFlags(copyOfEvent, teamMember.mappedKey.flags);
            
            return copyOfEvent;
        }
    }
    
    return NULL;
}

- (PXMappedKeyCache *)mappedKeyCacheForEvent:(CGEventRef)event
{
    CGKeyCode keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags flags = CGEventGetFlags(event);

    return _mappedKeyKeyCodeLookup[[NSString stringWithFormat:@"%d_%llu", keyCode, flags]];
}


#pragma mark - Internal helper methods

- (void)buildMappedKeyStoreCacheWithDictionary:(NSDictionary *)teamConfiguration
{
    _mappedKeyKeyCodeLookup = [[NSMutableDictionary alloc] init];
    _mappedKeyNameLookup = [[NSMutableDictionary alloc] init];
    
    NSDictionary *mappedKeys = teamConfiguration[@"PXMappedKeysKey"];
    
    for (NSString *key in mappedKeys.keyEnumerator) {
        PXMappedKey *mappedKey = [[PXMappedKey alloc] initWithDictionary:mappedKeys[key]];
        PXMappedKeyCache *mappedKeyCache = [[PXMappedKeyCache alloc] initWithMappedKey:mappedKey];
        _mappedKeyKeyCodeLookup[mappedKeyCache.key] = mappedKeyCache;
        _mappedKeyNameLookup[key] = mappedKeyCache;
    }
    
    NSArray *teamMembers = teamConfiguration[@"PXTeamMembersKey"];
    _numberOfTeamMembers = teamMembers.count;

    NSUInteger teamMemberIndex = 0;
    for (NSDictionary *teamMember in teamMembers) {
        NSDictionary *teamMemberMappedKeys = teamMember[@"PXTeamMemberMappedKeysKey"];
        
        for (NSString *key in teamMemberMappedKeys.keyEnumerator) {
            PXMappedKeyCache *mappedKeyCache = _mappedKeyNameLookup[key];
            
            PXMappedKey *teamMemberMappedKey = [[PXMappedKey alloc] initWithMappedKey:mappedKeyCache.mappedKey overrides:teamMemberMappedKeys[key]];
            
            PXMappedKeyStoreTeamMember *mappedKeyTeamMember = [[PXMappedKeyStoreTeamMember alloc] initWithMappedKey:teamMemberMappedKey];
            mappedKeyTeamMember.playerIndex = teamMemberIndex;

            [mappedKeyCache.teamMembers addObject:mappedKeyTeamMember];
        }
        
        teamMemberIndex++;
    }
}


@end
