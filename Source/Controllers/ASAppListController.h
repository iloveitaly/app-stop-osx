#import <Cocoa/Cocoa.h>

#define CHECK_OSX_10_4 if(![[[NSProcessInfo processInfo] minorOSVersionString] hasPrefix:@"10.4"]) return;
#define DEBUG_LOG(x) ; /* replace x w/; to turn off */

#define ASAppOpenedNotification @"ASAppOpened"
#define ASAppClosedNotification @"ASAppClosed"

@class ASStatusMenuController, ASAppRef, ASPreferenceController;

@interface ASAppListController : NSObject {
	IBOutlet NSArrayController *oController;
	
	NSMutableArray *_openApps;
	ASStatusMenuController *_menuController;
	NSTimer *_procListTimer, *_cpuUsageTimer;
}

//------------------------------------------
//		Class Methods
//------------------------------------------
+ (ASAppListController *) sharedController;

//------------------------------------------
//		Notifications for NSWorkspace
//------------------------------------------
- (void) appClosed:(NSNotification *)note;
- (void) appOpened:(NSNotification *)note;

//------------------------------------------
//		Misc Methods
//------------------------------------------
- (void) start;
- (void) authenticateHelper;
- (void) configureProcListTimer;
- (void) configureCpuUsageTimer;

- (void) _updateProcList:(NSTimer *)timer;
- (void) _updateCpuUsage:(NSTimer *)timer;

//------------------------------------------
//		NSApplication Notifications
//------------------------------------------
- (void) applicationWillTerminate:(NSNotification *)aNotification;

//------------------------------------------
//		Getter & Setter Methods
//------------------------------------------
- (NSMutableArray *) openApps;

//------------------------------------------
//		KVC NSArrayController Methods & KVO Methods
//------------------------------------------
- (void) insertObject:(ASAppRef *)ref inOpenAppsAtIndex:(unsigned int)index;
- (void) removeObjectFromOpenAppsAtIndex:(unsigned int)index;
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;	
@end
