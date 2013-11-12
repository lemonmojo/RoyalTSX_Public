//
//  AppDelegate.m
//  RdpViewTester
//
//  Created by Felix Deimel on 29.05.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

#import "AppDelegate.h"
#import <RdpView/RdpViewLibrary.h>
#import <RdpView/remojoRdesktopController.h>
#import <RdpView/ConnectionStatusArguments.h>
#import <RdpView/mrShared.h>

@implementation AppDelegate

@synthesize textFieldPort;
@synthesize textFieldHostname;
@synthesize window;
@synthesize buttonConnect;
@synthesize textFieldStatus;
@synthesize sessionView;

remojoRdesktopController *ctrl;
mrConnectionStatus status;

- (void)dealloc {
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (IBAction)buttonConnect_Action:(id)sender {
    if (!ctrl)
        ctrl = (remojoRdesktopController*)getRdpViewController(self, self.window);
    
    CordRdpOptions *options = [[CordRdpOptions alloc] init];
    options.hostname = textFieldHostname.stringValue;
    options.port = textFieldPort.intValue;
    options.screenWidth = sessionView.frame.size.width;
    options.screenHeight = sessionView.frame.size.height;
    options.username = @"fx";
    options.domain = @"";
    options.password = @"!qwe1991";
    options.connectToConsole = YES;
    options.smartSize = YES;
    options.colorDepth = 24;
    
    if (status == mrConnectionClosed)
        [ctrl connectWithOptions:options];
    else if (status == mrConnectionConnected)
        [ctrl disconnect];
}

- (void)sessionStatusChanged:(ConnectionStatusArguments*)args {
    status = args.status;
    
    if (status == mrConnectionConnecting)
        textFieldStatus.stringValue = @"Connecting";
    else if (status == mrConnectionConnected) {
        textFieldStatus.stringValue = @"Connected";
        [self.sessionView addSubview:ctrl.sessionView];
    } else if (status == mrConnectionDisconnecting)
        textFieldStatus.stringValue = @"Disconnecting";
    else if (status == mrConnectionClosed) {
        textFieldStatus.stringValue = @"Closed";
        [ctrl.sessionView removeFromSuperview];
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    NSLog(@"width: %i; height: %i", (int)sessionView.frame.size.width, (int)sessionView.frame.size.height);
}

@end
