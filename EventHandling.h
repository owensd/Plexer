/*
 *  EventHandling.h
 *  Plexer
 *
 *  Created by David Owens II on 6/13/09.
 *  Copyright 2009 Kiad Software. All rights reserved.
 *
 */

/*
 *  Registers the event handlers for handling keyboard events and application events.
 * 
 */
void KSRegisterEventHandlers(void);


/*
 *  Sets the broadcasting state to the value of 'broadcast'. When 'broadcast' is false, then
 *  the keys are not send to the other applications.
 *  The default is false.
 *
 */
void KSChangeBroadcastingTo(bool broadcast);


/*
 *  Allows the customization of when keys are broadcasted to other applications. When 'process' is
 *  true, then keys are only sent when one of the monitored applications has focus.
 *  The default is false.
 *
 */
void KSChangeOnlyProcessKeysWhenAppIsFocusedTo(bool process);


/*
 *  Function to call to clean up all of the resources that have been used.
 *
 */
void KSCleanUp(void);


/*
 *  A stupid workaround for focusing issue in OS X with games like World of Warcraft.
 *
 */
void KSFocusFirstWindowOfPid(pid_t pid);


/*
 *  Helper method to send the keycode for the given modifier keys to the application.
 *
 */
void KSSendModifierKeys(AXUIElementRef app, UInt32 modifiers, bool keydown);


/*
 *  Helper method to post the keyboard events to the application. This method attempts
 *  to deal with keys that didn't get send properly.
 *
 */
void KSPostKeyboardEvent(AXUIElementRef app, UInt32 keyCode, bool keydown);