//
//  PXTeamDocumentWindowController.m
//  Plexer
//
//  Created by David Owens II on 10/4/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXTeamDocumentWindowController.h"
#import "PXBroadcastController.h"
#import <PlexerLib/PlexerLib.h>


@implementation PXTeamDocumentWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)configureTeam:(id)sender
{
}

- (IBAction)launchTeam:(id)sender
{
    NSLog(@"attempting to launch xpc service");
    
    self.xpcConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.kiadsoftware.PlexerHelper"];
    self.xpcConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PXBroadcastController)];
    
    [self.xpcConnection resume];
    
    NSDictionary *team = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SampleTeam" ofType:@"plist"]];
    [[self.xpcConnection remoteObjectProxy] playTeam:team];
}

@end
