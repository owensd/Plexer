//
//  PXSupportedGamesTableViewController.h
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PXTeamListTableViewController.h"

@interface PXSupportedGamesTableViewController : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
    NSArray *_filteredApplications;
}

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSTableView *applicationTableView;
@property (weak) IBOutlet PXTeamListTableViewController *teamListTableViewController;

@end
