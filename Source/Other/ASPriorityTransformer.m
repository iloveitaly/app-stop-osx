#import "ASPriorityTransformer.h"
#import "ASGeneralPreferences.h"
#import "ASShared.h"

@implementation ASPriorityTransformer
//------------------------------------------
//		Superclass overides
//------------------------------------------
+ (Class) transformedValueClass {
	return [NSString class];
}

+ (BOOL) allowsReverseTransformation {
	return YES;
}

- (id) transformedValue:(id)value {
	int prio = [value intValue];

	if(PREF_KEY_BOOL(MABPRIORITYNUMERIC)) {
		return value;
	}
	
	if(prio > 10) {
		return @"Min";
	} else if(prio > 0) {
		return @"Low";
	} else if(prio == 0) {
		return @"Normal";
	} else if(prio < -10) {
		return @"Max";
	} else {
		return @"High";
	}
}

- (id) reverseTransformedValue:(id)value {
	NSString *strVal = [value lowercaseString];
	
	if([strVal isEqualToString:@"low"]) {
		[NSNumber numberWithInt:10];
	} else if([strVal isEqualToString:@"min"] || [strVal isEqualToString:@"minimum"]) {
		[NSNumber numberWithInt:20];
	} else if([strVal isEqualToString:@"high"]) {
		[NSNumber numberWithInt:-10];
	} else if([strVal isEqualToString:@"max"] || [strVal isEqualToString:@"maximum"]) {
		[NSNumber numberWithInt:-20];
	} else {
		return [NSNumber numberWithInt:0];
	}
}

@end
