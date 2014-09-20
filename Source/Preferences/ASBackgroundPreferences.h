//
//  ASBackgroundPreferences.h
//  App Stop
//
//  Created by Michael Bianco on 11/16/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferences.h"

#define ASBGProcessEnabled @"bgProcEnabled"
#define ASProcessUpdateInterval @"procUpdateInterval"
#define ASBGProcessesInMenu @"menuHasBGApps"
#define ASShowZombieProcesses @"zombieProcesses"

@interface ASBackgroundPreferences : NSPreferencesModule {
	
}

@end
