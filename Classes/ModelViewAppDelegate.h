//
//  ModelViewAppDelegate.h
//  ModelView
//
//  Copyright (c) 2010-2016 Andrew Henroid. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;

@interface ModelViewAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

@end

