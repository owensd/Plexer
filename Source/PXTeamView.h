//
//  PXTeamView.h
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXTeam.h"

@class PXTeamView;

@protocol PXTeamViewDelegate <NSObject>

- (void)teamView:(PXTeamView *)teamView shouldStartPlexingForTeam:(PXTeam *)team;

@end

@interface PXTeamView : NSView

@property (weak) IBOutlet NSTextField *teamNameField;
@property (weak) IBOutlet NSTextField *gameNameField;

@property (weak) IBOutlet id<PXTeamViewDelegate> delegate;
@property (weak) PXTeam *team;

- (IBAction)start:(id)sender;

@end
