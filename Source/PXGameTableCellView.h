//
//  PXGameTableCellView.h
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PXGameTableCellView : NSView

@property (weak) IBOutlet NSImageCell *gameIconView;
@property (weak) IBOutlet NSTextField *gameNameField;


@end
