/*
 *  ASPSNUtil.c
 *  App Stop
 *
 *  Created by Michael Bianco on 12/11/06.
 *  Copyright 2006 Prosit Software. All rights reserved.
 *
 */

#import "ASPSNUtil.h"
#import <unistd.h>

ProcessSerialNumber PID2PSN(pid_t pid) {
	ProcessSerialNumber tempPSN;
	GetProcessForPID(pid, &tempPSN);
	return tempPSN;
}

pid_t PSN2PID(ProcessSerialNumber psn) {
	pid_t tempPID;
	GetProcessPID(&psn, &tempPID);
	return tempPID;
}

void HideAppWithPid(pid_t p) {
	ProcessSerialNumber tempPSN = PID2PSN(p);
	ShowHideProcess(&tempPSN, false);		
}

void ShowAppWithPid(pid_t p) {
	ProcessSerialNumber tempPSN = PID2PSN(p);
	ShowHideProcess(&tempPSN, true);	
}

bool IsAppHidden(pid_t p) {
	ProcessSerialNumber tempPSN = PID2PSN(p);
	return !IsProcessVisible(&tempPSN);
}

CFDictionaryRef InformationDictionaryForPID(pid_t p) {
	ProcessSerialNumber tempPSN = PID2PSN(p);
	return ProcessInformationCopyDictionary(&tempPSN, kProcessDictionaryIncludeAllInformationMask);
}
