//
//  ASProcessFilter.m
//  App Stop
//
//  Created by Michael Bianco on 12/12/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "ASProcessFilter.h"
#import "ASAppListController.h"
#import "ASBackgroundPreferences.h"
#import "ASAppRef.h"
#import "AGProcess.h"

static ASProcessFilter *_sharedController;

@implementation ASProcessFilter
+ (ASProcessFilter *) sharedController {
	extern ASProcessFilter *_sharedController;
	if(!_sharedController) [self new];
	return _sharedController;	
}

- (id) init {
	if ((self = [super init]) != nil) {
		extern ASProcessFilter *_sharedController;
		_sharedController = self;
	}

	return self;
}


- (NSArray *) filterIntArray:(int *) array {
	extern int currentPid;
	extern int childPid;

	int a = 0;
	AGProcess *temp;
	NSMutableArray *returnArray = [NSMutableArray array];
	
	while(*(array + a) != -1) {
		// filter out App Stop & authnice
		if(*(array + a) == currentPid || *(array + a) == childPid) {
			a++;
			continue;
		}
		
		temp = [[AGProcess alloc] initWithProcessIdentifier:*(array + a)];
		
		if(temp && ![self processIsFiltered:temp]) {
			ASAppRef *newApp = [[ASAppRef alloc] initWithProcessReference:temp];
			[newApp setIsBackground:YES];
			[returnArray addObject:newApp];
			[newApp release];
		} else if(!temp) {
			// error creating AGProcess for this pid
			// the only way AGProcess can = nil is if the process has already exited
			DEBUG_LOG(NSLog(@"AGProcess is nil for pid %i", *(array + a)));
		}
		
		[temp release];
		
		a++;
	}
	
	return returnArray;
}

- (BOOL) processIsFiltered:(AGProcess *)proc {
	if(PREF_KEY_BOOL(ASShowZombieProcesses) == NO && [proc state] == AGProcessStateZombie) {
		//NSLog(@"Filtering... %@", ref);
		return YES;
	}
	
	return NO;
}

@end
