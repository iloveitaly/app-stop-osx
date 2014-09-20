//
//  ASInvertSliderTransformer.m
//  App Stop
//
//  Created by Michael Bianco on 11/15/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import "ASInvertSliderTransformer.h"

@implementation ASInvertSliderTransformer
+ (Class) transformedValueClass {
	return [NSNumber class];
}

+ (BOOL) allowsReverseTransformation {
	return YES;
}

- (id) transformedValue:(id)value {
	return [NSNumber numberWithInt:-[value intValue]];
}

- (id) reverseTransformedValue:(id)value {
	return [NSNumber numberWithInt:-[value intValue]];
}

@end
