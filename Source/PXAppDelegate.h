//
//  PXAppDelegate.h
//  Plexer
//
//  Created by David Owens II on 9/6/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXTeamListTableViewController.h"

@interface PXAppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableArray *_supportedGames;
}

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, readonly) NSArray *supportedGames;
@property (weak) IBOutlet PXTeamListTableViewController *teamListController;
@property (weak) IBOutlet NSPopover *applicationListPopover;

- (IBAction)createNewTeam:(id)sender;

@end
