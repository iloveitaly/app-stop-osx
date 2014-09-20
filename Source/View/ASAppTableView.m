//
//  ASAppTableView.m
//  App Stop
//
//  Created by Michael Bianco on 1/26/07.
//  Copyright 2007 Prosit Software. All rights reserved.
//

#import "ASAppTableView.h"


@implementation ASAppTableView
- (void) setPreventsJumping:(BOOL)prevents {
	_preventsJumping = prevents;
}

- (void) scrollRowToVisible:(int)rowIndex {
	if(_preventsJumping)
		return;
	
	[super scrollRowToVisible:rowIndex];
}
@end
