//
//  PXAppDelegate.m
//  Plexer
//
//  Created by David Owens II on 9/6/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXAppDelegate.h"
#import "PXGame.h"

@implementation PXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

- (NSArray *)teamList
{
    if (_teamList == nil) {
        _teamList = [[NSMutableArray alloc] init];

        
    }
    
    return _teamList;
}

- (NSArray *)supportedGames
{
    if (_supportedGames == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"games" ofType:@"json"];
        NSArray *games = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:NSJSONReadingAllowFragments error:nil];
        
        _supportedGames = [[NSMutableArray alloc] init];
        for (NSDictionary *game in games) {
            [_supportedGames addObject:[PXGame gameWithDictionary:game]];
        }
        
        //
        // Allow user specified games as well.
        //
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        if (searchPaths[0] != nil) {
            NSString *userPath = [searchPaths[0] stringByAppendingPathComponent:@"Plexer/games.json"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:userPath]) {
                NSArray *userGames = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:userPath] options:NSJSONReadingAllowFragments error:nil];
                for (NSDictionary *game in userGames) {
                    [_supportedGames addObject:[PXGame gameWithDictionary:game]];
                }
            }
        }
    }
    
    return _supportedGames;
}

- (IBAction)createNewTeam:(id)sender
{
}

@end
