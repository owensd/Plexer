//
//  PXAppDelegate.m
//  Plexer
//
//  Created by David Owens II on 9/6/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXAppDelegate.h"

@implementation PXAppDelegate
@synthesize applicationListPopover = _applicationListPopover;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.teamListController loadData];
}

- (NSArray *)supportedGames
{
    if (_supportedGames == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"supportedApplications" ofType:@"json"];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:NSJSONReadingAllowFragments error:nil];
        
        _supportedGames = [[NSMutableArray alloc] init];
        for (NSDictionary *game in dict[@"supportedApplications"]) {
            [_supportedGames addObject:[PXGame gameWithDictionary:game]];
        }
    }
    
    return _supportedGames;
}

- (IBAction)createNewTeam:(id)sender
{
    [self.applicationListPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxXEdge];
}

@end
