//
//  mrSession.h
//  mRemoteMac
//
//  Created by Felix Deimel on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "rdesktop.h"
#import "mrShared.h"

@class mrSessionView;

@protocol mrSessionDelegate <NSObject>;
    - (void)connectionStatusChanged:(mrConnectionStatus)newStatus forInstance:(mrSession*)inst;
    - (void)connectionStatusChanged:(NSArray*)argArray;
    - (void)instanceDisconnected:(mrSession*)session;
@end

@interface mrSession : NSObject <NSWindowDelegate, NSStreamDelegate, NSMachPortDelegate>
{
	// Represented rdesktop object
	RDConnectionRef conn;
    
	// User configurable RDP settings
	NSString *label, *hostName, *username, *password, *domain, *clientHostname;	
	BOOL savePassword, forwardDisks, forwardPrinters, drawDesktop, windowDrags, windowAnimation, themes, fontSmoothing, consoleSession, fullscreen;
	NSInteger forwardAudio, port;
	NSInteger hotkey, screenDepth, screenWidth, screenHeight;
	NSMutableDictionary *otherAttributes;
	
	// Working between main thread and connection thread
	volatile BOOL connectionRunLoopFinished;
	NSRunLoop *connectionRunLoop;
	NSThread *connectionThread;
	NSMachPort *inputEventPort;
	NSMutableArray *inputEventStack;
    
	// General information about instance
	BOOL isTemporary, modified, temporarilyFullscreen, _usesScrollers;
	NSInteger preferredRowIndex;
	volatile mrConnectionStatus connectionStatus;
	
	// Represented file
	NSString *rdpFilename;
	NSStringEncoding fileEncoding;
	
	// Clipboard
	BOOL isClipboardOwner;
	NSString *remoteClipboard;
	NSInteger clipboardChangeCount;
    
	// UI elements
	mrSessionView *view;
	NSScrollView *scrollEnclosure;
	NSWindow *window;
    
    NSObject <mrSessionDelegate> *delegate;
}

@property (copy, nonatomic) NSString *hostName, *label, *clientHostname, *username, *password, *domain;
@property (nonatomic) BOOL consoleSession;
@property (readonly) RDConnectionRef conn;
@property (readonly) mrSessionView *view;
@property (nonatomic, retain) NSScrollView *scrollEnclosure;
@property (assign, nonatomic) BOOL isTemporary;
@property (readonly) BOOL modified;
@property (readonly) volatile mrConnectionStatus status;
@property (readonly) NSWindow *window;
@property (assign) NSInteger hotkey, forwardAudio;

@property (nonatomic, assign) NSObject <mrSessionDelegate> *delegate;



- (id)initWithPath:(NSString *)path;
- (id)initWithBaseConnection;

// Working with rdesktop
- (BOOL)connect;
- (void)disconnect;
- (void)disconnectAsync:(NSNumber *)nonblocking;
- (void)sendInputOnConnectionThread:(uint32)time type:(uint16)type flags:(uint16)flags param1:(uint16)param1 param2:(uint16)param2;
- (void)runConnectionRunLoop;

// Clipboard
- (void)announceNewClipboardData;
- (void)setRemoteClipboard:(int)suggestedFormat;
- (void)setLocalClipboard:(NSData *)data format:(int)format;
- (void)requestRemoteClipboardData;
- (void)gotNewRemoteClipboardData;
- (void)informServerOfPasteboardType;

// Working with the rest of CoRD
- (void)cancelConnection;
- (NSComparisonResult)compareUsingPreferredOrder:(id)compareTo;
- (void)clearKeychainData;

// Working with GUI
- (void)createUnified:(BOOL)useScrollView enclosure:(NSRect)enclosure;
- (void)createWindow:(BOOL)useScrollView;
- (void)destroyUnified;
- (void)destroyWindow;
- (void)destroyUIElements;

// Working with the represented file
- (void)setFilename:(NSString *)filename;
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomicFlag updateFilenames:(BOOL)updateNamesFlag;
- (void)flushChangesToFile;


// Accessors
- (NSView *)tabItemView;
- (NSString *)filename;
- (void)setFilename:(NSString *)path;
- (void)setIsTemporary:(BOOL)temp;
- (void)setHostName:(NSString *)newHost;
- (void)setUsername:(NSString *)s;
- (void)setPassword:(NSString *)pass;
- (void)setPort:(int)newPort;
- (void)setSavePassword:(BOOL)saves;
@end