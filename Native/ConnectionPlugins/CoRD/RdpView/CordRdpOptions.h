//
//  RdpOptions.h
//  RdpViewFramework
//
//  Created by Felix Deimel on 30.05.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

// TODO: Should update with init and dealloc methods

#import <Foundation/Foundation.h>

@interface CordRdpOptions : NSObject

@property (nonatomic, retain) NSString* hostname;
@property (nonatomic, readwrite) int port;
@property (nonatomic, readwrite) int screenWidth;
@property (nonatomic, readwrite) int screenHeight;
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* domain;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, readwrite) BOOL connectToConsole;
@property (nonatomic, readwrite) BOOL smartSize;
@property (nonatomic, readwrite) int colorDepth;
@property (nonatomic, readwrite) BOOL allowWallpaper;
@property (nonatomic, readwrite) BOOL allowAnimations;
@property (nonatomic, readwrite) BOOL fontSmoothing;
@property (nonatomic, readwrite) BOOL showWindowContentsWhileDragging;
@property (nonatomic, readwrite) BOOL showThemes;
@property (nonatomic, readwrite) BOOL redirectPrinters;
@property (nonatomic, readwrite) BOOL redirectDiskDrives;
@property (nonatomic, readwrite) int audioRedirectionMode;

@end
