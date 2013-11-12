//
//  mrSwappedModifiersUtility.h
//  mRemoteMac
//
//  Created by Felix Deimel on 18.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface mrSwappedModifiersUtility : NSObject
{
}

+ (void)loadStandardTranslation;
+ (unsigned)physicalModifiersForVirtualFlags:(unsigned)flags;
+ (BOOL)modifiersAreSwapped;

@end