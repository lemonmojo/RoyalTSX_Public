//
//  mrSession.m
//  mRemoteMac
//
//  Created by Felix Deimel on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "mrSession.h"
#import "mrSessionView.h"
#import "mrKeyboard.h"
#import "remojoRdesktopController.h"
#import "keychain.h"
#import "RmCenteringClipView.h"

@interface mrSession (Private)
- (BOOL)readFileAtPath:(NSString *)path;
- (void)updateKeychainData:(NSString *)newHost user:(NSString *)newUser password:(NSString *)newPassword force:(BOOL)force;
- (void)setStatus:(mrConnectionStatus)status;
- (void)setStatusAsNumber:(NSNumber *)status;
- (void)createScrollEnclosure:(NSRect)frame;
- (void)createViewWithFrameValue:(NSValue *)frameRect;
- (void)setUpConnectionThread;
- (void)discardConnectionThread;
@end

#pragma mark -

@implementation mrSession

@synthesize delegate, username, domain, password, consoleSession, scrollEnclosure;

- (id)init
{
	if (![super init])
		return nil;
	
	rdpFilename = label = hostName = clientHostname = username = password = domain = @"";
	preferredRowIndex = -1;
	screenDepth = 16;
	isTemporary = themes = YES;
	hotkey = -1;
	forwardAudio = mrDisableAudio;
	fileEncoding = NSUTF8StringEncoding;
	
	// Other initialization
	otherAttributes = [[NSMutableDictionary alloc] init];
	
	inputEventStack = [[NSMutableArray alloc] init];
	
	[self setStatus:mrConnectionClosed];
	
	return self;
}

- (id)initWithPath:(NSString *)path
{
	if (![self init])
		return nil;
	
	if (![self readFileAtPath:path])
	{
		[self autorelease];
		return nil;
	}
	
	return self;
}

// Initializes using user's 'base connection' settings
- (id)initWithBaseConnection
{
	if (![self init])
		return nil;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	for (NSString *k in [NSArray arrayWithObjects:@"ConsoleSession", @"ForwardDisks", @"ForwardPrinters", @"DrawDesktop", @"WindowDrags", @"WindowAnimation", @"Themes", @"FontSmoothing", nil])
	{
		NSNumber *isChecked = [NSNumber numberWithBool:[[defaults valueForKey:[@"mrBaseConnection" stringByAppendingString:k]] boolValue]];
		
		[self setValue:isChecked forKey:[k lowercaseFirst]];
	}
	
	[self setValue:mrNumberForColorsText([defaults valueForKey:@"mrBaseConnectionColors"]) forKey:@"screenDepth"];
	
	[self setValue:[NSNumber numberWithInt:[[defaults valueForKey:@"mrBaseConnectionForwardAudio"] intValue]] forKey:@"forwardAudio"];
	
	[self setValue:[defaults valueForKey:@"mrBaseConnectionClientHostname"] forKey:@"clientHostname"];
    
	NSString *resolutionString = [defaults valueForKey:@"mrBaseConnectionScreenSize"];
	fullscreen = mrResolutionStringIsFullscreen(resolutionString);
    
	if (!fullscreen)
		mrSplitResolutionString(resolutionString, &screenWidth, &screenHeight);
    
	return self;
}

- (void)dealloc
{
	if (connectionStatus == mrConnectionConnected)
		[self disconnectAsync:[NSNumber numberWithBool:YES]];
    
	while (connectionStatus != mrConnectionClosed)
		usleep(1000);
	
	[inputEventPort invalidate];
	[inputEventPort release];
	[inputEventStack release];
	
	[label release];
	[hostName release];
	[clientHostname release];
	[username release];
	[password release];
	[domain release];
	[otherAttributes release];
	[rdpFilename release];
    
	[super dealloc];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return [otherAttributes objectForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	if (![[self valueForKey:key] isEqualTo:value])
	{
		modified |= ![key isEqualToString:@"view"];
		[super setValue:value forKey:key];
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	mrSession *newSession = [[mrSession alloc] init];
	
	newSession->label = [label copy];
	newSession->hostName = [hostName copy];
	newSession->clientHostname = [clientHostname copy];
	newSession->username = [username copy];
	newSession->password = [password copy];
	newSession->domain = [domain copy];
	newSession->otherAttributes = [otherAttributes copy];
	newSession->forwardDisks = forwardDisks; 
	newSession->forwardAudio = forwardAudio;
	newSession->forwardPrinters = forwardPrinters;
	newSession->savePassword = savePassword;
	newSession->drawDesktop = drawDesktop;
	newSession->windowDrags = windowDrags;
	newSession->windowAnimation = windowAnimation;
	newSession->themes = themes;
	newSession->fontSmoothing = fontSmoothing;
	newSession->consoleSession = consoleSession;
	newSession->fullscreen = fullscreen;
	newSession->screenDepth = screenDepth;
	newSession->screenWidth = screenWidth;
	newSession->screenHeight = screenHeight;
	newSession->port = port;
	newSession->modified = modified;
	newSession->hotkey = hotkey;
    
	return newSession;
}


#pragma mark -
#pragma mark Working with rdesktop

// Invoked on incoming data arrival, starts the processing of incoming packets
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent
{
	if (streamEvent == NSStreamEventErrorOccurred)
	{
        [delegate instanceDisconnected:self];
		return;
	}
    
	uint8 type;
	RDStreamRef s;
	uint32 ext_disc_reason;
	
	if (connectionStatus != mrConnectionConnected)
		return;
	
	do
	{
		s = rdp_recv(conn, &type);
		if (s == NULL)
		{
            [delegate instanceDisconnected:self];
			return;
		}
		
		switch (type)
		{
			case RDP_PDU_DEMAND_ACTIVE:
				process_demand_active(conn, s);
				break;
			case RDP_PDU_DEACTIVATE:
				DEBUG(("RDP_PDU_DEACTIVATE\n"));
				break;
			case RDP_PDU_DATA:
				if (process_data_pdu(conn, s, &ext_disc_reason))
				{
                    [delegate instanceDisconnected:self];
					return;
				}
				break;
			case RDP_PDU_REDIRECT:
				process_redirect_pdu(conn, s);
				break;
			case 0:
				break;
			default:
				unimpl("PDU %d\n", type);
		}
		
	} while ( (conn->nextPacket < s->end) && (connectionStatus == mrConnectionConnected) );
}

// Using the current properties, attempt to connect to a server. Blocks until timeout or failure.
- (BOOL)connect
{
	if (connectionStatus == mrConnectionDisconnecting)
	{
		time_t startTime = time(NULL);
		
		while (connectionStatus == mrConnectionDisconnecting)
			usleep(1000);
        
		if (time(NULL) - startTime > 10)
			mrLog(mrLogLevelError, @"Got hung up on old frozen connection while connecting to %@", label);
	}
	
	if (connectionStatus != mrConnectionClosed)
		return NO;
	
    [self setStatus:mrConnectionConnecting];
	
	free(conn);
	conn = malloc(sizeof(RDConnection));
	memset(conn, 0, sizeof(RDConnection));
	mrFillDefaultConnection(conn);
	conn->controller = self;
    
	// Fail quickly if it's a totally bogus host
	if (![hostName length])
	{
		connectionStatus = mrConnectionClosed;
		conn->errorCode = ConnectionErrorHostResolution;
		return NO;
	}
	
	// Set status to connecting on main thread so that the cell's progress indicator timer is on the main thread
	//[self performSelectorOnMainThread:@selector(setStatusAsNumber:) withObject:[NSNumber numberWithInt:mrConnectionConnecting] waitUntilDone:NO];
	
	//[g_appController performSelectorOnMainThread:@selector(validateControls) withObject:nil waitUntilDone:NO];
    
	// RDP5 performance flags
	unsigned performanceFlags = RDP5_DISABLE_NOTHING;
	if (!windowDrags)
		performanceFlags |= RDP5_NO_FULLWINDOWDRAG;
	
	if (!themes)
		performanceFlags |= RDP5_NO_THEMING;
	
	if (!drawDesktop)
		performanceFlags |= RDP5_NO_WALLPAPER;
	
	if (!windowAnimation)
		performanceFlags |= RDP5_NO_MENUANIMATIONS;
	
	if (fontSmoothing)
		performanceFlags |= RDP5_FONT_SMOOTHING;  
	
	conn->rdp5PerformanceFlags = performanceFlags;
	
    
	// Simple heuristic to guess if user wants to auto log-in
	unsigned logonFlags = RDP_LOGON_NORMAL;
	if ([username length] > 0 && ([password length] || savePassword))
		logonFlags |= RDP_LOGON_AUTO;
    
	if (consoleSession)
		logonFlags |= RDP_LOGON_LEAVE_AUDIO;
	
	logonFlags |= conn->useRdp5 ? RDP_LOGON_COMPRESSION2 : RDP_LOGON_COMPRESSION;
	
	// Other various settings
	conn->serverBpp = (screenDepth==8 || screenDepth==16 || screenDepth==24) ? screenDepth : 16;
	conn->consoleSession = consoleSession;
	conn->screenWidth = screenWidth ? screenWidth : mrDefaultScreenWidth;
	conn->screenHeight = screenHeight ? screenHeight : mrDefaultScreenHeight;
	conn->tcpPort = (!port || port>=65536) ? mrDefaultPort : port;
	strncpy(conn->username, mrMakeWindowsString(username), sizeof(conn->username));
    
	// Set remote keymap to match local OS X input type
	if (mrPreferenceIsEnabled(mrSetServerKeyboardLayout))
		conn->keyboardLayout = [mrKeyboard windowsKeymapForMacKeymap:[mrKeyboard currentKeymapIdentifier]];
	else
		conn->keyboardLayout = 0;
	
	if (forwardDisks)
	{
		NSMutableArray *validDrives = [NSMutableArray array], *validNames = [NSMutableArray array];
		
		if (mrPreferenceIsEnabled(mrForwardOnlyDefinedPaths) && [[[NSUserDefaults standardUserDefaults] arrayForKey:@"mrForwardedPaths"] count] > 0)
		{	
			for (NSDictionary *pair in [[NSUserDefaults standardUserDefaults] arrayForKey:@"mrForwardedPaths"])
			{
				if (![[pair valueForKey:@"enabled"] boolValue])
					continue;
				
				if (![[NSFileManager defaultManager] fileExistsAtPath:[[pair objectForKey:@"path"] stringByExpandingTildeInPath]] || ![[pair objectForKey:@"label"] length])
				{
					mrLog(mrLogLevelInfo, @"Empty custom forward label or path, skipping: %@", pair);
					continue;
				}
				
				[validDrives addObject:[[pair objectForKey:@"path"] stringByExpandingTildeInPath]];
				[validNames addObject:[pair objectForKey:@"label"]];
			}
		} 
		else 
		{
			for (NSString *volumePath in [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths])
				if ([volumePath characterAtIndex:0] != '.')
				{
					[validDrives addObject:volumePath];
					[validNames addObject:[[NSFileManager defaultManager] displayNameAtPath:volumePath]];
				}
		}
		
		if ([validDrives count] && [validNames count])
			disk_enum_devices(conn, mrMakeCStringArray(validDrives), mrMakeCStringArray(validNames), [validDrives count]);
	}
	
    
	if (forwardPrinters)
		printer_enum_devices(conn);
	
	if (forwardAudio == mrLeaveAudio)
	{
		logonFlags |= RDP_LOGON_LEAVE_AUDIO;
	}
	
	if ([clientHostname length]) {
		memset(conn->hostname,0,64);
		strncpy(conn->hostname, mrMakeWindowsString(clientHostname), 64);
        conn->hostname[MIN([clientHostname length], 64)] = '\0';
	}
	
	rdpdr_init(conn);
	cliprdr_init(conn);
    
	// Make the connection
	BOOL connected = rdp_connect(conn,
                                 [hostName UTF8String], 
                                 logonFlags, 
                                 domain,
                                 username,
                                 password,
                                 "",  /* xxx: command on logon */
                                 "", /* xxx: session directory */
                                 NO
                                 );
    
	// Upon success, set up the input socket
	if (connected)
	{
		[self setStatus:mrConnectionConnected];
		[self setUpConnectionThread];
        
		NSStream *is = conn->inputStream;
		[is setDelegate:self];
		[is scheduleInRunLoop:connectionRunLoop forMode:NSDefaultRunLoopMode];
        
		[self performSelectorOnMainThread:@selector(createViewWithFrameValue:) withObject:[NSValue valueWithRect:NSMakeRect(0.0, 0.0, conn->screenWidth, conn->screenHeight)] waitUntilDone:YES];
	}
	else if (connectionStatus == mrConnectionConnecting)
	{
		[self setStatus:mrConnectionClosed];
		//[self performSelectorOnMainThread:@selector(setStatusAsNumber:) withObject:[NSNumber numberWithInt:mrConnectionClosed] waitUntilDone:NO];
	}
	
	return connected;
}

- (void)disconnect
{
	[self disconnectAsync:[NSNumber numberWithBool:YES]];
}

- (void)disconnectAsync:(NSNumber *)nonblocking
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	if (connectionStatus == mrConnectionConnecting)
		conn->errorCode = ConnectionErrorCanceled;
	NSLog(@"disconnect Async called");
	[self setStatus:mrConnectionDisconnecting];
    NSLog(@"set status disconnecting");
	if (connectionRunLoopFinished || ![nonblocking boolValue])
	{
		// Try to forcefully break the connection thread out of its run loop
		@synchronized(self)
		{
			[inputEventPort sendBeforeDate:[NSDate dateWithTimeIntervalSinceNow:TIMEOUT_LENGTH] components:nil from:nil reserved:0];
		}
		
		time_t start = time(NULL);
		while (!connectionRunLoopFinished && (time(NULL) - start < TIMEOUT_LENGTH)) 
			usleep(1000);
        
		// UI cleanup
		[self performSelectorOnMainThread:@selector(destroyUIElements) withObject:nil waitUntilDone:YES];
        
		
		// Clear out the bitmap cache
		int i, k;
		for (i = 0; i < BITMAP_CACHE_SIZE; i++)
		{
			for (k = 0; k < BITMAP_CACHE_ENTRIES; k++)
			{	
				ui_destroy_bitmap(conn->bmpcache[i][k].bitmap);
				conn->bmpcache[i][k].bitmap = NULL;
			}
		}
		
		for (i = 0; i < CURSOR_CACHE_SIZE; i++)
			ui_destroy_cursor(conn->cursorCache[i]);
		
		
		free(conn->rdpdrClientname);
		
		
		memset(conn, 0, sizeof(RDConnection));
		free(conn);
		conn = NULL;
		
		[self setStatus:mrConnectionClosed];
	}
	else
	{
		[self performSelectorInBackground:@selector(disconnectAsync:) withObject:[NSNumber numberWithBool:NO]];
	}
	
	[pool release];
}

#pragma mark -
#pragma mark Working with the input run loop

- (void)runConnectionRunLoop
{
	NSAutoreleasePool *pool = nil;
	
	connectionRunLoopFinished = NO;
	
	BOOL gotInput;
	do
	{
		pool = [[NSAutoreleasePool alloc] init];
		gotInput = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
		[pool release];
	} while (connectionStatus == mrConnectionConnected && gotInput);
	
	pool = [[NSAutoreleasePool alloc] init];
	
	rdp_disconnect(conn);
	[self discardConnectionThread];
	connectionRunLoopFinished = YES;
    
	[pool release];
}


#pragma mark -
#pragma mark Clipboard synchronization

- (void)announceNewClipboardData
{
	int newChangeCount = [[NSPasteboard generalPasteboard] changeCount];
    
	if (newChangeCount != clipboardChangeCount)
		[self informServerOfPasteboardType];
    
	clipboardChangeCount = newChangeCount;
}

// Assures that the remote clipboard is the same as the passed pasteboard, sending new clipboard as needed
- (void)setRemoteClipboard:(int)suggestedFormat
{
	if (connectionStatus != mrConnectionConnected)
		return;
    
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	if (![pb availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]])
		return;
	
	NSString *pasteContent = mrConvertLineEndings([pb stringForType:NSStringPboardType], YES);
	
	CFDataRef pasteContentAsData = CFStringCreateExternalRepresentation(NULL, (CFStringRef)pasteContent, kCFStringEncodingUTF16LE, 0x20 /* unicode space */);
	NSMutableData *unicodePasteContent = [NSMutableData dataWithData:(NSData *)pasteContentAsData];
	CFRelease(pasteContentAsData);
	
	if (![unicodePasteContent length])
		return;
    
	[unicodePasteContent increaseLengthBy:2];  // NULL terminate with 2 bytes (UTF16LE)
	
	cliprdr_send_data(conn, (unsigned char *)[unicodePasteContent bytes], [unicodePasteContent length]);
}

- (void)requestRemoteClipboardData
{
	if (connectionStatus != mrConnectionConnected)
		return;
    
	conn->clipboardRequestType = CF_UNICODETEXT;
	cliprdr_send_data_request(conn, CF_UNICODETEXT);
}

// Sets the local clipboard to match the server provided data. Only called by server (via mrMixedGlue) when new data has actually arrived
- (void)setLocalClipboard:(NSData *)data format:(int)format
{
	if ( ((format != CF_UNICODETEXT) && (format != CF_AUTODETECT)) || ![data length] )
		return;
	
	unsigned char endiannessMarker[] = {0xFF, 0xFE};
	
	NSMutableData *rawClipboardData = [[NSMutableData alloc] initWithCapacity:[data length]];
	[rawClipboardData appendBytes:endiannessMarker length:2];
	[rawClipboardData appendBytes:[data bytes] length:[data length]-2];
	NSString *temp = [[NSString alloc] initWithData:rawClipboardData encoding:NSUnicodeStringEncoding];
	[rawClipboardData release];
	
	[remoteClipboard release];
	remoteClipboard = [mrConvertLineEndings(temp, NO) retain];
	[[NSPasteboard generalPasteboard] setString:remoteClipboard forType:NSStringPboardType];
    
    [temp release];
}

// Informs the receiver that the server has new clipboard data and is about to send it
- (void)gotNewRemoteClipboardData
{
	isClipboardOwner = YES;
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
}

- (void)informServerOfPasteboardType
{
	if ([[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]] == nil)
		return;
	
	if (connectionStatus == mrConnectionConnected)
		cliprdr_send_simple_native_format_announce(conn, CF_UNICODETEXT);
}

- (void)pasteboardChangedOwner:(NSPasteboard *)sender
{
	isClipboardOwner = NO;
}


#pragma mark -
#pragma mark Working with the represented file

// Saves all of the current settings to a Microsoft RDC client compatible file

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomicFlag updateFilenames:(BOOL)updateNamesFlag
{
#define write_int(n, v)	 [outputBuffer appendString:[NSString stringWithFormat:@"%@:i:%d\r\n", (n), (v)]]
#define write_string(n, v) [outputBuffer appendString:[NSString stringWithFormat:@"%@:s:%@\r\n", (n), (v) ? (v) : @""]]
	
	if (![path length])
		return NO;
    
	NSMutableString *outputBuffer = [[NSMutableString alloc] init];
	
	write_int(@"connect to console", consoleSession);
	write_int(@"redirectdrives", forwardDisks);
	write_int(@"redirectprinters", forwardPrinters);
	write_int(@"disable wallpaper", !drawDesktop);
	write_int(@"disable full window drag", !windowDrags);
	write_int(@"disable menu anims", !windowAnimation);
	write_int(@"disable themes", !themes);
	write_int(@"disable font smoothing", !fontSmoothing);
	write_int(@"audiomode", forwardAudio);
	write_int(@"desktopwidth", screenWidth);
	write_int(@"desktopheight", screenHeight);
	write_int(@"session bpp", screenDepth);
	write_int(@"cord save password", savePassword);
	write_int(@"cord fullscreen", fullscreen);
	write_int(@"cord row index", preferredRowIndex);
	write_int(@"cord hotkey", hotkey);
	
	write_string(@"full address", mrJoinHostNameAndPort(hostName, port));
	write_string(@"username", username);
	write_string(@"domain", domain);
	write_string(@"cord label", label);
	
	// Write all entries in otherAttributes	
	for (NSString *key in otherAttributes)
	{
		id value = [otherAttributes objectForKey:key];
		if ([value isKindOfClass:[NSNumber class]])
			write_int(key, [value integerValue]);
		else
			write_string(key, value);
	}
	
	BOOL writeToFileSucceeded = [outputBuffer writeToFile:path atomically:atomicFlag encoding:fileEncoding error:NULL] | [outputBuffer writeToFile:path atomically:atomicFlag encoding:(fileEncoding = NSUTF8StringEncoding) error:NULL];
    
	[outputBuffer release];
	
	if (writeToFileSucceeded)
	{
		NSDictionary *newAttrs = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:'RDP '] forKey:NSFileHFSTypeCode];
		//[[NSFileManager defaultManager] changeFileAttributes:newAttrs atPath:path];
        [[NSFileManager defaultManager] setAttributes:newAttrs ofItemAtPath:path error:nil];
	}
	else
	{
		mrLog(mrLogLevelError, @"Error writing RDP file to '%@'", path);
	}
    
	if (writeToFileSucceeded && updateNamesFlag)
	{
		modified = NO;
		[self setFilename:path];
	}
	
	return writeToFileSucceeded;
	
#undef write_int(n, v)
#undef write_string(n, v)
}

- (void)flushChangesToFile
{
	[self writeToFile:[self filename] atomically:YES updateFilenames:NO];
}


#pragma mark -
#pragma mark Working with GUI

- (void)createWindow:(BOOL)useScrollView
{	
	[NSAnimationContext beginGrouping];
	_usesScrollers = useScrollView;
	[window release];
	NSRect sessionScreenSize = [view bounds];
	window = [[NSWindow alloc] initWithContentRect:sessionScreenSize styleMask:(NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask) backing:NSBackingStoreBuffered defer:NO];
	
	[window setContentMaxSize:sessionScreenSize.size];
	[window setTitle:label];
	[window setAcceptsMouseMovedEvents:YES];
	[window setDelegate:self];
	[window setReleasedWhenClosed:NO];
	[[window contentView] setAutoresizesSubviews:YES];
	[window setContentMinSize:NSMakeSize(100.0, 75.0)];
	
	[window setAlphaValue:0.0];
	[view setFrameOrigin:NSZeroPoint];
	[view removeFromSuperview];
	
	if (useScrollView)
	{
		[self createScrollEnclosure:[[window contentView] bounds]];
		[[window contentView] addSubview:scrollEnclosure];
	}
	else
	{
		[view setFrameSize:[[window contentView] frame].size];
		[view setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
		[window setContentAspectRatio:sessionScreenSize.size];
		[[window contentView] addSubview:view];
		[view setNeedsDisplay:YES];
	}
	
	[[window animator] setAlphaValue:1.0];
	[window makeFirstResponder:view];
	[window display];
	[NSAnimationContext endGrouping];
}


- (void)createUnified:(BOOL)useScrollView enclosure:(NSRect)enclosure
{	
	_usesScrollers = useScrollView;
	if (useScrollView)
		[self createScrollEnclosure:enclosure];
	else
		[view setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
}

- (void)destroyUnified
{
}

- (void)destroyWindow
{
	[window setDelegate:nil]; // avoid the last windowWillClose delegate message
	[window close];
	[window release];
	window = nil;
}
- (void)destroyUIElements
{
    //TODO: May make problems
    [view setController:nil];
	[self destroyWindow];
	[scrollEnclosure release];
	scrollEnclosure = nil;
	[view release];
	view = nil;
}

#pragma mark -
#pragma mark NSWindow delegate

- (void)windowWillClose:(NSNotification *)aNotification
{
	if (connectionStatus == mrConnectionConnected)
		[delegate instanceDisconnected:self];
}

- (void)windowDidBecomeKey:(NSNotification *)sender
{
	if ([sender object] == window)
		[self announceNewClipboardData];
}

- (void)windowDidResignKey:(NSNotification *)sender
{
	if ([sender object] == window)
		[self requestRemoteClipboardData];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	NSSize realSize = [view bounds].size;
	realSize.height += [sender frame].size.height - [[sender contentView] frame].size.height;
	
	if ( (realSize.width-proposedFrameSize.width <= mrWindowSnapSize) && (realSize.height-proposedFrameSize.height <= mrWindowSnapSize) )
		return realSize;
    
	return proposedFrameSize;
}


#pragma mark -
#pragma mark Sending input from other threads

- (void)sendInputOnConnectionThread:(uint32)time type:(uint16)type flags:(uint16)flags param1:(uint16)param1 param2:(uint16)param2
{
	if (connectionStatus != mrConnectionConnected)
		return;
	
	if ([NSThread currentThread] == connectionThread)
	{
		rdp_send_input(conn, time, type, flags, param1, param2);
	}
	else
	{	
		// Push this event onto the event stack and handle it in the connection thread
		mrInputEvent queuedEvent = mrMakeInputEvent(time, type, flags, param1, param2), *ie;
		
		ie = malloc(sizeof(mrInputEvent));
		memcpy(ie, &queuedEvent, sizeof(mrInputEvent));
		
		@synchronized(inputEventStack)
		{
			[inputEventStack addObject:[NSValue valueWithPointer:ie]];
		}
		
		// Inform the connection thread it has unprocessed events
		[inputEventPort sendBeforeDate:[NSDate date] components:nil from:nil reserved:0];
	}
}

// Called by the connection thread in the run loop when new user input needs to be sent
- (void)handleMachMessage:(void *)msg
{
    @synchronized(inputEventStack)
	{
		while ([inputEventStack count] != 0)
		{
			mrInputEvent *ie = [[inputEventStack objectAtIndex:0] pointerValue];
			[inputEventStack removeObjectAtIndex:0];
			if (ie != NULL)
				[self sendInputOnConnectionThread:ie->time type:ie->type flags:ie->deviceFlags param1:ie->param1 param2:ie->param2];
			
			free(ie);
		}
	}
}


#pragma mark -
#pragma mark Working With CoRD

- (void)cancelConnection
{
	if ( (connectionStatus != mrConnectionConnecting) || !conn)
		return;
	
	conn->errorCode = ConnectionErrorCanceled;
}

- (NSComparisonResult)compareUsingPreferredOrder:(id)compareTo
{
	int otherOrder = [[compareTo valueForKey:@"preferredRowIndex"] intValue];
	
	if (preferredRowIndex == otherOrder)
		return [[compareTo label] compare:label];
	else
		return (preferredRowIndex - otherOrder > 0) ? NSOrderedDescending : NSOrderedAscending;
}


#pragma mark -
#pragma mark Keychain

- (void)clearKeychainData
{
	keychain_clear_password([hostName UTF8String], [username UTF8String]);
}


#pragma mark -
#pragma mark Accessors

@synthesize hostName, label, clientHostname, conn, view, isTemporary, modified, status=connectionStatus, window, hotkey, forwardAudio;

- (NSView *)tabItemView
{
	return (scrollEnclosure) ? scrollEnclosure : (NSView *)view;
}

- (NSString *)filename
{
	return rdpFilename;
}

- (void)setFilename:(NSString *)path
{
	if ([path isEqualToString:rdpFilename])
		return;
    
	[self willChangeValueForKey:@"rdpFilename"];
	[rdpFilename autorelease];
	rdpFilename = [path copy];
	[self didChangeValueForKey:@"rdpFilename"];
}

- (void)setIsTemporary:(BOOL)temp
{
	if (temp == isTemporary)
		return;
    
    
	[self willChangeValueForKey:@"temporary"];
	isTemporary = temp;
	[self didChangeValueForKey:@"temporary"];
	//[self updateCellData];
}


// KVC/KVO compliant setters that are used to propagate changes to the keychain item

- (void)setLabel:(NSString *)newLabel
{	
	[label autorelease];
	label = [newLabel copy];
	//[self updateCellData];
}

- (void)setHostName:(NSString *)newHost
{	
	//[self updateKeychainData:newHost user:username password:password force:NO];
	
	[hostName autorelease];
	hostName = [newHost copy];
	//[self updateCellData];
}

- (void)setUsername:(NSString *)newUser
{
	//[self updateKeychainData:hostName user:newUser password:password force:NO];
	
	[username autorelease];
	username = [newUser copy];
	//[self updateCellData];
}

- (void)setDomain:(NSString *)newDomain
{
    [domain autorelease];
    domain = [domain copy];
}

- (void)setPassword:(NSString *)newPassword
{
	//[self updateKeychainData:hostName user:username password:newPassword force:NO];
	
	[password autorelease];
	password = [newPassword copy];
}

- (void)setPort:(int)newPort
{
	if (port == newPort)
		return;
    
	port = newPort;
	//[self updateCellData];
}

- (void)setSavePassword:(BOOL)saves
{
	savePassword = saves;
	
	/* if (!savePassword)	
		[self clearKeychainData];
	else
		[self updateKeychainData:hostName user:username password:password force:YES]; */
}

@end


#pragma mark -

@implementation mrSession (Private)

#pragma mark -
#pragma mark Represented file

- (BOOL)readFileAtPath:(NSString *)path
{
	if ([path length] == 0 || ![[NSFileManager defaultManager] isReadableFileAtPath:path])
		return NO;
    
	NSString *fileContents = [NSString stringWithContentsOfFile:path usedEncoding:&fileEncoding error:NULL];
    
	if (fileContents == nil)
		fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	
	NSArray *fileLines = [fileContents componentsSeparatedByString:@"\r\n"];
    
	if (fileLines == nil)
	{
		mrLog(mrLogLevelError, @"Couldn't open RDP file '%@'!", path);
		return NO;
	}
    
	[self setFilename:path];
    
	NSScanner *scan;
	NSCharacterSet *colonSet = [NSCharacterSet characterSetWithCharactersInString:@":"],
    *emptySet = [NSCharacterSet characterSetWithCharactersInString:@""];
    
	NSString *name, *type, *value;
	int numVal = 0;
	BOOL b;
	
	// Extract the name, type, and value from each line and load into ivars
	id line;
	for ( line in fileLines )
	{
		scan = [NSScanner scannerWithString:line];
		[scan setCharactersToBeSkipped:colonSet];
		
		b = YES;
		b &= [scan scanUpToCharactersFromSet:colonSet intoString:&name];
		b &= [scan scanUpToCharactersFromSet:colonSet intoString:&type];
		
		if (![scan scanUpToCharactersFromSet:emptySet intoString:&value])
			value = @"";
		
		// Don't use KVC because none of the side effects in the setters are desirable at load time
		
		if (!b)
			continue;
        
		
		if ([type isEqualToString:@"i"])
			numVal = [value integerValue];
		
		if ([name isEqualToString:@"connect to console"])
			consoleSession = numVal;
		else if ([name isEqualToString:@"redirectdrives"])
			forwardDisks = numVal;
		else if ([name isEqualToString:@"redirectprinters"])
			forwardPrinters = numVal;
		else if ([name isEqualToString:@"disable wallpaper"])
			drawDesktop = !numVal;
		else if ([name isEqualToString:@"disable full window drag"])
			windowDrags = !numVal;
		else if ([name isEqualToString:@"disable menu anims"])
			windowAnimation = !numVal;
		else if ([name isEqualToString:@"disable themes"])
			themes = !numVal;
		else if ([name isEqualToString:@"disable font smoothing"])
			fontSmoothing = !numVal;
		else if ([name isEqualToString:@"audiomode"])
			forwardAudio = numVal;
		else if ([name isEqualToString:@"desktopwidth"]) 
			screenWidth = numVal;
		else if ([name isEqualToString:@"desktopheight"]) 
			screenHeight = numVal;
		else if ([name isEqualToString:@"session bpp"]) 
			screenDepth = numVal;
		else if ([name isEqualToString:@"username"])
			username = [value retain];
		else if ([name isEqualToString:@"cord save password"]) 
			savePassword = numVal;
		else if ([name isEqualToString:@"domain"])
			domain = [value retain];
		else if ([name isEqualToString:@"cord label"])
			label = [value retain];
		else if ([name isEqualToString:@"cord row index"])
			preferredRowIndex = numVal;
		else if ([name isEqualToString:@"full address"]) {
			mrSplitHostNameAndPort(value, &hostName, &port);
			[hostName retain];
		}
		else if ([name isEqualToString:@"cord fullscreen"])
			fullscreen = numVal;
		else if ([name isEqualToString:@"cord hotkey"]) {
			hotkey = (numVal == 0) ? (-1) : numVal;
		}
		else
		{
			if ([type isEqualToString:@"i"])
				[otherAttributes setObject:[NSNumber numberWithInt:numVal] forKey:name];
			else
				[otherAttributes setObject:value forKey:name];
		}
	}
    
	modified = NO;
	[self setIsTemporary:NO];
	
	if (savePassword)
	{
		const char *pass = keychain_get_password([hostName UTF8String], [username UTF8String]);
		if (pass != NULL)
		{
			password = [[NSString stringWithUTF8String:pass] retain];
			free((void*)pass);
		}
	}
	
	//[self updateCellData];
	
	return YES;
}


#pragma mark -
#pragma mark Keychain

// Force makes it save data to keychain regardless if it has changed. savePassword  is always respected.
- (void)updateKeychainData:(NSString *)newHost user:(NSString *)newUser password:(NSString *)newPassword force:(BOOL)force
{
	if (savePassword && (force || ![hostName isEqualToString:newHost] || ![username isEqualToString:newUser] || ![password isEqualToString:newPassword]) )
	{
		keychain_update_password([hostName UTF8String], [username UTF8String], [newHost UTF8String], [newUser UTF8String], [newPassword UTF8String]);
	}
}


#pragma mark -
#pragma mark Connection status

- (void)setStatus:(mrConnectionStatus)newStatus
{
    connectionStatus = newStatus;
    
    if (self.delegate) {
        [self.delegate connectionStatusChanged:connectionStatus forInstance:self];
    }
}

// Status needs to be set on the main thread when setting it to Connecting so the the mrServerCell will create its progress indicator timer in the main run loop
- (void)setStatusAsNumber:(NSNumber *)newStatus
{
	[self setStatus:[newStatus intValue]];
}


#pragma mark -
#pragma mark User Interface

- (void)createScrollEnclosure:(NSRect)frame
{
	[scrollEnclosure release];
	scrollEnclosure = [[NSScrollView alloc] initWithFrame:frame];
	[view setAutoresizingMask:NSViewNotSizable];
	[view setFrame:NSMakeRect(0,0, [view width], [view height])];
	[scrollEnclosure setAutoresizingMask:(NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable)];
    //NSClipView* clipView = [[CenteringClipView alloc] initWithFrame:[view frame]];
    //[scrollEnclosure setContentView:clipView];
    [scrollEnclosure setDocumentView:view];
	[scrollEnclosure setHasVerticalScroller:YES];
	[scrollEnclosure setHasHorizontalScroller:YES];
	[scrollEnclosure setAutohidesScrollers:YES];
	[scrollEnclosure setBorderType:NSNoBorder];
	[scrollEnclosure setDrawsBackground:YES];
    [scrollEnclosure setBackgroundColor:[NSColor lightGrayColor]];
    [RmCenteringClipView replaceClipViewInScrollView:scrollEnclosure];
}

- (void)createViewWithFrameValue:(NSValue *)frameRect
{	
	if (conn == NULL)
		return;
	
	view = [[mrSessionView alloc] initWithFrame:[frameRect rectValue]];
	[view setController:self];
	conn->ui = view;
}


#pragma mark -
#pragma mark General

- (void)setUpConnectionThread
{
	@synchronized(self)
	{
		connectionThread = [NSThread currentThread];
		connectionRunLoop  = [NSRunLoop currentRunLoop];
        
		inputEventPort = [[NSMachPort alloc] init];
		[inputEventPort setDelegate:self];
		[connectionRunLoop addPort:inputEventPort forMode:(NSString *)kCFRunLoopCommonModes];
	}
}

- (void)discardConnectionThread
{
	@synchronized(self)
	{
		[connectionRunLoop removePort:inputEventPort forMode:(NSString *)kCFRunLoopCommonModes];
		[inputEventPort invalidate];
		[inputEventPort release];
		inputEventPort = nil;
        
		@synchronized(inputEventStack)
		{
			while ([inputEventStack count] != 0)
			{
				free([[inputEventStack objectAtIndex:0] pointerValue]);
				[inputEventStack removeObjectAtIndex:0];
			}
		}
		
		connectionThread = nil;
		connectionRunLoop = nil;
	}
}

@end