#import <Cocoa/Cocoa.h>

//String & output
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

//getuid()
#import <sys/types.h>
#import <unistd.h>

//open() and O_xxxx constants
#import <sys/stat.h>
#import <fcntl.h>

//signal() and SIG macros
#import <signal.h>

//repair() and doCommands()
#import "handleCommands.h"
#import "selfRepair.h"

//PRINT() & DEBUG macros
#import "authSharedMacros.h"

int writePipe;
int readPipe;

/*
 Simple helper tool. Should be run as root.
 To self repair the uid bit of the root, run the tool as root using AEWP() and having the argument -repair for argv[1].
 
 When you want to run this tool send it the command -open in argv[1], 
 the fd fpr the read pipe in argv[2], the fd for the write pipe in argv[3]
 */

int main(int argc, char *argv[]) {
	if(setuid(0)) {
		NSLog(@"setuid() error");
	}
	
	if(argc <= 1) {//check to make sure some arguments are specified
		NSLog(@"Error executing authnice, invalid number of arguments");
		return 2;
	}
	
	NSLog(@"authnice executing...");
	
	if(strcmp(argv[1], "-repair") == 0 && geteuid() == 0) {//must be running as root to repair itself
		if(geteuid() == 0) {
			NSLog(@"authnice repairing...");
			return repair(argv[0]);
		} else {
			NSLog(@"-repair sent, but euid is not root. uid %i, euid, %i", getuid(), geteuid());
			return 1;
		}
	} else if(geteuid() == 0 && strcmp(argv[1], "-open") == 0 && argc >= 4) {//make sure we are running as root and have the -open flag
		NSLog(@"authnice running...");
		
		extern int writePipe;
		extern int readPipe;
		
		//convert the strings into fd nums
		readPipe = atoi(argv[2]);
		writePipe = atoi(argv[3]);
		
		struct stat sb;
		if(fstat(readPipe, &sb) == -1 || fstat(writePipe, &sb) == -1) {//check for invalid pipes
			NSLog(@"Error opening IPC pipes");
			return 1;
		}
		
		struct toolResponse response = {0};
		response.responseType = MABToolSuccess;
		debug_print("Sending startup notification to parent");
		write(writePipe, &response, sizeof(struct toolResponse));
				
		struct toolRequest request = {0};
		bzero(&response, sizeof(struct toolResponse));
		while(read(readPipe, &request, sizeof(struct toolRequest)) == sizeof(struct toolRequest)) {
			debug_print("Starting new sleep loop...");
			
			response = ExecuteCommand(request);
			if(write(writePipe, &response, sizeof(struct toolResponse)) != sizeof(struct toolResponse))
				NSLog(@"Authnice error sending response to parent!");
			
			bzero(&response, sizeof(struct toolResponse));
			bzero(&request, sizeof(struct toolRequest));
		} 
 	} else {//this should never happen... there must of been some sort of error
		NSLog(@"Error executing authnice...");
		NSLog(@"Argv[1]: %s", argv[1]);
		NSLog(@"euid: %i", geteuid());
	}
	
	return 1;
}