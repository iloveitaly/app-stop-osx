#import "ASAppMenuItem.h"
#import "ASAppRef.h"
#import "NSAttributedString+Additions.h"
#import "ASCPUPreferences.h"
#import "ASShared.h"

@implementation ASAppMenuItem
//------------------------------------------
//		Constructor Methods
//------------------------------------------
- (id) initWithAppRef:(ASAppRef *)app {
	if(self = [self init]) {
		//register for changes in the target app
		OB_OBSERVE_VALUE(@"state", self, app);
		OB_OBSERVE_VALUE(@"cpuUsage", self, app);
		
		//register for cpu changes
		PREF_OBSERVE_VALUE(@"values.cpuEnabled", self);
		
		//set the title and target action information
		[self setTarget:app];
		[self setAction:@selector(toggle:)];
		[self _updateTitle];
		[self bind:@"image" //always keep the image updated
		  toObject:app
	   withKeyPath:@"appIcon"
		   options:nil];
	}
	
	return self;
}

//------------------------------------------
//		Action Methods
//------------------------------------------
- (void) _updateTitle {
	NSString *newTitle = nil;
	ASAppRef *target = [self target]; //create tempref for target so [self target] is only run once
	
	if(PREF_KEY_BOOL(ASCpuUsageReporting)) {
		newTitle = [NSString stringWithFormat:@"%@ %.1f%%", [target appName], [target cpuUsage]];
	} else {
		newTitle = [NSString stringWithFormat:@"%@", [target appName]];
	}

	if([target state] == NO) {//paused
		[self setAttributedTitle:[NSAttributedString attributedStringWithString:newTitle color:[NSColor redColor]]];
	} else {//running
		//attributed titles overide normal titles, must delete the attributed title first before setting the new title
		[self setAttributedTitle:nil]; 
		[self setTitle:newTitle];
	}
	
	//this will enable the check box state reporting...
	//[self setState:MENU_ITEM_STATE];
}

//------------------------------------------
//		Subclass overides
//------------------------------------------
- (BOOL) isEqual:(ASAppRef *)o {
	if([o isMemberOfClass:[ASAppRef class]]) {
		if(o == [self target])
			return YES;
		else 
			return NO;
	} else if([o isKindOfClass:[NSDictionary class]]) {
		if([[self target] pid] == [[o valueForKey:ASApplicationPIDKey] intValue]) //compare pids of the target program and the 
			return YES;
		else
			return NO;
	}
	
	return NO;
}

- (void) dealloc {
	id target = [self target];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.cpuEnabled"];
	[target unbind:@"image"];
	[target removeObserver:self forKeyPath:@"cpuUsage"];
	[target removeObserver:self forKeyPath:@"state"];
	[super dealloc];
}

//------------------------------------------
//		KVO Methods
//------------------------------------------
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath isEqualToString:@"cpuUsage"] || [keyPath hasSuffix:ASCpuUsageReporting] || [keyPath isEqualToString:@"state"]) {
		[self _updateTitle];
	}
}

@end
