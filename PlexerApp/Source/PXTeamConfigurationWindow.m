//
//  PXTeamConfigurationWindow.m
//  Plexer
//
//  Created by David Owens II on 9/9/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamConfigurationWindow.h"

@implementation PXTeamConfigurationWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:deferCreation];
    if (self) {
        [self setAlphaValue:0.75];
        [self setOpaque:NO];
        [self setExcludedFromWindowsMenu:NO];
        [self setLevel:NSPopUpMenuWindowLevel];
    }

    return self;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

//
// The following methods are required to get the close functionality to work
// on a borderless window.
//
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
    if ([item action] == @selector(performClose:)) {
        return YES;
    }
    
    return [super validateUserInterfaceItem:item];
}

- (IBAction)performClose:(id)sender
{
    BOOL shouldClose = YES;
    if ([self.delegate respondsToSelector:@selector(windowShouldClose:)]) {
        shouldClose = [self.delegate windowShouldClose:self];
    }
    
    if (shouldClose) {
        [self close];
    }
}

@end
