//
//  PXTeamConfigurationWindowController.h
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PXTeamConfigurationWindowController : NSWindowController

@property (assign) IBOutlet NSPopover *applicationListPopover;

- (IBAction)chooseApplication:(id)sender;

@end