//
//  NSAttributedString+Additions.m
//  App Stop
//
//  Created by Michael Bianco on 11/14/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "NSAttributedString+Additions.h"

//Menuitem Font-size: http://www.cocoabuilder.com/archive/message/cocoa/2005/7/13/141729
//Changing color: http://www.cocoabuilder.com/archive/message/cocoa/2002/5/17/58184

@implementation NSAttributedString (ASAdditions)
+ (NSAttributedString *) attributedStringWithString:(NSString *)str color:(NSColor *)clr {
	return [self attributedStringWithString:str color:clr size:14.0];
}

+ (NSAttributedString *) attributedStringWithString:(NSString *)str color:(NSColor *)clr size:(float)s {
	return [[[NSAttributedString alloc] initWithString:str color:clr size:s] autorelease];
}

- (NSAttributedString *) initWithString:(NSString *)str color:(NSColor *)clr size:(float)s {
	NSDictionary *atr = [NSDictionary dictionaryWithObjectsAndKeys:clr, NSForegroundColorAttributeName, [NSFont systemFontOfSize:s], NSFontAttributeName, nil];
	if(self = [self initWithString:str attributes:atr]) {
		
	}
	
	return self;
}
@end
