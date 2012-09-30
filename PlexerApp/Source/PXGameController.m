//
//  PXGameController.m
//  Plexer
//
//  Created by David Owens II on 9/29/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXGameController.h"

NSString * const PXKeyForBroadcastingKey = @"PXKeyForBroadcastingKey";
NSString * const PXKeyForBroadcastingMappedKeysKey = @"PXKeyForBroadcastingMappedKeysKey";

NSString * const PXSupportedGamesKey = @"PXSupportedGamesKey";
NSString * const PXSupportedGameInstallPathKey = @"PXSupportedGameInstallPathKey";
NSString * const PXVirtualizeFileItemsKey = @"PXVirtualizeFileItemsKey";
NSString * const PXCopyFileItemsKey = @"PXCopyFileItemsKey";

NSString * const PXApplicationNameKey = @"PXApplicationNameKey";
NSString * const PXPathToApplicationKey = @"PXPathToApplicationKey";
NSString * const PXTeamMembersKey = @"PXTeamMembersKey";
NSString * const PXVirtualizeApplicationKey = @"PXVirtualizeApplicationKey";

NSString * const PXApplicationWindowBoundsKey = @"PXApplicationWindowBoundsKey";

NSString * const PXSupportedGamePreferencePathKey = @"PXSupportedGamePreferencePathKey";


NSArray *PXFilesToVirtualizeForApplication(NSString *applicationName)
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:PXSupportedGamesKey][applicationName][PXVirtualizeFileItemsKey];
}

NSArray *PXFilesToCopyForApplication(NSString *applicationName)
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:PXSupportedGamesKey][applicationName][PXCopyFileItemsKey];
}

NSString *PXPathToPreferencesFileForApplication(NSString *applicationName)
{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:PXSupportedGamesKey][applicationName][PXSupportedGamePreferencePathKey] stringByStandardizingPath];
}

void PXVirtualizeApplication(NSString *applicationName, NSString *pathToVirtualizedApplicationFolder, NSString *pathToApplication, BOOL removeExisting)
{
    if (removeExisting == YES) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToVirtualizedApplicationFolder error:nil];
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:pathToVirtualizedApplicationFolder withIntermediateDirectories:YES attributes:nil error:nil];
        
    NSString *pathToApplicationFolder = [pathToApplication stringByDeletingLastPathComponent];
    for (NSString *fileItemName in PXFilesToVirtualizeForApplication(applicationName)) {
        [[NSFileManager defaultManager] createSymbolicLinkAtPath:[pathToVirtualizedApplicationFolder stringByAppendingPathComponent:fileItemName]
                                             withDestinationPath:[pathToApplicationFolder stringByAppendingPathComponent:fileItemName]
                                                           error:nil];
    }
    for (NSString *fileItemName in PXFilesToCopyForApplication(applicationName)) {
        NSString *destinationPath = [pathToVirtualizedApplicationFolder stringByAppendingPathComponent:fileItemName];
        
        [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
        [[NSFileManager defaultManager] copyItemAtPath:[pathToApplicationFolder stringByAppendingPathComponent:fileItemName]
                                                toPath:destinationPath
                                                 error:nil];
    }
}

void PXSetupDesiredWindowLocationAndSizeForApplication(NSString *windowBounds, NSString *applicationName)
{
    //
    // UNDONE: This ONLY works for World of Warcraft!!
    //

    NSString *pathToPreferencesFile = PXPathToPreferencesFileForApplication(applicationName);

    NSMutableString *newFileContents = [[NSMutableString alloc] init];
    NSString *contentsOfFile = [NSString stringWithContentsOfFile:pathToPreferencesFile encoding:NSUTF8StringEncoding error:nil];
    NSArray *lines = [contentsOfFile componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSUInteger lineNumber = 0; lineNumber < lines.count; lineNumber++) {
        NSString *line = lines[lineNumber];
        [newFileContents appendFormat:@"%@\n", line];
        
        if ([line isEqualToString:@"$Current User\\World of Warcraft\\Client\\WindowBounds"]) {
            [newFileContents appendFormat:@"%@\n", windowBounds];
            lineNumber++;
        }
    }

    [newFileContents writeToFile:pathToPreferencesFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
}


@implementation PXGameController

- (void)launch
{
    PXLog(@"Launching applications");

    NSString *applicationName = self.teamConfiguration[PXApplicationNameKey];
    NSString *pathToApplication = self.teamConfiguration[PXPathToApplicationKey];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToApplication] == NO) {
        PXLog(@"Game is not installed!");
        return;
    }
    
    NSString *pathToVirtualizationRoot = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Plexer"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToVirtualizationRoot] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:pathToVirtualizationRoot withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSArray *teamMembers = self.teamConfiguration[PXTeamMembersKey];
    for (NSUInteger slot = 0; slot < teamMembers.count; slot++) {
        NSString *pathToVirtualizedApplicationFolder = [pathToVirtualizationRoot stringByAppendingPathComponent:[NSString stringWithFormat:@"Slot%lu", slot]];

        NSString *applicationLaunchPath;

        NSNumber *virtualizeApplication = [teamMembers[slot] valueForKey:PXVirtualizeApplicationKey];
        if ([virtualizeApplication boolValue] == YES) {
            PXVirtualizeApplication(self.teamConfiguration[PXApplicationNameKey], pathToVirtualizedApplicationFolder, pathToApplication, NO);
            applicationLaunchPath = [pathToVirtualizedApplicationFolder stringByAppendingPathComponent:[pathToApplication lastPathComponent]];
        }
        else {
            applicationLaunchPath = pathToApplication;
        }
        
        PXSetupDesiredWindowLocationAndSizeForApplication(teamMembers[slot][PXApplicationWindowBoundsKey]   , applicationName);
        
        NSTask *launchedApplicationTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[ applicationLaunchPath ]];
        [launchedApplicationTask waitUntilExit];
    }
}

@end
