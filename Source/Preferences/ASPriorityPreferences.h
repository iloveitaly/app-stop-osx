//
//  ASPriorityPreferences.h
//  App Stop
//
//  Created by Michael Bianco on 12/13/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferences.h"

extern NSString *ASPriorityDefaultsEnabled;
extern NSString *ASAutoRecordDefaults;

@interface ASPriorityPreferences : NSPreferencesModule {
	IBOutlet NSTableView *oPriorityDefaultsTable;
	NSMutableArray *_priorityDefaults;
	BOOL _canRemove;
}

- (IBAction) clearDefaults:(id)sender;
- (IBAction) add:(id)sender;
- (IBAction) remove:(id)sender;

- (BOOL) canRemove;
- (void) setCanRemove:(BOOL)can;
@end
