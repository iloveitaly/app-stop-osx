//
//  ASStatusItemView.m
//  App Stop
//
//  Created by Michael Bianco on 9/13/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ASStatusItemView.h"
#import "ASStatusMenuController.h"

@implementation ASStatusItemView

- (id) initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(trackingDidEnd:)
													 name:NSMenuDidEndTrackingNotification
												   object:nil];
		
		_statusController = [ASStatusMenuController sharedController];
    }
	
    return self;
}

- (void) drawRect:(NSRect)rect {
	[[_statusController statusItem] drawStatusBarBackgroundInRect:[self frame] withHighlight:_drawHighlight];
	[super drawRect:rect];
}

- (void) mouseDown:(NSEvent *) theEvent {
	//NSLog(@"Event %@ : %i", theEvent, ([theEvent modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask);	
	_drawHighlight = YES;
	[self setNeedsDisplay:YES];
		
	//dont pop-up the menu if the command key is pressed, or if there is no menu
	if(([theEvent modifierFlags] & NSCommandKeyMask) != NSCommandKeyMask && [[_statusController statusMenu] numberOfItems] != 0) {
		// this seems to be causing alot of memory usage for some reason
		[[_statusController statusItem] popUpStatusItemMenu:[_statusController statusMenu]];
	} else {// only perform action if cmd is held down
		[_target performSelector:_action withObject:self];
	}
}

- (void) mouseUp:(NSEvent *)theEvent {
	_drawHighlight = NO;
	[self setNeedsDisplay:YES];
}

- (void) trackingDidEnd:(NSNotification *)note {
	_drawHighlight = NO;
	[self setNeedsDisplay:YES];
}

- (void) setTarget:(id)object {
	[object retain];
	[_target release];
	_target = object;
}

- (id) target {
	return _target;	
}

- (void) setAction:(SEL)action {
	_action = action;	
}

- (SEL) action {
	return _action;	
}

@end
