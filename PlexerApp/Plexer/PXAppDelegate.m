//
//  PXAppDelegate.m
//  Plexer
//
//  Created by David Owens II on 9/6/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXAppDelegate.h"

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

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    
    NSString *pathToDefaults = [[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:pathToDefaults];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    self.broadcastingController = [[PXBroadcastingController alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(broadcastingStateDidChange:)
                                                 name:PXBroadcastingDidChangeNotification
                                               object:self.broadcastingController];
    
#ifdef DEBUG
    [self.debugLogWindow makeKeyAndOrderFront:self];
    self.debugLogWindow.level = NSPopUpMenuWindowLevel;
#endif
}

- (void)broadcastingStateDidChange:(NSNotification *)aNotification
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Broadcasting State Changed";
    
    switch (self.broadcastingController.broadcastingState) {
        case PXBroadcastingDisabled:
            notification.informativeText = @"No longer broadcasting any keybinds.";
            break;
            
        case PXBroadcastingAllKeys:
            notification.informativeText = @"Broadcasting all keybinds.";
            break;
            
        case PXBroadcastingMappedKeys:
            notification.informativeText = @"Broadcasting only mapped keys.";
            break;
    }
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (IBAction)launchApplications:(id)sender
{
    [self.teamConfigurationWindowController.window miniaturize:self];
}

- (IBAction)createNewTeam:(id)sender
{
}


#pragma mark - NSUserNotificationCenterDelegate methods

// Force notifications to always show, even if our app is front-most.
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end
