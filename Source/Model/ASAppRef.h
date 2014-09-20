#import <Cocoa/Cocoa.h>

//Notifications
#define ASAppPausedNotification @"ASAppPaused"
#define ASAppResumedNotification @"ASAppResumed"

//NSDictionary keys for notifications from NSWorkspace
#define ASApplicationNameKey @"NSApplicationName"
#define ASApplicationPIDKey @"NSApplicationProcessIdentifier"
#define ASApplicationBundleIdentifierKey @"NSApplicationBundleIdentifier"
#define ASApplicationPathKey @"NSApplicationPath"

// There is a way to get the state of a running process... ki_procinfo, ki_xstat, p_stat, XSTAT - ps - 11.

@class AGProcess;

@interface ASAppRef : NSObject {
	NSString *_appName, *_appPath, *_uidName;
	
	NSImage *_icon;
	AGProcess *_processInfo;
	NSMenuItem *_menuItem;
	
	int _pid;
	int _uid;
	int _priority;
	
	//cpu usuage variables
	int _avgCpuCount; //the amount of times the timer has been fired so we know how much to / the _avgCpu by
	float _avgCpu;
	float _cpu;
	
	//BOOLs
	BOOL _state; //YES = On/Running; NO = Off/Stopped
	BOOL _isHiding;
	BOOL _isAvgCpu;
	BOOL _isBackground;
}

//------------------------------------------
//		Class Methods
//------------------------------------------
+ (void) updateAvgCpu;
+ (NSImage *) defaultCommandImage;

//------------------------------------------
//		Constructor Methods
//------------------------------------------
- (id) initWithApplicationDictionary:(NSDictionary *) a;
- (id) initWithProcessID:(int)processID;
- (id) initWithProcessReference:(AGProcess *)p;

//------------------------------------------
//		Action Methods
//------------------------------------------
- (void) toggle:(id)sender;
- (void) killAppIgnoringAlert:(BOOL)yn;

- (void) hideAndStop;
- (void) contAndShow;

- (void) stop;
- (void) cont;

//------------------------------------------
//		Misc
//------------------------------------------
- (void) checkIfAppIsHidden:(NSTimer *)timer;
- (BOOL) updateCpuUsage; //returns YES if their was an unexpected error in getting the CPU usage, I.E. the app probobly quit
- (void) resetCpuVars;

//------------------------------------------
//		Notifications & KVO Methods
//------------------------------------------
- (void) willGoToSleep:(NSNotification *)note;
- (void) didAwakeFromSleep:(NSNotification *)note;
- (void) willShutDown:(NSNotification *)note;

//------------------------------------------
//		Setter & Getter
//------------------------------------------
- (int) uid;
- (int)	pid;

- (void) setPriority:(int)p;
- (int) priority;

- (void) setCpuUsage:(float)u;
- (float) cpuUsage;
- (NSString *) cpuUsageString;

- (void) setState:(BOOL)s;
- (BOOL) state;

- (BOOL) isBackground;
- (void) setIsBackground:(BOOL)b;

- (void) setApplicationName:(NSString *)name;
- (NSString *) appName;

- (void) setApplicationPath:(NSString *)path;
- (NSString *) applicationPath;

- (BOOL) isHiding;
- (void) setIsHiding:(BOOL)is;

- (NSString *) stateAsString;
- (NSString *) uidAsString;
- (NSImage *) appIcon;
- (NSMenuItem *) menuItem;
- (BOOL) isZombie;
@end