//
//  ASBackgroundPreferences.m
//  App Stop
//
//  Created by Michael Bianco on 11/16/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "ASBackgroundPreferences.h"


@implementation ASBackgroundPreferences
- (NSString *) preferencesNibName {
	return @"ASBackgroundPreferences";
}

- (BOOL) hasChangesPending {
	return NO;
}

- (NSImage *) imageForPreferenceNamed:(NSString *) name {
	return [NSImage imageNamed:@"BackgroundPrefs"];
}

- (BOOL) isResizable {
	return NO;
}

- (void) initializeFromDefaults {
	
}
@end
