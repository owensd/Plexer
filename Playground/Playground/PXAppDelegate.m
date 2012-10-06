//
//  PXAppDelegate.m
//  Playground
//
//  Created by David Owens II on 10/3/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXAppDelegate.h"

@implementation PXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSString *windowBounds = [[NSUserDefaults standardUserDefaults] stringForKey:@"windowBounds"];
    if (windowBounds != nil) {
        NSArray *components = [windowBounds componentsSeparatedByString:@","];
        
        if (components.count == 4) {
            CGFloat x = [components[0] floatValue];
            CGFloat y = [components[1] floatValue];
            CGFloat width = [components[2] floatValue] - x;
            CGFloat height = [components[3] floatValue] - y;
            
            CGRect frame = CGRectMake(x, y, width, height);
            CGRect backingFrame = [[NSScreen mainScreen] convertRectFromBacking:frame];
            
            [self.window setFrame:backingFrame display:YES];
        }
    }
}

@end
