/*
 Copyright (c) 2006 Michael Bianco, <software@mabwebdesign.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
 to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DKActionButtonCell.h"

NSString *DKActionButtonDefaultImage = @"ActionMenu.tiff";

@implementation DKActionButtonCell
- (id) initTextCell:(NSString *)stringValue withImage:(NSImage *)img pullsDown:(BOOL)pullDown {
	if (self = [super initTextCell:stringValue pullsDown:YES]) {
		if(img) {
			_actionImage = [img retain];
		} else {
			_actionImage = [[NSImage imageNamed:DKActionButtonDefaultImage] retain];
		}
		
		_buttonCell = [[NSButtonCell alloc] initImageCell:_actionImage];
				
		[_buttonCell setButtonType:NSPushOnPushOffButton];
		[_buttonCell setImagePosition:NSImageOnly];
		[_buttonCell setImageDimsWhenDisabled:YES];
		[_buttonCell setBordered:NO];
		
		[self synchronizeTitleAndSelectedItem];
	}
	
	return self;
}

- (void) dealloc {
	[_buttonCell release];
	[_actionImage release];
	[super dealloc];
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[_buttonCell drawWithFrame:cellFrame inView:controlView];
}

- (void) highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[_buttonCell highlight:flag withFrame:cellFrame inView:controlView];
}
@end
