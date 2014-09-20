//
//  ASMainController.h
//  App Stop
//
//  Created by Michael Bianco on 9/10/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SUUpdater, ASPreferenceController, ASLicenseInfoController;

@interface ASMainController : NSObject {
	// connected in ApplicationManager.nib
	IBOutlet NSWindow *oMainWindow; 
	IBOutlet NSTableView *oAppTable;
	
	// connected in DemoPanels.nib
	IBOutlet NSWindow *oRegisterSoon, *oRegisterNow; 
	IBOutlet NSButton *oRegisterSoonBuyButton, *oRegisterNowBuyButton;
	IBOutlet NSTextField *oDemoInformation;	
	
	ASLicenseInfoController *_licenseInfo;
	NSMenu *_globalMenu;
	SUUpdater *_sparkleUpdater;
	BOOL _hasStarted;
}

//------------------------------------------
//		Class Methods
//------------------------------------------
+ (ASMainController *) sharedController;

//------------------------------------------
//		Action Methods
//------------------------------------------
- (IBAction) openTableView:(id)sender;
- (IBAction) openAboutWindow:(id)sender;
- (IBAction) openPreferences:(id)sender;
- (IBAction) openHelp:(id)sender;
- (IBAction) checkForUpdates:(id)sender;
- (IBAction) purchase:(id)sender;
- (IBAction) purchaseLater:(id)sender;
- (IBAction) loadLicense:(id)sender;
- (IBAction) licenseInformation:(id)sender;

- (void) addMenuItemsToGlobalMenu:(NSMenu *) menu;
- (void) addGlobalMenuItem:(NSMenuItem *)item;

//------------------------------------------
//			Notifications
//------------------------------------------
- (void) applicationIsRegistered:(NSNotification *)note;
- (void) applicationWillFinishLaunching:(NSNotification *)note;
@end
