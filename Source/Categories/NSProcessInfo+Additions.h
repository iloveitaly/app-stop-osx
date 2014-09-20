#import <Cocoa/Cocoa.h>

@interface NSProcessInfo (MABAdditions)
-(NSString *) majorOSVersionString; //returns 10.x
-(NSString *) minorOSVersionString; //return 10.x.x
@end
