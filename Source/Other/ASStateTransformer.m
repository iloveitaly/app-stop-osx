#import "ASStateTransformer.h"

@implementation ASStateTransformer
//------------------------------------------
//		Superclass overides
//------------------------------------------
+ (Class) transformedValueClass {
	return [NSString class];
}

+ (BOOL) allowsReverseTransformation {
	return NO;
}

- (id) transformedValue:(id)value {
	if([value isEqualToString:@"Running"])
		return @"Pause";
	else 
		return @"Resume";
}
@end
