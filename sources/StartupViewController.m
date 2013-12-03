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
#import "NewFestivalParser.h"
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
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad
{
	[app setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	
    [super viewDidLoad];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
	
	[activityView stopAnimating];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[app setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

	[super viewWillDisappear: animated];
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
		appDelegate.festival = [[NewFestivalParser new] parseFestival];

        // uncomment the block below to test the console log for the A-Z segment
/*
		NSLog(@"alphabet keys");
        NSLog(@"%@", newFestival.sortedKeysInAlphabetToFilmsDictionary);
        for (NSString *key in newFestival.sortedKeysInAlphabetToFilmsDictionary) {
            NSLog(@"%@", key);
            NSArray *films = [newFestival.alphabetToFilmsDictionary objectForKey:key];
            for (Film *film in films) {
                NSLog(@"%@", film.name);
                for (Schedule *schedule in film.schedules) {
                    NSLog(@"%@ - %@", schedule.dateString, schedule.startTime);
                }
            }
        }
*/
        // uncomment the block below to test the console log for the Date segment
/*
        NSLog(@"date to films keys:");
        NSLog(@"%@", appDelegate.festival.sortedKeysInDateToFilmsDictionary);
        NSLog(@"date to films indexes");
        NSLog(@"%@", appDelegate.festival.sortedIndexesInDateToFilmsDictionary);
        
        for (NSString *key in appDelegate.festival.sortedKeysInDateToFilmsDictionary) {
            NSLog(@"%@", key);
            NSArray *films = [appDelegate.festival.dateToFilmsDictionary objectForKey:key];
            
            for (Film *film in films) {
                Schedule *schedule;
                for (Schedule *sch in film.schedules) {
                    if ([sch.longDateString isEqualToString:key])
                        schedule = sch;
                }
                NSLog(@"%@ - %@", film.name, schedule.startTime);
            }
            NSLog(@"\n");
        }
*/
        // uncomment the block below to test the console log for the Forum tab
/*
        NSLog(@"date to forums keys:");
        NSLog(@"%@", newFestival.sortedKeysInDateToForumsDictionary);
        NSLog(@"date to films indexes");
        NSLog(@"%@", newFestival.sortedIndexesInDateToForumsDictionary);
        for (NSString *key in newFestival.sortedKeysInDateToForumsDictionary) {
            NSLog(@"%@", key);
            NSArray *forums = [newFestival.dateToForumsDictionary objectForKey:key];
            
            for (Forum *forum in forums) {
                Schedule *schedule;
                for (Schedule *sch in forum.schedules) {
                    if ([sch.longDateString isEqualToString:key])
                        schedule = sch;
                }
                NSLog(@"%@ - %@", forum.name, schedule.startTime);
            }
            NSLog(@"\n");
        }
*/
        // uncomment the block below to test the console log for the Event Tab (Event ~ Special)
/*
        NSLog(@"date to specials keys:");
        NSLog(@"%@", newFestival.sortedKeysInDateToSpecialsDictionary);
        NSLog(@"date to specials indexes");
        NSLog(@"%@", newFestival.sortedIndexesInDateToSpecialsDictionary);
        for (NSString *key in newFestival.sortedKeysInDateToSpecialsDictionary) {
            NSLog(@"%@", key);
            NSArray *specials = [newFestival.dateToSpecialsDictionary objectForKey:key];
         
            for (Special *special in specials) {
                Schedule *schedule;
                for (Schedule *sch in special.schedules) {
                    if ([sch.longDateString isEqualToString:key])
                        schedule = sch;
                }
                NSLog(@"%@ - %@", special.name, schedule.startTime);
            }
            NSLog(@"\n");
        }
*/
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


