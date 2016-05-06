//
//  EAGLView.m
//  Viewer
//
//  Copyright (c) 2010-2016 Andrew Henroid. All rights reserved.
//

#import "EAGLView.h"

#import "ES1Renderer.h"

@implementation EAGLView

@synthesize animating;
@dynamic animationFrameInterval;

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{    
    if ((self = [super initWithCoder:coder]))
    {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

		renderer = [[ES1Renderer alloc] init];

        if (!renderer)
        {
            [self release];
            return nil;
        }
		
        animating = FALSE;
        displayLinkSupported = FALSE;
        animationFrameInterval = 1;
        displayLink = nil;
        animationTimer = nil;

        // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
        // class is used as fallback when it isn't available.
        NSString *reqSysVer = @"3.1";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
            displayLinkSupported = TRUE;

		self.multipleTouchEnabled = YES;
	}

    return self;
}

- (void)drawView:(id)sender
{
    [renderer render];
}

- (void)layoutSubviews
{
    [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;

        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        if (displayLinkSupported)
        {
            // CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
            // if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
            // not be called in system versions earlier than 3.1.

            displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
            [displayLink setFrameInterval:animationFrameInterval];
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawView:) userInfo:nil repeats:TRUE];

        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            animationTimer = nil;
        }

        animating = FALSE;
    }
}

static inline CGFloat calcDist(CGPoint a, CGPoint b)
{
	CGFloat dx = (a.x - b.x);
	CGFloat dy = (a.y - b.y);
	return sqrtf(dx * dx + dy * dy);
}

static inline int calcRot(CGPoint p0, CGPoint p1, CGPoint p2)
{
	int dx1 = (p1.x - p0.x);
	int dy1 = (p1.y - p0.y);
	int dx2 = (p2.x - p0.x);
	int dy2 = (p2.y - p0.y);
	int v1 = (dx1 * dy2);
	int v2 = (dy1 * dx2);
	if (v1 > v2)
		return 1;
	else if (v1 < v2)
		return -1;
	else if ((dx1 * dx2) < 0 || (dy1 * dy2) < 0)
		return -1;
	else if ((dx1 * dx1 + dy1 * dy1) < (dx2 * dx2 + dy2 * dy2))
		return 1;
	return 0;			   
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if ([touches count] == 1)
	{
		UITouch* touch = [touches anyObject];	
		if ([touch tapCount] == 1)
			[renderer rotate:0 y:0 z:0];
		else
			[renderer zoomMax];
	}
	touchDist = 0;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if ([touches count] == 1)
	{
		UITouch* touch = [touches anyObject];	
		if ([touch tapCount] == 1)
		{
			CGPoint now = [touch locationInView:self];
			CGPoint prev = [touch previousLocationInView:self];
			[renderer rotate:(now.x - prev.x) y:(now.y - prev.y) z:0];
		}
	}
	else
	{
		NSArray* t = [touches allObjects];
		UITouch* t0 = [t objectAtIndex:0];
		UITouch* t1 = [t objectAtIndex:1];
		
		CGFloat dist = calcDist([t0 locationInView:self], [t1 locationInView:self]);
		if (touchDist != 0)
			[renderer zoom:(touchDist - dist)];
		touchDist = dist;
#if 0
		CGFloat dir = calcDir([t0 previousLocationInView:self],
							  [t1 previousLocationInView:self],
							  [t0 locationInView:self]);		
		[renderer rotate:0 y:0 z:(dir * 10)];
#endif
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)dealloc
{
    [renderer release];

    [super dealloc];
}

@end
