//
//  mRemoteController.h
//  mRemoteMac
//
//  Created by Felix Deimel on 16.03.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "mrSession.h"
#import "CordRdpOptions.h"

@interface remojoRdesktopController : NSObject <NSApplicationDelegate, mrSessionDelegate> {
    NSWindow *mainWindow;
    NSView *sessionView;
    
    mrSession *currentSession;
    mrDisplayMode displayMode;
    
    id parentController;
}

@property (nonatomic, retain) NSView *sessionView;

- (id)initWithParentController:(id)parent andMainWindow:(NSWindow*)window;

- (void)connectWithOptions:(CordRdpOptions*)options;
- (void)disconnect;

- (void)connectInstance:(mrSession*)inst;
- (void)disconnectInstance:(mrSession*)inst;
- (void)connectAsync:(mrSession*)inst;
- (NSImage*)getScreenshot;

@end
