#import "ASAppListController.h"
#import "ASAppWindowController.h"
#import "ASAppTableArrayController.h"
#import "ASAppRef.h"
#import "AGProcess.h"
#import "ASStatusMenuController.h"
#import "NSProcessInfo+Additions.h"
#import "MABAuthorization.h"
#import "ASAuthniceController.h"
#import "ASProcessFilter.h"

// Preferences
#import "ASBackgroundPreferences.h"
#import "ASCPUPreferences.h"
#import "ASBackgroundPreferences.h"
#import "ASGeneralPreferences.h"
#import "ASShared.h"

// Registration
#import "RegistrationHandling.h"
#import "DemoPeriod.h"

//wait() for the authtool to finish authorizing
#import <sys/types.h>
#import <sys/wait.h>

//errAuthorizationSuccess
#import <Security/Authorization.h>

//for true and false
#import <stdbool.h>

//shared variables
static ASAppListController *_sharedController;

//global variables
int currentPid = -1;	//pid of the running application
int childPid = -1;		//pid of the authnice child application

NSString *authRenice; //path to the authnice binary

//Catching App Switching Events
//http://www.unsanity.org/archives/000045.php
//http://www.cocoadev.com/index.pl?ResignFrontmostApplication

//get all processes: http://developer.apple.com/qa/qa2001/qa1123.html
//GCC compiler errors: http://www.network-theory.co.uk/docs/gccintro/gccintro_94.html
//linker -bind_at_load warning: http://www.cocoabuilder.com/archive/message/xcode/2005/11/11/942
//initialization list order: http://www.thescripts.com/forum/thread213001.html
//best C FAQ: http://c-faq.com/decl/index.html
//right click menu: http://www.cocoadev.com/index.pl?RightClickSelectInTableView
//Debugging tips: http://developer.apple.com/technotes/tn2004/tn2124.html
//Crash log: http://developer.apple.com/technotes/tn2004/tn2123.html

@implementation ASAppListController
//------------------------------------------
//		Class Methods
//------------------------------------------
+ (ASAppListController *) sharedController {
	extern ASAppListController *_sharedController;
	return _sharedController;
}

//------------------------------------------
//		Superclass Overides
//------------------------------------------
+ (void) initialize {
	extern int currentPid;
	currentPid = getpid();
	
	//set the global authPath variable
	extern NSString *authRenice;
	authRenice = [[[NSBundle mainBundle] pathForResource:@"authnice" ofType:@""] retain];
}

- (id) init {	
	if(self = [super init]) {
		//set ourselves as the global shared controller, since their will only be one
		extern ASAppListController *_sharedController;
		_sharedController = self; 
		
		//register defaults changes
		PREF_OBSERVE_VALUE(@"values.bgProcEnabled", self);
		PREF_OBSERVE_VALUE(@"values.menuHasBGApps", self);
		PREF_OBSERVE_VALUE(@"values.procUpdateInterval", self);
		PREF_OBSERVE_VALUE(@"values.cpuEnabled", self);
		PREF_OBSERVE_VALUE(@"values.cpuInterval", self);
		PREF_OBSERVE_VALUE(@"values.averageCpu", self);
		PREF_OBSERVE_VALUE(@"values.zombieProcesses", self);
		
		_menuController = [ASStatusMenuController new];
		_openApps = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillTerminate:)
													 name:@"NSApplicationWillTerminateNotification"
												   object:nil];
	}
	
	return self;
}

//------------------------------------------
//		Misc Methods
//------------------------------------------

- (void) start {
	//before starting make sure they are registered
	if(!IsRegistered() && HasDemoExpired()) {
		return;
	}
	
	extern int currentPid;
	extern int childPid;
	
	DEBUG_LOG(freopen("./debug_output.txt", "w", stderr));

	// Create the menu, we must wait till the +sharedUpdater is availible so we can reference it
	[_menuController createMenu];
	
	// We have to make sure we have root access to processes first
	[self authenticateHelper];
	
	// Start the helper process
	[ASAuthniceController sharedController];
	
	NSLog(@"App Stop pid %i", currentPid);
	NSLog(@"Authnice pid %i", childPid);
	
	//create the application menu & dictionary with the default applications from NSWorkspace
	NSArray *tempOpenApps = [[NSWorkspace sharedWorkspace] launchedApplications];
	NSEnumerator *tempAppEnum = [tempOpenApps objectEnumerator];
	NSDictionary *tempEnumOb = nil;
	ASAppRef *tempAppRef = nil;
	
	while(tempEnumOb = [tempAppEnum nextObject]) {
		if([[tempEnumOb valueForKey:ASApplicationPIDKey] intValue] != currentPid) {//make sure we arent adding ourselves
			tempAppRef = [[ASAppRef alloc] initWithApplicationDictionary:tempEnumOb];
			[tempAppRef setIsBackground:NO];
			
			// add them manually since the appOpened: runs through oController which isn't bound yet
			[_openApps addObject:tempAppRef];
			[_menuController addMenuItem:tempAppRef];
			
			[tempAppRef release];
		}
	}
	
	[oController bind:@"contentArray"
			 toObject:self
		  withKeyPath:@"openApps"
			  options:0];

	// This registers the hotkey
	[[ASGeneralPreferences sharedInstance] loadHotKeyFromDefaults];
	
	//this needs to be called before the table view is setup
	[[ASAppWindowController sharedController] configureAppTable];
	
	// Setup the timers
	[self configureProcListTimer];
	[self configureCpuUsageTimer];
	
	//fire the timers methods since they wont be fired until they're first interval is up
	[self _updateProcList:nil];
	[self _updateCpuUsage:nil];
	
	//register for app open/close events
	//we dont want to recieve these notifications until the application starts/
	//so we register here instead of in the -init method
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSNotificationCenter *workspaceNotificationCenter = [workspace notificationCenter];
	
	[workspaceNotificationCenter addObserver:self
									selector:@selector(appClosed:)
										name:@"NSWorkspaceDidTerminateApplicationNotification"
									  object:workspace];
	[workspaceNotificationCenter addObserver:self
									selector:@selector(appOpened:)
										name:@"NSWorkspaceDidLaunchApplicationNotification"
									  object:workspace];		
}

- (void) authenticateHelper {
	extern NSString *authRenice;
	
	if(!HelperToolOwnerIsRoot(authRenice)) {
		// load the admin priv information window
		NSWindowController *adminPrivAlert = [[NSWindowController alloc] initWithWindowNibName:@"AdminPrivAlert"];
		[[adminPrivAlert window] setLevel:NSFloatingWindowLevel];
		[adminPrivAlert showWindow:self];
		
		// give the window some time to appear...
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
		
		// bring the app into focus and bring up the authentication
		[NSApp activateIgnoringOtherApps:YES];
		OSStatus status = AuthorizeApplication(authRenice, [NSArray arrayWithObject:@"-repair"], NULL);
		
		// release the window
		[[adminPrivAlert window] performClose:self];
		[adminPrivAlert release];
		
		if(status == errAuthorizationSuccess) {//if the user put in the password then wait for the tool to repair
			int status = 0, resultPid = 0;
			if((resultPid = wait(&status)) == -1) {
				NSLog(@"Error waiting for authorization completion");
			}
			
			NSLog(@"Return code on authnice -repair: %i", status);
		} else if(status != errAuthorizationSuccess) {//the root authorization failed
			NSRunAlertPanel(NSLocalizedString(@"Authorization Failed", nil), 
							NSLocalizedString(@"There was an error during the authorization process. If you know you entered your password correctly please contact support at support@prosit-software.com", nil),
							NSLocalizedString(@"OK", nil), nil, nil);
			exit(EXIT_FAILURE); //use exit() so we dont get applicationWillTerminate: notification
		} else if(!HelperToolOwnerIsRoot(authRenice)) {//authorization succeded, but the tool is still unauthorized
			NSRunAlertPanel(NSLocalizedString(@"Error", nil),
							NSLocalizedString(@"Authorization has succeeded, but an error has occurred while writing permissions. Make sure there are no special permissions on App Stop, and relaunch App Stop.", nil),
							NSLocalizedString(@"OK", nil), nil, nil);
			exit(EXIT_FAILURE);
		}
	}	
}

- (void) configureProcListTimer {
	[_procListTimer invalidate];

	if(PREF_KEY_BOOL(ASBGProcessEnabled)) {
		_procListTimer = [NSTimer scheduledTimerWithTimeInterval:[PREF_KEY_VALUE(ASProcessUpdateInterval) intValue] 
														  target:self
														selector:@selector(_updateProcList:)
														userInfo:nil
														 repeats:YES];
	} else {
		_procListTimer = nil;
	}
}

- (void) configureCpuUsageTimer {
	[_cpuUsageTimer invalidate];
	
	if(PREF_KEY_BOOL(ASCpuUsageReporting)) {
		_cpuUsageTimer = [NSTimer scheduledTimerWithTimeInterval:[PREF_KEY_VALUE(MABCPUINTERVAL) intValue]
														  target:self
														selector:@selector(_updateCpuUsage:)
														userInfo:nil
														 repeats:YES];
	} else {
		_cpuUsageTimer = nil;
	}
}

#define DUMP_ARRAY(x) \
{int i = 0;\
printf("---------------------------------\n"); \
for(; *(x + i) != -1; i++) {printf("%i : %i\n", i, *(x + i));} \
printf("---------------------------------\n");}

#define COMPARE_ARRAYS(x, y) \
{int i = 0, i2 = 0; \
printf("---------------------------------\n"); \
while( *(x + i) != -1 || *(y + i2) != -1) {\
	if(*(x + i) == -1) printf("(    ) : ");\
	else {printf("(%i : %i) : ", i, *(x + i));i++;} \
		\
	if(*(y + i2) == -1) printf("(    )\n"); \
	else {printf("(%i : %i)\n", i2, *(y +i2));i2++;} \
} \
printf("---------------------------------\n");}

- (void) _updateProcList:(NSTimer *)timer {
	//NSLog(@"Update proc list");
	//dont update the proc list if its disabled
	if(timer == nil && !PREF_KEY_BOOL(ASBGProcessEnabled))
		return;

	//get an array of all the procs, and make a ptr point to the beggining of the list
	int *allProcs = [AGProcess allProcessesSortedInts], *allProcsPtr = allProcs;
	int l, allProcsCount = 0, storedProcsCount = [_openApps count];
	
	// get the length of the allProcs
	while(*allProcsPtr++ != -1) {
		allProcsCount++;
	}
	
	// reset the ptr to the beggining 
	allProcsPtr = allProcs;
	
	// create a C array full of all the stored open applications
	int *storedProcs = (int *) malloc((storedProcsCount + 1) * sizeof(int)), *storedProcsPtr = storedProcs;
	
	l = storedProcsCount;
	while(l--) {
		*storedProcsPtr++ = [[_openApps objectAtIndex:l] pid];
	}
	
	*storedProcsPtr = -1;
	
	selectionSort(storedProcs, storedProcsCount);
	
	//COMPARE_ARRAYS(allProcs, storedProcs);

	// create the arrays for the closed and opened applications
	int *closedProcs = (int *) malloc(sizeof(int) * (MAX(storedProcsCount, allProcsCount))), *closedProcsPtr = closedProcs;
	int *openedProcs = (int *) malloc(sizeof(int) * (MAX(storedProcsCount, allProcsCount))), *openedProcsPtr = openedProcs;
	int differenceLengths[2]; //[0] = closedProcs, [1] = openedProcs
	
	arrayComparison(allProcs, storedProcs, openedProcs, closedProcs, differenceLengths);

	// create arrays to be inserted into the array controller
	//NSMutableArray *openedArray = [[NSMutableArray alloc] initWithCapacity:differenceLengths[0]], *closedArray = [[NSMutableArray alloc] initWithCapacity:differenceLengths[1]];
	NSArray *openedArray = [[ASProcessFilter sharedController] filterIntArray:openedProcs];
	NSMutableArray *closedArray = [[NSMutableArray alloc] initWithCapacity:differenceLengths[1]];

	// iterate through the closed applications
	if(*closedProcsPtr != -1) {
		do {
			[closedArray addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:*closedProcsPtr] forKey:ASApplicationPIDKey]];
		} while(*++closedProcsPtr != -1);
	}

	if([openedArray count]) {
		DEBUG_LOG(NSLog(@"Opening: %@", openedArray));
		[oController addObjects:openedArray];
	}
	
	if([closedArray count]) {
		DEBUG_LOG(NSLog(@"Closing: %@", closedArray));
		[oController removeObjects:closedArray];
	}

	// free us up
	[closedArray release];
	free(closedProcs);
	free(openedProcs);
	free(allProcs);
	free(storedProcs);
}

- (void) _updateCpuUsage:(NSTimer *)timer {
	//dont update the cpu usage if it is disabled!
	if(timer == nil && !PREF_KEY_BOOL(ASCpuUsageReporting))
		return;

	int l = [_openApps count];
	BOOL retrieveError = NO;
	BOOL removeZombies = !PREF_KEY_BOOL(ASShowZombieProcesses);
	ASAppRef *tempRef;
	
	while(l--) {
		tempRef = [_openApps objectAtIndex:l];
		if([tempRef updateCpuUsage]) {//updateCpuUsage returns YES if the app had trouble getting CPU
			retrieveError = YES;
			//NSLog(@"Error retrieving CPU usage for %@", tempRef);
			
			if(removeZombies && [tempRef isZombie]) {
				// At this point the process could of died already
				DEBUG_LOG(NSLog(@"Error retrieving CPU usage, and we've found its a zombie! %@", tempRef));
				[self appClosed:[NSNotification notificationWithName:ASAppClosedNotification object:tempRef userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[tempRef pid]], ASApplicationPIDKey, NULL]]];

			}
		}
	}
	
	// If there was an error retrieving the CPU usage its probobly because the process doesn't exist anymore!
	// So update the process list to remove any killed processed
	if(retrieveError) {
		//NSLog(@"There was an error getting CPU usage, performing process list refresh");
		[self _updateProcList:nil];
	}

	// Keep the CPU column sorted if it is being sorted
	if([[oController sortDescriptors] count] > 0 && [[[[oController sortDescriptors] objectAtIndex:0] key] isEqualToString:@"cpuUsage"]) {
		[(id)oController secretRearrangeObjects];		
	}
}

//------------------------------------------
//		NSWorkspace notification methods
//------------------------------------------
- (void) appOpened:(NSNotification *)note {
	//NSLog(@"Opening! %@", note);
	ASAppRef *tempAppRef;
	
	// If we are handling a notification from NSWorkspace
	// The notification could be a duplicate, or it just could be a real opened app notification
	if([[note name] isEqualToString:NSWorkspaceDidLaunchApplicationNotification]) {
		unsigned int index = [_openApps indexOfObject:[note userInfo]];
		
		//then we have a duplicate notification
		if(index != NSNotFound) {
			//NSLog(@"Duplicate notification %@", note);
			tempAppRef = [_openApps objectAtIndex:index];
			[tempAppRef setIsBackground:NO];
					
			//make sure the application is not already present in the menu
			//maybe this check should be done by the menu controller itself
			if([[_menuController statusMenu] indexOfItem:[tempAppRef menuItem]] == -1) {
				[_menuController addMenuItem:tempAppRef];
			}
			
			//quit early, we arent adding any new apps to the list
			return;
		}
		
		// Then the application is not already in the list, so create the new ASAppRef that will be added to the list
		tempAppRef = [[ASAppRef alloc] initWithApplicationDictionary:[note userInfo]];
	} else {
		NSLog(@"Uncaught appOpened: notification %@", note);
	}
	
	//NSLog(@"App Opened %@", tempAppRef);
	[oController setNewObject:tempAppRef];
	[oController addObject:tempAppRef];
	[tempAppRef release];
	//NSLog(@"App Added");
}

- (void) appClosed:(NSNotification *)note {
	// The dictionary will be compared with the ASAppRefs to see if the pids match up
	// Sometimes when the CPU refresher detects ad dead application and invokes _updateProcList 
	// A uncaught exception is created with an out of bounds message trying to remove an object from the [_openApps count] position in the array
	// Some possible solutions:
	//		- http://www.cocoabuilder.com/archive/message/cocoa/2004/1/16/98967
	
	//NSLog(@"App Closed Notification %@", note);
	//NSLog(@"App Closed %@", [[note userInfo] valueForKey:ASApplicationNameKey]);
	
	/*
	if([[note object] isKindOfClass:[NSWorkspace class]]) {
		NSLog(@"Workspace notification");
	} else {// then the notification object is ASAppRef
		
	}
	*/
	
	[oController removeObject:[note userInfo]];
}

//------------------------------------------
//		NSApp delegate methods
//------------------------------------------
- (void) applicationWillTerminate:(NSNotification *)aNotification {
	//loop through all the application and turn them on if they are off
	NSEnumerator *allContEnum = [_openApps objectEnumerator];
	ASAppRef *tempAppRef;
	while(tempAppRef = [allContEnum nextObject]) {
		if(![tempAppRef state]) {//check if they are off
			[tempAppRef toggle:self];
		}
	}	
}


//------------------------------------------
//		Setter & Getter methods
//------------------------------------------
- (NSMutableArray *) openApps {
	return _openApps;
}

//------------------------------------------
//		KVC NSArrayController Methods
//------------------------------------------
- (void) insertObject:(ASAppRef *)ref inOpenAppsAtIndex:(unsigned int)index {
	//NSLog(@"Going to insert %@ at index %i", ref, index);
	[_openApps insertObject:ref atIndex:index];
	[_menuController addMenuItem:ref];
}

- (void)removeObjectFromOpenAppsAtIndex:(unsigned int)index {
	//NSLog(@"Going to remove at index %i", index);
	ASAppRef *tempRef = [_openApps objectAtIndex:index];
	//NSLog(@"Removing: %@", tempRef);
	[_menuController removeMenuItem:tempRef];
	[_openApps removeObjectAtIndex:index];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath hasSuffix:ASCpuUsageReporting]) {
		[self configureCpuUsageTimer];
	} else if([keyPath hasSuffix:MABCPUINTERVAL]) {
		[self configureCpuUsageTimer];
	} else if([keyPath hasSuffix:ASUseAverageCPU]) {
		[ASAppRef updateAvgCpu];
	} else if([keyPath hasSuffix:ASProcessUpdateInterval]) {
		[self configureProcListTimer];
	} else if([keyPath hasSuffix:ASShowZombieProcesses]) {
		if(PREF_KEY_BOOL(ASShowZombieProcesses)) {
			[self _updateProcList:nil];
		} else {//zombies are turned off!
			//remove all zombie processes
			ASAppRef *tempRef;
			int l = [_openApps count];
			while(l--) {
				if([tempRef = [_openApps objectAtIndex:l] isZombie]) {
					[oController removeObject:tempRef];
				}
			}
		}
	} else if([keyPath hasSuffix:ASBGProcessEnabled]) {
		CHECK_OSX_10_4;
		
		[self configureProcListTimer];
		
		if(PREF_KEY_BOOL(ASBGProcessEnabled)) {
			[self _updateProcList:nil];
		} else {//no bg processes!
			//remove all the objects that are background apps
			ASAppRef *tempRef;
			int l = [_openApps count];

			while(l--) {
				if([tempRef = [_openApps objectAtIndex:l] isBackground]) {
					[oController removeObject:tempRef];
				}
			}
		}
	} else if([keyPath hasSuffix:ASBGProcessesInMenu]) {
		CHECK_OSX_10_4;

		ASAppRef *tempRef;

		if(PREF_KEY_BOOL(ASBGProcessesInMenu)) {
			//add all the background apps to the list
			int l = [_openApps count];
			while(l--) {
				if([tempRef = [_openApps objectAtIndex:l] isBackground]) {//make sure its a BG app
					[_menuController addMenuItem:tempRef];
				}
			}
		} else {
			//remove all the background apps from the menu
			int l = [_openApps count];
			while(l--) {
				if([tempRef = [_openApps objectAtIndex:l] isBackground]) {
					[_menuController removeMenuItem:tempRef];
				}
			}
		}
	}
}
@end