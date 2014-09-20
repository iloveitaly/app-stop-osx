//
//  NSException+ESStackTrace.m
//  App Stop
//
//  Created by Michael Bianco on 11/21/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <ExceptionHandling/NSExceptionHandler.h>
#import "ESStackTrace.h"
#import "ASShared.h"

//http://www.cocoadev.com/index.pl?StackTraces

void CB_exceptionHandler(NSException *exception) {
	[exception printStackTrace];
	
	NSRunAlertPanel(NSLocalizedString(@"Unexpected Error", nil),
					NSLocalizedString(@"An unexpected error has occurred. Please check your console log for any information relevent to App Stop and report this bug to info@prosit-software.com", nil),
					NSLocalizedString(@"OK", ), nil, nil);
    
	//exit(EXIT_FAILURE);
}

@implementation NSException (ESStackTrace)
- (void) printStackTrace {
	NSString *stackTrace = [[self userInfo] objectForKey:NSStackTraceKey];
	NSString *atosPath = [[NSBundle mainBundle] pathForResource:@"atos" ofType:@""];
	
	if(!isEmpty(stackTrace) && !isEmpty(atosPath)) {
		NSString *pidInspectString = [NSString stringWithFormat:@"'%@' -p %d %@ | tail -n +3 | head -n +%d | c++filt | cat -n", atosPath, [[NSProcessInfo processInfo] processIdentifier], stackTrace, ([[stackTrace componentsSeparatedByString:@"  "] count] - 4)];
		//NSString *binaryInspectString = [NSString stringWithFormat:@"'%@' -o %@ %@ | tail -n +3 | head -n +%d | c++filt | cat -n", atosPath, @"/Volumes/Work/CocoaApps/AppStop/trunk/build/Debug/App\ Stop.app/Contents/Resources/atos", stackTrace, ([[stackTrace componentsSeparatedByString:@"  "] count] - 4)];

		FILE *file = popen([pidInspectString UTF8String], "r" );
		
		if(file) {
			char buffer[512];
			size_t length = 0, charsWritten = 0;
			int returnStatus;

			fprintf(stderr, "An exception of type %s occured.\n%s\n", [[self name] cString], [[self reason] cString]);
			fprintf(stderr, "Stack trace:\n");
			
			while(length = fread(buffer, 1, sizeof(buffer), file)) {
				fwrite(buffer, 1, length, stderr);
				charsWritten++;
			}
			
			// this always seems to be 0 even though it cant read the process...
			// the not reading of the process is caused by the fact that on INTEL macs only
			// the users are not normally in the procmod group
			returnStatus = pclose(file);

			if(returnStatus != 0 || charsWritten == 0) {
				NSLog(@"Error getting process information!");
				NSLog(@"Stack Trace String: \"%@\"", stackTrace);
			}
		}
	} else {
		NSLog(@"An exception of type %@ occured.\n%@", [self name], [self reason]);
		NSLog(@"Empty stack trace");
	}
}
@end

@implementation NSApplication (ESExceptionHandling)
- (void) reportException:(NSException *)anException {
	CB_exceptionHandler(anException);
}
@end
