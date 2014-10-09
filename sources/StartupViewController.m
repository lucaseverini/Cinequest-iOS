//
//  StartupViewController.m
//  Cinequest
//
//  Created by Luca Severini on 11/7/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "StartupViewController.h"
#import "CinequestAppDelegate.h"
#import "FestivalParser.h"
#import "Reachability.h"
#import "DataProvider.h"
#import "NewsViewController.h"
#import "Film.h"
#import "Forum.h"
#import "Special.h"

@implementation StartupViewController

@synthesize cinequestImage;
@synthesize sjsuImage;
@synthesize activityView;

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

	[app setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade]; // Hide out the status bar
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
	
	[activityView stopAnimating];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[app setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

	[super viewWillDisappear: animated]; // Make it animated
}

- (void) viewDidLayoutSubviews
{
	if(appDelegate.iPhone4Display)
	{
		// Set the position correctly to compensate the shorter screen on iPhone 4
		[self.cinequestImage setFrame:CGRectOffset(self.cinequestImage.frame, 0.0, -44.0)];
		[self.activityView setFrame:CGRectOffset(self.activityView.frame, 0.0, -80.0)];		
		[self.sjsuImage setFrame:CGRectOffset(self.sjsuImage.frame, 0.0, -80.0)];
	}
	else
	{
		// Load the correct image for taller screen on iPhone 5
		[self.cinequestImage setImage:[UIImage imageNamed:@"Splash5.png"]];
	}
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

- (void) viewDidAppear:(BOOL)animated
{
	CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
	
    [super viewDidAppear:animated];

	[activityView startAnimating];
	
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if(![prefs stringForKey:@"CalendarID"])
	{
        [prefs setObject:@"" forKey:@"CalendarID"];
    }
	
	appDelegate.dataProvider = [DataProvider new];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		[appDelegate fetchFestival];
	});
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		[appDelegate fetchVenues];
	});

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		[appDelegate checkEventStoreAccessForCalendar];
	});

	// Calc the delay to leave the splash screen visible for at least 3 seconds
	CFTimeInterval spentTime = CFAbsoluteTimeGetCurrent() - startTime;
	int64_t delayTime = spentTime >= 2.0 ? 0.0 : (2.0 - spentTime) * NSEC_PER_SEC;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime), dispatch_get_main_queue(),
	^{
		UIWindow *window = [appDelegate window];
		[UIView transitionWithView:window duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:
		^{
			while(!appDelegate.festivalParsed || !appDelegate.venuesParsed) // Wait for festival and venues to be parsed completely...
			{
				[NSThread sleepForTimeInterval:0.01];
			}
			
			window.rootViewController = [appDelegate tabBar];
		}
		completion:nil];
	});
}

@end


