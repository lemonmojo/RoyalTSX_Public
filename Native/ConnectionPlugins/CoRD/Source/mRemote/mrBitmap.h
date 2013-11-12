//
//  mrBitmap.h
//  mRemoteMac
//
//  Created by Felix Deimel on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class mrSessionView;

@interface mrBitmap : NSObject
{
	NSImage *image;
	NSData *data;
	NSCursor *cursor;
	NSColor *color;
}

- (id)initWithBitmapData:(const unsigned char *)d size:(NSSize)s view:(mrSessionView *)v;
- (id)initWithGlyphData:(const unsigned char *)d size:(NSSize)s view:(mrSessionView *)v;
- (id)initWithCursorData:(const unsigned char *)d alpha:(const unsigned char *)a size:(NSSize)s hotspot:(NSPoint)hotspot view:(mrSessionView *)v bpp:(int)bpp;
- (id)initWithImage:(NSImage *)img;

- (void)drawInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op;
- (mrBitmap *)invert;

- (void)overlayColor:(NSColor *)c;

- (NSImage *)image;
- (void)setColor:(NSColor *)color;
- (NSColor *)color;
- (NSCursor *)cursor;
@end
