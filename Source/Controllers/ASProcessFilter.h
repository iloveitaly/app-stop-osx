//
//  ASProcessFilter.h
//  App Stop
//
//  Created by Michael Bianco on 12/12/06.
//  Copyright 2006 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AGProcess;

@interface ASProcessFilter : NSObject {

}

+ (ASProcessFilter *) sharedController;

- (NSArray *) filterIntArray:(int *) array;
- (BOOL) processIsFiltered:(AGProcess *)ref;

@end
