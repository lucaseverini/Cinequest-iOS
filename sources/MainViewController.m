//
//  MainViewController.m
//  Cinequest
//
//  Created by Luca Severini on 11/7/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "MainViewController.h"
#import "CinequestAppDelegate.h"
#import "FestivalParser.h"
#import "Reachability.h"
#import "DataProvider.h"
#import "NewsViewController.h"

@implementation MainViewController

@synthesize activityView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
	CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
	
    [super viewDidAppear:animated];

	[activityView startAnimating];
		
	[appDelegate startReachability:XML_FEED_URL];
	
	[appDelegate setMySchedule:[[NSMutableArray alloc] init]];
	[appDelegate setNewsView:[[NewsViewController alloc] init]];
	
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if(![prefs stringForKey:@"CalendarID"])
	{
        [prefs setObject:@"" forKey:@"CalendarID"];
    }
	
	[appDelegate setDataProvider:[[DataProvider alloc] init]];

	// Do we need it?
	if([appDelegate connectedToNetwork])
	{
		[appDelegate setOffSeason];
		// isOffSeason = YES;
		// NSLog(@"IS OFFSEASON? %@",(isOffSeason) ? @"YES" : @"NO");
	}

    FestivalParser *festivalParser = [[FestivalParser alloc] init];
	[appDelegate setFestival:[festivalParser parseFestival]];
	
	// Calc the delay to let the splash screen ve visible at least 3 seconds
	CFTimeInterval spentTime = CFAbsoluteTimeGetCurrent() - startTime;
	int64_t delayTime = spentTime >= 3.0 ? 0.0 : (3.0 - spentTime) * NSEC_PER_SEC;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime), dispatch_get_main_queue(),
	^{
		UIWindow *window = [appDelegate window];
		window.rootViewController = [appDelegate tabBarController];
	});
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	
	[activityView stopAnimating];
}

@end
