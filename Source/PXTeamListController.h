//
//  PXTeamListController.h
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXTeamView.h"

@interface PXTeamListController : NSWindow<NSTableViewDataSource, NSTableViewDelegate, PXTeamViewDelegate> {
    NSMutableArray *_teamList;
}

@property (nonatomic, strong) NSArray *teamList;

@end
