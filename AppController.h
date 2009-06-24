//
//  AppController.h
//  Plexer
//
//  Created by David Owens II on 6/10/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BWToolkitFramework/BWToolkitFramework.h>


@interface AppController : NSObject {
    IBOutlet NSMenu* statusMenu;
    IBOutlet NSMenuItem* startPlexingItem;
    IBOutlet NSMenuItem* stopPlexingItem;
    
    IBOutlet BWTransparentPopUpButton* configurationsPopUp;
    
    NSStatusItem* statusItem;
    NSImage* statusImageOn;
    NSImage* statusImageOff;
    
    IBOutlet NSPanel* plexerPanel;
    IBOutlet NSPanel* configurationNamePanel;
    IBOutlet NSTextField* configurationNameField;
    
    IBOutlet BWTransparentCheckbox* saveWindowSizeBox;
    IBOutlet BWTransparentCheckbox* moveWindowsNearMenuBarBox;
    IBOutlet BWTransparentCheckbox* autoHideDockBox;
    
    BOOL broadcasting;
}

@property (readonly) BOOL broadcasting;
-(void)setBroadcasting:(BOOL)broadcasting;

-(IBAction)startPlexing:(id)sender;
-(IBAction)stopPlexing:(id)sender;
-(IBAction)changeTogglePlexingHotKey:(id)sender;
-(IBAction)changeQuitAppHotKey:(id)sender;

-(IBAction)renameCurrentConfiguration:(id)sender;
-(IBAction)removeCurrentConfiguration:(id)sender;
-(IBAction)addNewConfiguration:(id)sender;
-(IBAction)cancelConfigurationNameSheet:(id)sender;
-(IBAction)closeConfigurationNameSheet:(id)sender;

-(IBAction)configurationSelectionChanged:(id)sender;

-(IBAction)toggleAutoHideDock:(id)sender;
-(IBAction)toggleSaveWindowPositions:(id)sender;
-(IBAction)toggleMoveWindowNearMenuBar:(id)sender;

@end
