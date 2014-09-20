//
//  ASPriorityDefaults.m
//  App Stop
//
//  Created by Michael Bianco on 12/13/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "ASPriorityDefaults.h"
#import "ASAppRef.h"
#import "MABSupportFolderController.h"

NSString *ASPriorityDefaultsFileName = @"priority_defaults.plist";

static ASPriorityDefaults *_sharedController;

@implementation ASPriorityDefaults

+ (ASPriorityDefaults *) sharedController {
	extern ASPriorityDefaults *_sharedController;
	if(!_sharedController) [self new];
	return _sharedController;		
}

- (id) init {
	if ((self = [super init]) != nil) {
		extern ASPriorityDefaults *_sharedController;
		_sharedController = self;
		
		_defaultsPath = [[[[MABSupportFolderController sharedController] supportFolder] stringByAppendingPathComponent:ASPriorityDefaultsFileName] retain];
		_priorityDefaults = [[NSMutableDictionary dictionaryWithContentsOfFile:_defaultsPath] retain];

		if(isEmpty(_priorityDefaults)) {
			_priorityDefaults = [NSMutableDictionary new];
		}
		
		NSLog(@"Priority Defaults: %@", _priorityDefaults);
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:@"NSApplicationWillTerminateNotification" object:nil];
	}

	return self;
}

- (void) saveDefaults {
	[[MABSupportFolderController sharedController] createSupportFolder];
	
	if(![_priorityDefaults writeToFile:_defaultsPath atomically:YES]) {
		NSLog(@"Error writing priority defaults file");
	}
}

- (NSMutableDictionary *) defaults {
	return _priorityDefaults;	
}

- (int) priorityForApplication:(ASAppRef *)app {
	return [self priorityForApplicationNamed:[app appName]];
}

- (int) priorityForApplicationNamed:(NSString *)name {
	return [[_priorityDefaults valueForKey:name] intValue];
}

- (void) setPriority:(int)prio forApplication:(ASAppRef *)app {
	[self setPriority:prio forApplicationNamed:[app appName]];
}

- (void) setPriority:(int)prio forApplicationNamed:(NSString *)name {
	[self willChangeValueForKey:@"defaults"];
	[_priorityDefaults setValue:[NSNumber numberWithInt:prio] forKey:name];
	[self didChangeValueForKey:@"defaults"];
}

- (void) deletePriorityForApplication:(ASAppRef *)app {
	[self deletePriorityForApplicationNamed:[app appName]];
}

- (void) deletePriorityForApplicationNamed:(NSString *)name {
	[self willChangeValueForKey:@"defaults"];
	[_priorityDefaults removeObjectForKey:name];
	[self didChangeValueForKey:@"defaults"];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification {
	[self saveDefaults];
}
@end
