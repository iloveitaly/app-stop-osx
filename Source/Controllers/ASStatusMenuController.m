#import <Sparkle/SUUpdater.h>

// Controller
#import "ASStatusMenuController.h"
#import "ASMainController.h"

// View
#import "ASStatusItemView.h"

// Model
#import "ASAppRef.h"

// Preferences
#import "ASBackgroundPreferences.h"
#import "ASGeneralPreferences.h"
#import "ASShared.h"

// Registration stuff
#import "DemoPeriod.h"
#import "RegistrationHandling.h"

#define ASMenuIconSize NSMakeSize(16.0, 16.0)

#define UPDATE_ICON \
[self willChangeValueForKey:@"statusItemImage"]; \
[self didChangeValueForKey:@"statusItemImage"];

static ASStatusMenuController *_sharedController = nil;

@implementation ASStatusMenuController
+ (ASStatusMenuController *) sharedController {
	extern ASStatusMenuController *_sharedController;
	if(!_sharedController) [self new];
	return _sharedController;	
}

//------------------------------------------
//		Constructor Methods
//------------------------------------------
- (id) init {
	if((self = [super init]) != nil) {
		extern ASStatusMenuController *_sharedController;
		_sharedController = self;
		
		_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:24.0] retain];
		_statusMenu = [[NSMenu alloc] init];
		_customMenuView = [ASStatusItemView new];
		_pausedAppCount = 0;
		
		_licensedMainMenu = [NSMenu new];
		_unlicensedMainMenu = [NSMenu new];
		_mainMenuItem = [NSMenuItem new];
		
		//create the two menu icons
		_menuIcon = [[NSImage imageNamed:@"menuIcon"] retain];
		_menuIconPaused = [NSImage imageNamed:@"menuIconPaused"];
		_menuIconPausedBlack = [[NSImage imageNamed:@"menuIconPausedBlack"] retain];
		_menuIconBlack = [[NSImage imageNamed:@"menuIconBlack"] retain];
		
		//set the icon sizes
		[_menuIcon setSize:ASMenuIconSize];
		[_menuIconPaused setSize:ASMenuIconSize];
		[_menuIconBlack setSize:ASMenuIconSize];
		[_menuIconPausedBlack setSize:ASMenuIconSize];
		
		[_customMenuView setTarget:self];
		[_customMenuView setAction:@selector(menuItemClicked:)];
		[_customMenuView bind:@"image" toObject:self withKeyPath:@"statusItemImage" options:nil];
		
		[_statusItem setView:_customMenuView];
		
		//register for pause continue notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appPaused:) name:ASAppPausedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appResumed:) name:ASAppResumedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationIsRegistered:) name:MABAppRegisteredNotification object:nil];
		
		//register for changes in preferences
		PREF_OBSERVE_VALUE(@"values.showPaused", self);
		PREF_OBSERVE_VALUE(@"values.blackMenuIcon", self);
	}
	
	return self;
}

//------------------------------------------
//		Setter & Getter methods
//------------------------------------------
- (NSStatusItem *) statusItem {
	return _statusItem;
}

- (NSImage *) statusItemImage {
	if(PREF_KEY_BOOL(ASShowPaused) && _pausedAppCount > 0) {
		if(PREF_KEY_BOOL(ASBlackMenuIcon)) {
			return _menuIconPausedBlack;
		} else {
			return _menuIconPaused;
		}
	} else {//then no paused icons
		if(PREF_KEY_BOOL(ASBlackMenuIcon)) {
			return _menuIconBlack;
		} else {
			return _menuIcon;
		}
	}	
}

- (NSMenu *) statusMenu {
	return _statusMenu;
}

//------------------------------------------
//		Menu Building methods
//------------------------------------------
- (void) createMenu {
	ASMainController *appController = [ASMainController sharedController];
	
	//create the menu before the app listing
	_appManagerItem = [NSMenuItem new];
	[_appManagerItem setTitle:NSLocalizedString(@"Application Manager", nil)];
	[_appManagerItem setTarget:appController];
	[_appManagerItem setAction:@selector(openTableView:)];
	[_statusMenu addItem:_appManagerItem];
	
	id sep = [NSMenuItem separatorItem];
	[_statusMenu addItem:sep];
	
	_appInsertIndex = [_statusMenu numberOfItems]; //set the adding index
	
	//create the bottom menu items
	sep = [NSMenuItem separatorItem];
	[_statusMenu addItem:sep];
	
	// == Create "App Stop" Main Menu ==
	
	NSMenuItem *mainMenuItem = _mainMenuItem;
	[mainMenuItem setTitle:APP_NAME];
	
	NSMenuItem *about = [NSMenuItem new];
	[about setTitle:NSLocalizedString(@"About App Stop", nil)];
	[about setTarget:appController];
	[about setAction:@selector(openAboutWindow:)];
	[_licensedMainMenu addItem:[about copy]];
	[_unlicensedMainMenu addItem:about];
	[about release];
			
	NSMenuItem *update = [NSMenuItem new];
	[update setTitle:NSLocalizedString(@"Check For Updates", nil)];
	[update setAction:@selector(checkForUpdates:)];
	[update setTarget:[ASMainController sharedController]];
	[_licensedMainMenu addItem:[update copy]];
	[_unlicensedMainMenu addItem:update];
	[update release];

	NSMenuItem *pref = [NSMenuItem new];
	[pref setTitle:NSLocalizedString(@"Preferences", nil)];
	[pref setKeyEquivalent:@","];
	[pref setKeyEquivalentModifierMask:NSCommandKeyMask];
	[pref setAction:@selector(openPreferences:)];
	[pref setTarget:appController];
	[_licensedMainMenu addItem:[pref copy]];
	[_unlicensedMainMenu addItem:pref];
	[pref release];

	NSMenuItem *help = [NSMenuItem new];
	[help setTitle:NSLocalizedString(@"App Stop Help", nil)];
	[help setKeyEquivalent:@"?"];
	[help setKeyEquivalentModifierMask:NSCommandKeyMask];
	[help setTarget:appController];
	[help setAction:@selector(openHelp:)];
	[_licensedMainMenu addItem:[help copy]];
	[_unlicensedMainMenu addItem:help];
	[help release];	
	
	[_licensedMainMenu addItem:[NSMenuItem separatorItem]];
	[_unlicensedMainMenu addItem:[NSMenuItem separatorItem]];
	
	NSMenuItem *licenseInfo = [NSMenuItem new];
	[licenseInfo setTitle:NSLocalizedString(@"License Information", nil)];
	[licenseInfo setTarget:[ASMainController sharedController]];
	[licenseInfo setAction:@selector(licenseInformation:)];
	[_licensedMainMenu addItem:licenseInfo];
	[licenseInfo release];
	
	NSMenuItem *purchaseAppStop = [NSMenuItem new];
	[purchaseAppStop setTitle:NSLocalizedString(@"Purchase App Stop", nil)];
	[purchaseAppStop setTarget:[ASMainController sharedController]];
	[purchaseAppStop setAction:@selector(purchase:)];
	[_unlicensedMainMenu addItem:purchaseAppStop];
	[purchaseAppStop release];
	
	NSMenuItem *loadLicense = [NSMenuItem new];
	[loadLicense setTitle:NSLocalizedString(@"Load License", nil)];
	[loadLicense setTarget:[ASMainController sharedController]];
	[loadLicense setAction:@selector(loadLicense:)];
	[_unlicensedMainMenu addItem:loadLicense];
	[loadLicense release];
	
	//config main menu
	[self applicationIsRegistered:nil];
		
	[_statusMenu addItem:mainMenuItem];
	
	NSMenuItem *quit = [NSMenuItem new];
	[quit setTitle:NSLocalizedString(@"Quit App Stop", nil)];
	//[quit setKeyEquivalent:@"Q"];
	//[quit setKeyEquivalentModifierMask:NSCommandKeyMask];
	[quit setAction:@selector(terminate:)]; //adds a shift to the command... guess you cant overide cmd+q
	[quit setTarget:NSApp];
	[_statusMenu addItem:quit];
	[quit release];	
	
	// == End Main Menu Creation ==
}

- (void) menuItemClicked:(id)sender {
	//make sure we want the action to be fired
	if(!PREF_KEY_BOOL(ASActivateOnMenuClick)) {
		return;
	}
	
	//NSLog(@"Activate!");
	if([NSApp modalWindow]) {
		//[[NSApp modalWindow] orderFront:self];
		[NSApp activateIgnoringOtherApps:YES];
		return;
	}
	
	NSArray *windows = [NSApp windows];
	int a = 0, l = [windows count];
	for(; a < l; a++) {
		//NSLog(@"%@ : %i : %i : %i", [windows objectAtIndex:a], [[windows objectAtIndex:a] level], [[windows objectAtIndex:a] isMainWindow], [[windows objectAtIndex:a] isVisible]);
		if([[windows objectAtIndex:a] isVisible] && [[windows objectAtIndex:a] level] == NSNormalWindowLevel) {
			//NSLog(@"%@ : %i", [windows objectAtIndex:a], [[windows objectAtIndex:a] isMainWindow]);
			[[windows objectAtIndex:a] makeKeyAndOrderFront:self];
		}
	}
	
	[NSApp activateIgnoringOtherApps:YES];
}

- (void) removeMenuItem:(ASAppRef *)app {
	if([_statusMenu indexOfItem:[app menuItem]] == -1) {
		// This occurs when BG proc is enabled but they are not in the menu, and then BG proc is disabled
		//NSLog(@"Menu item %@ for %@ is not in menu!", [app menuItem], app);
		return;
	}

	[_statusMenu removeItem:[app menuItem]];
	_appInsertIndex--; //make sure it was found before decrementing the index
}

- (void) addMenuItem:(ASAppRef *)app {
	if(!PREF_KEY_BOOL(ASBGProcessesInMenu) && [app isBackground]) {
		// When a process is launched this is always called, it is this methods responsibility to prevent
		// "Non-Worthy" applications from being inserted into the menu
		//NSLog(@"Attempting to insert background app (%@) when background applications are disabled!", app);
		return;
	}
	
	[_statusMenu insertItem:[app menuItem] atIndex:_appInsertIndex];
	_appInsertIndex++;
}

//------------------------------------------
//		Menu Icon Methods
//------------------------------------------
- (void) appPaused:(NSNotification *)note {
	_pausedAppCount++;
	UPDATE_ICON;
}

- (void) appResumed:(NSNotification *)note {
	_pausedAppCount--;
	UPDATE_ICON;
}

//------------------------------------------
//			KVO Methods
//------------------------------------------
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath hasSuffix:ASShowPaused] || [keyPath hasSuffix:ASBlackMenuIcon]) {
		UPDATE_ICON;
	}
}

//------------------------------------------
//			Notifications
//------------------------------------------
- (void) applicationIsRegistered:(NSNotification *)note {
	if(IsRegistered()) {
		[_mainMenuItem setSubmenu:_licensedMainMenu];
	} else {
		[_mainMenuItem setSubmenu:_unlicensedMainMenu];
	}
}
@end
