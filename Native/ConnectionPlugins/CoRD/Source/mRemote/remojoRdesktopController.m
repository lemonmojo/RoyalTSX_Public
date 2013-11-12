//
//  mRemoteController.m
//  mRemoteMac
//
//  Created by Felix Deimel on 16.03.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

#import "remojoRdesktopController.h"
#import "mrSessionView.h"
#import "mrShared.h"
#import "ConnectionStatusArguments.h"

@implementation remojoRdesktopController

@synthesize sessionView;

+ (void)initialize {
    
}

- (id)init {
	if (![super init])
		return nil;
    
	return self;
}
- (id)initWithParentController:(id)parent andMainWindow:(NSWindow*)window {
    if (![super init])
		return nil;
    
    parentController = parent;
    mainWindow = window;
    
	return self;
}
- (void)dealloc {
    [currentSession release];
    currentSession = nil;
    
    [sessionView release];
    sessionView = nil;
    
	[super dealloc];
}

- (void)awakeFromNib {	
	[mainWindow makeKeyAndOrderFront:self];
    mainWindow.acceptsMouseMovedEvents = YES;
}

- (NSResponder *)application:(NSApplication *)application shouldForwardEvent:(NSEvent *)ev {
	mrSessionView *viewedSessionView = currentSession.view;
	NSWindow *viewedSessionWindow = [viewedSessionView window];
	
	BOOL shouldForward = YES;
	
	shouldForward &= ([ev type] == NSKeyDown) || ([ev type] == NSKeyUp) || ([ev type] == NSFlagsChanged);
	shouldForward &= ([viewedSessionWindow firstResponder] == viewedSessionView) && [viewedSessionWindow isKeyWindow] && ([viewedSessionWindow isMainWindow] || (displayMode == mrDisplayFullscreen));
    
	return shouldForward ? viewedSessionView : nil;
}

- (void)connectionStatusChanged:(mrConnectionStatus)newStatus forInstance:(mrSession*)inst {
    ConnectionStatusArguments *args = [[ConnectionStatusArguments alloc] initWithStatus:newStatus andErrorNumber:(int)[inst conn]->errorCode];
    
    if (newStatus != mrConnectionClosed) {
        if (parentController && [parentController respondsToSelector:@selector(sessionStatusChanged:)])
            [parentController performSelectorOnMainThread:@selector(sessionStatusChanged:) withObject:args waitUntilDone:NO];
    } else {
        if (parentController && [parentController respondsToSelector:@selector(sessionStatusChanged:)])
            [parentController performSelectorOnMainThread:@selector(sessionStatusChanged:) withObject:args waitUntilDone:YES];
    }
}

- (void)connectionStatusChanged:(NSArray*)argArray {
    mrConnectionStatus status = [(NSNumber*)[argArray objectAtIndex:0] intValue];
    mrSession *session = (mrSession*)[argArray objectAtIndex:1];
    
    [self connectionStatusChanged:status forInstance:session];
}

- (void)connectWithOptions:(CordRdpOptions*)options {
    sessionView = [[[NSView alloc] init] retain];
    sessionView.frame = NSRectFromCGRect(CGRectMake(0, 0, options.screenWidth, options.screenHeight));
    sessionView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    displayMode = mrDisplayUnified;
    
    mrSession* session = [[mrSession alloc] init];
    session.delegate = self;
    session.hostName = options.hostname;
    session.port = options.port;
    
    session.username = options.username;
    session.domain = options.domain;
    session.password = options.password;
    
    session.consoleSession = options.connectToConsole;
    
    [session setValue:[NSNumber numberWithInteger:options.screenWidth] forKey:@"screenWidth"];
    [session setValue:[NSNumber numberWithInteger:options.screenHeight] forKey:@"screenHeight"];
    [session setValue:[NSNumber numberWithInteger:options.colorDepth] forKey:@"screenDepth"];
    [session setValue:[NSNumber numberWithInteger:options.allowWallpaper] forKey:@"drawDesktop"];
    [session setValue:[NSNumber numberWithInteger:options.allowAnimations] forKey:@"windowAnimation"];
    [session setValue:[NSNumber numberWithInteger:options.fontSmoothing] forKey:@"fontSmoothing"];
    [session setValue:[NSNumber numberWithInteger:options.showWindowContentsWhileDragging] forKey:@"windowDrags"];
    [session setValue:[NSNumber numberWithInteger:options.showThemes] forKey:@"themes"];
    [session setValue:[NSNumber numberWithInteger:options.redirectDiskDrives] forKey:@"forwardDisks"];
    [session setValue:[NSNumber numberWithInteger:options.redirectDiskDrives] forKey:@"forwardPrinters"];
    [session setValue:[NSNumber numberWithInteger:options.audioRedirectionMode] forKey:@"forwardAudio"];
    
    currentSession = session;
    
    [self connectInstance:currentSession];  
}

// Starting point to connect to a instance
- (void)connectInstance:(mrSession*)inst {
	if (!inst)
		return;
	
	if ([inst status] == mrConnectionConnecting || [inst status] == mrConnectionDisconnecting)
		return;
	
	if ([inst status] == mrConnectionConnected)
		[self disconnectInstance:inst];
    
	[NSThread detachNewThreadSelector:@selector(connectAsync:) toTarget:self withObject:inst];
}

- (void)disconnect {
    [self disconnectInstance:currentSession];
}

// Assures that the passed instance is disconnected and removed from view. Main thread only.
- (void)disconnectInstance:(mrSession *)inst {
    //[sessionView setDocumentView:nil];
    
	if (!inst)
		return;
    
	if ([inst status] == mrConnectionConnected)
		[inst disconnect];
    else if([inst status] == mrConnectionConnecting)
        [inst cancelConnection];
    
	[[inst retain] autorelease];
}

- (void)instanceDisconnected:(mrSession*)session {
    [self disconnectInstance:session];
}

- (void)connectAsync:(mrSession*)inst {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	BOOL connected = [inst connect];
	
	[self performSelectorOnMainThread:@selector(completeConnection:) withObject:inst waitUntilDone:NO];
    
	if (connected)
		[inst runConnectionRunLoop]; // this will block until the connection is finished
    
	if ([inst status] == mrConnectionConnected)
		[self performSelectorOnMainThread:@selector(disconnectInstance:) withObject:inst waitUntilDone:YES];
	
	[pool release];
}

- (void)completeConnection:(mrSession *)inst {
	if ([inst status] == mrConnectionConnected) {
        [inst createUnified:YES enclosure:sessionView.frame];
        [sessionView addSubview:inst.scrollEnclosure];
        //[sessionView addSubview:inst.view];
        //[sessionView setDocumentView:inst.view];
        [mainWindow makeFirstResponder:[inst view]];
	} else {
		/* RDConnectionError errorCode = [inst conn]->errorCode;
		
		if (errorCode != ConnectionErrorNone && errorCode != ConnectionErrorCanceled) {
			NSString *localizedErrorDescriptions[] = {
                @"No error", //shouldn't ever occur
                NSLocalizedString(@"The connection timed out.", @"Connection errors -> Timeout"),
                NSLocalizedString(@"The host name could not be resolved.", @"Connection errors -> Host not found"), 
                NSLocalizedString(@"There was an error connecting.", @"Connection errors -> Couldn't connect"),
                NSLocalizedString(@"You canceled the connection.", @"Connection errors -> User canceled")
            };
            
			NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Couldn't connect to %@",
                                                                           @"Connection error alert -> Title"), [inst label]];
			
			NSAlert *alert = [NSAlert alertWithMessageText:title 
											 defaultButton:NSLocalizedString(@"Retry", @"Connection errors -> Retry button") 
										   alternateButton:NSLocalizedString(@"Cancel",@"Connection errors -> Cancel button") 
											   otherButton:nil 
								 informativeTextWithFormat:localizedErrorDescriptions[errorCode]];
			[alert setAlertStyle:NSCriticalAlertStyle];
			
			// Retry if requested
			if ([alert runModal] == NSAlertDefaultReturn)
				[self connectInstance:inst];
		} */
	}	
}

- (NSImage*)getScreenshot {
    if (!currentSession || (currentSession && !currentSession.view))
        return nil;
    
    return [[currentSession view] getScreenCapture];
}


@end
