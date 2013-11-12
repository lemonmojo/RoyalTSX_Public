//
//  mrKeyboard.h
//  mRemoteMac
//
//  Created by Felix Deimel on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "rdesktop.h"

@class mrSession;

@interface mrKeyboard : NSObject
{
@private
    unsigned remoteModifiers;
    NSMutableDictionary *virtualKeymap;
    mrSession *controller;
}

@property (assign, nonatomic) mrSession *controller;

- (void)handleKeyEvent:(NSEvent *)ev keyDown:(BOOL)down;
- (void)handleFlagsChanged:(NSEvent *)ev;
- (void)sendKeycode:(uint8)keyCode modifiers:(uint16)rdflags pressed:(BOOL)down;
- (void)sendScancode:(uint8)scancode flags:(uint16)flags;

+ (unsigned int)windowsKeymapForMacKeymap:(NSString *)keymapIdentifier;
+ (NSString *)currentKeymapIdentifier;
+ (uint16)modifiersForEvent:(NSEvent *)ev; 

@end