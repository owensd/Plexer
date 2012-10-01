//
//  PXTeamDocumentController.m
//  Plexer
//
//  Created by David Owens II on 9/11/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamDocumentController.h"
#import "PXTeamDocument.h"

@implementation PXTeamDocumentController

- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)error
{
    if (self.currentDocument != nil) {
        [self.currentDocument close];
    }
    
    return [super openUntitledDocumentAndDisplay:displayDocument error:error];
}

@end
