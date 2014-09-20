//
//  MABTimerController.h
//  App Stop
//
//  Created by Michael Bianco on 9/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MABTimerController : NSObject {
	NSTimer *_nagTimer;
}

+ (MABTimerController *) sharedController;

- (void) configure;
- (void) timerFired:(NSTimer *)time;
- (void) applicationRegistered:(NSNotification *) note;
@end
