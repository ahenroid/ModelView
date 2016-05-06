//
//  ES1Renderer.m
//  Viewer
//
//  Copyright (c) 2010-2016 Andrew Henroid. All rights reserved.
//

#import "ES1Renderer.h"

@implementation ES1Renderer

static GLuint texid;

#include "scene.h"

// Create an OpenGL ES 1.1 context
- (id)init
{
    self = [super init];
	if (!self)
		return nil;

	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

    if (!context || ![EAGLContext setCurrentContext:context])
    {
        [self release];
        return nil;
    }

    glGenFramebuffersOES(1, &defaultFramebuffer);
    glGenRenderbuffersOES(1, &colorRenderbuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);

	glEnable(GL_CULL_FACE);	
	glEnable(GL_DEPTH_TEST);
    glClearColor(0, 0, 0, 1.0);

	texid = [self loadTexture:@"scene.jpg"];
	zoomMax = 0;
	for (int i = 0; i < (sizeof(scene_vert0) / sizeof(GLfloat)); i += 3)
	{
		GLfloat dist = (scene_vert0[0] * scene_vert0[0]
						+ scene_vert0[1] * scene_vert0[1]
						+ scene_vert0[2] * scene_vert0[2]);
		if (dist > zoomMax)
			zoomMax = dist;
	}
	zoomMax = sqrtf(zoomMax);
	zoom = zoomMax;

	for (int i = 0; i < (sizeof(scene_tex0) / sizeof(GLfloat)); i += 2)
		scene_tex0[i] = (1.0 - scene_tex0[i]);
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_SRC_COLOR);
	glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

#if 0
	GLfloat light_spec[] = {0, 0, 0, 1};
	glLightfv(GL_LIGHT0, GL_SPECULAR, light_spec);
	GLfloat light_amb[] = {0, 0, 0, 1};
	glLightfv(GL_LIGHT0, GL_AMBIENT, light_amb);
	GLfloat light_dif[] = {1, 1, 1, 1};
	glLightfv(GL_LIGHT0, GL_DIFFUSE, light_dif);
	GLfloat light_pos[] = {-1.5, 1.0, -4, 1.0};
	glLightfv(GL_LIGHT0, GL_POSITION, light_pos);
	glShadeModel(GL_SMOOTH);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable(GL_COLOR_MATERIAL);
#endif

	glRotatef(90, 1, 0, 0);
	glRotatef(-90, 0, 0, 1);
	memset(rot, 0, sizeof(rot));
	
    return self;
}

- (GLuint)loadTexture:(NSString*)path
{
	UIImage* image = [[UIImage alloc]
					  initWithContentsOfFile:[[NSBundle mainBundle]
											  pathForResource:path
											  ofType:nil]];
	if (!image)
		return 0;

	GLuint width = CGImageGetWidth(image.CGImage);
	if (width != 1 && (width & (width - 1)))
	{
		int i;
		for (i = 1; (i * 2) < width;)
			i <<= 1;
		width = i;
	}
	while (width > 1024)
		width >>= 1;

	GLuint height = CGImageGetHeight(image.CGImage);
	if (height != 1 && (height & (height - 1)))
	{
		int i;
		for (i = 1; (i * 2) < height;)
			i <<= 1;
		height = i;
	}
	while (height > 1024)
		height >>= 1;

	GLubyte* data = (GLubyte*) malloc(width * height * 4);
	CGContextRef ctx = CGBitmapContextCreate(data,
											 width,
											 height,
											 8,
											 width * 4,
											 CGImageGetColorSpace(image.CGImage),
											 kCGImageAlphaPremultipliedLast);

	//CGContextClearRect(ctx, CGRectMake(0, 0, width, height));
	if (width != CGImageGetWidth(image.CGImage) || height != CGImageGetHeight(image.CGImage))
	{
		CGAffineTransform trans = CGAffineTransformScale(
				CGAffineTransformIdentity,
				(float) width / (float) CGImageGetWidth(image.CGImage),
				(float) height / (float) CGImageGetHeight(image.CGImage));
		CGContextConcatCTM(ctx, trans);	
	}
	CGContextDrawImage(ctx,
					   CGRectMake(0,
								  0,
								  CGImageGetWidth(image.CGImage),
								  CGImageGetHeight(image.CGImage)),
					   image.CGImage);
	CGContextRelease(ctx);
	[image release];

	GLuint id;
	glGenTextures(1, &id);
	glBindTexture(GL_TEXTURE_2D, id);
	glTexImage2D(GL_TEXTURE_2D,
				 0,
				 GL_RGBA,
				 width,
				 height,
				 0,
				 GL_RGBA,
				 GL_UNSIGNED_BYTE,
				 data);
	free(data);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	return id;
}

- (void)rotate:(float)x y:(float)y z:(float)z
{
	rot[0] = (y / 2);
	rot[1] = (x / 2);
	rot[2] = z;
}

- (void)zoom:(float)z
{
	zoom += (z * 0.2);
	if (zoom < zoomMax)
		zoom = zoomMax;
}

- (void)zoomMax
{
	zoom = zoomMax;
}

- (void)render
{
    glClear(GL_COLOR_BUFFER_BIT);

	glMatrixMode(GL_MODELVIEW);
	GLfloat m[16];
	glGetFloatv(GL_MODELVIEW_MATRIX, m);
	glLoadIdentity();
	glRotatef(rot[0], 1, 0, 0);
	glRotatef(rot[1], 0, 1, 0);
	glRotatef(rot[2], 0, 0, 1);
	glMultMatrixf(m);
	rot[2] = 0;

	glPushMatrix();
	GLfloat scale = (1 / zoom);
	glScalef(scale, scale, scale);
		
	glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);

	glColor4f(1, 1, 1, 1);	
    glVertexPointer(3, GL_FLOAT, 0, scene_vert0);	
	glNormalPointer(GL_FLOAT, 0, scene_norm0);
	glTexCoordPointer(2, GL_FLOAT, 0, scene_tex0);
    glDrawArrays(GL_TRIANGLES, 0, sizeof(scene_vert0) / sizeof(GLfloat) / 3);

#if 0
	glColor4f(1, 1, 1, 1);	
    glVertexPointer(3, GL_FLOAT, 0, scene_vert1);	
	glNormalPointer(GL_FLOAT, 0, scene_norm1);
	glTexCoordPointer(2, GL_FLOAT, 0, scene_tex1);
    glDrawArrays(GL_TRIANGLES, 0, sizeof(scene_vert1) / sizeof(GLfloat) / 3);
#endif

	glPopMatrix();

    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{	
    // Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
	
	glViewport(0, 0, backingWidth, backingHeight);
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	glOrthof(-1, 1, -1.5, 1.5, -1, 1);

    return YES;
}

- (void)dealloc
{
    // Tear down GL
    if (defaultFramebuffer)
    {
        glDeleteFramebuffersOES(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
        glDeleteRenderbuffersOES(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }

    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    context = nil;

    [super dealloc];
}

@end
