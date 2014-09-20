/*
 Copyright (c) 2006 Michael Bianco, <software@mabwebdesign.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
 to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "MABLoginItems.h"

NSString *MABLoginPreferencesDomain = @"loginwindow";
NSString *MABLoginItemsKey = @"AutoLaunchedApplicationDictionary";

NSString *MABStartupItemPathKey = @"Path";
NSString *MABStartupItemHideKey = @"Hide";

@interface MABLoginItems (Private)
- (NSString *) _extractAppPath:(NSString *)path;
@end

@implementation MABLoginItems
- (id) init {
	if(self = [super init]) {
		_thisAppPath = [[self _extractAppPath:[[[NSProcessInfo processInfo] arguments] objectAtIndex:0]] retain];
		[self updateStartupItems];
	}

	return self;
}

- (void) dealloc {
	[_thisAppPath release];
	[_defaults release];
	[_loginDictionary release];
	[_startupItems release];
	[super dealloc];
}

- (void) updateStartupItems {
	// free all the previous items
	[_defaults release];
	[_loginDictionary release];
	[_startupItems release];
	
	_defaults = [NSUserDefaults new];
	
	if(!(_loginDictionary = [[_defaults persistentDomainForName:MABLoginPreferencesDomain] mutableCopy]))
		_loginDictionary = [NSMutableDictionary new];
	
	if(!(_startupItems = [[_loginDictionary objectForKey:MABLoginItemsKey] mutableCopy]))
		_startupItems = [NSMutableArray new];			
}

- (BOOL) isInStartupItems {
	return [self applicationIsInStartupItems:_thisAppPath];
}

- (void) addToStartupItems {
	[self addApplicationToStartupItems:_thisAppPath hide:NO];
}

- (void) removeFromStartupItems {
	[self removeApplicationFromStartupItems:_thisAppPath];
}

- (BOOL) applicationIsInStartupItems:(NSString *)path {
	int a = 0, l = [_startupItems count];
	NSString *tempPath = nil;
	
	for(; a < l; a++) {
		tempPath = [[_startupItems objectAtIndex:a] objectForKey:MABStartupItemPathKey];
		if([tempPath isEqualToString:path]) {
			return YES;
		}
	}
	
	return NO;
}

- (void) addApplicationToStartupItems:(NSString *)path hide:(BOOL)h {	
	if([self applicationIsInStartupItems:path])
		return;
		
	NSDictionary *newEntry = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:h], MABStartupItemHideKey, path, MABStartupItemPathKey, nil];
	
	// Add entry
	[_startupItems insertObject:newEntry atIndex:0];
	[_loginDictionary setObject:_startupItems forKey:MABLoginItemsKey];
	
	// Update user defaults
	[_defaults removePersistentDomainForName:MABLoginPreferencesDomain];
	[_defaults setPersistentDomain:_loginDictionary forName:MABLoginPreferencesDomain];
	[_defaults synchronize];	
}

- (void) removeApplicationFromStartupItems:(NSString *)path {
	int a = 0, l = [_startupItems count];
	NSString *tempPath = nil;
	
	for(; a < l; a++) {
		tempPath = [[_startupItems objectAtIndex:a] objectForKey:MABStartupItemPathKey];
		if([tempPath isEqualToString:path]) {
			[_startupItems removeObjectAtIndex:a];
			break;
		}
	}
	
	[_loginDictionary setObject:_startupItems forKey:MABLoginItemsKey];
	
	// Update user defaults
	[_defaults removePersistentDomainForName:MABLoginPreferencesDomain];
	[_defaults setPersistentDomain:_loginDictionary forName:MABLoginPreferencesDomain];
	[_defaults synchronize];
}

- (NSMutableArray *) startupItems {
	return _startupItems;	
}
@end

@implementation MABLoginItems (Private)
- (NSString *) _extractAppPath:(NSString *)path {
	// if we arent dealing with a cocoa app just return the path we started with
	if([path rangeOfString:@".app"].location == NSNotFound)
		return path;
	
	while(![[path pathExtension] isEqualToString:@"app"]) {//get to the .app
		path = [path stringByDeletingLastPathComponent];
	}
	
	return path;
}
@end
