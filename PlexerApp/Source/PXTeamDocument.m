//
//  PXTeamDocument.m
//  Plexer
//
//  Created by David Owens II on 9/10/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamDocument.h"
#import "PXAppDelegate.h"

@implementation PXTeamDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (void)makeWindowControllers
{
    PXAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
    [self addWindowController:[appDelegate teamConfigurationWindowController]];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)controller
{

    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
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


+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
