//
//  NSString+Additions.m
//  App Stop
//
//  Created by Michael Bianco on 11/28/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (MABAdditions)

- (BOOL) containsString:(NSString *)aString {
    return [self containsString:aString ignoringCase:YES];
}

- (BOOL) containsString:(NSString *)aString ignoringCase:(BOOL)flag {
    unsigned mask = (flag ? NSCaseInsensitiveSearch : 0);
    return [self rangeOfString:aString options:mask].length > 0;
}

- (NSString *) trimWhiteSpace {
	NSMutableString *s = [[self mutableCopy] autorelease];
	
	CFStringTrimWhitespace ((CFMutableStringRef) s);
	
	return (NSString *) [[s copy] autorelease];
}
@end