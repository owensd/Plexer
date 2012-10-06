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
        self.undoManager = NO;
    }
    return self;
}

- (void)makeWindowControllers
{
    PXAppDelegate *appDelegate = (PXAppDelegate *)[[NSApplication sharedApplication] delegate];
    [self addWindowController:appDelegate.teamDocumentWindowController];
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

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    //[self.windowControllers[0] updateWithTeam:self.team];
    [super restoreStateWithCoder:coder];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
