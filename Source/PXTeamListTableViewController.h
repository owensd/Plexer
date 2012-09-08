//
//  PXTeamListController.h
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXTeamTableCellView.h"
#import "PXTeam.h"

@interface PXTeamListTableViewController : NSWindow<NSTableViewDataSource, NSTableViewDelegate, PXTeamViewDelegate> {
    NSMutableArray *_teamList;
}
@property (weak) IBOutlet NSTableView *teamListView;
@property (nonatomic, strong) NSArray *teamList;

- (void)loadData;
- (void)addTeam:(PXTeam *)team;

@end
