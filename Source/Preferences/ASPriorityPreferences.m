//
//  ASPriorityPreferences.m
//  App Stop
//
//  Created by Michael Bianco on 12/13/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "ASPriorityPreferences.h"
#import "ASPriorityDefaults.h"
#import "ASGeneralPreferences.h"

NSString *ASPriorityDefaultsEnabled = @"priorityDefaultsEnabled";
NSString *ASAutoRecordDefaults = @"autoRecordPriorityDefaults";

@implementation ASPriorityPreferences
- (NSString *) preferencesNibName {
	return @"ASPriorityPreferences";
}

- (BOOL) hasChangesPending {
	return NO;
}

- (NSImage *) imageForPreferenceNamed:(NSString *) name {
	return [NSImage imageNamed:@"PriorityPrefs"];
}

- (BOOL) isResizable {
	return NO;
}

- (void) saveChanges {
	[[ASPriorityDefaults sharedController] saveDefaults];
}

- (void) initializeFromDefaults {
	static BOOL hasInited = NO;
	
	[self _createPriorityDefaults];
	
	if(!hasInited) {
		[oPriorityDefaultsTable setRowHeight:20.0];
		[oPriorityDefaultsTable reloadData];
		[oPriorityDefaultsTable setNeedsDisplay:YES];
		[[ASPriorityDefaults sharedController] addObserver:self forKeyPath:@"defaults" options:0 context:NULL];
		hasInited = YES;
	}
}

- (IBAction) clearDefaults:(id)sender {
	if(NSRunAlertPanel(NSLocalizedString(@"Confirm", nil),
					   NSLocalizedString(@"Are you sure you want to delete all entries in the priority defaults? This action cannot be undone.", nil),
					   NSLocalizedString(@"Yes", nil), NSLocalizedString(@"No", nil), nil) == NSAlertDefaultReturn) {
		[[ASPriorityDefaults sharedController] setValue:[NSMutableDictionary dictionary] forKey:@"priorityDefaults"];
		[self _createPriorityDefaults];
		[oPriorityDefaultsTable reloadData];
	}
}

- (IBAction) add:(id)sender {
	[oPriorityDefaultsTable selectRow:[_priorityDefaults count] byExtendingSelection:NO];
	[oPriorityDefaultsTable editColumn:0 row:[_priorityDefaults count] withEvent:nil select:YES];
}

- (IBAction) remove:(id)sender {
	int row = [oPriorityDefaultsTable selectedRow];
	NSString *name = [[_priorityDefaults objectAtIndex:row] valueForKey:@"name"];
	[[ASPriorityDefaults sharedController] deletePriorityForApplicationNamed:name];
	
	// remember, when we delete something from the database the table is immediatly updated
	// if there is still something left in the table, select the previous row for convience
	if([_priorityDefaults count] > 0)
		[oPriorityDefaultsTable selectRow:row - 1 byExtendingSelection:NO];
}

- (BOOL) canRemove {
	return _canRemove;
}

- (void) setCanRemove:(BOOL)can {
	_canRemove = can;	
}

- (void) _createPriorityDefaults {
	//NSLog(@"Rebuild");
	[_priorityDefaults release];
	_priorityDefaults = [NSMutableArray new];
	
	NSDictionary *defaults = [[ASPriorityDefaults sharedController] defaults];
	NSEnumerator *keys = [[defaults allKeys] objectEnumerator], *values = [[defaults allValues] objectEnumerator];
	id temp;
	
	while(temp = [keys nextObject]) {
		[_priorityDefaults addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:temp, @"name", [values nextObject], @"priority", nil]];
	}
	
	[_priorityDefaults sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
}

- (int) numberOfRowsInTableView:(NSTableView *)aTableView {
	return [_priorityDefaults count] + 1;
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if(rowIndex == [_priorityDefaults count]) {
		return @"";
	}
	
	if([[aTableColumn identifier] isEqualToString:@"name"]) {
		return [[_priorityDefaults objectAtIndex:rowIndex] valueForKey:@"name"];
	} else {//priority
		if(PREF_KEY_BOOL(MABPRIORITYNUMERIC))
			return [[_priorityDefaults objectAtIndex:rowIndex] valueForKey:@"priority"];
		else
			return [[NSValueTransformer valueTransformerForName:@"ASPriorityTransformer"] transformedValue:[[_priorityDefaults objectAtIndex:rowIndex] valueForKey:@"priority"]];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	// if we adding a new row
	if(rowIndex == [_priorityDefaults count] || [[aTableColumn identifier] isEqualToString:@"name"]) {
		if(isEmpty(anObject)) //make sure we are actually adding something
			return;
		
		[[ASPriorityDefaults sharedController] setPriority:0 forApplicationNamed:anObject];
		
		int newIndex = [_priorityDefaults indexOfObject:[NSDictionary dictionaryWithObjectsAndKeys:anObject, @"name", [NSNumber numberWithInt:0], @"priority", nil]];
		[oPriorityDefaultsTable selectRow:newIndex byExtendingSelection:NO];
		[oPriorityDefaultsTable editColumn:1 row:newIndex withEvent:nil select:YES];
		return;
	}
	
	NSString *oldAppName = [[_priorityDefaults objectAtIndex:rowIndex] valueForKey:@"name"];
	NSNumber *oldPriority = [[_priorityDefaults objectAtIndex:rowIndex] valueForKey:@"priority"];
	
	if([[aTableColumn identifier] isEqualToString:@"name"]) {
		[[ASPriorityDefaults sharedController] deletePriorityForApplicationNamed:oldAppName];
		[[ASPriorityDefaults sharedController] setPriority:[oldPriority intValue] forApplicationNamed:anObject];
	} else {//priority
		int prio = [anObject intValue];
		
		if(prio == 0)
			prio = [[[NSValueTransformer valueTransformerForName:@"ASPriorityTransformer"] reverseTransformedValue:anObject] intValue];
		
		// check bounds
		if(prio > 20 || prio < -20)
			prio = 0;
		
		[[ASPriorityDefaults sharedController] setPriority:prio forApplicationNamed:oldAppName];
	}
	
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	// disable editing of the 'new' priority column
	return rowIndex != [_priorityDefaults count] || [[aTableColumn identifier] isEqualToString:@"name"];
}

- (void) tableViewSelectionDidChange:(NSNotification *)aNotification {
	[self setCanRemove:[oPriorityDefaultsTable selectedRow] != -1 && [oPriorityDefaultsTable selectedRow] != [_priorityDefaults count]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([[_preferencesView window] isVisible]) {
		//NSLog(@"Changed!");
		[self _createPriorityDefaults];
		[oPriorityDefaultsTable reloadData];
	}
}
@end
