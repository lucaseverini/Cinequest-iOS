//
//  GPlusDialogView.m
//  Cinequest
//
//  Created by Luca Severini on 1/21/14.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "GPlusDialogView.h"

const static CGFloat kDialogViewCornerRadius = 7.0;
const static CGFloat kDialogViewMotionEffectExtent = 10.0;
const static CGFloat kDialogViewAnimationDuration = 0.3;


@implementation GPlusDialogView

@synthesize alertFrame;
@synthesize parentView;
@synthesize content;
@synthesize dialogView;
@synthesize useMotionEffects;

- (id) initWithContent:(UIViewController*)viewController
{
	CGRect frame;
	
	if([viewController isKindOfClass:[UINavigationController class]])
	{
		frame = [(UINavigationController*)viewController topViewController].view.frame;
	}
	else
	{
		frame = viewController.view.frame;
	}

	// Center frame on screen
	CGSize screenSize = [self countScreenSize];	
	frame.origin.x = screenSize.width / 2.0 - frame.size.width / 2.0;
	frame.origin.y = screenSize.height / 2.0 - frame.size.height / 2.0;
	
    self = [self initWithFrame:frame];
    if(self != nil)
	{
		[self setContent:viewController];
	}
	
	return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self != nil)
	{
		self.alertFrame = frame;
        useMotionEffects = YES;
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
	
    return self;
}

// Create the dialog view, and animate opening the dialog
- (void) show
{
    dialogView = [self createContainerView];

    dialogView.layer.shouldRasterize = YES;
    dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
  
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];

#if (defined(__IPHONE_7_0))
    if (useMotionEffects)
	{
        [self applyMotionEffects];
    }
#endif

    dialogView.layer.opacity = 0.5;
    dialogView.layer.transform = CATransform3DMakeScale(1.3, 1.3, 1.0);

    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];

    [self addSubview:dialogView];

    // Can be attached to a view or to the top most window
    // Attached to a view:
    if (parentView != NULL)
	{
        [parentView addSubview:self];
    }
	else	// Attached to the top most window (make sure we are using the right orientation):
	{
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (interfaceOrientation)
		{
            case UIInterfaceOrientationLandscapeLeft:
                self.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                self.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
                break;

            case UIInterfaceOrientationPortraitUpsideDown:
                self.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
                break;

            default:
                break;
        }

        [[[[UIApplication sharedApplication] windows] firstObject] addSubview:self];
    }

    [UIView animateWithDuration:kDialogViewAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
	animations:
	^{
		self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4];
		dialogView.layer.opacity = 1.0;
		dialogView.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0);
	}
	completion:NULL];
}

// Button has been touched
- (IBAction) closeDialog:(id)sender
{
    NSLog(@"Button %@ Clicked", sender);
    [self close];
}

// Dialog close animation then cleaning and removing the view from the parent
- (void) close
{
    CATransform3D currentTransform = dialogView.layer.transform;

    CGFloat startRotation = [[dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0, 0.0, 0.0);

    dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1.0, 1.0, 1.0));
    dialogView.layer.opacity = 1.0;

    [UIView animateWithDuration:kDialogViewAnimationDuration delay:0.0 options:UIViewAnimationOptionTransitionNone
	animations:
	^{
		self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
		dialogView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6, 0.6, 1.0));
		dialogView.layer.opacity = 0.0;
	}
	completion:
	^(BOOL finished)
	{
		for(UIView *view in [self subviews])
		{
			[view removeFromSuperview];
		}
		
		[self removeFromSuperview];
	}];
}

// Creates the container view here: create the dialog, then add the custom content and buttons
- (UIView*) createContainerView
{
	if(content == nil)
	{
		return nil;
	}
	
    CGSize screenSize = [self countScreenSize];

    // For the black background
    [self setFrame:CGRectMake(0.0, 0.0, screenSize.width, screenSize.height)];

    UIView *dialogContainer = [[UIView alloc] initWithFrame:alertFrame];
	dialogContainer.opaque = NO;
	dialogContainer.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
	[dialogContainer.layer setCornerRadius:kDialogViewCornerRadius];
	[dialogContainer.layer setMasksToBounds:YES];

    // Add the custom container if there is any
    [dialogContainer addSubview:content.view];

    return dialogContainer;
}

// Helper function: count and return the screen's size
- (CGSize) countScreenSize
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
	{
        CGFloat tmp = screenWidth;
        screenWidth = screenHeight;
        screenHeight = tmp;
    }

    return CGSizeMake(screenWidth, screenHeight);
}

#if (defined(__IPHONE_7_0))
// Add motion effects
- (void) applyMotionEffects
{
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
	{
        return;
    }

    UIInterpolatingMotionEffect *horizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kDialogViewMotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @( kDialogViewMotionEffectExtent);

    UIInterpolatingMotionEffect *verticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kDialogViewMotionEffectExtent);
    verticalEffect.maximumRelativeValue = @( kDialogViewMotionEffectExtent);

    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[horizontalEffect, verticalEffect];

    [dialogView addMotionEffect:motionEffectGroup];
}
#endif

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

// Handle device orientation changes
- (void) deviceOrientationDidChange:(NSNotification*)notification
{
    // If dialog is attached to the parent view, it probably wants to handle the orientation change itself
    if (parentView != NULL)
	{
        return;
    }

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    CGFloat startRotation = [[self valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CGAffineTransform rotation;

    switch (interfaceOrientation)
	{
        case UIInterfaceOrientationLandscapeLeft:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 270.0 / 180.0);
            break;

        case UIInterfaceOrientationLandscapeRight:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 90.0 / 180.0);
            break;

        case UIInterfaceOrientationPortraitUpsideDown:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 180.0 / 180.0);
            break;

        default:
            rotation = CGAffineTransformMakeRotation(-startRotation + 0.0);
            break;
    }

    [UIView animateWithDuration:kDialogViewAnimationDuration delay:0.0 options:UIViewAnimationOptionTransitionNone
	animations:
	^{
		dialogView.transform = rotation;
	}
	completion:^(BOOL finished)
	{
		// fix errors caused by being rotated one too many times
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(),
		^{
			UIInterfaceOrientation endInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
			if (interfaceOrientation != endInterfaceOrientation)
			{
				// TODO user moved phone again before than animation ended: rotation animation can introduce errors here
			}
		});
	}];
}

// Handle keyboard show/hide changes
// Improve it for correct repositioning of dialog in any circumstance (more general)
- (void) keyboardWillShow:(NSNotification*)notification
{
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(UIInterfaceOrientationIsLandscape(interfaceOrientation))
	{
        CGFloat tmp = keyboardRect.size.height;
        keyboardRect.size.height = keyboardRect.size.width;
        keyboardRect.size.width = tmp;
    }

    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionTransitionNone
	animations:
	^{
		prevDialogFrame = CGRectNull;
		if(CGRectIntersectsRect(CGRectInset(dialogView.frame, 0.0, -20.0), keyboardRect))
		{
			CGRect frame = dialogView.frame;
			prevDialogFrame = frame;
			frame.origin.y = keyboardRect.origin.y - 20.0 - frame.size.height;
			dialogView.frame = frame;
		}
	}
	completion:nil];
}

- (void) keyboardWillHide:(NSNotification*)notification
{
	if(!CGRectEqualToRect(prevDialogFrame, CGRectNull))
	{
		[UIView animateWithDuration:kDialogViewAnimationDuration delay:0.0 options:UIViewAnimationOptionTransitionNone animations:
		^{
			dialogView.frame = prevDialogFrame;
		}
		completion:nil];
	}
}

@end

