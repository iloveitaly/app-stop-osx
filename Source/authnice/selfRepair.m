#import <Cocoa/Cocoa.h>
#import <stdio.h>

#import "selfRepair.h"

//open() & close()
#import <fcntl.h>
#import <unistd.h>

//stat() & fstat()
#import <sys/stat.h>

//http://heather.cs.ucdavis.edu/~matloff/UnixAndC/CLanguage/SetUserID.html
//http://en.wikipedia.org/wiki/Setuid
//http://wpollock.com/AUnix1/FilePermissions.htm
//http://www.cs.berkeley.edu/~daw/papers/setuid-usenix02.pdf

int repair(char *path) {
	NSLog(@"Repairing authnice...");
	
	//self repair itself and set the uid bit to 0 so the rest of the time it runs as root
	int self = open(path, O_NONBLOCK|O_RDONLY|O_EXLOCK, 0); //open self
	
	//check for errors
	if(self == -1) {
		NSLog(@"Error repairing authnice! Step 1");
	}
	
	struct stat toolStat;
	
	if(fstat(self, &toolStat) == -1) {
		NSLog(@"Error repairing authnice! Step 2");
	}
	
	if(fchown(self, 0, toolStat.st_gid) == -1) {
		NSLog(@"Error repairing authnice! Step 3");
	}
	
	//if(fchmod(self, (toolStat.st_mode & (~(S_IWGRP|S_IWOTH))) | S_ISUID) == -1) {
	if(fchmod(self, 04711) == -1) {
		NSLog(@"Error repairing authnice! Step 4");
	}
	
	if(close(self) != 0) {
		NSLog(@"Error closing repair handle on App Stop");
	}
	
	return 0;	
}
