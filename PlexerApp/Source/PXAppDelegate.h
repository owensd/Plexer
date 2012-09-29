//
//  PXAppDelegate.h
//  Plexer
//
//  Created by David Owens II on 9/6/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXTeamConfigurationWindowController.h"

@interface PXAppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableArray *_supportedGames;
    NSMutableArray *_teamList;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet PXTeamConfigurationWindowController *teamConfigurationWindowController;

@property (nonatomic, readonly) NSArray *teamList;
@property (nonatomic, readonly) NSArray *supportedGames;

- (IBAction)createNewTeam:(id)sender;

@end
