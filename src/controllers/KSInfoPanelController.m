//
//  KSInfoPanelController.m
//  Plexer
//
//  Created by David Owens II on 7/2/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSInfoPanelController.h"


@implementation KSInfoPanelController


-(NSWindow*)window {
    return infoPanel;
}

-(void)showPanelWithTitle:(NSString*)title message:(NSString*)message buttonText:(NSString*)buttonText {
    [self showPanelWithTitle:title
                     message:message
                  buttonText:buttonText
                    delegate:self
              didEndSelector:@selector(sheetDidEnd:code:context:)
                 contextInfo:NULL];
}

-(void)showPanelWithTitle:(NSString*)title
                  message:(NSString*)message
               buttonText:(NSString*)buttonText
                 delegate:(id)delegate
           didEndSelector:(SEL)didEndSelector
              contextInfo:(void*)contextInfo
{
    [infoPanel setTitle:title];
    [infoPanelTextField setStringValue:message];
    [infoPanelButton setTitle:buttonText];
    [NSApp beginSheet:infoPanel
       modalForWindow:parentWindow
        modalDelegate:delegate
       didEndSelector:didEndSelector
          contextInfo:contextInfo];
}

-(void)sheetDidEnd:(NSPanel*)sheet code:(int)choice context:(void*)v {
    [sheet orderOut:infoPanel];
}

-(IBAction)okPressed:(id)sender {
    [NSApp endSheet:infoPanel];
}

// Handle this so that the window isn't actually closed. Errors occur if this isn't handled this way.
-(BOOL)windowShouldClose:(id)window {
    [NSApp endSheet:infoPanel];
    return NO;
}

@end
