//
//  ASAdvancedPreferences.m
//  App Stop
//
//  Created by Michael Bianco on 1/16/07.
//  Copyright 2007 Prosit Software. All rights reserved.
//

#import "ASAdvancedPreferences.h"

NSString *ASEnableAdvancedPreferences = @"enableAdvancedPreferences";

@implementation ASAdvancedPreferences
- (NSString *) preferencesNibName {
	return @"ASAdvancedPreferences";
}

- (BOOL) hasChangesPending {
	return NO;
}

- (NSImage *) imageForPreferenceNamed:(NSString *) name {
	return [NSImage imageNamed:@""];
}

- (BOOL) isResizable {
	return NO;
}

@end
