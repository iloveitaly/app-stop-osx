//
//  ASAppWindowController.h
//  App Stop
//
//  Created by Michael Bianco on 9/3/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DKActionButton;

@interface ASAppWindowController : NSObject {
	IBOutlet DKActionButton *oAppTableActionButton;
	IBOutlet NSTableView *oAppTable;
	IBOutlet NSWindow *oAppTableWindow;
	IBOutlet NSMenu *oMenuAdditions;
	
	IBOutlet NSWindow *oSetPriorityWindow;
	IBOutlet NSButton *oSetPriorityButton;
	IBOutlet NSComboBox *oNewPriorityDefault;
}

+ (ASAppWindowController *) sharedController;

//------------------------------------------
//		Action Methods
//-----------------------------------------
- (IBAction) updateCpuAndAppList:(id)sender;
- (IBAction) updateCpuUsage:(id)sender;
- (IBAction) updateApplicationList:(id)sender;
- (IBAction) selectPausedApplications:(id)sender;
- (IBAction) selectRunningApplications:(id)sender;
- (IBAction) openSetPrioritySheet:(id)sender;
- (IBAction) submitPrioritySheet:(id)sender;
- (IBAction) closeSetPrioritySheet:(id)sender;

//------------------------------------------
//		Config Methods
//-----------------------------------------
- (void) configureAppTableWindow;
- (void) configureAppTable;

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
- (BOOL) validateMenuItem:(id <NSMenuItem>)menuItem;
@end
