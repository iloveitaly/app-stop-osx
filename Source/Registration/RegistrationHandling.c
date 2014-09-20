/*
 *  RegistrationHandling.c
 *  DictPod
 *
 *  Created by Michael Bianco on 3/15/06.
 *  Copyright 2006 Prosit Software. All rights reserved.
 *
 */

#import <CoreFoundation/CoreFoundation.h>

#import "RegistrationHandling.h"
#import "AquaticPrime.h"
#import "MABSupportFolderController.h"
#import "ASGeneralPreferences.h"
#import "ASShared.h"

#ifdef HIDDEN_LICENSE_FUNCTIONS
static NSDictionary *_someCoolDictionary = nil;
#define _licenseDictionary _someCoolDictionary
#else
static NSDictionary *_licenseDictionary = nil;
#endif

int RunInvalidLicenseAlert(void) {
	int result = NSRunAlertPanel(NSLocalizedString(@"Invalid License", nil),
								 NSLocalizedString(@"The license file you have chosen is invalid. If you know you have a valid license file, please contact customer support and we will resolve this issue. If you haven't yet purchased a license file, you can do so at our web-site.", nil),
								 NSLocalizedString(@"Buy License", nil),
								 NSLocalizedString(@"Contact Support", nil),
								 NSLocalizedString(@"Buy Later", nil));
	
	switch(result) {
		case NSAlertDefaultReturn: //then they want to buy the license
			OPEN_URL(PURCHASE_URL);
			break;
		case NSAlertAlternateReturn: //then they want to contact support
			OPEN_URL(SUPPORT_URL);
			break;
	}
	
	return result;
}

int RunSuccessfulLicenseAlert(void) {
	return NSRunInformationalAlertPanel(NSLocalizedString(@"Success!", nil),
										NSLocalizedString(@"App Stop has been successfully licensed!", nil),
										nil, nil, nil);	
}

void RunLoadLicensePanel(void) {
	//make an open file dialog to load the license file
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	
	if([panel runModalForTypes:[NSArray arrayWithObject:ASLicenseFileExtension]] == NSOKButton) {//choose a license file
		//get the path of file chosen
		NSString *licenseFile = [[panel filenames] objectAtIndex:0];
		
		//memory leak here... we should autorelease the dictionary...
		if(APCreateDictionaryForLicenseFile((CFURLRef)[NSURL fileURLWithPath:licenseFile]) != nil) {//successfull validation of the license
			[[MABSupportFolderController sharedController] createSupportFolder];
			
			if(![[NSFileManager defaultManager] copyPath:licenseFile 
												  toPath:[[[MABSupportFolderController sharedController] supportFolder] stringByAppendingPathComponent:ASLicenseFileName]
												 handler:nil]) {
				NSLog(@"Error copying license file");
				return;
			}
			
			if(!IsRegistered()) {//check again, just in case, just to make sure the license file chosen is a valid license
				RunInvalidLicenseAlert();
			} else {//the license loaded was a valid license
				RunSuccessfulLicenseAlert();
				
				//reconfigure the menu items and notify any observers that we are registered!
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:MABAppRegisteredNotification object:nil]];
			}
		} else {//then their was an error validating the license
			RunInvalidLicenseAlert();
			return;	
		}
	} else {//didn't choose a license
		//maybe show another alert panel here asking the user to buy a license?
		return;
	}				
}

int RunBuyNowAlert(void) {
	//maybe do this in the future, it would make it easier to handle different license situations
	return 0;
}

#ifdef HIDDEN_LICENSE_FUNCTIONS
BOOL PreCreateDictionary(void) {
#else
BOOL CheckLicense(void) {
#endif
	if(!IsRegistered()) {
		int result = 0;
		result = NSRunAlertPanel(NSLocalizedString(@"Purchase App Stop", nil),
								 NSLocalizedString(@"App Stop requires you a license to use. You can try out App Stop for 30 days, but after that point it will not work.", nil),
								 NSLocalizedString(@"Buy License", nil),
								 NSLocalizedString(@"Load License", nil),
								 NSLocalizedString(@"Use Demo", nil));
		
		switch(result) {
			case NSAlertDefaultReturn: //then they want to buy a license
				OPEN_URL(PURCHASE_URL);
				return NO;
			case NSAlertAlternateReturn: //then they want to load a license file
				RunLoadLicensePanel();
				return NO;
			case NSAlertOtherReturn: //then they want to use the demo
				return YES;
				break;
		}
	} else {//then the program is already registered
		return YES;	
	}
	
	 //the executation should never reach this point, but it makes the compiler happy
	return NO;
}

#ifdef HIDDEN_LICENSE_FUNCTIONS
NSDictionary *LicenseDictionaryReference(void) { return nil; } /* fake license dictionary reference to fool hackers */
NSDictionary *DictionaryDataReference(void) {
#else
NSDictionary *LicenseDictionary(void) {
#endif
	extern NSDictionary *_licenseDictionary;
	IsRegistered();
	
	return _licenseDictionary;
}

#ifdef HIDDEN_LICENSE_FUNCTIONS
BOOL _isRegistered() { return NO; } /* fake isRegistered() function to fool people */
BOOL IsValidDictionaryBundle() {
#else
BOOL IsRegistered(void) {
#endif
	static BOOL isKeySet = NO;
	static BOOL setKeyError = NO;
	
	NSString *supportFolder, *licenseFile;
	NSURL *licenseURL;
	NSDictionary *licenseDict;
		
	if(!isKeySet) {//if the key isn't already created, create the key and register it
		// This string is specially constructed to prevent key replacement

		// *** Begin Public Key ***
		NSMutableString *key = [NSMutableString string];
		[key appendString:@"0xC2DC31BD4"];
		[key appendString:@"3"];
		[key appendString:@"3"];
		[key appendString:@"7E60F635C1D8B2404"];
		[key appendString:@"E75E8A937205C"];
		[key appendString:@"4"];
		[key appendString:@"4"];
		[key appendString:@"6819D7D21930E59"];
		[key appendString:@"50C20C7CF1"];
		[key appendString:@"0"];
		[key appendString:@"0"];
		[key appendString:@"C6046AF9E170D8A6F4"];
		[key appendString:@"6741414E0F6089E3D864683"];
		[key appendString:@"6"];
		[key appendString:@"6"];
		[key appendString:@"47937"];
		[key appendString:@"2BF1D085A05C0F4F"];
		[key appendString:@"3"];
		[key appendString:@"3"];
		[key appendString:@"242F82913417"];
		[key appendString:@"5CA"];
		[key appendString:@"2"];
		[key appendString:@"2"];
		[key appendString:[NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c", '4','8','5','B','3','A','4','E','A','1','C','1','2','D','A','2','7','C','D','5','8','3','F','D','8']];
		[key appendString:@"BC20"];
		[key appendString:@"8"];
		[key appendString:@"8"];
		[key appendString:@"54290B8A6A400A934EFEC124"];
		[key appendString:@"AF1"];
		[key appendString:@"D"];
		[key appendString:@"D"];
		[key appendString:@"D51D46470E4C2CA98303948DF"];
		[key appendString:@"32470CEB6242EBFABD"];
		// *** End Public Key *** 

		if(APSetKey((CFStringRef) key) == FALSE) {
			NSLog(@"Error setting key");
			setKeyError = YES;
		}
		
		isKeySet = YES;
	}
	
	//release previously created dictionary
	[_licenseDictionary release];
	_licenseDictionary = nil;
		
	if(setKeyError) {//if their was an error setting the public key
		return NO;	
	}

	if(![[MABSupportFolderController sharedController] isSupportFolderCreated]) {//if the support folder isn't created then the license cant be located there
		return NO;	
	}
	
	if(!(supportFolder = [[MABSupportFolderController sharedController] supportFolder])) {
#if REGISTRATION_DEBUG
		NSLog(@"Error getting support folder");
#endif
		return NO;	
	}
	
	licenseFile = [supportFolder stringByAppendingPathComponent:ASLicenseFileName];

	if(![[NSFileManager defaultManager] fileExistsAtPath:licenseFile]) {
#if REGISTRATION_DEBUG
		NSLog(@"No license file found!");
#endif
		return NO;
	}
	
	licenseURL = [NSURL fileURLWithPath:licenseFile];
	
	if(!licenseURL) {
#if REGISTRATION_DEBUG
		NSLog(@"Error creating license URL");
#endif
		return NO;
	}
	
	licenseDict = (NSDictionary *) APCreateDictionaryForLicenseFile((CFURLRef) licenseURL);

	if(licenseDict == NULL) {
		return NO;	
	}
	
	extern NSDictionary *_licenseDictionary;
	
	_licenseDictionary = licenseDict; //maybe retain this in the future?
	
	return YES;
}
