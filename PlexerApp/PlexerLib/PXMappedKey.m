//
//  PXMappedKey.m
//  Plexer
//
//  Created by David Owens II on 10/8/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXMappedKey.h"

@implementation PXMappedKey

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _broadcastType = [dictionary[@"PXMappedKeyBroadcastTypeKey"] intValue];
        _keyCode = [dictionary[@"PXMappedKeyKeyCodeKey"] shortValue];
        _flags = [dictionary[@"PXMappedKeyFlagsKey"] integerValue];
    }
    return self;
}

- (id)initWithMappedKey:(PXMappedKey *)mappedKey overrides:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        NSNumber *broadcastType = dictionary[@"PXMappedKeyBroadcastTypeKey"];
        NSNumber *keyCode = dictionary[@"PXMappedKeyKeyCodeKey"];
        NSNumber *flags = dictionary[@"PXMappedKeyFlagsKey"];

        _broadcastType = (broadcastType != nil) ? [broadcastType intValue] : mappedKey.broadcastType;
        _keyCode = (keyCode != nil) ? [keyCode shortValue] : mappedKey.keyCode;
        _flags = (flags != nil) ? [flags integerValue] : mappedKey.flags;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"keyCode: %d, flags: %llu, broadcastType: %d", self.keyCode, self.flags, self.broadcastType];
}

@end
