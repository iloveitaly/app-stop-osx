#import "NSProcessInfo+Additions.h"

@implementation NSProcessInfo (MABAdditions)
- (NSString *) majorOSVersionString {
	NSString *osVersion = [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] valueForKey:@"ProductVersion"];
	return [osVersion substringToIndex:4];
}

- (NSString *) minorOSVersionString {
	NSString *osVersion = [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] valueForKey:@"ProductVersion"];
	return osVersion;
}
@end
