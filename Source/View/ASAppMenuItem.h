#import <Cocoa/Cocoa.h>

#define MENU_ITEM_STATE ([_targetApp state] ? NSOnState : NSOffState)

@class ASAppRef;

@interface ASAppMenuItem : NSMenuItem {}
- (id) initWithAppRef:(ASAppRef *)app;
@end
