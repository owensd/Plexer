//
//  PXMappedKeyStore.m
//  Plexer
//
//  Created by David Owens II on 10/5/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXMappedKeyStore.h"
#import <Carbon/Carbon.h>

const NSUInteger PXNumberOfKeyCodes = 1 << (sizeof(uint16_t) * 8);
const NSUInteger PXNumberOfFlags    = 1 << (sizeof(uint8_t) * 8);

typedef enum {
    PXAllWindows                = 0,
    PXAllWindowsButCurrent      = 1,
    PXRoundRobin                = 2
} PXMappedKeyBroadastType;

typedef struct {
    BOOL hasOverrides;
    CGKeyCode keyCode;
    CGEventFlags flags;
} PXMappedKeyTarget;

typedef struct {
    PXMappedKeyTarget **targets;
    NSUInteger numberOfTargets;
    
    PXMappedKeyBroadastType broadcastType;
    NSInteger lastTargetIndex;              // used for the round-robin broadcast type
    
} PXMappedKeyTargetInfoCache;

typedef struct {
    PXMappedKeyTargetInfoCache *targetInfoCache[PXNumberOfFlags];
} PXMappedKeyFlagCacheTable;

PXMappedKeyTarget *PXMappedKeyTargetCreate()
{
    PXMappedKeyTarget *target = malloc(sizeof(PXMappedKeyTarget));
    target->flags = 0;
    target->keyCode = 0;
    target->hasOverrides = NO;
    
    return target;
}

PXMappedKeyFlagCacheTable *PXMappedKeyFlagCacheTableCreate()
{
    PXMappedKeyFlagCacheTable *table = malloc(sizeof(PXMappedKeyFlagCacheTable));
    for (NSUInteger idx = 0; idx < PXNumberOfFlags; idx++) {
        table->targetInfoCache[idx] = 0;
    }
    
    return table;
}

PXMappedKeyTargetInfoCache *PXMappedKeyTargetInfoCacheCreate(NSUInteger numberOfTeamMembers)
{
    PXMappedKeyTargetInfoCache *cache = malloc(sizeof(PXMappedKeyTargetInfoCache));
    cache->numberOfTargets = numberOfTeamMembers;
    cache->lastTargetIndex = 0;
    cache->targets = malloc(sizeof(PXMappedKeyTarget) * numberOfTeamMembers);
    memset(cache->targets, 0, sizeof(PXMappedKeyTarget) * numberOfTeamMembers);
    
    return cache;
}

uint8_t PXEventFlagsToFlagIndex(CGEventFlags flags)
{
    // There are 25 different possibilites for flags; 4! + 1. (shift, cmd, alt/option, ctrl)
    // However, we can optimize lookup for memory but giving each a slot in a bit-field;
    // this requires 4 bits.
    
    static uint8_t shiftMask = 0x1;
    static uint8_t cmdMask = (0x1 << 1);
    static uint8_t optionMask = (0x1 << 2);
    static uint8_t ctrlMask = (0x1 << 3);
    
    uint8_t index = 0;
    if ((kCGEventFlagMaskAlternate & flags) == kCGEventFlagMaskAlternate) {
        index |= optionMask;
    }
    if ((kCGEventFlagMaskCommand & flags) == kCGEventFlagMaskCommand) {
        index |= cmdMask;
    }
    if ((kCGEventFlagMaskControl & flags) == kCGEventFlagMaskControl) {
        index |= ctrlMask;
    }
    if ((kCGEventFlagMaskShift & flags) == kCGEventFlagMaskShift) {
        index |= shiftMask;
    }
    
    return index;
}

@implementation PXMappedKeyStore {
    PXMappedKeyFlagCacheTable *_keyCodeLookup[PXNumberOfKeyCodes];
    NSMutableArray *_playerList;
}

- (id)initWithDictionary:(NSDictionary *)teamConfiguration
{
    self = [super init];
    if (self) {
        [self buildMappedKeyStoreCacheWithDictionary:teamConfiguration];
        _playerList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    for (NSUInteger keyCodeIdx = 0; keyCodeIdx < PXNumberOfKeyCodes; keyCodeIdx++) {
        PXMappedKeyFlagCacheTable * flagCacheTable = _keyCodeLookup[keyCodeIdx];
        if (flagCacheTable != 0) {
            for (NSUInteger flagIdx = 0; flagIdx < PXNumberOfFlags; flagIdx++) {
                PXMappedKeyTargetInfoCache *targetInfoCache = flagCacheTable->targetInfoCache[flagIdx];
                if (targetInfoCache != 0) {
                    for (NSUInteger targetIdx = 0; targetIdx < targetInfoCache->numberOfTargets; targetIdx++) {
                        PXMappedKeyTarget *mappedKeyTarget = targetInfoCache->targets[targetIdx];
                        if (mappedKeyTarget != 0) {
                            free(mappedKeyTarget);
                        }
                    }
                    free(targetInfoCache->targets);
                    free(targetInfoCache);
                }
            }
            free(flagCacheTable->targetInfoCache);
            free(flagCacheTable);
        }
    }
    
    free(_keyCodeLookup);
}

- (CGEventRef)processEvent:(CGEventRef)event forPlayerAtIndex:(NSUInteger)index currentPSN:(ProcessSerialNumber *)currentPSN playerPSN:(ProcessSerialNumber *)playerPSN
{
    assert(currentPSN != NULL);
    assert(playerPSN != NULL);
    
    CGKeyCode keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags eventFlags = CGEventGetFlags(event);
    uint8_t flagIndex = PXEventFlagsToFlagIndex(eventFlags);
    
    BOOL samePSN = (currentPSN->highLongOfPSN == playerPSN->highLongOfPSN && currentPSN->lowLongOfPSN == playerPSN->lowLongOfPSN);
    NSLog(@"same PSN? : %@", samePSN ? @"YES" : @"NO");
    
    PXMappedKeyFlagCacheTable *flagTableCache = _keyCodeLookup[keyCode];
    if (flagTableCache == NULL) {
        return (samePSN == YES) ? event : NULL;
    }
    
    NSLog(@"flagIndex: %d", flagIndex);
    PXMappedKeyTargetInfoCache *targetInfoCache = flagTableCache->targetInfoCache[flagIndex];
    if (targetInfoCache == NULL) {
        return (samePSN == YES) ? event : NULL;
    }

    return event;
}


#pragma mark - Internal helper methods

- (void)buildMappedKeyStoreCacheWithDictionary:(NSDictionary *)teamConfiguration
{
    NSLog(@"number of keycodes: %lu", PXNumberOfKeyCodes);
    NSLog(@"number of flags: %lu", PXNumberOfFlags);
    
    for (NSUInteger idx = 0; idx < PXNumberOfKeyCodes; idx++) {
        _keyCodeLookup[idx] = 0;
    }
    
    NSMutableDictionary *mappedKeyNameToKeyCodeLookup = [[NSMutableDictionary alloc] init];
    
    NSArray *teamMembers = teamConfiguration[@"PXTeamMembersKey"];
    NSDictionary *mappedKeys = teamConfiguration[@"PXMappedKeysKey"];
    
    for (NSString *key in mappedKeys.keyEnumerator) {
        NSDictionary *mappedKeyDict = mappedKeys[key];

        CGKeyCode inputKeyCode = [mappedKeyDict[@"PXMappedKeyInputKeyCodeKey"] unsignedShortValue];
        CGEventFlags inputEventFlags = [mappedKeyDict[@"PXMappedKeyInputFlagsKey"] unsignedIntegerValue];
// Potentially not going to be used...
//        CGKeyCode outputKeyCode = [mappedKeyDict[@"PXMappedKeyOutputKeyCodeKey"] unsignedShortValue];
//        CGEventFlags outputEventFlags = [mappedKeyDict[@"PXMappedKeyOutputFlagsKey"] unsignedIntegerValue];
        PXMappedKeyBroadastType broadcastType = (PXMappedKeyBroadastType)[mappedKeyDict[@"PXMappedKeyBroadcastTypeKey"] integerValue];

        if (_keyCodeLookup[inputKeyCode] == NULL) {
            PXMappedKeyFlagCacheTable *table = PXMappedKeyFlagCacheTableCreate();
            uint8_t flagIndex = PXEventFlagsToFlagIndex(inputEventFlags);
            
            PXMappedKeyTargetInfoCache *targetInfoCache = PXMappedKeyTargetInfoCacheCreate(teamMembers.count);
            targetInfoCache->broadcastType = broadcastType;
            table->targetInfoCache[flagIndex] = targetInfoCache;

            _keyCodeLookup[inputKeyCode] = table;
            mappedKeyNameToKeyCodeLookup[key] = @{ @"keyCode" : @(inputKeyCode), @"flagIndex" : @(flagIndex) };
        }
        else {
            NSLog(@"A mapped key already exists for keyCode: %d", inputKeyCode);
        }
    }
    
    NSUInteger teamMemberIndex = 0;
    for (NSDictionary *teamMember in teamMembers) {
        NSDictionary *teamMemberMappedKeys = teamMember[@"PXTeamMemberMappedKeysKey"];
        
        for (NSString *key in teamMemberMappedKeys.keyEnumerator) {
            NSDictionary *teamMemberMappedKey = teamMemberMappedKeys[key];
            
            NSDictionary *mappedKeyLookup = mappedKeyNameToKeyCodeLookup[key];
            if (mappedKeyLookup != nil) {
                CGKeyCode keyCode = [mappedKeyLookup[@"keyCode"] unsignedShortValue];
                uint8_t flagIndex = [mappedKeyLookup[@"flagIndex"] unsignedCharValue];

                PXMappedKeyTarget *target = PXMappedKeyTargetCreate();
                NSNumber *overrideKeyCode = teamMemberMappedKey[@"PXMappedKeyInputKeyCodeKey"];
                if (overrideKeyCode != nil) {
                    target->keyCode = [overrideKeyCode unsignedShortValue];
                    target->flags = [teamMemberMappedKey[@"PXMappedKeyInputFlagsKey"] unsignedIntegerValue];
                }
                _keyCodeLookup[keyCode]->targetInfoCache[flagIndex]->targets[teamMemberIndex] = target;
            }
        }
        teamMemberIndex++;
    }
}


@end
