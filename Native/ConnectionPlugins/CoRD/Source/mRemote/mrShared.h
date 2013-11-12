//
//  mrShared.h
//  mRemoteMac
//
//  Created by Felix Deimel on 18.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


// Enums
typedef enum _mrConnectionStatus {
    mrConnectionClosed = 0,
    mrConnectionConnecting = 1,
    mrConnectionConnected = 2,
    mrConnectionDisconnecting = 3
} mrConnectionStatus;

typedef enum _mrDisplayMode {
	mrDisplayUnified = 0,
	mrDisplayWindowed = 1,
	mrDisplayFullscreen = 2
} mrDisplayMode;

typedef struct _mrInputEvent {
	unsigned int time; 
	unsigned short type, deviceFlags, param1, param2;
} mrInputEvent;

typedef enum _mrLogLevel {
	mrLogLevelOff   = 0,
	mrLogLevelError = 1,
	mrLogLevelWarn  = 2,
	mrLogLevelInfo  = 3,
	mrLogLevelDebug = 4
} mrLogLevel;


// Constants
extern const NSInteger mrDefaultPort;
extern const NSInteger mrDefaultScreenWidth, mrDefaultScreenHeight, mrDefaultFrameWidth, mrDefaultFrameHeight;
extern const NSInteger mrMouseEventLimit;
extern const NSInteger mrInspectorMaxWidth;
extern const NSInteger mrForwardAudio, mrLeaveAudio, mrDisableAudio;
extern const NSPoint mrWindowCascadeStart;
extern const float mrWindowSnapSize;


// NSUserDefaults keys
extern NSString* const mrDefaultsUnifiedDrawerShown;
extern NSString* const mrDefaultsUnifiedDrawerSide;
extern NSString* const mrDefaultsUnifiedDrawerWidth;
extern NSString* const mrDefaultsDisplayMode;
extern NSString* const mrDefaultsQuickConnectServers;
extern NSString* const mrDefaultsSendWindowsKey;


// User-configurable NSUserDefaults keys (preferences)
extern NSString* const mrPrefsReconnectIntoFullScreen;
extern NSString* const mrPrefsReconnectOutOfFullScreen;
extern NSString* const mrPrefsScaleSessions;
extern NSString* const mrPrefsMinimalisticServerList;
extern NSString* const mrPrefsIgnoreCustomModifiers;
extern NSString* const mrSetServerKeyboardLayout;
extern NSString* const mrForwardOnlyDefinedPaths;
extern NSString* const mrUseSocksProxy;


// Shared Methods
void mrSplitHostNameAndPort(NSString *address, NSString **host, NSInteger *port);
NSString *mrJoinHostNameAndPort(NSString *host, NSInteger port);

BOOL mrResolutionStringIsFullscreen(NSString *screenResolution);
void mrSplitResolutionString(NSString *resolution, NSInteger *width, NSInteger *height);
NSNumber *mrNumberForColorsText(NSString * colorsText);

unsigned int mrRoundUpToEven(float n);

NSString *mrConvertLineEndings(NSString *orig, BOOL withCarriageReturn);
const char *mrMakeWindowsString(NSString *src);
const char *mrMakeUTF16LEString(NSString *src);
int mrGetUTF16LEStringLength(NSString *src);

void mrCreateDirectory(NSString *directory);
NSString *mrFindAvailableFileName(NSString *path, NSString *base, NSString *extension);
NSArray *mrFilterFilesByType(NSArray *unfilteredFiles, NSArray *types);
NSString *mrTemporaryFile(void);
BOOL mrPathIsHidden(NSString *path);

char ** mrMakeCStringArray(NSArray *conv);

void mrSetAttributedStringColor(NSMutableAttributedString *as, NSColor *color);
void mrSetAttributedStringFont(NSMutableAttributedString *as, NSFont *font);

mrInputEvent mrMakeInputEvent(unsigned int time, unsigned short type, unsigned short deviceFlags, unsigned short param1, unsigned short param2);
NSToolbarItem * mrMakeToolbarItem(NSString *name, NSString *label, NSString *tooltip, SEL action);
NSMenuItem * mrMakeSearchFieldMenuItem(NSString *title, NSInteger tag);


BOOL mrPreferenceIsEnabled(NSString *prefName);
void mrSetPreferenceIsEnabled(NSString *prefName, BOOL enabled);

void mrFillDefaultConnection(RDConnectionRef conn);
NSSize mrProportionallyScaleSize(NSSize orig, NSSize enclosure);
BOOL mrLog(mrLogLevel logLevel, NSString *format, ...);


// Convenience macros
#define BUTTON_STATE_AS_NUMBER(b) [NSNumber numberWithInt:([(b) state] == NSOnState ? 1 : 0)]
#define mrRectFromSize(s) ((NSRect){NSZeroPoint, (s)})
#define POINT_DISTANCE(p1, p2) ( sqrtf( powf( (p1).x - (p2).x, 2) + powf( (p1).y - (p2).y, 2) ) )
#define CGRECT_FROM_NSRECT(r) CGRectMake((r).origin.x, (r).origin.y, (r).size.width, (r).size.height)

#define LOCALS_FROM_CONN									\
    /*TRACE_FUNC;*/ \
    mrSessionView *v = (mrSessionView *)conn->ui;			\
    mrSession *inst = (mrSession *)conn->controller;


// Debug Output
#ifdef WITH_MID_LEVEL_DEBUG
#define UNIMPL mrLog(mrLogLevelWarn, @"Unimplemented: %s", __func__)
#else
#define UNIMPL
#endif

//#define WITH_DEBUG_KEYBOARD

#ifdef WITH_DEBUG_KEYBOARD
#define DEBUG_KEYBOARD(args) NSLog args 
#else
#define DEBUG_KEYBOARD(args)
#endif 

#ifdef WITH_DEBUG_UI
#define DEBUG_UI(args) NSLog args
#define CHECKOPCODE(x) if ((x)!=12 && (x) < 16) { mrLog(mrLogLevelWarn, @"Unimplemented opcode %d in function %s", (x), __func__); }
#else
#define DEBUG_UI(args)
#define CHECKOPCODE(x) 
#endif

#ifdef WITH_DEBUG_MOUSE
#define DEBUG_MOUSE(args) NSLog args
#else
#define DEBUG_MOUSE(args)
#endif

#if defined(CORD_RELEASE_BUILD) && (defined(WITH_MID_LEVEL_DEBUG) || defined(WITH_DEBUG_UI) || defined(WITH_DEBUG_KEYBOARD) || defined(WITH_DEBUG_MOUSE))
#error Debugging output is enabled and building Release
#endif

#ifdef CORD_DEBUG_BUILD
#define TRACE_FUNC mrLog(mrLogLevelDebug, (@"%s (%@@%u) entered", __func__, [[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent], __LINE__)
#endif