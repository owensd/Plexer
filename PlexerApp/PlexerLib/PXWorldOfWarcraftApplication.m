//
//  PXWorldOfWarcraftApplication.m
//  WorldOfWarcraft
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXWorldOfWarcraftApplication.h"

@implementation PXWorldOfWarcraftApplication

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super initWithDictionary:dictionary];
    if (self) {
        self.pathToPreferencesFile = [@"~/Library/Preferences/com.blizzard.World of Warcraft.prefs" stringByStandardizingPath];
    }
    return self;
}

- (NSRunningApplication *)launchWithOptions:(NSDictionary *)options
{
    NSError *error;
    if ([self writeWindowConfigurationToPreferencesFile:options[PXApplicationWindowBoundsKey] error:&error] == NO) {
        NSLog(@"Unable to write configuration file: %@", error.localizedDescription);
    }
    
    return [super launchWithOptions:options];
}


#pragma mark - Helper methods

- (BOOL)writeWindowConfigurationToPreferencesFile:(NSString *)windowBounds error:(NSError **)error
{
    if (windowBounds == nil) { return YES; }
    
    NSString *contentsOfFile = [NSString stringWithContentsOfFile:self.pathToPreferencesFile encoding:NSUTF8StringEncoding error:nil];
    
    NSMutableString *newFileContents = [[NSMutableString alloc] init];
    NSArray *lines = [contentsOfFile componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSUInteger lineNumber = 0; lineNumber < lines.count; lineNumber++) {
        NSString *line = lines[lineNumber];
        
        [newFileContents appendFormat:@"%@\n", line];
        
        if ([line isEqualToString:@"$Current User\\World of Warcraft\\Client\\WindowBounds"]) {
            [newFileContents appendFormat:@"%@\n", windowBounds];
            lineNumber++;
        }
    }
    
    return [newFileContents writeToFile:self.pathToPreferencesFile atomically:YES encoding:NSUTF8StringEncoding error:error];
}

@end
