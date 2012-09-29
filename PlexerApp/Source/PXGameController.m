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
NSString * const PXSupportGameInstallPathKey = @"PXSupportGameInstallPathKey";
NSString * const PXVirtualizeFileItemsKey = @"PXVirtualizeFileItemsKey";
NSString * const PXCopyFileItemsKey = @"PXCopyFileItemsKey";

NSString * const PXApplicationNameKey = @"PXApplicationNameKey";
NSString * const PXPathToApplicationKey = @"PXPathToApplicationKey";
NSString * const PXTeamMembersKey = @"PXTeamMembersKey";
NSString * const PXVirtualizeApplicationKey = @"PXVirtualizeApplicationKey";


NSArray *PXFilesToVirtualizeForApplication(NSString *applicationName)
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:PXSupportedGamesKey][applicationName][PXVirtualizeFileItemsKey];
}

NSArray *PXFilesToCopyForApplication(NSString *applicationName)
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:PXSupportedGamesKey][applicationName][PXCopyFileItemsKey];
}

void PXVirtualizeApplication(NSString *applicationName, NSString *pathToVirtualizationRoot, NSString *pathToApplication, NSUInteger playerSlot)
{
    NSLog(@"Attempting to virtualize application for slot #%lu", playerSlot);
    NSString *pathToVirtualizedApplicationFolder = [pathToVirtualizationRoot stringByAppendingPathComponent:[NSString stringWithFormat:@"Slot%lu", playerSlot]];
    
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


@implementation PXGameController

- (void)launch
{
    PXLog(@"Launching applications");

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
        NSNumber *virtualizeApplication = [teamMembers[slot] valueForKey:PXVirtualizeApplicationKey];
        if ([virtualizeApplication boolValue] == YES) {
            PXVirtualizeApplication(self.teamConfiguration[PXApplicationNameKey], pathToVirtualizationRoot, pathToApplication, slot);
        }
        
    }
}

@end
