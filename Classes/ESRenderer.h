//
//  ESRenderer.h
//  Viewer
//
//  Copyright (c) 2010-2016 Andrew Henroid. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@protocol ESRenderer <NSObject>

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (void)rotate:(float)x y:(float)y z:(float)z;
- (void)zoom:(float)z;
- (void)zoomMax;

@end
