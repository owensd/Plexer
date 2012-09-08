//
//  PXTeamView.h
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXTeam.h"

@class PXTeamTableCellView;

@protocol PXTeamViewDelegate <NSObject>

- (void)teamView:(PXTeamTableCellView *)teamView willStartPlexingWithTeam:(PXTeam *)team;
- (void)teamView:(PXTeamTableCellView *)teamView willRemoveTeam:(PXTeam *)team;
- (void)teamView:(PXTeamTableCellView *)teamView willConfigureTeam:(PXTeam *)team;

@end

@interface PXTeamTableCellView : NSView

@property (weak) IBOutlet NSTextField *teamNameField;
@property (weak) IBOutlet NSImageCell *applicationImageView;

@property (weak) IBOutlet id<PXTeamViewDelegate> delegate;
@property (weak) PXTeam *team;

- (IBAction)start:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)configure:(id)sender;

@end
