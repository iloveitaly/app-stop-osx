//
//  ASGeneralPreferences.h
//  App Stop
//
//  Created by Michael Bianco on 11/16/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferences.h"
#import "ShortcutRecorder.h"

#define ASAppIconSize @"iconSize"
#define MABPRIORITYNUMERIC @"numericPriority"
#define ASFloatAppTableWindow @"mainWindowFloat"
#define ASActivateOnMenuClick @"activateOnMenuClick"
#define ASBlackMenuIcon @"blackMenuIcon"
#define ASShowPaused @"showPaused"
#define ASNumericUserDisplay @"numericUserDisplay"
#define ASHasAppManagerHotKey @"hasAppManagerHotKey"
#define ASAppManagerHotKey @"appManagerHotKey"
#define ASDefaultFilterType @"defaultFilterType"

//urls
#define PURCHASE_URL @"http://prosit-software.com/appstop.html#purchase"
#define SUPPORT_URL @"http://prosit-software.com/contact.html?type=support&prod=appstop"
#define BUG_URL @"http://prosit-software.com/contact.html?type=bug&prod=appstop"
#define SITE_URL @"http://prosit-software.com/"

@class MABLoginItems, ShortcutRecorder, PTHotKey;

@interface ASGeneralPreferences : NSPreferencesModule {
	IBOutlet NSButton *oInStartupList;
	IBOutlet NSButton *oLoadLicense;
	IBOutlet NSButton *oPurchase;
	IBOutlet ShortcutRecorder *oAppManagerHotKey;
	
	PTHotKey *_appManagerHotKey;
	MABLoginItems *_loginItems;
	NSMenuItem *_appManagerItem;
}

//------------------------------------------
//		Action Methods
//------------------------------------------
- (IBAction) checkForUpdates:(id)sender;
- (IBAction) contactSupport:(id)sender;
- (IBAction) purchase:(id)sender;
- (IBAction) loadLicense:(id)sender;
- (IBAction) toggleAddToLoginItems:(id)sender;
- (IBAction) registerAppManagerHotKey:(id)sender;

// HotKey Stuff
- (void) loadHotKeyFromDefaults;
- (void) setAppManagerHotKey:(KeyCombo)combo;

//------------------------------------------
//			Notifications
//------------------------------------------
- (void) applicationIsRegistered:(NSNotification *)note;
@end
