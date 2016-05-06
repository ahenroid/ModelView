//
//  ES1Renderer.h
//  Viewer
//
//  Copyright (c) 2010-2016 Andrew Henroid. All rights reserved.
//

#import "ESRenderer.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface ES1Renderer : NSObject <ESRenderer>
{
@private
    EAGLContext *context;

    GLint backingWidth;
    GLint backingHeight;

    GLuint defaultFramebuffer, colorRenderbuffer;

	float rot[3];
	float zoom;
	float zoomMax;
}

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (void)rotate:(float)x y:(float)y z:(float)z;
- (void)zoom:(float)z;
- (void)zoomMax;
- (GLuint)loadTexture:(NSString*)path;

@end
