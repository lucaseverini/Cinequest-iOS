//
//  GPlusDialogView.h
//  Cinequest
//
//  Created by Luca Severini on 1/21/14.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@interface GPlusDialogView : UIView
{
	CGFloat buttonHeight;
	CGFloat buttonSpacerHeight;
	CGRect prevDialogFrame;
}

@property (nonatomic, assign) CGRect alertFrame;
@property (nonatomic, retain) UIView *parentView;			// The parent view this 'dialog' is attached to
@property (nonatomic, retain) UIView *dialogView;			// Dialog's container view
@property (nonatomic, retain) UIViewController *content;	// Content view delegate within the dialog (place your ui elements here)
@property (nonatomic, assign) BOOL useMotionEffects;

- (id) initWithFrame:(CGRect)alertFrame;
- (id) initWithContent:(UIViewController*)viewController;
- (void) show;
- (void) close;
- (void) deviceOrientationDidChange:(NSNotification *)notification;
- (void) dealloc;

@end
