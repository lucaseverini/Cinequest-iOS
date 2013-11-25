//
//  CinequestAppDelegate.m
//  Cinequest
//
//  Created by Loc Phan on 1/10/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "CinequestAppDelegate.h"
#import "FestivalParser.h"
#import "Reachability.h"
#import "StartupViewController.h"
#import "DataProvider.h"
#import "VenueParser.h"

#define ONE_YEAR (60.0 * 60.0 * 24.0 * 365.0)


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
#if TARGET_IPHONE_SIMULATOR
	NSLog(@"App folder: %@", NSHomeDirectory());
#endif // TARGET_IPHONE_SIMULATOR
		
    if (!self.mySchedule) {
        self.mySchedule = [NSMutableArray array];
    }
    
	deviceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
	NSLog(@"UI idiom: %ld %@", (long)deviceIdiom, deviceIdiom == UIUserInterfaceIdiomPhone ? @"(iPhone)" : @"(iPad)");
	NSLog(@"Device name: %@", [[UIDevice currentDevice] name]);
	NSLog(@"Device model: %@", [[UIDevice currentDevice] model]);
	
	CGSize screenSize = [[UIScreen mainScreen] currentMode].size;
	retinaDisplay = (screenSize.height >= 1536.0);
	iPhone4Display = (screenSize.height == 960.0);
	NSLog(@"Screen size: %gx%g %@", screenSize.width, screenSize.height, retinaDisplay ? @"(Retina)" : @"");

	OSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

	StartupViewController *startupViewController = [[StartupViewController alloc] initWithNibName:@"StartupViewController" bundle:nil];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:startupViewController];
	[navController setNavigationBarHidden:YES animated:NO];
	
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
	
	tabBar.delegate = self;
	
	[self startReachability:MAIN_FEED];
	
	return YES;
}

-(void)applicationDidEnterBackground:(UIApplication *)application{
    [self saveCalendarToDocuments];
}

-(void)applicationDidBecomeActive:(UIApplication *)application{
    
    if (!self.dictSavedEventsInCalendar) {
        self.dictSavedEventsInCalendar = [[NSMutableDictionary alloc] init];
    }
    
    NSURL *url = [[self documentsDirectory] URLByAppendingPathComponent:CALENDAR_FILE];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[url path]])
    {
        self.dictSavedEventsInCalendar = [NSMutableDictionary dictionaryWithContentsOfURL:url];
        NSLog(@"Content from Cache:%@",self.dictSavedEventsInCalendar);
    }
    else{
        
    }
}

//Saves the Calendar.plist file to Documents Directory to keep track of save items in calendar
-(void) saveCalendarToDocuments{
    NSError *error = nil;
    NSURL *url = [[self documentsDirectory] URLByAppendingPathComponent:CALENDAR_FILE];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[url path]]) {
        
        NSLog(@"Dictionary is:%@", [NSMutableDictionary dictionaryWithContentsOfURL:url]);
        
        [fileManager removeItemAtURL:url error:&error];
        BOOL flag = [self.dictSavedEventsInCalendar writeToURL:url atomically: YES];
        NSLog(@"Dictionary is after update:%@",[NSMutableDictionary dictionaryWithContentsOfURL:url]);
        
        if (flag) {
            NSLog(@"Success saving file");
        }
        else{
            NSLog(@"Fail saving file");
        }
    }
    else{
        BOOL flag = [self.dictSavedEventsInCalendar writeToURL:url atomically: YES];
        if (flag) {
            NSLog(@"Success saving file");
        }
        else{
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

- (void) jumpToScheduler
{
	tabBar.selectedIndex = 4;
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
		if(kSCNetworkReachabilityFlagsTransientConnection)
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
        
        // Pass back the Documents dir
        // rootDir = [fsManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    }
    
    return docsDir;
}

#pragma mark -
#pragma mark TabBarController delegate

- (BOOL) tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
	curTabIndex = [tabBarController selectedIndex];
	
	return YES;
}

- (void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
	if(curTabIndex != [tabBarController selectedIndex])
	{
		CATransition *animation = [CATransition animation];
		[animation setType:kCATransitionReveal];
		[animation setSubtype:curTabIndex > [tabBarController selectedIndex] ? kCATransitionFromLeft : kCATransitionFromRight];
		[animation setDuration:0.5];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
		[self.window.layer addAnimation:animation forKey:nil];
	}
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
             CinequestAppDelegate * __weak weakSelf = self;
             // Let's ensure that our code will be executed from the main queue
             dispatch_async(dispatch_get_main_queue(),
                            ^{
                                // The user has granted access to their Calendar; let's populate our UI with all events occuring in the next 24 hours.
                                [weakSelf accessGrantedForCalendar];
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
    NSLog(@"Identifier:%@ Calendar:%@",self.calendarIdentifier, self.cinequestCalendar);
    if (!self.cinequestCalendar) {
        [self checkAndCreateCalendar];
    }
}

-(void)checkAndCreateCalendar{
    
    EKCalendar *calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
    calendar.title = @"Cinequest";
    
    //Get the current EKSource in use
    EKSource *theSource = nil;
    theSource = self.eventStore.defaultCalendarForNewEvents.source;
    
    if (theSource) {
        calendar.source = theSource;
    } else {
        NSLog(@"Error: Local source not available");
        return;
    }
    
    if (!self.cinequestCalendar) {
        NSError *error = nil;
        BOOL result = [self.eventStore saveCalendar:calendar commit:YES error:&error];
        if (result) {
            self.calendarIdentifier = calendar.calendarIdentifier;
            
            NSArray *caleandarsArray = [NSArray array];
            caleandarsArray = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
            BOOL isCalendar = false;
            
            for (EKCalendar *iCalendar in caleandarsArray)
            {
                if ([iCalendar.title isEqualToString:@"Cinequest"] || [iCalendar.calendarIdentifier isEqualToString:self.calendarIdentifier]) {
                    isCalendar = true;
                    //Get and Save Calendar ID for future use
                    self.calendarIdentifier = iCalendar.calendarIdentifier;
                    [[NSUserDefaults standardUserDefaults] setValue:self.calendarIdentifier forKey:@"CalendarID"];
                    self.cinequestCalendar = [self.eventStore calendarWithIdentifier:self.calendarIdentifier];
                    break;
                }
            }
        }
        else {
            NSLog(@"Error saving calendar: %@.", error);
        }
    }
    else{
        NSLog(@"Calendar found with :%@",self.cinequestCalendar);
    }
}


#pragma mark -
#pragma mark Event Add/Delete from Calendar

- (void) addToDeviceCalendar:(Schedule*)film{
    NSDate *startDate = [film.startDate dateByAddingTimeInterval:ONE_YEAR];
    NSDate *endDate = [film.endDate dateByAddingTimeInterval:ONE_YEAR];
    NSString *uniqueIDForEvent = [NSString stringWithFormat:@"%@-%@",film.itemID,film.ID];
    if ([self.arrayCalendarItems containsObject:uniqueIDForEvent])
    {
        NSPredicate *predicateForEvents = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:self.cinequestCalendar]];
        //set predicate to search for an event of the calendar(you can set the startdate, enddate and check in the calendars other than the default Calendar)
        NSArray *events_Array = [self.eventStore eventsMatchingPredicate: predicateForEvents];
        //get array of events from the eventStore
        
        for (EKEvent *eventToCheck in events_Array)
        {
            if( [eventToCheck.title isEqualToString:film.title] )
            {
                NSError *err;
                NSString *stringID = eventToCheck.eventIdentifier;
                BOOL success = [self.eventStore removeEvent:eventToCheck span:EKSpanThisEvent error:&err];
                if(success)
                {
                    [self.arrayCalendarItems removeObject:uniqueIDForEvent];
                    [self.dictSavedEventsInCalendar removeObjectForKey:[NSString stringWithFormat:@"%@-%@",film.itemID,film.ID]];
                    [self.arrCalendarIdentifiers removeObject:stringID];
                    NSLog( @"Event %@ with ID:%@ deleted successfully", eventToCheck.title,[NSString stringWithFormat:@"%@-%@",film.itemID,film.ID]);
                    NSLog(@"Dictionary is after delete:%@",self.dictSavedEventsInCalendar);
                }
                break;
            }
        }
    }
    else
    {
        EKEvent *newEvent = [EKEvent eventWithEventStore:self.eventStore];
        newEvent.title = [NSString stringWithFormat:@"%@",film.title];
        newEvent.location = film.venue;
        newEvent.startDate = startDate;
        newEvent.endDate = endDate;
        [newEvent setCalendar:self.cinequestCalendar];
        NSError *error= nil;
        
        BOOL result = [self.eventStore saveEvent:newEvent span:EKSpanThisEvent error:&error];
        if (result)
        {
            [self.arrayCalendarItems addObject:uniqueIDForEvent];
            NSLog(@"Succesfully saved event %@ %@ - %@", newEvent.title, startDate, endDate);
            
        }
        
        NSPredicate *predicateForEvents = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:self.cinequestCalendar]];
        //set predicate to search for an event of the calendar(you can set the startdate, enddate and check in the calendars other than the default Calendar)
        NSArray *events_Array = [self.eventStore eventsMatchingPredicate:predicateForEvents];
        for (EKEvent *event in events_Array) {
            if (![self.dictSavedEventsInCalendar objectForKey:[NSString stringWithFormat:@"%@-%@",film.itemID,film.ID]]) {
                [self.dictSavedEventsInCalendar setObject:event.eventIdentifier forKey:[NSString stringWithFormat:@"%@-%@",film.itemID,film.ID]];
                [self.arrCalendarIdentifiers addObject:event.eventIdentifier];
                NSLog(@"Item added to Calednar Dictionary");
            }
        }
    }
    [self saveCalendarToDocuments];
}

- (void) addOrRemoveFilm:(Schedule*)film
{
	if(film.isSelected)
	{
		// Add the selected film
		BOOL alreadyAdded = NO;
		NSInteger scheduleCount = [mySchedule count];
		for(NSInteger idx = 0; idx < scheduleCount; idx++)
		{
			Schedule *obj = [mySchedule objectAtIndex:idx];
			if (obj.ID == film.ID)
			{
				alreadyAdded = YES;
				break;
			}
		}
		if(!alreadyAdded)
		{
			[mySchedule addObject:film];
			NSLog(@"%@ : %@ %@ added to my schedule", film.title, film.dateString, film.timeString);
		}
	}
	else
	{
		// Remove the un-selected film
		NSInteger scheduleCount = [mySchedule count];
		for(NSInteger idx = 0; idx < scheduleCount; idx++)
		{
			Schedule *obj = [mySchedule objectAtIndex:idx];
			if (obj.ID == film.ID)
			{
				[mySchedule removeObject:film];
				
				NSLog(@"%@ : %@ %@ removed from my schedule", film.title, film.dateString, film.timeString);
				break;
			}
		}
	}
}

- (void) populateCalendarEntries
{
    if (!self.mySchedule) {
        self.mySchedule = [NSMutableArray array];
    }
    
    if ([mySchedule count] == 0 && [[self.dictSavedEventsInCalendar allKeys] count]>0) {
        for (Schedule *schedule in self.festival.schedules) {
            NSString *stringID = [NSString stringWithFormat:@"%@-%@",schedule.itemID,schedule.ID];
            if ([[self.dictSavedEventsInCalendar allKeys] containsObject:stringID]) {
                EKEvent *event = [self.eventStore eventWithIdentifier:[self.dictSavedEventsInCalendar objectForKey:stringID]];
                if (event) {
                    schedule.isSelected = YES;
                    [mySchedule addObject:schedule];
                    [self.arrayCalendarItems addObject:stringID];
                }
                else{
                    [self.dictSavedEventsInCalendar removeObjectForKey:stringID];
                }
            }
        }
    }
}

@end

