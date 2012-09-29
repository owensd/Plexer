//
//  PXAppDelegate.m
//  PlexerHelper
//
//  Created by David Owens II on 9/28/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXAppDelegate.h"

NSString * const PXKeyForBroadcastingKey = @"PXKeyForBroadcastingKey";
NSString * const PXKeyForBroadcastingMappedKeysKey = @"PXKeyForBroadcastingMappedKeysKey";

NSString * const PXSupportedGamesKey = @"PXSupportedGamesKey";
NSString * const PXSupportGameInstallPathKey = @"PXSupportGameInstallPathKey";
NSString * const PXVirtualizeFileItemsKey = @"PXVirtualizeFileItemsKey";
NSString * const PXCopyFileItemsKey = @"PXCopyFileItemsKey";



NSImage *PXLoadNamedImageForStatusBar(NSString *imageName)
{
    static CGFloat thickness = -1;
    static CGFloat padding = -1;
    static CGSize statusItemSize;

    if (thickness < 0) {
        thickness = [NSStatusBar systemStatusBar].thickness;
        padding = 2.0;
        statusItemSize = CGSizeMake(thickness - padding * 2, thickness - padding * 2);
    }

    NSImage *image = [NSImage imageNamed:imageName];
    image.size = statusItemSize;
    
    return image;
}

@implementation PXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *pathToDefaults = [[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:pathToDefaults];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    self.statusOnImage = PXLoadNamedImageForStatusBar(NSImageNameEveryone);
    self.statusOffImage = PXLoadNamedImageForStatusBar(NSImageNameUser);
    self.statusMixedImage = PXLoadNamedImageForStatusBar(NSImageNameUserGroup);
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.image = self.statusOffImage;
    self.statusItem.menu = self.statusItemMenu;
    self.statusItem.highlightMode = YES;
    
    self.broadcastingController = [[PXBroadcastingController alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(broadcastingStateDidChange:)
                                                 name:PXBroadcastingDidChangeNotification
                                               object:self.broadcastingController];

    self.broadcastingController.broadcasting = NO;
    self.broadcastingController.broadcastingMappedKeys = NO;

#ifdef DEBUG
    self.showDebugLogMenuItem.hidden = NO;
    [self.debugLogWindow makeKeyAndOrderFront:self];
    self.debugLogWindow.level = NSPopUpMenuWindowLevel;
#endif
}

- (void)broadcastingStateDidChange:(NSNotification *)notification
{
    self.toggleBroadcastingMappedKeysStatusMenuItem.state = self.broadcastingController.broadcastingMappedKeys ? NSOnState : NSOffState;

    if (self.broadcastingController.broadcasting == NO) {
        self.statusItem.image = self.statusOffImage;
        self.toggleBroadcastingStatusMenuItem.title = @"Start Plexing";
    }
    else {
        self.toggleBroadcastingStatusMenuItem.title = @"Stop Plexing";

        if (self.broadcastingController.broadcastingMappedKeys == NO) {
            self.statusItem.image = self.statusOnImage;
        }
        else {
            self.statusItem.image = self.statusMixedImage;
        }
    }
}

#pragma - Status Menu Item Actions

- (IBAction)togglePlexingStatus:(id)sender
{
    self.broadcastingController.broadcasting = !self.broadcastingController.broadcasting;
}

- (IBAction)togglePlexingMappedKeysStatus:(id)sender
{
    self.broadcastingController.broadcastingMappedKeys = !self.broadcastingController.broadcastingMappedKeys;
}

- (IBAction)quit:(id)sender
{
    [[NSApplication sharedApplication] terminate:sender];
}

- (IBAction)showPreferences:(id)sender
{
    
}

- (IBAction)showDebugLog:(id)sender
{
    [self.debugLogWindow makeKeyAndOrderFront:sender];
}


@end
