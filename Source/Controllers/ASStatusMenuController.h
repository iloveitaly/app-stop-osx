#import <Cocoa/Cocoa.h>

@class ASAppRef, ASStatusItemView;

@interface ASStatusMenuController : NSObject {
	NSImage *_menuIcon, *_menuIconPaused;
	NSImage *_menuIconBlack, *_menuIconPausedBlack;
	
	NSMenu *_statusMenu, *_licensedMainMenu, *_unlicensedMainMenu;
	NSMenuItem *_mainMenuItem;
	NSMenuItem *_appManagerItem;
	ASStatusItemView *_customMenuView;
	NSStatusItem *_statusItem;
	
	int _appInsertIndex;
	int _pausedAppCount;
	
	BOOL _showBGApps;
}

+ (ASStatusMenuController *) sharedController;

//------------------------------------------
//		Setter & Getter methods
//------------------------------------------
- (NSStatusItem *) statusItem;
- (NSImage *) statusItemImage;
- (NSMenu *) statusMenu;

//------------------------------------------
//		Menu Building methods
//------------------------------------------
- (void) createMenu;
- (void) menuItemClicked:(id)sender;
- (void) removeMenuItem:(ASAppRef *)app;
- (void) addMenuItem:(ASAppRef *)app;

//------------------------------------------
//		Menu Icon Methods
//------------------------------------------
- (void) appPaused:(NSNotification *)note;
- (void) appResumed:(NSNotification *)note;

//------------------------------------------
//			Notifications
//------------------------------------------
- (void) applicationIsRegistered:(NSNotification *)note;
@end
