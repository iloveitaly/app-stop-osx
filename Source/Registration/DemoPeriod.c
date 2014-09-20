/*
 *  DemoPeriod.c
 *  App Stop
 *
 *  Created by Michael Bianco on 9/6/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import "DemoPeriod.h"
#import "RegistrationHandling.h"
#import "ASShared.h"

#import <time.h>

#ifdef HIDDEN_LICENSE_FUNCTIONS
int _initDemoExpiration(void) { return ASCompileTime; }
int InitProcessListHook(void) {
#else
int InitDemoExpiration(void) {
#endif
	// Before checking for an expiration date, check to see if we are registered, if we are call ClearDemoPeriod()
	// If not continue by writing files to disk
	// Before writing the files to disk, check if they already are on the disk
	// To make sure its not too easy to break the demo expiration we want to write the expiration date in three places
	//	a) User defaults in a non-demo related key
	//	b) ~/Library/Preferences in ".CoreConfigPreferences"
	// The expiration date will be stored as a plain int in both files
	// If a expiration date is found in ANY of these places, and we have passed the expiration date, then the program should
	// Present a dialog allowing the user to purchase the software, and then quit the application.
	// Make sure all files have the same expiration date
	// You can clear the demo files in ~/Library/Preferences by using this command: `rm .AppStopDemo.plist .CoreConfigPreferences`
	
	if(IsRegistered()) {
		ClearDemoFiles();
		return 0;
	}
	
	NSString *libraryPath = [[NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Preferences"];
	NSString *secretPrefPath = [libraryPath stringByAppendingPathComponent:ASSecretPreferenceFile];
	NSString *fakeDemoFilePath = [libraryPath stringByAppendingPathComponent:ASFakePreferenceFile];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSFileManager *manager = [NSFileManager defaultManager];
	
	// These represent the expiration values extracted from the two storage locations
	int secretPrefExpirationDate = 0;
	int defaultsExpirationDate = 0;
	
	//==========================================
	//
	//		Retrieving Stored Expiration
	//
	//==========================================
	#pragma mark Retrieving Stored Expiration
	
	// The following macro checks to see if the expiration date is earlier than should be
	// In the future I could use this to extend the expiration date when a new version is compiled, but for now it should do nothing
	#define CHECK_EXP_DATE(x) \
		if(x < ASCompileTime + ASDemoPeriod) { \
			NSLog(@"Invalid expiration date"); \
			if(x > ASFirstCompileTime + ASDemoPeriod) { \
				NSLog(@"Resetting demo period"); \
				x = 0; \
			} \
		}
	
	//returns the remaining days in the demo period specified by x
	#define EXP_DAYS_LEFT(x) ((x - time(NULL))/ONE_DAY)

	//get the expiration date stored in preferences
	if([defaults valueForKey:ASPrefDemoExpirationKey] != nil) {
		id tempTime = [defaults valueForKey:ASPrefDemoExpirationKey];
		
		if([tempTime isKindOfClass:[NSNumber class]]) {
			defaultsExpirationDate = [tempTime intValue];
			
			CHECK_EXP_DATE(defaultsExpirationDate);
		} else {
			NSLog(@"245: Invalid data class");
		}
	}
	
	// Get the expiration date stored in the secret preferences
	if([manager fileExistsAtPath:secretPrefPath]) {
		NSData *plistData = [NSData dataWithContentsOfFile:secretPrefPath];
		NSDictionary *secretPlistFile = nil;
		id tempTime = nil;
		NSString *error = nil;
		
		//If there was an error retrieving the plist from disk
		if(isEmpty(plistData)) {
			NSLog(@"245: Error reading file S"); 
		} else {
			//get the NSDictionary representation of the plist
			secretPlistFile = [NSPropertyListSerialization propertyListFromData:plistData
															   mutabilityOption:NSPropertyListMutableContainers
																		 format:NULL
															   errorDescription:&error];
			
			if(isEmpty(secretPlistFile)) {
				NSLog(@"245: Error retrieving dictionary rep");
			} else {//valid NSDictionary
				//extract the key from the dictionary
				tempTime = [secretPlistFile valueForKey:ASTrickyDemoExpirationKey];
				if(isEmpty(tempTime)) {
					NSLog(@"245: Error retrieving key T2");
				} else {//success in retrieving expiration key from the dictionary
					if([tempTime isKindOfClass:[NSNumber class]]) {
						secretPrefExpirationDate = [tempTime intValue];
						CHECK_EXP_DATE(secretPrefExpirationDate);
					} else {
						NSLog(@"254: Class error retrieving key T2");
					}
				}
			}
		}
	}
		
	// End get expiration date from secret file
	
	//==========================================
	//
	//		Expiration Date Check
	//
	//==========================================
	#pragma mark Expiration Date Check
	
	// The expiration date of the program
	int determinedExpirationDate = 0;
	
	//no expiration date has been determined yet, determine one
	if(defaultsExpirationDate == 0 && secretPrefExpirationDate == 0) {
		determinedExpirationDate = time(NULL) + ASDemoPeriod;
		
		// This is essentially the "first run" of the software... or it should be
		// The authentication done for the authnice also signifies the first run, maybe use that to check for hackers in the future also
		//NSLog(@"Generated expiration date! %i...", determinedExpirationDate);
		//NSLog(@"Diff %i", determinedExpirationDate - time(NULL));
	} else if(defaultsExpirationDate != secretPrefExpirationDate) {//some sort of expiration date HAS been determined, just figure out what it is
		//NSLog(@"Expiration descrepency. defaults %i : secret %i", defaultsExpirationDate, secretPrefExpirationDate);
		
		//check to see if one of the dates in 0 (undefined, or incorrectly defined)
		if(defaultsExpirationDate == 0) {
			determinedExpirationDate = secretPrefExpirationDate;
		} else if(secretPrefExpirationDate == 0) {
			determinedExpirationDate = defaultsExpirationDate;
		}
		
		//check to see if both dates dont equal each other and both are valid dates
		//this should never occur, and definitly means someone beens hacking to see whats going on
		if(defaultsExpirationDate != 0 && secretPrefExpirationDate != 0) {
			//NSLog(@"Time discrepancy");
			exit(EXIT_FAILURE);
		}		
	} else if(EXP_DAYS_LEFT(defaultsExpirationDate) > ASDemoDays || EXP_DAYS_LEFT(secretPrefExpirationDate) > ASDemoDays) {//someone has been fudging with the dates, they are longer than 30 days
		NSLog(@"Expiration date too long! %i : %i", EXP_DAYS_LEFT(defaultsExpirationDate), EXP_DAYS_LEFT(secretPrefExpirationDate));
		exit(EXIT_FAILURE);
	} else {//then both times are valid! Nothing special to do!
		//NSLog(@"Valid expiration date!! defaults %i : secret %i", defaultsExpirationDate, secretPrefExpirationDate);
		//we could return either defaultsExpirationDate, or secretPrefExpirationDate since they are both valid
		return determinedExpirationDate = defaultsExpirationDate;
	}
	
	//if either one of the preferences isn't set, set them :)
	if(defaultsExpirationDate == 0 || secretPrefExpirationDate == 0) {
		if(defaultsExpirationDate == 0) {
			//set the defaults expiration date
			[defaults setValue:[NSNumber numberWithInt:determinedExpirationDate] forKey:ASPrefDemoExpirationKey];
			[defaults synchronize];
		} else {//then the secretPrefExpirationDate must be 0
			//set the secret prefs default value
			NSString *error = nil;
			NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:ASCompileTime], ASTrickyFakeKey, [NSNumber numberWithInt:determinedExpirationDate], ASTrickyDemoExpirationKey, nil]
																		   format:NSPropertyListBinaryFormat_v1_0
																 errorDescription:&error];
			
			//check to make sure we successfully created the plist
			if(isEmpty(plistData)) {
				NSLog(@"Error creating plist data S");
			} else {
				if([manager fileExistsAtPath:secretPrefPath]) {
					if(![manager removeFileAtPath:secretPrefPath
										  handler:nil]) {
						NSLog(@"245: Error removing file S");
					}
				}
				
				if(![plistData writeToFile:secretPrefPath atomically:YES]) {
					NSLog(@"245: Error writing file");
				}
			}
		}
		
		//write fake demo file to try to fool casual hackers
		[[NSString stringWithFormat:@"%i", ASCompileTime] writeToFile:fakeDemoFilePath atomically:YES];
	}
	
	return determinedExpirationDate;
}

#ifdef HIDDEN_LICENSE_FUNCTIONS
void _clearDemoFiles(void) {}
void ClearProcessListHook(void) {
#else
void ClearDemoFiles(void) {
#endif
	//NSLog(@"Clear demo period files");
	NSString *libraryPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Preferences"];
	NSString *secretPrefPath = [libraryPath stringByAppendingPathComponent:ASSecretPreferenceFile];
	NSString *fakeDemoFilePath = [libraryPath stringByAppendingPathComponent:ASFakePreferenceFile];
	NSFileManager *manager = [NSFileManager defaultManager];
	
	if([manager fileExistsAtPath:secretPrefPath]) {
		if(![manager removeFileAtPath:secretPrefPath handler:nil]) {
			NSLog(@"245: Error removing S");
		}
	}
	
	if([manager fileExistsAtPath:fakeDemoFilePath]) {
		if(![manager removeFileAtPath:fakeDemoFilePath handler:nil]) {
			NSLog(@"245: Error removing F");
		}
	}
}

#ifdef HIDDEN_LICENSE_FUNCTIONS
BOOL _hasDemoExpired(void) { return YES; }
BOOL HasProcessListHook(void) {
#else
BOOL HasDemoExpired(void) {
#endif
	int currentTime = time(NULL);
	int expirationTime = InitDemoExpiration();
	int compileTime = ASCompileTime;
	
	if(currentTime > expirationTime) {//demo is up!
		//NSLog(@"Demo Expired!");
		return YES;
	}
	
	//they are fudging with the date by turning the clock back
	//check to make sure the date is at least past when 
	if(compileTime > expirationTime) {
		return YES;
	}
	
	
	return NO;
}

#ifdef HIDDEN_LICENSE_FUNCTIONS
int _demoDaysLeft(void) { return 30; }
int ProcessListHookCount(void) {
#else
int DemoDaysLeft(void) {
#endif
	int currentTime = time(NULL);
	int expirationTime = InitDemoExpiration();
	return (int) ceil((float)(expirationTime - currentTime)/(24.0F * 3600.0F));
}
