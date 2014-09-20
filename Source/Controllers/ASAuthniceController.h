#import <Cocoa/Cocoa.h>

@interface ASAuthniceController : NSObject {
	int _write;
	int _read;
	int _pid;
}
//------------------------------------------
//		Class Methods
//------------------------------------------
+(ASAuthniceController *) sharedController;

//------------------------------------------
//		Action Methods
//------------------------------------------
- (int) getCpuUsageForPid:(int) pid;
- (int) stopApplicationWithPid:(int) pid;
- (int) contApplicationWithPid:(int) pid;
- (int) setPriority:(int)prio forPid:(int)pid;
- (int) killApplicationWithPid:(int)pid;

- (void) _sendRequest:(struct toolRequest) request;
- (int) _getChildOutput;

- (void) quit;

//------------------------------------------
//		NSApplication Notifications
//------------------------------------------
- (void) applicationWillTerminate:(NSNotification *)aNotification;

//------------------------------------------
//		Setter & Getter Methods
//------------------------------------------
- (int) pid;
@end
