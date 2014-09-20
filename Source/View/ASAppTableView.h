//
//  ASAppTableView.h
//  App Stop
//
//  Created by Michael Bianco on 1/26/07.
//  Copyright 2007 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ASAppTableView : NSTableView {
	BOOL _preventsJumping;
}

- (void) setPreventsJumping:(BOOL)prevents;
@end
