//
//  PXGame.h
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PXGame : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary;
+ (id)gameWithDictionary:(NSDictionary *)dictionary;

@property (strong, readonly) NSString *name;
@property (strong, readonly) NSImage *icon;
@property (strong, readonly) NSString *applicationPath;
@property (assign, readonly, getter=isInstalled) BOOL installed;

@end
