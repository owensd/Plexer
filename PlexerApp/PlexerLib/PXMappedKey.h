//
//  PXMappedKey.h
//  Plexer
//
//  Created by David Owens II on 10/8/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PXAllWindows                = 0,
    PXAllWindowsButCurrent      = 1,
    PXRoundRobin                = 2
} PXMappedKeyBroadastType;

@interface PXMappedKey : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (id)initWithMappedKey:(PXMappedKey *)mappedKey overrides:(NSDictionary *)dictionary;

@property (assign) CGKeyCode keyCode;
@property (assign) CGEventFlags flags;
@property (assign) PXMappedKeyBroadastType broadcastType;

@end
