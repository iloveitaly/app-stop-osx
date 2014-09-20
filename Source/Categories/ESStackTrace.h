//
//  NSException+ESStackTrace.h
//  App Stop
//
//  Created by Michael Bianco on 11/21/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

void CB_exceptionHandler(NSException *exception);

@interface NSException (ESStackTrace)
- (void) printStackTrace;
@end

@interface NSApplication (ESExceptionHandling)
- (void) reportException:(NSException *)anException;
@end
