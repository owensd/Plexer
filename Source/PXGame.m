//
//  PXGame.m
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXGame.h"

@implementation PXGame

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _name = dictionary[@"name"];
        
        for (NSString *executableName in dictionary[@"executablePaths"]) {
            NSString *executablePath = [@"/Applications" stringByAppendingPathComponent:executableName];
            _installed = [[NSFileManager defaultManager] fileExistsAtPath:executablePath];
            
            if (_installed) {
                _applicationPath = executablePath;
                _icon = [[NSWorkspace sharedWorkspace] iconForFile:_applicationPath];
                break;
            }
        }
    }
    
    return self;
}

+ (id)gameWithDictionary:(NSDictionary *)dictionary
{
    return [[PXGame alloc] initWithDictionary:dictionary];
}

@end
