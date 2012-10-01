//
//  PXTeamMember.h
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PXTeamMember : NSObject<NSCoding>

@property (copy) NSString *characterName;
@property (assign) BOOL virtualizeGameInstance;
@property (strong) NSImage *characterPortrait;
@property (assign) NSInteger slotNumber;

@end
