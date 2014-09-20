#import <Cocoa/Cocoa.h>

// Filter type constants
typedef enum {
	ASAllFilterType = 1,
	ASNameFilterType,
	ASStatusFilterType,
	ASPidFilterType,
	ASPriorityFilterType,
	ASUserNameFilterType
} ASFilterType;

@class AppRef, ASAppTableView;

@interface ASAppTableArrayController : NSArrayController {
	IBOutlet NSSearchField *oSearchField;
	IBOutlet ASAppTableView *oAppManager;
	NSString *_searchString;
	ASFilterType _type;
	AppRef *_newObject;
}

+ (ASAppTableArrayController *) sharedController;

//------------------------------------------
//		Action Methods
//------------------------------------------
- (IBAction) killSelectedApp:(id)sender;
- (IBAction) toggleSelectedApp:(id)sender;
- (IBAction) increasePriorityForSelectedApps:(id)sender;
- (IBAction) decreasePriorityForSelectedApps:(id)sender;
- (IBAction) search:(id)sender;
- (IBAction) setSearchType:(id)sender;

- (void) secretRearrangeObjects;

//------------------------------------------
//		Getter & Setters
//-----------------------------------------
- (NSString *) searchString;
- (void) setSearchString:(NSString *)s;

- (AppRef *) newObject;
- (void) setNewObject:(id)object;
@end
