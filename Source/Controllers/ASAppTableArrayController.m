#import "ASAppTableArrayController.h"
#import "ASAppRef.h"
#import "ASMainController.h"
#import "ASAppTableView.h"
#import "ASAppListController.h"
#import "ASPriorityTransformer.h"
#import "ASGeneralPreferences.h"
#import "NSString+Additions.h"
#import "ASShared.h"

#define ASNameFilterKey @"appName"
#define ASStatusFilterKey @"stateAsString"
#define ASUserNameFilterKey @"uidAsString"
#define ASUIDFilterKey @"uid"
#define ASPriorityFilterKey @"priority"
#define ASPIDFilterKey @"pid"

static ASAppTableArrayController *_sharedController;

@implementation ASAppTableArrayController
//------------------------------------------
//		Superclass Overides
//------------------------------------------
+ (ASAppTableArrayController *) sharedController {
	extern ASAppTableArrayController *_sharedController;
	if(!_sharedController) [self new];
	return _sharedController;	
}

- (id) initWithCoder:(NSCoder *)decoder {
	if(self = [super initWithCoder:decoder]) {
		extern ASAppTableArrayController *_sharedController;
		_sharedController = self;
		
		_type = [PREF_KEY_VALUE(ASDefaultFilterType) intValue];
	}
	
	return self;
}

#pragma mark Overides

- (void) secretRearrangeObjects {
	[oAppManager setPreventsJumping:YES];
	[self rearrangeObjects];
	[oAppManager setPreventsJumping:NO];
}

- (NSArray *) arrangeObjects:(NSArray *)objects {	
	//if there is no search string
	if(isEmpty(_searchString)) {
		[self setNewObject:nil];
		return [super arrangeObjects:objects];
	}

	NSMutableArray *filteredObjects = [NSMutableArray arrayWithCapacity:[objects count]];
	int l = [objects count];
	id tempRef;
	
	ASPriorityTransformer *prioTrans = [ASPriorityTransformer new];
	int intCompare = [_searchString intValue];
	BOOL prioAsNum = PREF_KEY_BOOL(MABPRIORITYNUMERIC);
	
	// check to make sure that the user actually entered 0, and it didn't just return 0
	if(intCompare == 0 && [[_searchString trimWhiteSpace] characterAtIndex:0] != '0')
		intCompare = -1;
		
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	while(l--) {
		tempRef = [objects objectAtIndex:l];
		
		/*
		Also add any newly-created object unconditionally:
			(a) You'll get an error if a newly-added object isn't added to arrangedObjects.
			(b) The user will see newly-added objects even if they don't match the search term.
		*/			
		if(tempRef == _newObject) {
			if(tempRef == nil) {
				NSLog(@"Temp object in array filtering is nil. Please report!");
			}
			
			[filteredObjects addObject:tempRef];
			[self setNewObject:nil];
			continue;
		}

		switch(_type) {
			case ASNameFilterType:
				if([[tempRef valueForKey:ASNameFilterKey] containsString:_searchString]) {
					[filteredObjects addObject:tempRef];
				}
				
				break;
			case ASStatusFilterType:
				if([[tempRef valueForKey:ASStatusFilterKey] containsString:_searchString]) {
					[filteredObjects addObject:tempRef];
				}
				
				break;
			case ASUserNameFilterType:
				if([[tempRef valueForKey:ASUserNameFilterKey] containsString:_searchString]) {
					[filteredObjects addObject:tempRef];
				}
				
				break;
			case ASPidFilterType:
				if([[tempRef valueForKey:ASPIDFilterKey] intValue] == intCompare) {
					[filteredObjects addObject:tempRef];
				}
				
				break;
			case ASPriorityFilterType:
				if(prioAsNum) {
					if([[tempRef valueForKey:ASPriorityFilterKey] intValue] == intCompare) {
						[filteredObjects addObject:tempRef];
					}
				} else {
					if([[prioTrans transformedValue:[tempRef valueForKey:ASPriorityFilterKey]] containsString:_searchString]) {
						[filteredObjects addObject:tempRef];
					}
				}
				
				break;
			case ASAllFilterType:
				if([[tempRef valueForKey:ASNameFilterKey] containsString:_searchString] ||
				   [[tempRef valueForKey:ASStatusFilterKey] containsString:_searchString] ||
				   [[tempRef valueForKey:ASUserNameFilterKey] containsString:_searchString] ||
				   [[tempRef valueForKey:ASPIDFilterKey] intValue] == intCompare ||
				   (prioAsNum ? [[tempRef valueForKey:ASPriorityFilterKey] intValue] == intCompare : [[prioTrans transformedValue:[tempRef valueForKey:ASPriorityFilterKey]] containsString:_searchString])) {
					[filteredObjects addObject:tempRef];
				}
				
				break;
		}
	}
	
	[prioTrans release];
	[pool release];
	
	return [super arrangeObjects:filteredObjects];
}

- (void) addObjects:(NSArray *)array {
	[super addObjects:array];
	[self rearrangeObjects];
}

- (void) awakeFromNib {
	// set the state of the filter item which was previously selected
	[[[[oSearchField cell] searchMenuTemplate] itemWithTag:_type] setState:NSOnState];
	
	NSArray *filterItems = [[[oSearchField cell] searchMenuTemplate] itemArray];
	[filterItems makeObjectsPerformSelector:@selector(setAction:) withObject:@selector(setSearchType:)];
	[filterItems makeObjectsPerformSelector:@selector(setTarget:) withObject:self];
}

//------------------------------------------
//		Action Methods
//------------------------------------------
- (IBAction) killSelectedApp:(id)sender {
	NSArray *currentSelection = [self selectedObjects];
	int count = [currentSelection count];
	
	if(count > 1 && NSRunAlertPanel(@"Confirm", @"Are you sure you want to force quit %i applications?", @"No", @"Yes", nil, count) == NSAlertAlternateReturn) {
		int a = 0;
		for(; a < count; a++) {
			[[currentSelection objectAtIndex:a] killAppIgnoringAlert:YES];
		}
	} else if(count == 1) {			
		[[currentSelection objectAtIndex:0] killAppIgnoringAlert:NO];
	}
	
	//wait a little before updating the list... The applications need some time to quit
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.2]];
	[[ASAppListController sharedController] _updateProcList:nil];
	
}

- (IBAction) toggleSelectedApp:(id)sender {
	NSArray *tempSel = [self selectedObjects];
	int a = 0, l = [tempSel count];
	for(; a<l; a++)
		[[tempSel objectAtIndex:a] toggle:sender];
}

- (IBAction) increasePriorityForSelectedApps:(id)sender {
	NSArray *tempSel = [self selectedObjects];
	int l = [tempSel count];
	ASAppRef *tempRef; //create a temp ref so NSArray doesn't have to do objectAtIndex: twice
	while(l--) {
		tempRef = [tempSel objectAtIndex:l];
		
		// check priority bounds
		if([tempRef priority] - 1 < PRIO_MIN) {
			if([tempSel count] == 1) {
				NSBeep();
			}			
		} else {
			[tempRef setPriority:[tempRef priority] - 1]; //lower the better for prioritys
		}
	}
}

- (IBAction) decreasePriorityForSelectedApps:(id)sender {
	NSArray *tempSel = [self selectedObjects];
	int l = [tempSel count];
	ASAppRef *tempRef;
	
	while(l--) {
		tempRef = [tempSel objectAtIndex:l];

		// check priority bounds
		if([tempRef priority] + 1 > PRIO_MAX) {
			if([tempSel count] == 1) {
				NSBeep();
			}			
		} else {
			[tempRef setPriority:[tempRef priority] + 1]; //lower the better for priorities
		}
	}	
}

- (IBAction) search:(id)sender {
	[self setSearchString:[sender stringValue]];
	[self rearrangeObjects];
}

- (IBAction) setSearchType:(id)sender {
	// toggle item states
	[[[sender menu] itemWithTag:_type] setState:NSOffState];	
	[(NSMenuItem *)sender setState:NSOnState];
	
	// get the new filter type and save it
	_type = [sender tag];
	PREF_SET_KEY_VALUE(ASDefaultFilterType, [NSNumber numberWithInt:_type]);
	
	// resort array
	[self rearrangeObjects];
}

//------------------------------------------
//		Getter & Setters
//-----------------------------------------
- (NSString *) searchString {
	return _searchString;
}

- (void) setSearchString:(NSString *)s {
	[s retain];
	[_searchString release];
	_searchString = s;
}

- (AppRef *) newObject {
	return 	_newObject;
}

- (void) setNewObject:(id)object {
	// we only want to retain this object when there is some filtering going on
	// otherwise we dont need to reference it at all
	
	if(isEmpty(_searchString)) {
		[_newObject release];
		_newObject = nil;
	} else {		
		[object retain];
		[_newObject release];
		_newObject = object;
	}
}
@end
