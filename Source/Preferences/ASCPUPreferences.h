//
//  ASCPUPreferences.h
//  App Stop
//
//  Created by Michael Bianco on 11/16/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferences.h"

#define MABCPUINTERVAL @"cpuInterval"
#define ASUseAverageCPU @"averageCpu"
#define ASCpuUsageReporting @"cpuEnabled"

@interface ASCPUPreferences : NSPreferencesModule {
	
}

@end
