//
//  NSAttributedString+Additions.h
//  App Stop
//
//  Created by Michael Bianco on 11/14/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAttributedString (ASAdditions)
+ (NSAttributedString *) attributedStringWithString:(NSString *)str color:(NSColor *)clr;
+ (NSAttributedString *) attributedStringWithString:(NSString *)str color:(NSColor *)clr size:(float)s;
- (NSAttributedString *) initWithString:(NSString *)str color:(NSColor *)clr size:(float)s;
@end
