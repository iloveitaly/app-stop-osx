#import "ASPreferenceController.h"

@implementation ASPreferenceController
- (id) init {
	_preferenceTitles = [[NSMutableArray array] retain];
	_preferenceModules = [[NSMutableArray array] retain];
	_currentSessionPreferenceViews = [[NSMutableDictionary dictionary] retain];
	_masterPreferenceViews = [[NSMutableDictionary dictionary] retain];
	return self;
}

- (BOOL) usesButtons {return NO;}
@end
