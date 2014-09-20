#import <stdio.h>
#import <string.h>
#import <unistd.h>

//the AGProcess class
#import "AGProcess.h"

//exit()
#import <stdlib.h>

//setpriority();
#import <sys/time.h>
#import <sys/resource.h>

//kill() and SIG macros
#import <signal.h>

#import "ASAppListController.h" /* for DEBUG_LOG */
#import "authSharedMacros.h"
#import "handleCommands.h"

struct toolResponse ExecuteCommand(struct toolRequest request) {
	struct toolResponse response = {0};
	int result;
	
	switch(request.requestType) {
		case MABStopApplication:
			debug_print("Stopping application...");
			result = kill(request.pid, SIGSTOP); //send the result to stdout to the parent knows that we are done with the command
			break;
		case MABContApplication:
			debug_print("Cont application...");
			result = kill(request.pid, SIGCONT);
			break;
		case MABKillApplication:
			debug_print("Killing application...");
			result = kill(request.pid, SIGKILL);
			break;
		case MABApplicationSetPriority:
			debug_print("Setting application priority...");
			result = setpriority(PRIO_PROCESS, request.pid, request.otherInfo);
			break;
		case MABApplicationGetCpu: {
			debug_print("Getting CPU usage...");
			AGProcess *tempProc = [[AGProcess alloc] initWithProcessIdentifier:request.pid];
			
			if(!tempProc) {
				DEBUG_LOG(NSLog(@"Error initializing AGProcess instance to retrieve CPU usage for pid %i", request.pid));
				response.otherInfo = result = -1;
				[tempProc release];
				break;
			}
			
			//get float rep of CPU usage
			double percent = [tempProc percentCPUUsage];
			
			if(percent == AGProcessValueUnknown) {
				DEBUG_LOG(NSLog(@"Unknown CPU value for pid %i", request.pid));
				result = -1;
			} else {
				result = (int) (percent * CPU_PRECISION); //since percentCPUUsage returns a float percent, convert it to a whole number % (int)
			}

			response.otherInfo = result;
			
			[tempProc release];
			
			break;
		}
		case MABQuitTool:
			debug_print("Quitting Authnice...");
			
			//close pipes
			extern int readPipe, writePipe;
			close(readPipe);
			close(writePipe);
			
			exit(0);
			break;
	}
	
	//set the result
	if(result == -1) response.responseType = MABToolFailure;
	else response.responseType = MABToolSuccess;
	
	return response;
}