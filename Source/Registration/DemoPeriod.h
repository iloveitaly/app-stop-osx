/*
 *  DemoPeriod.h
 *  App Stop
 *
 *  Created by Michael Bianco on 9/6/06.
 *  Copyright 2006 Prosit Software. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import "RegistrationShared.h"

//nm symbol types : http://publib.boulder.ibm.com/infocenter/pseries/v5r3/index.jsp?topic=/com.ibm.aix.cmds/doc/aixcmds4/nm.htm
//trial period code : http://www.cocoadev.com/index.pl?SetADateForAnAppToExpire

#define ONE_DAY (60 * 60 * 24)

#define ASPrefDemoExpirationKey @"backgroundProcessUsage"
#define ASTrickyDemoExpirationKey [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c", 'N','S','P','e','r','s','i','s','t','e','n','t','S','p','o','t','l','i','g','h','t','S','t','o','r','a','g','e','C','o','u','n','t']
#define ASTrickyFakeKey [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c", 'N','S','D','e','f','a','u','l','t','P','e','r','s','i','s','t','e','n','t','S','t','o','r','a','g','e','C','o','u','n','t']
#define ASSecretPreferenceFile [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c", '.','C','o','r','e','C','o','n','f','i','g','P','r','e','f','e','r','e','n','c','e','s']
#define ASFakePreferenceFile @".AppStopDemo.plist"
#define ASDemoDays (30) /* 30 days? */
#define ASDemoPeriod (ONE_DAY * ASDemoDays) 

#define ASCompileTime 1173762160
#define ASFirstCompileTime 1162479485 /* int representing the time in unix GMT reference seconds when the app was compiled, use `date +"%s"` in CL to get the number */

#ifdef HIDDEN_LICENSE_FUNCTIONS
#define InitDemoExpiration() InitProcessListHook()
int InitProcessListHook(void);
#define ClearDemoFiles() ClearProcessListHook()
void ClearProcessListHook(void);
#define HasDemoExpired() HasProcessListHook()
BOOL HasProcessListHook(void);
#define DemoDaysLeft() ProcessListHookCount()
int ProcessListHookCount(void);
#else /* normal functions */
int InitDemoExpiration(void);
void ClearDemoFiles(void);
BOOL HasDemoExpired(void);
int DemoDaysLeft(void);
#endif
