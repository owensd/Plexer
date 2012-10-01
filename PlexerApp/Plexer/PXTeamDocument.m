//
//  PXTeamDocument.m
//  Plexer
//
//  Created by David Owens II on 9/10/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamDocument.h"
#import "PXAppDelegate.h"

NSString * const PXTeamDocumentErrorDomain = @"PXTeamDocumentErrorDomain";
NSString * const PXPlexerTeamDocumentTypeName = @"PlexerTeam";

NSString * const PXTeamKey = @"Team";

@implementation PXTeamDocument

- (id)init
{
    self = [super init];
    if (self) {
        self.team = [[PXTeam alloc] init];
    }
    return self;
}

- (void)makeWindowControllers
{
    PXAppDelegate *appDelegate = (PXAppDelegate *)[[NSApplication sharedApplication] delegate];
    [self addWindowController:[appDelegate teamConfigurationWindowController]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ([typeName isEqualToString:PXPlexerTeamDocumentTypeName] == NO) {
        if (outError != nil) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unsupported document type: %@", typeName] };
            *outError = [NSError errorWithDomain:PXTeamDocumentErrorDomain code:1 userInfo:userInfo];
        }
    }
    else {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.team];
        if (data == nil) {
            if (outError != nil) {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Error persisting data." };
                *outError = [NSError errorWithDomain:PXTeamDocumentErrorDomain code:2 userInfo:userInfo];
            }
        }
        
        return data;
    }
    
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if ([typeName isEqualToString:PXPlexerTeamDocumentTypeName] == NO) {
        if (outError != nil) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unsupported document type: %@", typeName] };
            *outError = [NSError errorWithDomain:PXTeamDocumentErrorDomain code:1 userInfo:userInfo];
        }
        
        return NO;
    }
    else {
        self.team = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (self.team == nil) {
            if (outError) {
                *outError = [NSError errorWithDomain:PXTeamDocumentErrorDomain code:3 userInfo:@{ NSLocalizedDescriptionKey : @"Unable to load document" }];
            }
            
            return NO;
        }
    }
    
    return YES;
}

- (void)showWindows
{
    static CGFloat initialWindowWidth = 0;
    static CGFloat initialWindowHeight = 0;
    
    CGFloat menuBarHeight = [[[NSApplication sharedApplication] mainMenu] menuBarHeight];
    CGFloat screenHeight = [NSScreen mainScreen].frame.size.height;
    CGFloat screenWidth = [NSScreen mainScreen].frame.size.width;

    PXTeamConfigurationWindowController *teamConfigurationWindowController = self.windowControllers[0];
    if (initialWindowWidth == 0) {
        initialWindowWidth = teamConfigurationWindowController.window.frame.size.width;
    }
    if (initialWindowHeight == 0) {
        initialWindowHeight = teamConfigurationWindowController.window.frame.size.height;
    }
    
    CGRect rect = NSMakeRect(screenWidth / 2 - initialWindowWidth / 2, screenHeight - menuBarHeight - initialWindowHeight, initialWindowWidth, initialWindowHeight);

    [teamConfigurationWindowController.window setFrame:rect display:YES];
    [teamConfigurationWindowController.window makeKeyAndOrderFront:self];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [self.windowControllers[0] updateWithTeam:self.team];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
