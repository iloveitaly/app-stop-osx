/*
 *  ASPSNUtil.h
 *  App Stop
 *
 *  Created by Michael Bianco on 12/11/06.
 *  Copyright 2006 Prosit Software. All rights reserved.
 *
 */

#import <Carbon/Carbon.h>

bool IsAppHidden(int p);
void HideAppWithPid(int p);
void ShowAppWithPid(int p);

CFDictionaryRef InformationDictionaryForPID(int p);
