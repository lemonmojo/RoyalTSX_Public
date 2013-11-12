//
//  mRemoteApplication.m
//  mRemoteMac
//
//  Created by Felix Deimel on 16.03.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

#import "mRemoteApplication.h"

@implementation mRemoteApplication

- (void)sendEvent:(NSEvent *)ev {
	if (([ev type] == NSKeyDown) && 
        [[self menu] performKeyEquivalent:ev])
		return;
    
	if (([ev type] == NSKeyDown) && 
        ([[ev characters] isEqualToString:@"`"])) {
		[super sendEvent:ev];
		return;
	}
	
	NSResponder *forwardEventTo = [self.delegate application:self shouldForwardEvent:ev];
    
	if ((forwardEventTo != nil) && [forwardEventTo tryToPerform:[mRemoteApplication selectorForEvent:ev] with:ev])
		return;
    
	[super sendEvent:ev];
}

+ (SEL)selectorForEvent:(NSEvent *)ev {
	switch ([ev type]) {
		case NSKeyDown:	
			return @selector(keyDown:);
		case NSKeyUp:
			return @selector(keyUp:);
		case NSFlagsChanged:
			return @selector(flagsChanged:);
		default:
			return NULL;
	}
}

@end
