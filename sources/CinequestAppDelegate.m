//
//  CinequestAppDelegate.m
//  Cinequest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestAppDelegate.h"
#import "FestivalParser.h"
#import "Reachability.h"
#import "StartupViewController.h"
#import "DataProvider.h"
#import "VenueParser.h"


@implementation CinequestAppDelegate

@synthesize window;
@synthesize tabBar;
@synthesize mySchedule;
@synthesize isPresentingModalView;
@synthesize isLoggedInFacebook;
@synthesize isOffSeason;
@synthesize newsView;
@synthesize festival;
@synthesize venuesDictionary;
@synthesize reachability;
@synthesize networkConnection;
@synthesize dataProvider;
@synthesize OSVersion;
@synthesize iPhone4Display;
@synthesize retinaDisplay;
@synthesize deviceIdiom;
@synthesize festivalParsed;
@synthesize venuesParsed;
@synthesize eventStore;
@synthesize cinequestCalendar;
@synthesize calendarIdentifier;
@synthesize arrayCalendarItems;
@synthesize dictSavedEventsInCalendar;
@synthesize arrCalendarIdentifiers;

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    if([self checkForFirstAppLaunch])
    {
        [self removeUnwantedCalendars];
    }
    
	[self startReachability:MAIN_FEED];

	[self collectContextInformation];
	
    if (!self.mySchedule)
	{
        self.mySchedule = [NSMutableArray array];
    }

	StartupViewController *startupViewController = [[StartupViewController alloc] initWithNibName:@"StartupViewController" bundle:nil];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:startupViewController];
	[navController setNavigationBarHidden:YES animated:NO];
	
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
	
	tabBar.delegate = self;

	// Force to draw the tabbar items in red color
	[[UITabBar appearance] setTintColor:[UIColor redColor]];

	for(UITabBarItem *item in tabBar.tabBar.items)
	{
		// Force to draw the image of tabbar items with their own color
		item.selectedImage = item.image;
		item.image = [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
		
		// Force to draw the title of tabbar items with black or red if selected
		[item setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
		[item setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor redColor], NSForegroundColorAttributeName, nil] forState:UIControlStateSelected];
	}

	// Change the font color of Cancel button in the searchbar of FilmViewController to colorRed
	NSShadow *shadow = [NSShadow new];
	[shadow setShadowColor: [UIColor redColor]];
	[shadow setShadowOffset: CGSizeMake(0.0, 1.0)];
	[[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor redColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];

	return YES;
}

- (void) applicationDidEnterBackground:(UIApplication *)application
{
    [self saveCalendarToDocuments];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
    if (!self.dictSavedEventsInCalendar)
	{
        self.dictSavedEventsInCalendar = [[NSMutableDictionary alloc] init];
    }
    
    NSURL *url = [[self documentsDirectory] URLByAppendingPathComponent:CALENDAR_FILE];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[url path]])
    {
        self.dictSavedEventsInCalendar = [NSMutableDictionary dictionaryWithContentsOfURL:url];
        // NSLog(@"Content from Cache:%@", self.dictSavedEventsInCalendar);
    }
}

//Check if the application is launching for the first time
-(BOOL)checkForFirstAppLaunch
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
    {
        // app already launched
        return NO;
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // This is the first launch ever
        return YES;
    }
}

//Remove if extra calendar exists with name Cinequest
-(void)removeUnwantedCalendars
{
    EKEventStore *eventStoreLocal = [[EKEventStore alloc] init];
    NSArray *caleandarsArray = [[NSArray alloc] init];
    caleandarsArray = [eventStoreLocal calendarsForEntityType:EKEntityTypeEvent];
    
    for (EKCalendar *iCalendars in caleandarsArray)
    {
        NSLog(@"Calendar Title : %@", iCalendars.title);
        if ([iCalendars.title isEqualToString:@"Cinequest"])
        {
            NSError *error = nil;
            [eventStoreLocal removeCalendar:iCalendars commit:YES error:&error];
            NSLog(@"Error:%@",[error localizedDescription]);
        }
    }
}


//Saves the Calendar.plist file to Documents Directory to keep track of save items in calendar
- (void) saveCalendarToDocuments
{
    NSError *error = nil;
    NSURL *url = [[self documentsDirectory] URLByAppendingPathComponent:CALENDAR_FILE];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[url path]])
	{
        NSLog(@"Dictionary is:%@", [NSMutableDictionary dictionaryWithContentsOfURL:url]);
        
        [fileManager removeItemAtURL:url error:&error];
        BOOL flag = [self.dictSavedEventsInCalendar writeToURL:url atomically: YES];
        NSLog(@"Dictionary is after update:%@", [NSMutableDictionary dictionaryWithContentsOfURL:url]);
        
        if (flag)
		{
            NSLog(@"Success saving file");
        }
        else
		{
            NSLog(@"Fail saving file");
        }
    }
    else
	{
        BOOL flag = [self.dictSavedEventsInCalendar writeToURL:url atomically: YES];
        if (flag)
		{
            NSLog(@"Success saving file");
        }
        else
		{
            NSLog(@"Fail saving file");
        }
    }
}

- (void) fetchVenues
{
    // Store Venues in a dictionary--> Key in Dictionary is ID and Value is Venue
    self.venuesDictionary = [[VenueParser new] parseVenues];
    // Print Venue Dictionary
    // NSLog(@"Venues Dictionary:%@", self.venuesDictionary);
}

#pragma mark -
#pragma mark Network Reachability

- (BOOL) connectedToNetwork
{
	return [self.reachability isReachable];
}

- (void) startReachability:(NSString*)hostName
{
	if(hostName == nil)
	{
		return;
	}
	
	networkConnection = -1;

	NSRange range = [hostName rangeOfString:@"://"];
	NSString *cleanHostName = range.location == NSNotFound ? hostName : [hostName substringFromIndex:NSMaxRange(range)];
	range = [cleanHostName rangeOfString:@"/"];
	cleanHostName = range.location == NSNotFound ? hostName : [cleanHostName substringToIndex:NSMaxRange(range) - 1];
	
	if(reachability != nil)
	{
		[reachability stopNotifier];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
	}
	
	reachability = [Reachability reachabilityWithHostname:cleanHostName];
	[reachability startNotifier];
	
	// Wait for the networkConnection value to be set...
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	while(networkConnection < 0)
	{
		[runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	}
}

- (void) reachabilityDidChange:(NSNotification*)note
{
    Reachability *reach = note != nil ? [note object] : reachability;
	if([reach isReachable])
	{
		SCNetworkReachabilityFlags flags = [reach reachabilityFlags];
		if(flags & kSCNetworkReachabilityFlagsTransientConnection)
		{
			networkConnection = NETWORK_CONNECTION_PHONE;
		}
		else if(flags & kSCNetworkReachabilityFlagsReachable)
		{
			networkConnection = NETWORK_CONNECTION_WIFI;
		}
		else
		{
			networkConnection = NETWORK_CONNECTION_NONE;
		}
	}
	else
	{
		networkConnection = NETWORK_CONNECTION_NONE;
	}
	
	NSLog(@"Network Connection: %s", networkConnection == 1 ? "DialUp" : networkConnection == 2 ? "WiFi" : "None");
}

#pragma mark -
#pragma mark Utility functions

- (NSURL*) cachesDirectory
{
    static NSURL *cachesDir;
    
    if(cachesDir == nil)
    {
        // Pass back the Caches dir
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachesDir = [NSURL fileURLWithPath:[paths objectAtIndex:0] isDirectory:YES];
    }
    
    return cachesDir;
}

- (NSURL*) documentsDirectory
{
    static NSURL *docsDir;
    
    if(docsDir == nil)
    {
        // Pass back the Documents dir
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        docsDir = [NSURL fileURLWithPath:[paths objectAtIndex:0] isDirectory:YES];
    }
    
    return docsDir;
}

#pragma mark -
#pragma mark Access Calendar

// Check the authorization status of our application for Calendar
- (void) checkEventStoreAccessForCalendar
{
    if (!self.eventStore) {
        self.eventStore = [[EKEventStore alloc] init];
    }
    
    if (!self.arrayCalendarItems) {
        self.arrayCalendarItems = [[NSMutableArray alloc] init];
    }
    
    if (!self.dictSavedEventsInCalendar) {
        self.dictSavedEventsInCalendar = [[NSMutableDictionary alloc] init];
    }
    
    if (!self.arrCalendarIdentifiers) {
        self.arrCalendarIdentifiers = [[NSMutableArray alloc] init];
    }
    
    EKAuthorizationStatus status1 = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    
    switch (status1)
    {
            // Update our UI if the user has granted access to their Calendar
        case EKAuthorizationStatusAuthorized: [self accessGrantedForCalendar];
            break;
            
			// Prompt the user for access to Calendar if there is no definitive answer
        case EKAuthorizationStatusNotDetermined: [self requestCalendarAccess];
            break;
            
			// Display a message if the user has denied or restricted access to Calendar
        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning"
															message:@"Permission was not granted for Calendar"
															delegate:nil
															cancelButtonTitle:@"OK"
															otherButtonTitles:nil];
            [alert show];
        }
            break;
			
        default:
            break;
    }
}

// Prompt the user for access to their Calendar
- (void) requestCalendarAccess
{
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:
	^(BOOL granted, NSError *error)
	{
		if(granted)
		{
			// Let's ensure that our code will be executed from the main queue
			dispatch_async(dispatch_get_main_queue(),
			^{
				 // The user has granted access to their Calendar; let's populate our UI with all events occuring in the next 24 hours.
				 [appDelegate accessGrantedForCalendar];
			});
         }
     }];
}

// This method is called when the user has granted permission to Calendar
- (void) accessGrantedForCalendar
{
    // Let's get the default calendar associated with our event store
    self.calendarIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:@"CalendarID"];
    self.cinequestCalendar = [self.eventStore calendarWithIdentifier:self.calendarIdentifier];
    NSLog(@"Identifier:%@ Calendar:%@", self.calendarIdentifier, self.cinequestCalendar);
    if (!self.cinequestCalendar)
	{
        [self checkAndCreateCalendar];
    }
}

- (void) checkAndCreateCalendar
{
    EKCalendar *calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
    calendar.title = CALENDAR_NAME;
    
    //Get the current EKSource in use
    EKSource *theSource = nil;
    theSource = self.eventStore.defaultCalendarForNewEvents.source;
    
    if (theSource)
	{
        calendar.source = theSource;
    }
	else
	{
        NSLog(@"Error: Local source not available");
        return;
    }
    
    if (!self.cinequestCalendar)
	{
        NSError *error = nil;
        BOOL result = [self.eventStore saveCalendar:calendar commit:YES error:&error];
        if (result)
		{
            self.calendarIdentifier = calendar.calendarIdentifier;
            
            NSArray *caleandarsArray = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
            for (EKCalendar *iCalendar in caleandarsArray)
            {
                if ([iCalendar.title isEqualToString:CALENDAR_NAME] || [iCalendar.calendarIdentifier isEqualToString:self.calendarIdentifier])
				{
                    // Get and Save Calendar ID for future use
                    self.calendarIdentifier = iCalendar.calendarIdentifier;
                    [[NSUserDefaults standardUserDefaults] setValue:self.calendarIdentifier forKey:@"CalendarID"];
                    self.cinequestCalendar = [self.eventStore calendarWithIdentifier:self.calendarIdentifier];
                    break;
                }
            }
        }
        else
		{
            NSLog(@"Error saving calendar: %@.", error);
        }
    }
    else
	{
        NSLog(@"Calendar found with :%@", self.cinequestCalendar);
    }
}


#pragma mark -
#pragma mark Event Add/Delete from Calendar

- (void) addScheduleToDeviceCalendar:(Schedule*)schedule
{
    NSDate *startDate = schedule.startDate;
    NSDate *endDate = schedule.endDate;
	
    NSString *uniqueIDForEvent = [NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID];
    if ([self.arrayCalendarItems containsObject:uniqueIDForEvent])
    {
        NSPredicate *predicateForEvents = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:self.cinequestCalendar]];
        //set predicate to search for an event of the calendar(you can set the startdate, enddate and check in the calendars other than the default Calendar)
        NSArray *events_Array = [self.eventStore eventsMatchingPredicate: predicateForEvents];
        //get array of events from the eventStore
        
        for (EKEvent *eventToCheck in events_Array)
        {
            if( [eventToCheck.title isEqualToString:schedule.title] )
            {
                NSError *err;
                NSString *stringID = eventToCheck.eventIdentifier;
                BOOL success = [self.eventStore removeEvent:eventToCheck span:EKSpanThisEvent error:&err];
                if(success)
                {
                    [self.arrayCalendarItems removeObject:uniqueIDForEvent];
                    [self.dictSavedEventsInCalendar removeObjectForKey:[NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID]];
                    [self.arrCalendarIdentifiers removeObject:stringID];
                    NSLog( @"Event %@ with ID:%@ deleted successfully", eventToCheck.title,[NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID]);
                    NSLog(@"Dictionary is after delete:%@",self.dictSavedEventsInCalendar);
                }
                break;
            }
        }
    }
    else
    {
		Venue *venue = [appDelegate.venuesDictionary objectForKey:schedule.venueItem.ID];
		NSString *venueLocation = [NSString stringWithFormat:@"%@, %@, %@ %@", venue.address1, venue.city, venue.state, venue.zip];

        EKEvent *newEvent = [EKEvent eventWithEventStore:self.eventStore];
        newEvent.title = schedule.title;
        newEvent.location = [NSString stringWithFormat:@"Venue: %@ %@", schedule.venue, venueLocation];
        newEvent.startDate = startDate;
        newEvent.endDate = endDate;
        [newEvent setCalendar:self.cinequestCalendar];
		
        NSError *error = nil;
        BOOL result = [self.eventStore saveEvent:newEvent span:EKSpanThisEvent error:&error];
        if (result)
        {
            [self.arrayCalendarItems addObject:uniqueIDForEvent];
            NSLog(@"Succesfully saved event %@ %@ - %@", newEvent.title, startDate, endDate);
        }
        
        NSPredicate *predicateForEvents = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:self.cinequestCalendar]];
        // set predicate to search for an event of the calendar (you can set the startdate, enddate and check in the calendars other than the default Calendar)
        NSArray *events_Array = [self.eventStore eventsMatchingPredicate:predicateForEvents];
        for (EKEvent *event in events_Array)
		{
            if (![self.dictSavedEventsInCalendar objectForKey:[NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID]])
			{
                [self.dictSavedEventsInCalendar setObject:event.eventIdentifier forKey:[NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID]];
                [self.arrCalendarIdentifiers addObject:event.eventIdentifier];
                NSLog(@"Item added to Calendar dictionary");
            }
        }
    }
	
    [self saveCalendarToDocuments];
}

- (void) addOrRemoveSchedule:(Schedule*)schedule
{
	if(schedule.isSelected)
	{
		// Add the selected schedule
		BOOL alreadyAdded = NO;
		NSInteger scheduleCount = [mySchedule count];
		for(NSInteger idx = 0; idx < scheduleCount; idx++)
		{
			Schedule *obj = [mySchedule objectAtIndex:idx];
			if (obj.ID == schedule.ID)
			{
				alreadyAdded = YES;
				break;
			}
		}
		if(!alreadyAdded)
		{
			[mySchedule addObject:schedule];
			NSLog(@"%@ : %@ %@ added to my schedule", schedule.title, schedule.dateString, schedule.timeString);
		}
	}
	else
	{
		// Remove the un-selected schedule
		NSInteger scheduleCount = [mySchedule count];
		for(NSInteger idx = 0; idx < scheduleCount; idx++)
		{
			Schedule *obj = [mySchedule objectAtIndex:idx];
			if (obj.ID == schedule.ID)
			{
				[mySchedule removeObject:schedule];
				
				NSLog(@"%@ : %@ %@ removed from my schedule", schedule.title, schedule.dateString, schedule.timeString);
				break;
			}
		}
	}
}

- (void) populateCalendarEntries
{
    if (!self.mySchedule)
	{
        self.mySchedule = [NSMutableArray array];
    }
    
    if ([mySchedule count] == 0 && [[self.dictSavedEventsInCalendar allKeys] count] > 0)
	{
        for (Schedule *schedule in self.festival.schedules)
		{
            NSString *stringID = [NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID];
            if ([[self.dictSavedEventsInCalendar allKeys] containsObject:stringID])
			{
                EKEvent *event = [self.eventStore eventWithIdentifier:[self.dictSavedEventsInCalendar objectForKey:stringID]];
                if (event)
				{
                    schedule.isSelected = YES;
                    [mySchedule addObject:schedule];
                    [self.arrayCalendarItems addObject:stringID];
                }
                else
				{
                    [self.dictSavedEventsInCalendar removeObjectForKey:stringID];
                }
            }
        }
    }
}

- (void) collectContextInformation
{
#if TARGET_IPHONE_SIMULATOR
	NSLog(@"App folder: %@", NSHomeDirectory());
#endif // TARGET_IPHONE_SIMULATOR
	
	NSDictionary *pList = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];
	NSLog(@"Cinequest App Version %@ (built %s %s)", [pList objectForKey:@"CFBundleShortVersionString"], __DATE__, __TIME__);
	NSLog(@"Bundle ID: %@", [pList objectForKey:@"CFBundleIdentifier"]);

	NSLog(@"Device name: %@", [[UIDevice currentDevice] name]);
	
	struct utsname systemInfo;
    uname(&systemInfo);
	NSLog(@"Device model: %@ (%s)", [[UIDevice currentDevice] model], systemInfo.machine);
	
	OSVersion = [[UIDevice currentDevice] systemVersion];
	NSLog(@"iOS Version: %@", OSVersion);
	
	NSLog(@"64-bit: %@", sizeof(long) == 8 ? @"Yes" : @"No");
	
	CGSize screenSize = [[UIScreen mainScreen] currentMode].size;
	retinaDisplay = (screenSize.height >= 1536.0);
	iPhone4Display = (screenSize.height == 960.0);
	NSLog(@"Screen size: %gx%g %@", screenSize.width, screenSize.height, retinaDisplay ? @"(Retina)" : @"");
	NSLog(@"Screen scale: %g", [UIScreen mainScreen].scale);
	
	deviceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
	NSLog(@"UI idiom: %ld %@", (long)deviceIdiom, deviceIdiom == UIUserInterfaceIdiomPhone ? @"(iPhone)" : @"(iPad)");
}

- (BOOL) application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation
{
    return [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

@end

