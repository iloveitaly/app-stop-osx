//
//  ASPauseResumePreferences.m
//  App Stop
//
//  Created by Michael Bianco on 11/16/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "ASPauseResumePreferences.h"


@implementation ASPauseResumePreferences
- (NSString *) preferencesNibName {
	return @"ASPauseResumePreferences";
}

- (BOOL) hasChangesPending {
	return NO;
}

- (NSImage *) imageForPreferenceNamed:(NSString *) name {
	return [NSImage imageNamed:@"PausePrefs"];
}

- (BOOL) isResizable {
	return NO;
}

- (void) initializeFromDefaults {
	
}
@end
