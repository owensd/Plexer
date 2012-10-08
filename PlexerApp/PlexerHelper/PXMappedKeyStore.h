//
//  PXMappedKeyStore.h
//  Plexer
//
//  Created by David Owens II on 10/5/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PXMappedKeyStore : NSObject

- (id)initWithDictionary:(NSDictionary *)teamConfiguration;
- (CGEventRef)handleMappedKeyEvent:(CGEventRef)event applications:(NSArray *)runningApplications;

@end
