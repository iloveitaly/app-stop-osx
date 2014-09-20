//
//  ASPriorityDefaults.h
//  App Stop
//
//  Created by Michael Bianco on 12/13/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *ASPriorityDefaultsFileName;

@class ASAppRef;

@interface ASPriorityDefaults : NSObject {
	NSMutableDictionary *_priorityDefaults;
	NSString *_defaultsPath;
}

+ (ASPriorityDefaults *) sharedController;

- (void) saveDefaults;
- (NSMutableDictionary *) defaults;

- (int) priorityForApplication:(ASAppRef *)app;
- (int) priorityForApplicationNamed:(NSString *)name;

- (void) setPriority:(int)prio forApplication:(ASAppRef *)app;
- (void) setPriority:(int)prio forApplicationNamed:(NSString *)name;

- (void) deletePriorityForApplication:(ASAppRef *)app;
- (void) deletePriorityForApplicationNamed:(NSString *)name;

@end
