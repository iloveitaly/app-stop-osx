//
//  ASMainController.m
//  App Stop
//
//  Created by Michael Bianco on 9/10/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <ExceptionHandling/NSExceptionHandler.h>
#import "ESStackTrace.h"

#import "ASMainController.h"
#import "ASAppListController.h"
#import "ASShared.h"

// Preferences
#import "ASCPUPreferences.h"
#import "ASBackgroundPreferences.h"
#import "ASGeneralPreferences.h"
#import "ASPauseResumePreferences.h"
#import "ASPreferenceController.h"
#import "ASPriorityPreferences.h"
#import "ASAdvancedPreferences.h"

// Transformers
#import "ASStateTransformer.h"
#import "ASPriorityTransformer.h"
#import "ASInvertSliderTransformer.h"
#import "ASFloatRounderTransformer.h"

// Registration Stuff
#import "DemoPeriod.h"
#import "MABTimerController.h"
#import "RegistrationHandling.h"

#define ASLoadLicenseModalReturnCode 10

static ASMainController *_sharedController;

@implementation ASMainController

+ (void) initialize {
	//register the defaults
	NSMutableDictionary *defaults = [[NSMutableDictionary alloc] init];
	
	//general/vanity
	[defaults setValue:[NSNumber numberWithFloat:16.0] forKey:ASAppIconSize];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:ASFloatAppTableWindow];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:ASBGProcessesInMenu];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:ASBlackMenuIcon];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:MABPRIORITYNUMERIC];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:ASNumericUserDisplay];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:ASActivateOnMenuClick];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:ASHasAppManagerHotKey];
	[defaults setValue:[NSNumber numberWithInt:1] forKey:ASDefaultFilterType];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:ASEnableAdvancedPreferences];
	
	//stop/continue options
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:MABAUTOHIDE];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:ASShowPaused];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:MABAUTOSHOW];
	
	//cpu usage reporting
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:ASUseAverageCPU];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:ASCpuUsageReporting];
	[defaults setValue:[NSNumber numberWithInt:4] forKey:MABCPUINTERVAL];
	
	//process options
	[defaults setValue:[NSNumber numberWithInt:5] forKey:ASProcessUpdateInterval];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:ASBGProcessEnabled];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:ASShowZombieProcesses];
	
	//priority
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:ASPriorityDefaultsEnabled];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:ASAutoRecordDefaults];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	[defaults release];
	
	//register the transformers
	ASStateTransformer *stateTrans = [[ASStateTransformer new] autorelease];
	[NSValueTransformer setValueTransformer:stateTrans forName:[stateTrans className]];
	
	ASPriorityTransformer *prioTrans = [[ASPriorityTransformer new] autorelease];
	[NSValueTransformer setValueTransformer:prioTrans forName:[prioTrans className]];
	
	ASFloatRounderTransformer *floatRounder = [[ASFloatRounderTransformer new] autorelease];
	[NSValueTransformer setValueTransformer:floatRounder forName:[floatRounder className]];
	
	ASInvertSliderTransformer *invertSlider = [[ASInvertSliderTransformer new] autorelease];
	[NSValueTransformer setValueTransformer:invertSlider forName:[invertSlider className]];
}

+ (ASMainController *) sharedController {
	extern ASMainController *_sharedController;
	if(!_sharedController) [self new];
	return _sharedController;	
}

//------------------------------------------
//		Superclass Overides
//------------------------------------------
- (id) init {
	if ((self = [super init]) != nil) {
		extern ASMainController *_sharedController;
		_sharedController = self;
		
		_hasStarted = NO;
		
		_sparkleUpdater = [SUUpdater new];
		
		[NSApp setDelegate:self];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationIsRegistered:)
													 name:MABAppRegisteredNotification
												   object:nil];
	}
	
	return self;
}

- (void) awakeFromNib {
	// this is called more than once since we are the owner of multiple nibs
	// this is called before any other objects -awakeFromNibs since we are loaded first

	_globalMenu = [[[NSApp mainMenu] itemAtIndex:3] submenu];
}

- (void) applicationDidFinishLaunching:(NSNotification *)note {
	//makesure someone hasn't been screwing around with the bundle
	if(isEmpty([[NSBundle mainBundle] pathForResource:@"authnice" ofType:@""])) {
		exit(EXIT_FAILURE);
	}

	if(!oMainWindow || !oAppTable) {
		if(![NSBundle loadNibNamed:@"ApplicationManager" owner:self]) {
			// If this cant be loaded, none of the other objects will ever initialize
			NSLog(@"Error loading ApplicationManager.nib");
			exit(EXIT_FAILURE);
		}
	}
	
	if(!IsRegistered() && HasDemoExpired()) {//we have an unrunnable version
		// check to make sure it hasn't been loaded yet
		if(!oRegisterNow) {
			// load up the demo panels if they arent loaded already and test for hacking
			if(![NSBundle loadNibNamed:@"DemoPanel" owner:self] || !oRegisterNow || !oRegisterNowBuyButton) {
				NSLog(@"Error loading DemoPanel.nib");
				exit(EXIT_FAILURE);
			}
		}
		
		[oRegisterNow setDefaultButtonCell:[oRegisterNowBuyButton cell]];
		[NSApp activateIgnoringOtherApps:YES];
		
		if([NSApp runModalForWindow:oRegisterNow] == ASLoadLicenseModalReturnCode) {
			[oRegisterNow orderOut:self];
			RunLoadLicensePanel();
		} else {
			[oRegisterNow orderOut:self];
		}
		
		//check again to make sure that they are still unregistered (they could of loaded a license via the modal dialog)
		if(!IsRegistered()) {
			exit(EXIT_SUCCESS);
		} else {//then we are registered
			// Run through this method again to startup the application since we are now registered
			[self applicationDidFinishLaunching:nil];
		}
	} else {//then we have a runnable version
		// If we were running a demo and the person decides to register without quitting the application we dont want to start the app twice!
		// Start the application before doing the demo/license stuff because if there is an error with authnice or something
		// A error message will pop-up, and then the demo window will pop-up on top - evil.
		if(!_hasStarted) {
			[[ASAppListController sharedController] start];
			_hasStarted = YES;
		}

		if(!IsRegistered() && !HasDemoExpired()) {//then we have a demo version
			// load up the demo panels if they arent loaded already and test for hacking
			if(!oRegisterSoon) {
				if(![NSBundle loadNibNamed:@"DemoPanel" owner:self] || !oRegisterSoon || !oRegisterSoonBuyButton || !oDemoInformation) {
					NSLog(@"Error loading DemoPanel.nib");
					exit(EXIT_FAILURE);
				}
			}
			
			[oRegisterSoon setDefaultButtonCell:[oRegisterSoonBuyButton cell]];
			[oDemoInformation setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Purchasing App Stop only takes a couple minutes and costs about the price of a movie ticket. Your demo for App Stop will expire in %i days.", nil), DemoDaysLeft()]];
			[oRegisterSoon center];
			[oRegisterSoon makeKeyAndOrderFront:self];
			[NSApp activateIgnoringOtherApps:YES];			
			[MABTimerController sharedController];
		} else {//then we have a registered version
			// this can also be run once App Stop has been registered
			// but we can release the windows even if they havent been loaded
			// because if they arent loaded they are nil, and we can send messages to nil
			
			//release all the windows to free some memory
			[oRegisterSoon release];
			[oRegisterNow release];
			oRegisterSoon = oRegisterNow = nil;
			
			// clear the demo files
			ClearDemoFiles();
		}
	}
}

//------------------------------------------
//		Action Methods
//------------------------------------------
- (IBAction) openTableView:(id)sender {
	static BOOL firstOpen = NO;
	if(!firstOpen) {
		[oMainWindow center];
		firstOpen = YES;
	}
	
	[oMainWindow makeKeyAndOrderFront:self];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction) openAboutWindow:(id)sender {
	[NSApp orderFrontStandardAboutPanel:self];
	[NSApp activateIgnoringOtherApps:YES];
}

#define ADD_PREFERENCE_PANE(x, y) [[ASPreferenceController sharedPreferences] addPreferenceNamed:NSLocalizedString(x, nil) owner:[y sharedInstance]];

- (IBAction) openPreferences:(id)sender {
	static BOOL hasLoaded = NO;
	
	if(!hasLoaded) {
		[ASPreferenceController setDefaultPreferencesClass:[ASPreferenceController class]];
		
		ADD_PREFERENCE_PANE(@"General", ASGeneralPreferences);
		ADD_PREFERENCE_PANE(@"Pause & Resume", ASPauseResumePreferences);
		ADD_PREFERENCE_PANE(@"Priorities", ASPriorityPreferences);
		ADD_PREFERENCE_PANE(@"CPU", ASCPUPreferences);
		ADD_PREFERENCE_PANE(@"Background Apps", ASBackgroundPreferences);
		
		if(PREF_KEY_BOOL(ASEnableAdvancedPreferences)) {
			NSLog(@"Enabling advanced preferences");
			ADD_PREFERENCE_PANE(@"Advanced", ASAdvancedPreferences);
		}
		
		hasLoaded = YES;
	}
	
	[[ASPreferenceController sharedPreferences] showPreferencesPanel];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction) openHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"access" inBook:@"App Stop Help"];
}

- (IBAction) checkForUpdates:(id)sender {
	[_sparkleUpdater checkForUpdates:self];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction) purchase:(id)sender {
	// this is called from both registration window types
	
	OPEN_URL(PURCHASE_URL);
	
	if([oRegisterSoon isMainWindow] || [oRegisterSoon isKeyWindow]) {
		[oRegisterSoon performClose:self];
	} else if([NSApp modalWindow] == oRegisterNow) {
		[NSApp stopModal];
	}
}

- (IBAction) purchaseLater:(id)sender {
	// this is only called by the buy now window
	// now sure why we are performClosing: it, it is orderedOut: after this
	
	if([NSApp modalWindow] == oRegisterNow) {
		[NSApp stopModal];
	}
	
	[[sender window] performClose:self];
}

- (IBAction) loadLicense:(id)sender {
	// Cancelling the modal window from here wont do anything cause this action is tied
	// to the modal window itself and will call another modal dialog to appear, preventing the old modal window from canceling since the new modal
	// dialog is tied to a button on the old modal window

	if([NSApp modalWindow] == oRegisterNow && oRegisterNow != nil) {
		[NSApp stopModalWithCode:ASLoadLicenseModalReturnCode];
	} else {
		RunLoadLicensePanel();
	}
}

- (IBAction) licenseInformation:(id)sender {
	if(!_licenseInfo) {
		_licenseInfo = [ASLicenseInfoController new];
	}
	
	[_licenseInfo showWindow:self];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void) addMenuItemsToGlobalMenu:(NSMenu *) menu {
	NSMenuItem *temp;
	NSArray *items = [menu itemArray];
	int l = [items count];
	
	while(l--) {
		temp = [[items objectAtIndex:l] retain];
		[menu removeItem:temp];
		[self addGlobalMenuItem:temp];
		[temp release];
	}
}

- (void) addGlobalMenuItem:(NSMenuItem *)item {
	[_globalMenu addItem:item];
}

//------------------------------------------
//			Notifications
//------------------------------------------
- (void) applicationIsRegistered:(NSNotification *)note {
	//NSLog(@"Registered!");
}

- (void) applicationWillFinishLaunching:(NSNotification *)note {
	//register the exception handler
	[[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:(NSHandleUncaughtExceptionMask | NSHandleUncaughtSystemExceptionMask | NSHandleUncaughtRuntimeErrorMask | NSHandleTopLevelExceptionMask | NSHandleOtherExceptionMask)];
	NSSetUncaughtExceptionHandler(*CB_exceptionHandler);
}
@end
