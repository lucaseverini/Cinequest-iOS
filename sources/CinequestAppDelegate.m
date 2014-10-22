//
//  CinequestAppDelegate.m
//  Cinequest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <EventKit/EKObject.h>
#import <EventKit/EKEvent.h>
#import <EventKit/EventKitDefines.h>
#import <EventKit/EKCalendarItem.h>
#import "CinequestAppDelegate.h"
#import "FestivalParser.h"
#import "Reachability.h"
#import "StartupViewController.h"
#import "DataProvider.h"
#import "VenueParser.h"
#import "NewFestivalParser.h"
#import "MBProgressHUD.h"


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
@synthesize firstLaunch;
@synthesize locationServicesON;
@synthesize userLocationON;

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [Crashlytics startWithAPIKey:CRASHLYTICS_ID];
	if([self checkPrefsForDataDeletion])
	{
		NSFileManager *fileMgr = [NSFileManager defaultManager];
		
		NSString *cacheDir = [[[self cachesDirectory] path] stringByAppendingPathComponent:CINEQUEST_DATACACHE_FOLDER];
		if([fileMgr removeItemAtPath:cacheDir error:nil])
		{
			NSLog(@"App cache data deleted");
		}
		
		NSInteger fileDeleted = 0;
		NSString *docDir = [[self documentsDirectory] path];
		for(NSString *file in [fileMgr contentsOfDirectoryAtPath:docDir error:nil])
		{
			if([fileMgr removeItemAtPath:[docDir stringByAppendingPathComponent:file] error:nil])
			{
				fileDeleted++;
			}
		}
		if(fileDeleted > 0)
		{
			NSLog(@"App document data deleted");
		}
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	[self checkForFirstAppLaunch];

	if(firstLaunch)
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
    
    // Set UITextFields to have light appearance instead of dark appearance
    [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceLight];

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
    [self saveCalendar];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
	[self loadCalendar];
}

- (void) applicationWillTerminate:(UIApplication*)application
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL) checkPrefsForDataDeletion
{
	NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
		
	BOOL deleteAppData = [userDefs boolForKey:@"deleteAppData"];
	if(deleteAppData)
	{
        [userDefs setBool:NO forKey:@"deleteAppData"];
        [userDefs synchronize];
	}
		
	return deleteAppData;
}

// Check if the application is launching for the first time
- (BOOL) checkForFirstAppLaunch
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
	{
        // App already launched
        firstLaunch = NO;
    }
	else
	{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // This is the first launch ever
        firstLaunch = YES;
    }

    return firstLaunch;
}

- (void) fetchVenues
{
    self.venuesDictionary = [[VenueParser new] parseVenues];
}

- (void) fetchFestival
{
	self.festival = [[NewFestivalParser new] parseFestival];
}

#pragma mark - Network Reachability

- (BOOL) connectedToNetwork
{
	return [self.reachability isReachable];
}

// Initialze the connection, and hold in the loop until get connected
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

// Notify if changing the type of connection, then write down the log
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

#pragma mark - Utility functions

// Returns the caches directory in the domain server, then set to local variable
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

// Returns the document directory in the domain server, then set to local variable
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

#pragma mark - Access Calendar

// Check if there are any new events on the calendar, then sync with the stored databse
- (void) checkAndSyncWithCalendar:(BOOL)calendarAccessGranted
{
	NSLog(@"checkAndSyncWithCalendar");
	
	NSArray *allKeys = [self.dictSavedEventsInCalendar allKeys];
	for (NSString* key in allKeys)
	{
		NSMutableArray *eventArray = [self.dictSavedEventsInCalendar objectForKey:key];
		if(eventArray != nil)
		{
			EKEvent *newEvent = [EKEvent eventWithEventStore:self.eventStore];
			if(newEvent != nil)
			{
				NSString *uniqueIDForEvent = key;
				NSString *title = [eventArray objectAtIndex:0];
				NSString *location = [eventArray objectAtIndex:1];
				NSDate *startDate = [eventArray objectAtIndex:2];
				NSDate *endDate = [eventArray objectAtIndex:3];

				// Search for same event already present in the calendar
				NSString *eventIdentifier = nil;
				NSPredicate *predicateForEvents = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:self.cinequestCalendar]];
				NSArray *eventsArray = [self.eventStore eventsMatchingPredicate: predicateForEvents];
				for (EKEvent *event in eventsArray)
				{
					if([event.title isEqualToString:title])
					{
						eventIdentifier = event.eventIdentifier;
						break;
					}
				}

				if(eventIdentifier == nil)
				{
					newEvent.title = title;
					newEvent.location = location;
					newEvent.startDate = startDate;
					newEvent.endDate = endDate;
					
					[newEvent setCalendar:self.cinequestCalendar];

					NSError *error = nil;
					if ([self.eventStore saveEvent:newEvent span:EKSpanThisEvent error:&error])
					{
						[self.arrayCalendarItems addObject:uniqueIDForEvent];
						
						NSLog(@"Succesfully saved event %@ %@", newEvent.title, newEvent.eventIdentifier);
						
						eventIdentifier = newEvent.eventIdentifier;
					}
				}

				NSArray *newEventDict = [NSArray arrayWithObjects:newEvent.title, newEvent.location, newEvent.startDate, newEvent.endDate, eventIdentifier, nil];
				[self.dictSavedEventsInCalendar setObject:newEventDict forKey:uniqueIDForEvent];
			}
		}
	}
	
	[self saveCalendar];
}

// Check the authorization status of our application for Calendar
- (void) checkEventStoreAccessForCalendar
{
    if (!self.eventStore)
	{
        self.eventStore = [EKEventStore new];
    }
    
    if (!self.arrayCalendarItems)
	{
        self.arrayCalendarItems = [NSMutableArray new];
    }
    
    if (!self.dictSavedEventsInCalendar)
	{
        self.dictSavedEventsInCalendar = [NSMutableDictionary new];
    }
    
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    switch (status)
    {
		// Update our UI if the user has granted access to their Calendar
        case EKAuthorizationStatusAuthorized:
		{
			[self accessGrantedForCalendar];
			
			if (![[NSUserDefaults standardUserDefaults] boolForKey:@"CalendarAccessGranted"])
			{
				[self checkAndSyncWithCalendar:YES];
				
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CalendarAccessGranted"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}

			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"UserWarnedStatusDenied"];
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"UserWarnedStatusRestricted"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
            break;
            
		// Prompt the user for access to Calendar if there is no definitive answer
        case EKAuthorizationStatusNotDetermined:
		{
			[self requestCalendarAccess];
		}
            break;
            
		// Display a message if the user has denied or restricted access to Calendar
        case EKAuthorizationStatusDenied:
        {
 			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CalendarAccessGranted"])
			{
				// [self checkAndSyncWithCalendar:NO];
				
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CalendarAccessGranted"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
			
 			if (![[NSUserDefaults standardUserDefaults] boolForKey:@"UserWarnedStatusDenied"])
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning"
															message:@"Permission was not granted for Calendar"
															delegate:nil
															cancelButtonTitle:@"OK"
															otherButtonTitles:nil];
				[alert show];
				
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UserWarnedStatusDenied"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
        }
            break;

        case EKAuthorizationStatusRestricted:
        {
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CalendarAccessGranted"])
			{
				// [self checkAndSyncWithCalendar:NO];
				
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CalendarAccessGranted"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}

 			if (![[NSUserDefaults standardUserDefaults] boolForKey:@"UserWarnedStatusRestricted"])
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning"
															message:@"Permission was not granted for Calendar"
															delegate:nil
															cancelButtonTitle:@"OK"
															otherButtonTitles:nil];
				[alert show];

				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UserWarnedStatusRestricted"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
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
		else
		{
			NSLog(@"User refused Calendar access");
		}
     }];
}

// This method is called when the user has granted permission to Calendar
- (void) accessGrantedForCalendar
{
    // Let's get the default calendar associated with our event store
    self.calendarIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:@"CalendarID"];
	if(self.calendarIdentifier != nil)
	{
		self.cinequestCalendar = [self.eventStore calendarWithIdentifier:self.calendarIdentifier];
	}
    if (self.cinequestCalendar == nil)
	{
        [self checkAndCreateCalendar];
    }
	if(self.cinequestCalendar != nil)
	{
		NSLog(@"Identifier:%@ Calendar:%@", self.calendarIdentifier, self.cinequestCalendar);
	}
	else
	{
		NSLog(@"Calendar is not available");
	}
}

- (void) checkAndCreateCalendar
{
    EKCalendar *calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
    calendar.title = CALENDAR_NAME;
    
    // Get the current EKSource in use
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


#pragma mark - Calendar

// Remove if extra calendar exists with name Cinequest
- (void) removeUnwantedCalendars
{
    EKEventStore *eventStoreLocal = [[EKEventStore alloc] init];
    NSArray *calendarsArray = [NSArray arrayWithArray:[eventStoreLocal calendarsForEntityType:EKEntityTypeEvent]];
    
    for (EKCalendar *iCalendars in calendarsArray)
	{
        NSLog(@"Calendar Title : %@", iCalendars.title);
        
        if ([iCalendars.title isEqualToString:@"Cinequest"])
		{
            NSError *error = nil;
            [eventStoreLocal removeCalendar:iCalendars commit:YES error:&error];
            if (error != nil)
			{
                NSLog(@"Error:%@",[error localizedDescription]);
            }
        }
    }
}

// Saves the Calendar.plist file to Documents Directory to keep track of events in calendar
- (void) saveCalendar
{
    NSURL *url = [[self documentsDirectory] URLByAppendingPathComponent:CALENDAR_FILE];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[url path]])
	{
        [fileManager removeItemAtURL:url error:nil];
	}
    
	if (![self.dictSavedEventsInCalendar writeToURL:url atomically: YES])
	{
		NSLog(@"Fail saving calendar file");
	}
}

// Loads the Calendar.plist file from Documents Directory to keep track of events in calendar
- (void) loadCalendar
{
	NSURL *url = [[self documentsDirectory] URLByAppendingPathComponent:CALENDAR_FILE];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:[url path]])
	{
		self.dictSavedEventsInCalendar = [NSMutableDictionary dictionaryWithContentsOfURL:url];
	}
	else
	{
		NSLog(@"Fail loading calendar file");
	}
	
	if(self.dictSavedEventsInCalendar == nil)
	{
		self.dictSavedEventsInCalendar = [NSMutableDictionary new];
	}
}

- (BOOL) addOrRemoveScheduleToCalendar:(Schedule*)schedule
{
    NSDate *startDate = schedule.startDate;
    NSDate *endDate = schedule.endDate;
    NSString *uniqueIDForEvent = [NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID];
	
    if ([self.arrayCalendarItems containsObject:uniqueIDForEvent])
    {
		if(self.cinequestCalendar != nil)
		{
			NSPredicate *predicateForEvents = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:self.cinequestCalendar]];
		
			// Set predicate to search for an event of the calendar (you can set the startdate, enddate and check in the calendars other than the default Calendar)
			NSArray *events_Array = [self.eventStore eventsMatchingPredicate: predicateForEvents];
			for (EKEvent *eventToCheck in events_Array)
			{
				if([eventToCheck.title isEqualToString:schedule.title])
				{
					NSError *err;
					BOOL success = [self.eventStore removeEvent:eventToCheck span:EKSpanThisEvent error:&err];
					if(success)
					{
						[self.arrayCalendarItems removeObject:uniqueIDForEvent];
						[self.dictSavedEventsInCalendar removeObjectForKey:uniqueIDForEvent];
						
						NSLog( @"Event %@ with ID:%@ deleted successfully", eventToCheck.title, uniqueIDForEvent);
						
						// NSLog(@"Dictionary is after delete:%@", self.dictSavedEventsInCalendar);
	 
						[self saveCalendar];
						
						return YES;
					}
					
					return NO;
				}
			}
		}
		else
		{
			[self.dictSavedEventsInCalendar removeObjectForKey:uniqueIDForEvent];
			
			[self saveCalendar];
			
			return YES;
		}
    }
    else
    {
        EKEvent *newEvent = [EKEvent eventWithEventStore:self.eventStore];
 		if(newEvent == nil)
		{
			return NO;
		}
		
		Venue *venue = [appDelegate.venuesDictionary objectForKey:schedule.venueItem.ID];
		NSString *venueLocation = [NSString stringWithFormat:@"%@, %@, %@ %@", venue.address1, venue.city, venue.state, venue.zip];
		newEvent.location = [NSString stringWithFormat:@"Venue: %@ %@", schedule.venue, venueLocation];
		newEvent.title = schedule.title;
		newEvent.startDate = startDate;
		newEvent.endDate = endDate;
		
		if(self.cinequestCalendar != nil)
		{
			[newEvent setCalendar:self.cinequestCalendar];

			NSError *error = nil;
			if ([self.eventStore saveEvent:newEvent span:EKSpanThisEvent error:&error])
			{
				[self.arrayCalendarItems addObject:uniqueIDForEvent];
				
				NSLog(@"Succesfully saved event %@ %@", newEvent.title, newEvent.eventIdentifier);
			}
		}
			  
		if ([self.dictSavedEventsInCalendar objectForKey:uniqueIDForEvent] == nil)
		{
			if(newEvent.eventIdentifier != nil)
			{
				NSArray *newEventDict = [NSArray arrayWithObjects:newEvent.title, newEvent.location, newEvent.startDate, newEvent.endDate, newEvent.eventIdentifier, nil];
				[self.dictSavedEventsInCalendar setObject:newEventDict forKey:uniqueIDForEvent];
			}
			else
			{
				NSArray *newEventDict = [NSArray arrayWithObjects:newEvent.title, newEvent.location, newEvent.startDate, newEvent.endDate, @"", nil];
				[self.dictSavedEventsInCalendar setObject:newEventDict forKey:uniqueIDForEvent];
			}
			
			NSLog(@"Event %@ added to Calendar dictionary", newEvent.eventIdentifier);
		}

        [self saveCalendar];
		
		return YES;
	}
	
	return NO;
}

- (void) addOrRemoveSchedule:(Schedule*)schedule
{
	if(schedule.isSelected)
	{
		// Add the selected schedule
		BOOL alreadyAdded = NO;
		NSInteger scheduleCount = [self.mySchedule count];
		for(NSInteger idx = 0; idx < scheduleCount; idx++)
		{
			Schedule *obj = [self.mySchedule objectAtIndex:idx];
			if ([obj.ID isEqualToString:schedule.ID])
			{
				alreadyAdded = YES;
				break;
			}
		}
		if(!alreadyAdded)
		{
			[self.mySchedule addObject:schedule];
			NSLog(@"%@ : %@ added to my schedule", schedule.title, schedule.dateString);
		}
	}
	else
	{
		// Remove the un-selected schedule
		NSInteger scheduleCount = [self.mySchedule count];
		for(NSInteger idx = 0; idx < scheduleCount; idx++)
		{
			Schedule *obj = [self.mySchedule objectAtIndex:idx];
			if ([obj.ID isEqualToString:schedule.ID])
			{
                [self.mySchedule removeObjectAtIndex:idx];
				
				NSLog(@"%@ : %@ removed from my schedule", schedule.title, schedule.dateString);
				break;
			}
		}
	}
}


// Update the calendar with new events created
- (void) populateCalendarEntries
{
    if (!self.mySchedule)
	{
        self.mySchedule = [NSMutableArray new];
    }
    
	if ([self.mySchedule count] == 0 && [[self.dictSavedEventsInCalendar allKeys] count] > 0)
	{
		for (Schedule *schedule in self.festival.schedules)
		{
			NSString *stringID = [NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID];
			if ([[self.dictSavedEventsInCalendar allKeys] containsObject:stringID])
			{
				if(self.cinequestCalendar != nil)
				{
					NSArray *eventArray = [self.dictSavedEventsInCalendar objectForKey:stringID];
					NSString *identifier = [eventArray lastObject];
					if(identifier.length > 0)
					{
						EKEvent *event = [self.eventStore eventWithIdentifier:identifier];
						if (event)
						{
							schedule.isSelected = YES;
							[self.mySchedule addObject:schedule];
							[self.arrayCalendarItems addObject:stringID];
						}
						else
						{
							[self.dictSavedEventsInCalendar removeObjectForKey:stringID];
						}
					}
				}
				else
				{
					schedule.isSelected = YES;
					[self.mySchedule addObject:schedule];
					[self.arrayCalendarItems addObject:stringID];
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

- (void) showMessage:(NSString*)message onView:view hideAfter:(NSTimeInterval)time
{
	dispatch_async(dispatch_get_main_queue(),
	^{
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
		hud.mode = MBProgressHUDModeText;
		hud.labelText = message;
		hud.margin = 10.0;
		hud.yOffset = 0.0;
		hud.removeFromSuperViewOnHide = YES;
		[hud hide:YES afterDelay:time];
	});
}

- (void) appBecomeActive
{
	locationServicesON = [CLLocationManager locationServicesEnabled];
	userLocationON = [CLLocationManager authorizationStatus];
}

@end

