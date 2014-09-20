#import "ASAuthniceController.h"
#import "ASAppListController.h" /* for DEBUG, and other global macros */
#import "handleCommands.h"
#import "authSharedMacros.h"

#import <stdio.h>
#import <string.h>
#import <unistd.h>
#import <fcntl.h>

#import <sys/stat.h>
#import <sys/types.h>

static ASAuthniceController *_sharedController = NULL;

@implementation ASAuthniceController
//------------------------------------------
//		Class Methods
//------------------------------------------
+ (ASAuthniceController *) sharedController {
	extern ASAuthniceController *_sharedController;
	
	if(!_sharedController) {
		_sharedController = [ASAuthniceController new];
	}
	
	return _sharedController;
}

//------------------------------------------
//		Superclass Overides
//------------------------------------------
- (id) init {
	self = [super init];
	if (self != nil) {
		extern NSString *authRenice;
		extern int childPid;
		
		int readPipe[2], writePipe[2];

		//create two communication pipes
		pipe(readPipe);
		pipe(writePipe);
				
		_read = readPipe[0];
		_write = writePipe[1];
		
		//convert the integers into string to send through execl()
		char writeFD[10], readFD[10];
		sprintf(readFD, "%i", writePipe[0]);
		sprintf(writeFD, "%i", readPipe[1]);
	
		if(!(_pid = fork())) {//create child process
			//send the read pipe for the child in argv[2], the write pipe in argv[3]
			if(execl([authRenice cString], [authRenice cString], "-open", readFD, writeFD, NULL) == -1) {//start the sub-program
				NSLog(@"Error starting authnice helper program.");
			}
		}
		
		childPid = _pid;
		
		//close the unneeded FDs
		close(readPipe[1]);
		close(writePipe[0]);
		
		//read the authnice response
		struct toolResponse response = {0};
		size_t bytesRead = 0;
		if((bytesRead = read(_read, &response, sizeof(struct toolResponse))) != sizeof(struct toolResponse)) {
			NSLog(@"Error reading authnice startup confirmation. %i bytes read, %i bytes needed to be read", bytesRead, sizeof(struct toolResponse));
			NSRunAlertPanel(NSLocalizedString(@"Communication Error", nil),
							NSLocalizedString(@"A communication error has occured. Make sure you are not running App Stop from a disk-image, CD-ROM, or any other unwritable volume. If the problem persists check the console log for information pertaining to App Stop and send a bug report.", nil),
							NSLocalizedString(@"OK", nil), nil, nil);
		} else if(response.responseType == MABToolSuccess) {
			NSLog(@"Startup message from authnice: Success!");
			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(applicationWillTerminate:)
														 name:@"NSApplicationWillTerminateNotification"
													   object:nil];
		} else {
			NSLog(@"Startup message from authnice: Failure!");
		}
		
		
	}
	
	return self;
}

//------------------------------------------
//		Action Methods
//------------------------------------------
- (int) getCpuUsageForPid:(int) pid {
	struct toolRequest request = {0};
	
	request.requestType = MABApplicationGetCpu;
	request.pid = pid;
	
	[self _sendRequest:request];
	
	struct toolResponse response = {0};
	
	if(read(_read, &response, sizeof(struct toolResponse)) != sizeof(struct toolResponse)) {
		NSLog(@"Error reading response from authnice!");
	}
	
	if(response.responseType == MABToolFailure) {
		DEBUG_LOG(NSLog(@"Error getting CPU for process with pid: %i", pid));
	}
	
	return response.otherInfo;
}

- (int) stopApplicationWithPid:(int) pid {
	struct toolRequest request = {0};
	
	request.requestType = MABStopApplication;
	request.pid = pid;
	
	[self _sendRequest:request];
	return [self _getChildOutput];
}

- (int) contApplicationWithPid:(int) pid {
	struct toolRequest request = {0};
	
	request.requestType = MABContApplication;
	request.pid = pid;
	
	[self _sendRequest:request];
	return [self _getChildOutput]; //return the result as a number
}

- (int) setPriority:(int)prio forPid:(int)pid {
	struct toolRequest request = {0};
	
	request.requestType = MABApplicationSetPriority;
	request.pid = pid;
	request.otherInfo = prio;
	
	[self _sendRequest:request];
	return [self _getChildOutput]; //return the result as a number
}

- (int) killApplicationWithPid:(int)pid {
	struct toolRequest request = {0};
	
	request.requestType = MABKillApplication;
	request.pid = pid;
	
	[self _sendRequest:request];
	return [self _getChildOutput]; //return the result as a number
}

- (void) _sendRequest:(struct toolRequest) request {
	if(write(_write, &request, sizeof(struct toolRequest)) != sizeof(struct toolRequest))
		NSLog(@"Error sending toolRequest");
}

- (int) _getChildOutput {
	struct toolResponse response = {0};
	
	if(read(_read, &response, sizeof(struct toolResponse)) != sizeof(struct toolResponse)) {
		NSLog(@"Error reading response from authnice!");
	}
	
	return response.responseType == MABToolSuccess;
}

- (void) quit {
	struct toolRequest request = {0};
	
	request.requestType = MABQuitTool;
	
	[self _sendRequest:request];
	
	//wait for authnice to quit
	wait(NULL); 
	
	//close the pipes
	close(_write);
	close(_read);
}

//------------------------------------------
//		NSApplication Notifications
//------------------------------------------
- (void) applicationWillTerminate:(NSNotification *)aNotification {
	[self quit];
}

//------------------------------------------
//		Setter & Getter Methods
//------------------------------------------
- (int) pid {
	return _pid;
}
@end
