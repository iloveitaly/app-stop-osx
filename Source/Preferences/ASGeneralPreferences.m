//
//  ASGeneralPreferences.m
//  App Stop
//
//  Created by Michael Bianco on 11/16/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "ASGeneralPreferences.h"
#import "RegistrationHandling.h"
#import "MABLoginItems.h"
#import "ASMainController.h"
#import "ASStatusMenuController.h"
#import "PTHotKeyCenter.h"
#import "PTKeyCombo.h"
#import "PTHotKey.h"
#import "ASShared.h"

@implementation ASGeneralPreferences
- (NSString *) preferencesNibName {
	return @"ASGeneralPreferences";
}

- (BOOL) hasChangesPending {
	return NO;
}

- (NSImage *) imageForPreferenceNamed:(NSString *) name {
	return [NSImage imageNamed:@"GeneralPrefs"];
}

- (BOOL) isResizable {
	return NO;
}

- (void) initializeFromDefaults {
	static BOOL hasInited = NO;
	
	if(hasInited)
		return;
	
	PREF_OBSERVE_VALUE(@"values.hasAppManagerHotKey", self);
	
	// retrieve hotkey & make recorder display it
	NSData *serializedCombo = PREF_KEY_VALUE(ASAppManagerHotKey);
	if(!isEmpty(serializedCombo)) {
		KeyCombo *combo = (KeyCombo *) [serializedCombo bytes];
		[oAppManagerHotKey setKeyCombo:*combo];
	}
		
	// setup the login button
	_loginItems = [MABLoginItems new];
	[oInStartupList setState:[_loginItems isInStartupItems]];
	
	// hide/show register buttons, register for future isRegistered notifications
	[self applicationIsRegistered:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationIsRegistered:) name:MABAppRegisteredNotification object:nil];
	
	hasInited = YES;
}

- (void) willBeDisplayed {
	//NSLog(@"Will display");
}

- (void) loadHotKeyFromDefaults {
	// This is called when the application first loads
	// the outlets are not connected at this point, and we need a shortcut recorder to
	// register the global hotkeys, so as a dirty hack we alloc a sortcut recorder and then kill it
	
	// get the app manager menu-item reference
	_appManagerItem = [[[ASStatusMenuController sharedController] statusMenu] itemAtIndex:0];
	
	// if the user doesn't want a hotkey dont bother loading it
	if(PREF_KEY_BOOL(ASHasAppManagerHotKey)) {
		NSData *serializedCombo = PREF_KEY_VALUE(ASAppManagerHotKey);
		
		if(!isEmpty(serializedCombo)) {
			// create dummy hotkey recorder
			oAppManagerHotKey = [[ShortcutRecorder alloc] init];
			
			// set the combo
			KeyCombo *combo = (KeyCombo *) [serializedCombo bytes];
			[self setAppManagerHotKey:*combo];
			
			[oAppManagerHotKey release];
			oAppManagerHotKey = nil;
		}
	}
}

//------------------------------------------
//		Action Methods
//------------------------------------------
- (IBAction) contactSupport:(id)sender {
	OPEN_URL(SUPPORT_URL);
}

- (IBAction) checkForUpdates:(id)sender {
	[[ASMainController sharedController] checkForUpdates:self];
}

-(IBAction) purchase:(id)sender {
	OPEN_URL(PURCHASE_URL);
}

- (IBAction) loadLicense:(id)sender {
	[[ASMainController sharedController] loadLicense:self];
}

- (IBAction) toggleAddToLoginItems:(id)sender {
	[_loginItems updateStartupItems];
	
	if([sender state] == YES) {
		NSLog(@"add");
		[_loginItems addToStartupItems];
	} else {
		NSLog(@"Remove");
		[_loginItems removeFromStartupItems];
	}
}

- (IBAction) registerAppManagerHotKey:(id)sender {
	KeyCombo newHotKeyCombo = [oAppManagerHotKey keyCombo];
	
	// save hotkey in preferences first
	// we want to save the correct key combo code even if we dont want a key combo
	// so when we do want a key combo again it will come up
	NSData *serializedKeyCombo = [NSData dataWithBytes:&newHotKeyCombo length:sizeof(KeyCombo)];
	PREF_SET_KEY_VALUE(ASAppManagerHotKey, serializedKeyCombo);

	// if we dont want a key combo, just set an invalid code
	if(!PREF_KEY_BOOL(ASHasAppManagerHotKey)) {
		newHotKeyCombo.code = -1;
	}
	
	// if we want a hotkey and the user entered a hotkey, register the new one
	[self setAppManagerHotKey:newHotKeyCombo];
}

- (void) setAppManagerHotKey:(KeyCombo)combo {
	if(_appManagerHotKey) {
		[[PTHotKeyCenter sharedCenter] unregisterHotKey:_appManagerHotKey];
		[_appManagerHotKey release];
		_appManagerHotKey = nil;		
	}
	
	// make sure we have a valid key combo code
	if(combo.code == -1) {
		[_appManagerItem setKeyEquivalent:@""]; // no key equiv on menu either!
		return;
	}
	
	_appManagerHotKey = [[PTHotKey alloc] initWithIdentifier:@"ASAppManager"
													keyCombo:[PTKeyCombo keyComboWithKeyCode:combo.code
																				   modifiers:[oAppManagerHotKey cocoaToCarbonFlags:combo.flags]]];

	// set target & action
	[_appManagerHotKey setTarget:[ASMainController sharedController]];
	[_appManagerHotKey setAction:@selector(openTableView:)];
	
	[[PTHotKeyCenter sharedCenter] registerHotKey:_appManagerHotKey];
	
	// set the menu-items shortcut to match up with the newly defined hotkey
	[_appManagerItem setKeyEquivalent:[[oAppManagerHotKey cell] _stringForKeyCode:combo.code]]; // private -[ShortcutRecorderCell _stringForKey]
	[_appManagerItem setKeyEquivalentModifierMask:combo.flags];
}

- (void) shortcutRecorder:(ShortcutRecorder *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
	[self registerAppManagerHotKey:self];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath hasSuffix:ASHasAppManagerHotKey]) {
		[self registerAppManagerHotKey:self];

		[[oAppManagerHotKey cell] setValue:[NSNumber numberWithBool:NO] forKey:@"isRecording"];
	}
}

- (void) applicationIsRegistered:(NSNotification *) note {
	// hide the license related buttons
	BOOL isRegistered = IsRegistered();
	[oLoadLicense setHidden:isRegistered];
	[oPurchase setHidden:isRegistered];	
}
@end
