//
//  TestController.h
//  RdpViewFramework
//
//  Created by Felix Deimel on 29.05.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestController : NSObject {
    
    NSWindow *window;
    NSView *sessionView;
    NSTextField *textFieldHostname;
    NSTextField *textFieldPort;
    NSTextField *textFieldStatus;
    
}

@property (assign) IBOutlet NSTextField *textFieldStatus;
@property (assign) IBOutlet NSTextField *textFieldPort;
@property (assign) IBOutlet NSTextField *textFieldHostname;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *sessionView;

- (IBAction)buttonConnect_Action:(id)sender;

@end
