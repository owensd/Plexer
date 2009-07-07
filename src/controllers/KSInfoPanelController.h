//
//  KSInfoPanelController.h
//  Plexer
//
//  Created by David Owens II on 7/2/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BWToolkitFramework/BWToolkitFramework.h>


@interface KSInfoPanelController : NSObject {
    IBOutlet NSWindow* infoPanel;
    IBOutlet NSTextField* infoPanelTextField;
    IBOutlet BWTransparentButton* infoPanelButton;
    IBOutlet NSWindow* parentWindow;
}

-(IBAction)okPressed:(id)sender;

-(NSWindow*)window;

-(void)showPanelWithTitle:(NSString*)title
                  message:(NSString*)message
               buttonText:(NSString*)buttonText;

-(void)showPanelWithTitle:(NSString*)title
                  message:(NSString*)message
               buttonText:(NSString*)buttonText
                 delegate:(id)delegate
           didEndSelector:(SEL)didEndSelector
              contextInfo:(void*)contextInfo;


@end
