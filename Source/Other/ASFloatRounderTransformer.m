//
//  ASFloatRounderTransformer.m
//  App Stop
//
//  Created by Michael Bianco on 9/9/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ASFloatRounderTransformer.h"

@implementation ASFloatRounderTransformer
+ (Class) transformedValueClass {
	return [NSNumber class];
}

+ (BOOL) allowsReverseTransformation {
	return YES;
}

- (id) transformedValue:(id)value {
	return [NSNumber numberWithInt:[value intValue]];
}

- (id) reverseTransformedValue:(id)value {
	return [NSNumber numberWithInt:[value intValue]];
}
@end
