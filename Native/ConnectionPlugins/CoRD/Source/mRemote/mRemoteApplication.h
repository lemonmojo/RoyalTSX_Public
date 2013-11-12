//
//  mRemoteApplication.h
//  mRemoteMac
//
//  Created by Felix Deimel on 16.03.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface mRemoteApplication : NSApplication {
    
}

+ (SEL)selectorForEvent:(NSEvent *)ev;

@end

@interface NSObject (mRemoteApplicationDelegate)
- (NSResponder *)application:(NSApplication *)application shouldForwardEvent:(NSEvent *)ev;
@end