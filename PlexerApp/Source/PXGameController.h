//
//  PXGameController.h
//  Plexer
//
//  Created by David Owens II on 9/29/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PXGameController : NSObject

@property (strong) NSDictionary *teamConfiguration;

- (void)launch;

@end
