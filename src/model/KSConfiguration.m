//
//  KSConfiguration.m
//  Plexer
//
//  Created by David Owens II on 6/27/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSConfiguration.h"

NSString* Name = @"Name";
NSString* BlackListKeys = @"BlackListKeys";
NSString* RoundRobinKeys = @"RoundRobinKeys";
NSString* Applications = @"Applications";

@implementation KSConfiguration

@synthesize name, applications, blackListKeys, roundRobinKeys;

+(KSConfiguration*)withName:(NSString*)name {
    KSConfiguration* config = [[KSConfiguration alloc] init];
    config.name = name;
    config.blackListKeys = nil;
    config.roundRobinKeys = nil;
    config.applications = nil;
    
    return config;
}

+(KSConfiguration*)fromDictionary:(NSDictionary*)data {
    KSConfiguration* config = [[KSConfiguration alloc] init];
    config.name = [data valueForKey:Name];
    NSMutableArray* blKeys = [[NSMutableArray alloc] init];
    for (NSString* keyInfo in [[data valueForKey:BlackListKeys] componentsSeparatedByString:@":"]) {
        NSArray* keyInfoComponents = [keyInfo componentsSeparatedByString:@","];
        [blKeys addObject:[NSDictionary dictionaryWithObjectsAndKeys:[keyInfoComponents objectAtIndex:0], @"KeyCode", [keyInfoComponents objectAtIndex:1], @"Modifiers", nil]];
    }
    config.blackListKeys = blKeys;
    config.roundRobinKeys = [[data valueForKey:RoundRobinKeys] componentsSeparatedByString:@":"];
    config.applications = [[data valueForKey:Applications] componentsSeparatedByString:@":"];
    
    return config;
}


-(NSDictionary*)configurationAsDictionary {
    NSMutableDictionary* aDictionary = [[NSMutableDictionary alloc] init];
    
    [aDictionary setObject:name forKey:Name];
    if (blackListKeys != nil) {
        NSMutableArray* keys = [[NSMutableArray alloc] init];
        for (NSDictionary* keyInfo in blackListKeys) {
            [keys addObject:[NSString stringWithFormat:@"%d,%d", [[keyInfo valueForKey:@"KeyCode"] integerValue], [[keyInfo valueForKey:@"Modifiers"] integerValue]]];
        }
        [aDictionary setValue:[keys componentsJoinedByString:@":"] forKey:BlackListKeys];
    }
    if (roundRobinKeys != nil)
        [aDictionary setValue:[roundRobinKeys componentsJoinedByString:@":"] forKey:RoundRobinKeys];
    if (applications != nil)
        [aDictionary setValue:[applications componentsJoinedByString:@":"] forKey:Applications];
    
    return aDictionary;
}

@end
