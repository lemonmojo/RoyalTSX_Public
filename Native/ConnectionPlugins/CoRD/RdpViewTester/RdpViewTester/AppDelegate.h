//
//  AppDelegate.h
//  RdpViewTester
//
//  Created by Felix Deimel on 29.05.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    NSWindow *window;
    NSButton *buttonConnect;
    NSTextField *textFieldStatus;
    NSView *sessionView;
    NSTextField *textFieldHostname;
    NSTextField *textFieldPort;
}

@property (assign) IBOutlet NSTextField *textFieldPort;
@property (assign) IBOutlet NSTextField *textFieldHostname;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *buttonConnect;
@property (assign) IBOutlet NSTextField *textFieldStatus;
@property (assign) IBOutlet NSView *sessionView;
- (IBAction)buttonConnect_Action:(id)sender;

@end
