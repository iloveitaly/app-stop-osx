#import "ASAppRef.h"

// View
#import "ASAppMenuItem.h"

// Controller
#import "ASAppListController.h" /* for DEBUG_LOG */
#import "ASPreferenceController.h"
#import "ASAuthniceController.h"
#import "ASPriorityDefaults.h"

// Model
#import "AGProcess.h"

// Preference stuff
#import "ASGeneralPreferences.h"
#import "ASPauseResumePreferences.h"
#import "ASCPUPreferences.h"
#import "ASPriorityPreferences.h"
#import "ASShared.h"

//kill() & SIGSTOP stuff
#import <sys/signal.h>
#import <signal.h>
#import <unistd.h>

//get & set priority headers
#import <sys/time.h>
#import <sys/resource.h>

//user_from_uid()
#import <pwd.h>

//geteuid()
#import <sys/types.h>

#define ASHideCheckInterval .1

// Unix Error Checking Functions

int ClearErrno() {
	extern int errno;
	return errno = 0;
}

// Error Number Information: http://aplawrence.com/Unixart/errors.html
// Returns YES on fatal error (no such pid) and NO on non-fatal
BOOL CheckErrno(ASAppRef *ref) {
	extern int errno;
	
	switch(errno) {		
		// Invalid PID
		// Occurs for set/getpriority() and kill()
		case ESRCH: 
			NSLog(@"Removing %@ from list, invalid PID as detected by errno", ref);
			
			[[ASAppListController sharedController] appClosed:[NSNotification notificationWithName:ASAppClosedNotification
																							object:ref 
																						  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[ref pid]], ASApplicationPIDKey, NULL]]];
			return YES;
			break;
			
		// When appstop tries to increase priority but fails
		case EACCES:
			//NSLog(@"Priority being increased by unprivledged App Stop");
			break;
			
		default:
			//uncaught errors
			if(errno != 0) {
				NSLog(@"Uncaught errno error: %i, for: %@", errno, ref);
			}
	}
	
	return NO;
}

static int ASRealUserID;	//the real/effective user-id
static int ASAvgCPU;		//report average CPU rather than instantious

@interface ASAppRef (Private)
- (void) _createIcon;
- (void) _retrieveAdditionalInformation;
@end

@implementation ASAppRef (Private)
- (void) _createIcon {
	[self willChangeValueForKey:@"appIcon"];
	[_icon release];
	
	if(!_appPath || !(_icon = [[NSWorkspace sharedWorkspace] iconForFile:_appPath])) {
		_icon = [ASAppRef defaultCommandImage];
	}
	
	float s = [PREF_KEY_VALUE(ASAppIconSize) intValue];
	[_icon setSize:NSMakeSize(s, s)];
	[_icon retain];
	[self didChangeValueForKey:@"appIcon"];	
}

- (void) _retrieveAdditionalInformation {
	//InformationDictionaryForPID(_pid);
}
@end


@implementation ASAppRef
//------------------------------------------
//		Class Methods
//------------------------------------------
+ (void) initialize {
	extern int ASRealUserID;
	ASRealUserID = geteuid();
}

+ (NSImage *) defaultCommandImage {
	static NSImage *_defaultCommandImage = nil;
	
	if(!_defaultCommandImage) {
		_defaultCommandImage = [[[NSWorkspace sharedWorkspace] iconForFileType:@"command"] retain];
	}
	
	return _defaultCommandImage;
}

+ (void) updateAvgCpu {
	extern int ASAvgCPU;
	ASAvgCPU = PREF_KEY_BOOL(ASUseAverageCPU);
	
	[[[ASAppListController sharedController] openApps] makeObjectsPerformSelector:@selector(resetCpuVars)];
}

//------------------------------------------
//		Constructor Methods
//------------------------------------------
- (id) initWithApplicationDictionary:(NSDictionary *) a {
	if(self = [self initWithProcessReference:[[[AGProcess alloc] initWithProcessIdentifier:[[a valueForKey:ASApplicationPIDKey] intValue]] autorelease]]) {
		[self setApplicationName:[a valueForKey:ASApplicationNameKey]];
		[self setApplicationPath:[a valueForKey:ASApplicationPathKey]];
	}
	
	return self;
}

- (id) initWithProcessID:(int)processID {
	return self = [self initWithProcessReference:[[[AGProcess alloc] initWithProcessIdentifier:processID] autorelease]];
}

- (id) initWithProcessReference:(AGProcess *)p {
	if(self = [self init]) {
		if(p == nil) {// check for invalid initializations
			[NSException raise:NSInvalidArgumentException format:@"nil parameter in appref initializer"];
			[self release];
			return nil;
		}
		
		_processInfo = [p retain];		
		_pid = [_processInfo processIdentifier];
		_uid = [_processInfo userIdentifier];
		_priority = getpriority(PRIO_PROCESS, _pid);
		_uidName = [[NSString alloc] initWithCString:user_from_uid(_uid, 0)];

		[self setApplicationName:[_processInfo annotatedCommand]];
		[self setApplicationPath:[[NSWorkspace sharedWorkspace] fullPathForApplication:[_processInfo command]]];
		[self resetCpuVars];
		[self _createIcon];
		
		if(PREF_KEY_BOOL(ASPriorityDefaultsEnabled)) {
			int storedPrio = [[ASPriorityDefaults sharedController] priorityForApplication:self];
			if(storedPrio != 0) {// then we have a stored prio!
				[self setPriority:storedPrio];
			}
		}
	}
	
	return self;
}

- (id) init {
	if ((self = [super init]) != nil) {
		_menuItem = nil; //for calling release on it if it wasn't allocated
		_isBackground = NO;
		_state = YES;
		_isHiding = NO;
		
		//register observers
		PREF_OBSERVE_VALUE(@"values.iconSize", self);
		PREF_OBSERVE_VALUE(@"values.numericPriority", self);
		
		//register for sleep, wake, and shut down events
		NSWorkspace *wrkSpace = [NSWorkspace sharedWorkspace];
		NSNotificationCenter *wrkNotify = [wrkSpace notificationCenter];
		[wrkNotify addObserver:self
					  selector:@selector(willGoToSleep:)
						  name:@"NSWorkspaceWillSleepNotification"
						object:wrkSpace];
		[wrkNotify addObserver:self
					  selector:@selector(didAwakeFromSleep:)
						  name:@"NSWorkspaceDidWakeNotification"
						object:wrkSpace];
		[wrkNotify addObserver:self
					  selector:@selector(willShutDown:)
						  name:@"NSWorkspaceWillPowerOffNotification"
						object:wrkSpace];
	}
	
	return self;
}


//------------------------------------------
//		Action Methods
//------------------------------------------

#pragma mark Stop/Start/Kill/Toggle

- (void) toggle:(id)sender {
	if(_state) {//then the process is running
		[self setState:NO];
	} else {//then the process is off
		[self setState:YES];
	}
}

- (void) killAppIgnoringAlert:(BOOL)ignore {
	[NSApp activateIgnoringOtherApps:YES]; //bring our app to front
	
	if(ignore || NSRunAlertPanel(@"Confirm", @"Are you sure you want to force quit %@?", @"Yes", @"No", nil, [self appName]) == NSAlertDefaultReturn) {
		if(kill(_pid, SIGKILL) == -1) {
			if([[ASAuthniceController sharedController] killApplicationWithPid:_pid] != 1) {
				NSLog(@"Error killing %@ through authnice", self);
			}
		}
	}
}

#define SET_STATE(x) \
[self willChangeValueForKey:@"stateAsString"]; \
_state = x; \
[self didChangeValueForKey:@"stateAsString"]

- (void) hideAndStop {
	// you cant hide background applications...
	if(_isBackground) {
		[self stop];
		SET_STATE(NO);
	} else {
		[self setIsHiding:YES];
		HideAppWithPid(_pid);
		
		[[NSTimer scheduledTimerWithTimeInterval:ASHideCheckInterval
								target:self 
							  selector:@selector(checkIfAppIsHidden:) 
							  userInfo:nil
							   repeats:YES] retain];
	}
}

- (void) contAndShow {
	[self cont];
	
	if(!_isBackground)
		ShowAppWithPid(_pid);
}

- (void) stop {
	extern int ASRealUserID;

	if(_uid != ASRealUserID) {		
		[[ASAuthniceController sharedController] stopApplicationWithPid:_pid];
	} else {
		ClearErrno();
		kill(_pid, SIGSTOP);
		CheckErrno(self);
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:ASAppPausedNotification object:self];
}

- (void) cont {
	extern int ASRealUserID;
	
	if(_uid != ASRealUserID) {
		[[ASAuthniceController sharedController] contApplicationWithPid:_pid];
	} else {
		ClearErrno();
		kill(_pid, SIGCONT);
		CheckErrno(self);
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ASAppResumedNotification object:self];
}

//------------------------------------------
//		Misc
//------------------------------------------
- (void) checkIfAppIsHidden:(NSTimer *)timer {//polling function for the hiding
	if(IsAppHidden(_pid)) {//check if the application is hidden
		[timer invalidate];
		[timer release];
		
		[self setIsHiding:NO];
		
		//change and notify about the state value
		[self willChangeValueForKey:@"state"];
		SET_STATE(NO);
		[self didChangeValueForKey:@"state"];
		
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.3]];
		[self stop];
	}
}

#pragma mark CPU Update

// Returns YES if there is an error, NO if everything went fine
- (BOOL) updateCpuUsage {	
	float appCpuUsage = [[ASAuthniceController sharedController] getCpuUsageForPid:_pid];
	
	// only scale the cpu usage if it didn't return an error
	if(appCpuUsage != -1) {
		appCpuUsage /= 100.0F;
	}
	
	// because of dual processors the only boundry we need to check is < 0
	if(appCpuUsage < 0 && appCpuUsage != -1) {
		DEBUG_LOG(NSLog(@"Error getting CPU usage for %@, reported %f%%", self, appCpuUsage));
		appCpuUsage = -1;
	}
	
	// Perform CPU usage average algorthithm if the pref is set and there was no error
	if(ASAvgCPU && appCpuUsage != -1) {
		_avgCpu += appCpuUsage;
		[self setCpuUsage:_avgCpu/_avgCpuCount++];
	} else {
		// Set the CPU usage to represent the instantanous CPU usage
		// _cpu will be set to -1 if there is an error
		[self setCpuUsage:appCpuUsage];
	}

	return _cpu == -1;
}

- (void) resetCpuVars {
	_avgCpu = 0;
	_avgCpuCount = 1;
	_cpu = 0;	
}

//------------------------------------------
//		Notifications & KVO Methods
//------------------------------------------

//We must run the apps before the comp shuts down/sleeps
//register for sleep/shut down/awake events to fix that bug
- (void) willGoToSleep:(NSNotification *)note {
	if(!_state) {
		[self cont];
	}
}

- (void) didAwakeFromSleep:(NSNotification *)note {
	if(!_state) {//if the application is supposed to be stopped
		[self stop]; //then stop it
	}
}

- (void) willShutDown:(NSNotification *)note {
	[self cont];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath hasSuffix:ASAppIconSize]) {
		[self _createIcon];
	} else if([keyPath hasSuffix:MABPRIORITYNUMERIC]) {
		//is the display preferences for the priority values has changes, simply notify of a priority change
		[self willChangeValueForKey:@"priority"];
		[self didChangeValueForKey:@"priority"];
	}
}

//------------------------------------------
//		Subclass overides
//------------------------------------------

//Will only be used to find if this app is being closed
//the o object will always be a NSDictionary or a ASAppMenuItem
- (BOOL) isEqual:(id) o {
	if([super isEqual:o]) {
		return YES;
	} else if([o isKindOfClass:[NSDictionary class]]) {
		if(_pid == [[o valueForKey:ASApplicationPIDKey] intValue]) //check if we are looking at the same object
			return YES;
		else
			return NO;
	} else if([o isMemberOfClass:[ASAppMenuItem class]]) {
		if(self == [o target]) 
			return YES;
		else
			return NO;
	} else if([o isKindOfClass:[AGProcess class]]) {
		if(_pid == [o processIdentifier]) {
			return YES;
		} else {
			return NO;
		}
	}

	return NO;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"ASAppRef {Name %@, Pid %i, Uid %i}", _appName, _pid, _uid];
}

// Rev. 113 has retain/release debugging functions

- (void) dealloc {	
	// if the application was paused, and it is now dying, we should issue a app resumed notification
	// to let listeners know that the app is 'resumed' (dead)
	if(!_state) {
		[[NSNotificationCenter defaultCenter] postNotificationName:ASAppResumedNotification object:self];
	}
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.iconSize"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.numericPriority"];
	[_processInfo release];
	[_icon release];
	[_appPath release];
	[_appName release];
	[_uidName release];
	[super dealloc];
}

//------------------------------------------
//		Setter & Getter
//------------------------------------------
- (void) setApplicationName:(NSString *)name {
	NSString *temp = [name copy];
	[_appName release];
	_appName = temp;
}

- (NSString *) appName {
	return _appName;
}

- (void) setApplicationPath:(NSString *)path {
	NSString *temp = [path copy];
	[_appPath release];
	_appPath = temp;
}

- (NSString *) applicationPath {
	return _appPath;
}

- (int) pid {
	return _pid;
}

- (BOOL) state {
	return _state;
}

//If s == YES then the application is running, if s == false then it is paused
- (void) setState:(BOOL)s {
	//cant switch state while hiding the app itself!!
	if(_isHiding) {
		NSLog(@"Application is already hiding!");
		return;
	}
	
	if(PREF_KEY_BOOL(MABAUTOHIDE) && !s) {
		[self hideAndStop];
		return;
	}
	
	if(s) {//Start the application
		if(PREF_KEY_BOOL(MABAUTOSHOW)) {
			[self contAndShow];
		} else {
			[self cont];
		}
	} else {//stop the application
		[self stop];
	}
		
	// notify about the string value change also
	SET_STATE(s);
}

- (NSString *) stateAsString {
	return _state ? @"Running" : @"Stopped";
}

- (NSImage *) appIcon {
	return _icon;
}

- (void) setPriority:(int)p {
	ClearErrno();

	// setpriority returns -1 if we dont have enough priv, or if the process doesn't exist
	if(setpriority(PRIO_PROCESS, _pid, p) == -1 && CheckErrno(self) == NO) {
		if(![[ASAuthniceController sharedController] setPriority:p forPid:_pid]) {
			NSLog(@"Error setting priority to %i for process %@", p, self);
		}
	}
	
	_priority = p;
	
	if(PREF_KEY_BOOL(ASPriorityDefaultsEnabled) && PREF_KEY_BOOL(ASAutoRecordDefaults)) {
		[[ASPriorityDefaults sharedController] setPriority:_priority forApplication:self];
	}
}

- (int) priority {
	return _priority;
}

- (void) setCpuUsage:(float)u {
	[self willChangeValueForKey:@"cpuUsageString"];
	_cpu = u;
	[self didChangeValueForKey:@"cpuUsageString"];
}

- (float) cpuUsage {
	return _cpu;
}

- (NSString *) cpuUsageString {
	return [NSString stringWithFormat:@"%.1f%%", _cpu];
}

- (int) uid {
	return _uid;
}

- (NSString *) uidAsString {
	return _uidName;
}

- (BOOL) isBackground {
	return _isBackground;
}

- (void) setIsBackground:(BOOL)b {
	_isBackground = b;
}

- (BOOL) isHiding {
	return _isHiding;
}

- (void) setIsHiding:(BOOL)is {
	_isHiding = is;
}

- (NSMenuItem *) menuItem {
	if(!_menuItem) {
		// retain a weak reference to the menu item
		// ASAppRef creates it but doesn't own it, ASStatusItemController does
		_menuItem = [[(ASAppMenuItem*)[ASAppMenuItem alloc] initWithAppRef:self] autorelease];
	}
	
	return _menuItem;
}

- (BOOL) isZombie {
	return [_processInfo state] == AGProcessStateZombie;
}
@end
