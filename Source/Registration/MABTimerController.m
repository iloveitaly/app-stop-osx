//
//  MABTimerController.m
//  App Stop
//
//  Created by Michael Bianco on 9/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MABTimerController.h"
#import "ASMainController.h"
#import "RegistrationHandling.h"
#import "DemoPeriod.h"

static MABTimerController *_sharedController;

@implementation MABTimerController
+ (MABTimerController *) sharedController {
	extern MABTimerController *_sharedController;
	if(!_sharedController) [self new];
	return _sharedController;
}

- (id) init {
	if ((self = [super init]) != nil) {
		extern MABTimerController *_sharedController;
		_sharedController = self;

		[self configure];
	}
	
	return self;
}


- (void) configure {
	if(_nagTimer) {
		[_nagTimer invalidate];
		[_nagTimer release];
		_nagTimer = nil;
	}
	
	if(!IsRegistered()) {
		_nagTimer = [[NSTimer scheduledTimerWithTimeInterval:(60 * 60 * (24 * 2)) //every 2 days
													  target:self
													selector:@selector(timerFired:)
													userInfo:nil
													 repeats:YES] retain];
	}
}

- (void) timerFired:(NSTimer *)time {
	//NSLog(@"Show Nag");
	//this displays the nag and makes sure everything is cousure with the registration stuff
	[[ASMainController sharedController] applicationDidFinishLaunching:nil];
}

- (void) applicationRegistered:(NSNotification *) note {
	[self configure];
}
@end
