//
//  ASLicenseInfoController.m
//  App Stop
//
//  Created by Michael Bianco on 9/15/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ASLicenseInfoController.h"
#import "RegistrationHandling.h"

@implementation ASLicenseInfoController
- (id) init {
	if((self = [self initWithWindowNibName:@"LicenseInformation"]) != nil) {
		
	}
	
	return self;
}

- (NSString *) name {
	return [LicenseDictionary() valueForKey:@"Name"];
}

- (NSString *) email {
	return [LicenseDictionary() valueForKey:@"Email"];
}

- (NSString *) date {
	return [LicenseDictionary() valueForKey:@"Date"];
}

@end
