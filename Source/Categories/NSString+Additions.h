//
//  NSString+Additions.h
//  App Stop
//
//  Created by Michael Bianco on 11/28/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (MABAdditions)

- (BOOL)containsString:(NSString *)aString;
- (BOOL)containsString:(NSString *)aString ignoringCase:(BOOL)flag;
- (NSString *) trimWhiteSpace;

@end