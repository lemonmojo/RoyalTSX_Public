//
//  mrSwappedModifiersUtility.m
//  mRemoteMac
//
//  Created by Felix Deimel on 18.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "mrSwappedModifiersUtility.h"
#import "IOKit/hidsystem/IOLLEvent.h"

// Constants
static NSString* const SwappedModifiersRootKey = @"com.apple.keyboard.modifiermapping";
static NSString* const SwappedModifiersSourceKey = @"HIDKeyboardModifierMappingSrc";
static NSString* const SwappedModifiersDestinationKey = @"HIDKeyboardModifierMappingDst";
static NSString* const KeyFlagRight = @"KeyFlagRight";
static NSString* const KeyFlagLeft = @"KeyFlagLeft";
static NSString* const KeyFlagDeviceIndependent = @"KeyFlagDeviceIndependent";

typedef enum _mrSwappedModifiersKeyCode {
    mrSwappedModifiersCapsLockKey = 0,
    mrSwappedModifiersShiftKey = 9,
    mrSwappedModifiersControlKey = 10,
    mrSwappedModifiersOptionKey = 11,
    mrSwappedModifiersCommandKey = 12
} mrSwappedModifiersKeyCode;

// Convenience macros
#define MakeNum(n) [NSNumber numberWithInt:(n)]
#define MakeInt(num) [num intValue]
#define GetFlagForKey(keyNum, flag) MakeInt([[keyFlagTable objectForKey:MakeNum(keyNum)] objectForKey:flag])

static mrSwappedModifiersUtility *sharedInstance;
static NSDictionary *keyFlagTable, *modifierTranslator, *keyDisplayNames;
static NSArray *rawDefaultTable;


#define KEY_NAMED(n) [keyDisplayNames objectForKey:MakeNum(n)]

@implementation mrSwappedModifiersUtility

+ (void)initialize
{
#define CREATE_KEY_FLAG(r, l, di) \
[NSDictionary dictionaryWithObjectsAndKeys:MakeNum(r), KeyFlagRight, MakeNum(l), KeyFlagLeft, MakeNum(di), KeyFlagDeviceIndependent, nil]
    
	keyFlagTable = [[NSDictionary dictionaryWithObjectsAndKeys:
                     CREATE_KEY_FLAG(0, 0, NSAlphaShiftKeyMask), MakeNum(mrSwappedModifiersCapsLockKey),
                     CREATE_KEY_FLAG(NX_DEVICERCTLKEYMASK, NX_DEVICELCTLKEYMASK, NSControlKeyMask), MakeNum(mrSwappedModifiersControlKey),
                     CREATE_KEY_FLAG(NX_DEVICERALTKEYMASK, NX_DEVICELALTKEYMASK, NSAlternateKeyMask), MakeNum(mrSwappedModifiersOptionKey),
                     CREATE_KEY_FLAG(NX_DEVICERCMDKEYMASK, NX_DEVICELCMDKEYMASK, NSCommandKeyMask), MakeNum(mrSwappedModifiersCommandKey),
                     CREATE_KEY_FLAG(NX_DEVICERSHIFTKEYMASK, NX_DEVICELSHIFTKEYMASK, NSShiftKeyMask), MakeNum(mrSwappedModifiersShiftKey),
                     nil] retain];
	
	// Just for debug purposes
	keyDisplayNames =  [[NSDictionary dictionaryWithObjectsAndKeys:
                         @"Caps Lock", MakeNum(mrSwappedModifiersCapsLockKey),
                         @"Control", MakeNum(mrSwappedModifiersControlKey),
                         @"Option", MakeNum(mrSwappedModifiersOptionKey),
                         @"Command", MakeNum(mrSwappedModifiersCommandKey),
                         @"Shift", MakeNum(mrSwappedModifiersShiftKey),
                         nil] retain];
    
	// xxx: doesn't actually inform us of changes
	[[NSUserDefaults standardUserDefaults] addObserver:[[[mrSwappedModifiersUtility alloc] init] autorelease] forKeyPath:SwappedModifiersRootKey options:0 context:NULL];
	[mrSwappedModifiersUtility loadStandardTranslation];
}

+ (void)loadStandardTranslation
{
	NSMutableDictionary *modifiersBuilder = [[NSMutableDictionary alloc] initWithCapacity:4];
	NSArray *userDefaultTable = nil;
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	userDefaultTable = [[NSUserDefaults standardUserDefaults] objectForKey:SwappedModifiersRootKey];
    
	if ( (userDefaultTable != nil) && ![userDefaultTable isEqualToArray:rawDefaultTable])
	{		
		[rawDefaultTable release];
		rawDefaultTable = [userDefaultTable retain];
		
		id item;
		for ( item in rawDefaultTable )
		{
			[modifiersBuilder setObject:[item objectForKey:SwappedModifiersDestinationKey] forKey:[item objectForKey:SwappedModifiersSourceKey]];	
		}
	}
	
	if ([modifiersBuilder count] == 0)
	{
		[modifiersBuilder setObject:MakeNum(mrSwappedModifiersCapsLockKey) forKey:MakeNum(mrSwappedModifiersCapsLockKey)];
		[modifiersBuilder setObject:MakeNum(mrSwappedModifiersControlKey) forKey:MakeNum(mrSwappedModifiersControlKey)];
		[modifiersBuilder setObject:MakeNum(mrSwappedModifiersOptionKey) forKey:MakeNum(mrSwappedModifiersOptionKey)];
		[modifiersBuilder setObject:MakeNum(mrSwappedModifiersCommandKey) forKey:MakeNum(mrSwappedModifiersCommandKey)];
		[modifiersBuilder setObject:MakeNum(mrSwappedModifiersShiftKey) forKey:MakeNum(mrSwappedModifiersShiftKey)];
	}
	
	[modifierTranslator release];
	modifierTranslator = modifiersBuilder;
}

+ (unsigned)physicalModifiersForVirtualFlags:(unsigned)flags
{	
	[mrSwappedModifiersUtility loadStandardTranslation];
    
#define TEST_THEN_SWAP(realKeyFlag, virtKeyFlag) if (flags & virtKeyFlag) newFlags |= realKeyFlag;
	//	mrLog(mrLogLevelInfo, @"Swapping? %s", (flags & virtKeyFlag) ? "Yes." : "No.");
    
	int keys[5] = {mrSwappedModifiersCapsLockKey, mrSwappedModifiersControlKey, mrSwappedModifiersOptionKey, mrSwappedModifiersCommandKey, mrSwappedModifiersShiftKey};
	unsigned newFlags = 0, i, realKeyNum;
	
	for (i = 0; i < 5; i++)
	{	
		realKeyNum = MakeInt([modifierTranslator objectForKey:MakeNum(keys[i])]);
		TEST_THEN_SWAP(GetFlagForKey(keys[i], KeyFlagRight), GetFlagForKey(realKeyNum, KeyFlagRight));
		TEST_THEN_SWAP(GetFlagForKey(keys[i], KeyFlagLeft), GetFlagForKey(realKeyNum, KeyFlagLeft));
		TEST_THEN_SWAP(GetFlagForKey(keys[i], KeyFlagDeviceIndependent), GetFlagForKey(realKeyNum, KeyFlagDeviceIndependent));		
	}
    
	return newFlags;
}

+ (BOOL)modifiersAreSwapped
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	return [[NSUserDefaults standardUserDefaults] objectForKey:SwappedModifiersRootKey] != nil;
}




- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:SwappedModifiersRootKey])
	{
		[mrSwappedModifiersUtility loadStandardTranslation];
    }
}

@end