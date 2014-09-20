//
//  ASStatusItemView.h
//  App Stop
//
//  Created by Michael Bianco on 9/13/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ASStatusMenuController;

@interface ASStatusItemView : NSImageView {
	ASStatusMenuController *_statusController;
	BOOL _drawHighlight;
	//id _target;
	//SEL _action;
}

- (void) setTarget:(id)object;
- (id) target;
- (void) setAction:(SEL)action;
- (SEL) action;
@end
