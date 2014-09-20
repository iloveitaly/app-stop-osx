//
//  ASAppWindowController.m
//  App Stop
//
//  Created by Michael Bianco on 9/3/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Carbon/Carbon.h> /* floating window constants */

#import "ASAppWindowController.h"
#import "ASMainController.h"
#import "ASPriorityDefaults.h"
#import "ASAppTableArrayController.h"
#import "ASAppListController.h"
#import "OATextWithIconCell.h"
#import "RSVerticallyCenteredTextFieldCell.h"
#import "DKActionButton.h"

// Preferences
#import "ASBackgroundPreferences.h"
#import "ASCPUPreferences.h"
#import "ASGeneralPreferences.h"
#import "ASShared.h"

static ASAppWindowController *_sharedController;

@implementation ASAppWindowController
+ (ASAppWindowController *) sharedController {
	extern ASAppWindowController *_sharedController;
	if(!_sharedController) [self new];
	return _sharedController;
}

//------------------------------------------
//		Superclass Overides
//------------------------------------------
- (id) init {
	if ((self = [super init]) != nil) {
		extern ASAppWindowController *_sharedController;
		_sharedController = self;
		
		PREF_OBSERVE_VALUE(@"values.mainWindowFloat", self);
		PREF_OBSERVE_VALUE(@"values.numericUserDisplay", self);
		PREF_OBSERVE_VALUE(@"values.cpuEnabled", self);
		PREF_OBSERVE_VALUE(@"values.iconSize", self);
	}
	
	return self;
}

- (void) awakeFromNib {
	// action menu confiration
	NSMenu *popupMenu = [NSMenu new];
	[popupMenu addItem:[[NSMenuItem new] autorelease]];
	[popupMenu addItemWithTitle:NSLocalizedString(@"Select Paused Applications", nil) action:@selector(selectPausedApplications:) keyEquivalent:@""];
	[popupMenu addItemWithTitle:NSLocalizedString(@"Select Running Applications", nil) action:@selector(selectRunningApplications:) keyEquivalent:@""];
	[popupMenu addItem:[NSMenuItem separatorItem]];
	[popupMenu addItemWithTitle:NSLocalizedString(@"Update Application List", nil) action:@selector(updateCpuAndAppList:) keyEquivalent:@""];
	[[popupMenu itemArray] makeObjectsPerformSelector:@selector(setTarget:) withObject:self];
	[[oAppTableActionButton cell] setMenu:popupMenu];
	
	// add application wide shortcuts
	[[ASMainController sharedController] addMenuItemsToGlobalMenu:oMenuAdditions];

	//set the default button on the priority window
	[oNewPriorityDefault addItemsWithObjectValues:[NSArray arrayWithObjects:@"Maximum", @"High", @"Normal", @"Low", @"Minimum", nil]];
	[oNewPriorityDefault setUsesDataSource:NO];
	[oNewPriorityDefault setCompletes:YES];
	[oSetPriorityWindow setDefaultButtonCell:[oSetPriorityButton cell]];
	
	//setup window levels
	[self configureAppTableWindow];
}

//------------------------------------------
//			Action Methods
//------------------------------------------
- (IBAction) updateCpuAndAppList:(id)sender {
	if(PREF_KEY_BOOL(ASBGProcessEnabled)) {
		[self updateApplicationList:sender];
	}
	
	if(PREF_KEY_BOOL(ASCpuUsageReporting)) {
		[self updateCpuUsage:sender];
	}
}

- (IBAction) updateCpuUsage:(id)sender {
	[[ASAppListController sharedController] _updateCpuUsage:nil];
}

- (IBAction) updateApplicationList:(id)sender {
	[[ASAppListController sharedController] _updateProcList:nil];
}

- (IBAction) selectPausedApplications:(id)sender {
	NSArray *tempSel = [[ASAppTableArrayController sharedController] arrangedObjects];
	NSMutableIndexSet *pausedApps = [[NSMutableIndexSet alloc] init];
	int a = 0, l = [tempSel count];
	
	for(; a < l; a++) {
		if([(ASAppRef *)[tempSel objectAtIndex:a] state] == NO) {//if the app is paused add it to the list
			[pausedApps addIndex:a];
		}
	}
	
	[[ASAppTableArrayController sharedController] setSelectionIndexes:pausedApps];
	[oAppTableWindow makeFirstResponder:oAppTable];
	[pausedApps release];
}

- (IBAction) selectRunningApplications:(id)sender {
	NSArray *tempSel = [[ASAppTableArrayController sharedController] arrangedObjects];
	NSMutableIndexSet *runningApps = [[NSMutableIndexSet alloc] init];
	int a = 0, l = [tempSel count];
	
	for(; a < l; a++) {
		if([(ASAppRef*)[tempSel objectAtIndex:a] state] == YES) {//if the app is paused add it to the list
			[runningApps addIndex:a];
		}
	}
	
	[[ASAppTableArrayController sharedController] setSelectionIndexes:runningApps];
	[oAppTableWindow makeFirstResponder:oAppTable];
	[runningApps release];	
}

- (IBAction) openSetPrioritySheet:(id)sender {
	NSArray *selected = [[ASAppTableArrayController sharedController] selectedObjects];
	if([selected count] == 1)
		[oAppTableWindow setTitle:[NSString stringWithFormat:@"Application Manager: Setting Default Priority For %@", [[selected objectAtIndex:0] appName]]];
	else
		[oAppTableWindow setTitle:@"Application Manager: Setting Default Priority"];
	
	[NSApp beginSheet:oSetPriorityWindow modalForWindow:oAppTableWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction) submitPrioritySheet:(id)sender {
	if(isEmpty([oNewPriorityDefault stringValue])) {
		NSBeep();
		return;
	}
	
	int prio = [oNewPriorityDefault intValue];
	
	if(prio == 0) {
		prio = [[[NSValueTransformer valueTransformerForName:@"ASPriorityTransformer"] reverseTransformedValue:[oNewPriorityDefault stringValue]] intValue];
		
		// check to make sure it was a valid string
		if(prio == 0 && ![[[oNewPriorityDefault stringValue] lowercaseString] isEqualToString:@"normal"]) {
			NSBeep();
			return;
		}
	} else if(prio > 20 || prio < -20) {// check the range for non-string priority values
		NSBeep();
		return;
	}
	
	/*
	NSLog(@"Set priority: %i", prio);
	NSLog(@"Selected %@", [[ASAppTableArrayController sharedController] selectedObjects]);
	*/
	
	NSArray *selected = [[ASAppTableArrayController sharedController] selectedObjects];
	int l = [selected count];
	while(l--) {
		[[ASPriorityDefaults sharedController] setPriority:prio forApplication:[selected objectAtIndex:l]];
	}
	
	[self closeSetPrioritySheet:sender];
}

- (IBAction) closeSetPrioritySheet:(id)sender {
	[oSetPriorityWindow orderOut:self];
	[NSApp endSheet:oSetPriorityWindow];
	[oAppTableWindow setTitle:@"Application Manager"];
}

//------------------------------------------
//		Config Methods
//-----------------------------------------
- (void) configureAppTableWindow {
	if(PREF_KEY_BOOL(ASFloatAppTableWindow)) {
		[oAppTableWindow setLevel:kFloatingWindowClass];
	} else {//if we dont want to float above all others
		[oAppTableWindow setLevel:NSNormalWindowLevel];
	}	
}

- (void) configureAppTable {
	static BOOL didSetupCells = NO;
	
	// make sure we only setup the cells once
	if(!didSetupCells) {
		// set all cells except the first one to use centered cell
		NSArray *columns = [oAppTable tableColumns];
		id centeredCell = [RSVerticallyCenteredTextFieldCell new];
		int a = 1, l = [columns count];
		
		for(; a < l; a++) {
			[[columns objectAtIndex:a] setDataCell:centeredCell];
		}
		
		OATextWithIconCell *textIconCell = [OATextWithIconCell new];
		[textIconCell setImageKey:@"appIcon"];
		[textIconCell setTextKey:@"appName"];
		
		[[oAppTable tableColumnWithIdentifier:@"name"] setDataCell:textIconCell];
		[oAppTable setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
		[oAppTable setFocusRingType:NSFocusRingTypeNone];
		[oAppTable setRowHeight:[PREF_KEY_VALUE(ASAppIconSize) intValue] + 4];
		
		[centeredCell release];
		[textIconCell release];
		
		didSetupCells = YES;
	}
	
	// Setup the UID column
	if(!PREF_KEY_BOOL(ASNumericUserDisplay)) {
		NSTableColumn *uidCol = [oAppTable tableColumnWithIdentifier:@"uid"];
		[uidCol bind:@"value"
			toObject:[ASAppTableArrayController sharedController]
		 withKeyPath:@"arrangedObjects.uidAsString"
			 options:nil];
	} else {
		NSTableColumn *uidCol = [oAppTable tableColumnWithIdentifier:@"uid"];
		[uidCol bind:@"value"
			toObject:[ASAppTableArrayController sharedController]
		 withKeyPath:@"arrangedObjects.uid"
			 options:nil];
	}
	
	// Setup the CPU column
	if(PREF_KEY_BOOL(ASCpuUsageReporting)) {
		if([oAppTable columnWithIdentifier:@"cpu"] != -1) {//if the column is already in place we dont need to add it again
			return;
		}
		
		NSTableColumn *cpuColumn = [[NSTableColumn alloc] initWithIdentifier:@"cpu"];
		[cpuColumn setDataCell:[[RSVerticallyCenteredTextFieldCell new] autorelease]];
		[[cpuColumn headerCell] setTitle:@"CPU"];
		[cpuColumn setSortDescriptorPrototype:[[[NSSortDescriptor alloc] initWithKey:@"cpuUsage" ascending:YES selector:@selector(compare:)] autorelease]];
		[cpuColumn bind:@"value"
			   toObject:[ASAppTableArrayController sharedController] 
			withKeyPath:@"arrangedObjects.cpuUsageString"
				options:nil];
		
		[oAppTable addTableColumn:cpuColumn];
		[cpuColumn release];
	} else {
		[oAppTable removeTableColumn:[oAppTable tableColumnWithIdentifier:@"cpu"]];
	}	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath hasSuffix:ASFloatAppTableWindow]) {
		[self configureAppTableWindow];
	} else if([keyPath hasSuffix:ASNumericUserDisplay] || [keyPath hasSuffix:ASCpuUsageReporting]) {
		[self configureAppTable];
	} else if([keyPath hasSuffix:ASAppIconSize]) {
		[oAppTable setRowHeight:[PREF_KEY_VALUE(ASAppIconSize) intValue] + 4];
	}
}

- (BOOL) validateMenuItem:(id <NSMenuItem>)menuItem {
	//NSLog(@"Validate");
	return YES;
}
@end
