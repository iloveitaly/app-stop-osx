/*
 Copyright (c) 2005-2006, Michael Bianco
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of the Prosit Software nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "MABAuthorization.h"

#import <sys/types.h>
#import <sys/stat.h>
#import <Security/Security.h>

OSStatus AuthorizeApplication(NSString *path, NSArray *arguments, FILE **pipe) {
	int a = 0, l = [arguments count];
	char *args[l + 1];
	
	for(; a < l; a++) {
		args[a] = strdup([[arguments objectAtIndex:a] cString]);
	}
	
	//end the list with a null
	args[a] = NULL;

	OSStatus status;
	AuthorizationRef auth;
	
	if(AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth) != errAuthorizationSuccess)
		NSLog(@"Error creating authorization environment");
	
	status = AuthorizationExecuteWithPrivileges(auth, [path  cString], kAuthorizationFlagDefaults, args, pipe);
	AuthorizationFree(auth, kAuthorizationFlagDefaults);
	
	while(a--) {
		free(args[a]);
	}
	
	return status;
}

BOOL HelperToolOwnerIsRoot(NSString *path) {
	struct stat fileStat;
	
	if(stat([path cString], &fileStat) == -1) {
		NSLog(@"An error occured while reading %@ with stat() from helpToolOwnerIsRoot()", path);
		return NO;
	} else {
		return fileStat.st_uid == 0; //if the owner is root
	}
}