//
//  ASCPUPreferences.m
//  App Stop
//
//  Created by Michael Bianco on 11/16/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "ASCPUPreferences.h"


@implementation ASCPUPreferences
- (NSString *) preferencesNibName {
	return @"ASCPUPreferences";
}

- (BOOL) hasChangesPending {
	return NO;
}

- (NSImage *) imageForPreferenceNamed:(NSString *) name {
	return [NSImage imageNamed:@"CpuPrefs"];
}

- (BOOL) isResizable {
	return NO;
}

- (void) initializeFromDefaults {
	
}
@end
