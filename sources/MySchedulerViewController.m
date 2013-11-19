//
//  MySchedulerViewController.m
//  CineQuest
//
//  Created by someone on 11/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MySchedulerViewController.h"
#import "FilmDetailController.h"
#import "EventDetailViewController.h"
#import "CinequestAppDelegate.h"
#import "Schedule.h"

#define CALENDAR_NAME @"Cinequest"
#define ONE_YEAR (60.0 * 60.0 * 24.0 * 365.0)

static NSString *const kScheduleCellIdentifier = @"ScheduleCell";


@interface MySchedulerViewController ()

@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) EKCalendar *defaultCalendar;
@property (nonatomic, strong) EKCalendar *cinequestCalendar;
@property (nonatomic, copy) NSString *calendarIdentifier;
@property (nonatomic, strong) NSMutableArray *arrCalendarItems;

@end

@implementation MySchedulerViewController

@synthesize scheduleTableView;
@synthesize username;
@synthesize password;
@synthesize retrievedTimeStamp;
@synthesize status;
@synthesize offSeasonLabel;

- (void) didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark UIViewController

// Resets some variables when the users moves to a different screen
- (void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	status = @"none";
	previousCell = nil;
	previousEndDate = nil;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	// Get mySchedule array
	delegate = appDelegate;
	mySchedule = delegate.mySchedule;
	
	// initialize variables
	index = [[NSMutableArray alloc] init];
	displayData = [[NSMutableDictionary alloc] init];
	titleForSection = [[NSMutableArray alloc] init];

	if(delegate.isOffSeason)
	{
		offSeasonLabel.hidden = NO;
		self.scheduleTableView.hidden = YES;
		return;
	}
	
    //display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
																							target:self
																							action:@selector(edit)];
	// harold's variables
	confirmedList	= [[NSMutableArray alloc] init];
	movedList		= [[NSMutableArray alloc] init];
	removedList		= [[NSMutableArray alloc] init];	
	currentColor	= [UIColor blackColor];
	masterList		= [NSArray arrayWithObjects:confirmedList, movedList, removedList, nil];
    
    [self checkAndCreateCalendar];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
	delegate = appDelegate;
	if (delegate.isOffSeason)
	{
		return;
	}
	
	NSSortDescriptor *sortTime = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	
	[mySchedule sortUsingDescriptors:[NSArray arrayWithObjects:sortTime,nil]];
	
	[displayData removeAllObjects];
	[index removeAllObjects];
	[titleForSection removeAllObjects];
	
	NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	
	NSString *lastDateString = @"";
	for (Schedule *item in mySchedule) 
	{
		if ([item.longDateString isEqualToString:lastDateString])
		{
			[tempArray addObject:item];
		}
		else 
		{
			[displayData setObject:tempArray forKey:lastDateString];
			
			lastDateString = item.longDateString;
			
			[titleForSection addObject:lastDateString];
			[index addObject:[[lastDateString componentsSeparatedByString:@" "] objectAtIndex: 2]];
			
			tempArray = [[NSMutableArray alloc] init];
			[tempArray addObject:item];
		}

	}
	[displayData setObject:tempArray forKey:lastDateString];
		
	// reload tableView data
	[self.scheduleTableView reloadData];
	[self doneEditing];

	if(mySchedule.count == 0)
	{
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self checkEventStoreAccessForCalendar];
}

#pragma mark -
#pragma mark Actions

- (void) edit
{
	[self.scheduleTableView setEditing:YES animated:YES];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							target:self
																							action:@selector(doneEditing)];
}

- (void) doneEditing
{
	[self.scheduleTableView setEditing:NO animated:YES];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
																							target:self
																							action:@selector(edit)];
	if(mySchedule.count == 0)
	{
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
}

- (void) addItemToCalendar:(id)sender event:(id)touchEvent
{
	NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.scheduleTableView];
	NSIndexPath *indexPath = [self.scheduleTableView indexPathForRowAtPoint:currentTouchPosition];
	int row = [indexPath row];
	int section = [indexPath section];
	
	if (indexPath != nil)
	{
		// get date
		NSString *dateString = [titleForSection objectAtIndex:section];
		
		// get film objects using dateString
		NSMutableArray *films = [displayData objectForKey:dateString];
		Schedule *film = [films objectAtIndex:row];
        
		NSDate *startDate = [film.startDate dateByAddingTimeInterval:ONE_YEAR];
        NSDate *endDate = [film.endDate dateByAddingTimeInterval:ONE_YEAR];
        
        if ([_arrCalendarItems containsObject:film.title])
		{
            NSPredicate *predicateForEvents = [_eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:_cinequestCalendar]];
            //set predicate to search for an event of the calendar(you can set the startdate, enddate and check in the calendars other than the default Calendar)
            NSArray *events_Array = [_eventStore eventsMatchingPredicate: predicateForEvents];
            //get array of events from the eventStore
            
            for (EKEvent *eventToCheck in events_Array)
            {
                if( [eventToCheck.title isEqualToString:film.title] )
                {
                    NSError *err;
                    BOOL success = [_eventStore removeEvent:eventToCheck span:EKSpanThisEvent error:&err];
                    [_arrCalendarItems removeObject:film.title];
					if(success)
					{
						NSLog( @"Event %@ deleted successfully", eventToCheck.title);
					}
                    break;
                }
            }
        }
        else
		{
            EKEvent *newEvent = [EKEvent eventWithEventStore:_eventStore];
            newEvent.title = [NSString stringWithFormat:@"%@",film.title];
            newEvent.location = film.venue;
            newEvent.startDate = startDate;
            newEvent.endDate = endDate;
            [newEvent setCalendar:_cinequestCalendar];
            NSError *error= nil;
            
            BOOL result = [_eventStore saveEvent:newEvent span:EKSpanThisEvent error:&error];
            if (result)
			{
                NSLog(@"Succesfully saved event %@ %@ - %@", newEvent.title, startDate, endDate);
            }
        }
	}
	
    [self reloadCalendarItems];
}

#pragma mark Utility Methods

// This method helps increment the timestamp supplied
// PRECOND: the format should be similiar to the one used in the CQ XML
// PSTCOND: Will return the string with exactly 1 second incremented from the supplie time
+ (NSString *) incrementCQTime:(NSString *)CQdateTime
{
	//NSLog(@"CQdateTime: %@", CQdateTime);
	if(CQdateTime == nil)
		return @"0";
	
	NSDateFormatter *CQDateFormat = [[NSDateFormatter alloc] init];	
	[CQDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	
	NSDate *parsedDate = [CQDateFormat dateFromString:CQdateTime];
    parsedDate = [parsedDate dateByAddingTimeInterval:1];
	
	NSString *returnString = [CQDateFormat stringFromDate:parsedDate];	
	
	return returnString;
}

- (void) checkAndCreateCalendar
{
    if (!_arrCalendarItems)
	{
        _arrCalendarItems = [[NSMutableArray alloc] init];
    }
    
    _calendarIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:@"CalendarID"];
    _eventStore = [[EKEventStore alloc] init];
    
    NSArray *caleandarsArray = [[NSArray alloc] init];
    caleandarsArray = [_eventStore calendarsForEntityType:EKEntityTypeEvent];
    BOOL isCalendar = false;
    
    for (EKCalendar *iCalendar in caleandarsArray)
    {
        if ([iCalendar.title isEqualToString:CALENDAR_NAME] || [iCalendar.calendarIdentifier isEqualToString:_calendarIdentifier]) {
            isCalendar = true;
            self.calendarIdentifier = iCalendar.calendarIdentifier;
            self.cinequestCalendar = iCalendar;
            [[NSUserDefaults standardUserDefaults] setValue:self.calendarIdentifier forKey:@"CalendarID"];
            break;
        }
    }
    
    if (!isCalendar)
	{
        // Iterate over all sources in the event store and look for the local source
        EKSource *theSource = nil;
        for (EKSource *source in _eventStore.sources)
		{
            if (source.sourceType == EKSourceTypeLocal)
			{
                theSource = source;
                break;
            }
        }
        
        EKCalendar *calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:_eventStore];
        calendar.title = CALENDAR_NAME;
        if (theSource)
		{
            calendar.source = theSource;
        }
		else
		{
            NSLog(@"Error: Local source not available");
            return;
        }
        
        NSError *error = nil;
        BOOL result = [_eventStore saveCalendar:calendar commit:YES error:&error];
        if (result)
		{
            NSLog(@"Saved calendar to event store.");
            
            caleandarsArray = [_eventStore calendarsForEntityType:EKEntityTypeEvent];
            BOOL isCalendar = false;
            
            for (EKCalendar *iCalendar in caleandarsArray)
            {
                if ([iCalendar.title isEqualToString:CALENDAR_NAME])
				{
                    isCalendar = true;
                    self.calendarIdentifier = iCalendar.calendarIdentifier;
                    self.cinequestCalendar = iCalendar;
                    [[NSUserDefaults standardUserDefaults] setValue:self.calendarIdentifier forKey:@"CalendarID"];
                    break;
                }
            }
        }
		else
		{
            NSLog(@"Error saving calendar: %@.", error);
        }
    }
    
    [self reloadCalendarItems];
}

- (void) reloadCalendarItems
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
	// EKCalendar *calendarMain = [_eventStore calendarWithIdentifier:_calendarIdentifier];
    NSDateComponents *oneDayAgoComponents = [[NSDateComponents alloc] init];
    oneDayAgoComponents.day = -1;
    
    NSDate *oneDayAgo = [calendar dateByAddingComponents:oneDayAgoComponents
													toDate:[NSDate date]
													options:0];
    // Create the end date components
    NSDateComponents *oneYearFromNowComponents = [[NSDateComponents alloc] init];
    oneYearFromNowComponents.year = 1;
    
    NSDate *oneYearFromNow = [calendar dateByAddingComponents:oneYearFromNowComponents
															toDate:[NSDate date]
															options:0];
    // Create the predicate from the event store's instance method
    NSPredicate *predicate = [_eventStore predicateForEventsWithStartDate:oneDayAgo
																endDate:oneYearFromNow
                                                                calendars:[NSArray arrayWithObject:self.cinequestCalendar]];
    // Fetch all events that match the predicate
    NSArray *list = [_eventStore eventsMatchingPredicate:predicate];
    for (EKEvent *event in list)
	{
        if (![_arrCalendarItems containsObject:event.title])
		{
            [_arrCalendarItems addObject:event.title];
        }
    }
    
    [self.scheduleTableView reloadData];
}

#pragma mark -
#pragma mark UITableView DataSource

// There are multiple ways to load this table, one is to load the "scheduler list" of added films
// the second is to display the return of "SLGET" (confirmed,moved,removed)
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [titleForSection count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSString *sectionTitle = [titleForSection objectAtIndex:section];
	NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
    return [rowsData count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [titleForSection objectAtIndex:section];
}

// not too sure what this does, hopefully does not affect the "SLGET";
// it is one of the implemented functions for the "scheduler list"
- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return index;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Loading Schedule into the TabelViewCells
	NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
	NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];		
	Schedule *film = [rowsData objectAtIndex:indexPath.row];

	CGFloat labelFontSize = [UIFont labelFontSize];
	CGFloat fontSize = [UIFont systemFontSize];

	UILabel *titleLabel;
	UILabel *timeLabel;
	UILabel *venueLabel;
	UIButton *calendarButton;
	
	UITableViewCell *tempCell = [tableView dequeueReusableCellWithIdentifier:kScheduleCellIdentifier];
 	if (tempCell == nil)
	{
		tempCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kScheduleCellIdentifier];
			 	
		// tempCell.selectionStyle = UITableViewCellSelectionStyleNone;

		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 2.0, 290.0, 20.0)];
		titleLabel.tag = CELL_TITLE_LABEL_TAG;
		titleLabel.font = [UIFont boldSystemFontOfSize:labelFontSize];
		[tempCell.contentView addSubview:titleLabel];
		
		timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 22.0, 250.0, 20.0)];
		timeLabel.tag = CELL_TIME_LABEL_TAG;
		timeLabel.font = [UIFont systemFontOfSize:fontSize];
		[tempCell.contentView addSubview:timeLabel];
				
		venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 40.0, 250.0, 20.0)];
		venueLabel.tag = CELL_VENUE_LABEL_TAG;
		venueLabel.font = [UIFont systemFontOfSize:fontSize];
		[tempCell.contentView addSubview:venueLabel];
        
        calendarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [calendarButton addTarget:self action:@selector(addItemToCalendar:event:) forControlEvents:UIControlEventTouchDown];
        calendarButton.frame = CGRectMake(266.0, 16.0, 48.0, 48.0);
        calendarButton.tag = CELL_LEFTBUTTON_TAG;
        [tempCell.contentView addSubview:calendarButton];
	}
	
	titleLabel = (UILabel*)[tempCell viewWithTag:CELL_TITLE_LABEL_TAG];
	titleLabel.text = film.title;
	
    calendarButton = (UIButton *)[tempCell viewWithTag:CELL_LEFTBUTTON_TAG];
    
    if([_arrCalendarItems containsObject:film.title])
	{
        [calendarButton setImage:[UIImage imageNamed:@"cal_selected"] forState:UIControlStateNormal];
    }
    else
	{
        [calendarButton setImage:[UIImage imageNamed:@"cal_unselected"] forState:UIControlStateNormal];
    }
    
	timeLabel = (UILabel*)[tempCell viewWithTag:CELL_TIME_LABEL_TAG];
	timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", film.dateString, film.startTime, film.endTime];
	
	venueLabel = (UILabel*)[tempCell viewWithTag:CELL_VENUE_LABEL_TAG];
	venueLabel.text = [NSString stringWithFormat:@"Venue:%@", film.venue];
	
#pragma message "For what is this for?"
	if(film.fontColor == nil)
	{
		titleLabel.textColor = [UIColor blackColor];
		timeLabel.textColor = [UIColor blackColor];
		venueLabel.textColor = [UIColor blackColor];
	}
	else
	{
		titleLabel.textColor = film.fontColor;
		timeLabel.textColor = film.fontColor;
		venueLabel.textColor = film.fontColor;
	}

#pragma message "For what is this for?"
	if(film.fontColor == [UIColor blueColor])
	{
		timeLabel.textColor = [UIColor grayColor];
		venueLabel.textColor = [UIColor blackColor];
		timeLabel.font = [UIFont italicSystemFontOfSize:[UIFont smallSystemFontSize]];
	}

    return tempCell;
}

#pragma mark -
#pragma mark UITableView Delegate

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	// Just for testing
	int section = [indexPath section];
	int row = [indexPath row];
	
	[self launchCalendar];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView beginUpdates];
    if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
		NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
		
		Schedule *item = [rowsData objectAtIndex:indexPath.row];
		[rowsData removeObjectAtIndex:indexPath.row];
		
		// Delete the row from the data source
		[mySchedule removeObject:item];
		
		// remove row from tableView
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		
		if ([rowsData count] == EMPTY)
		{
			[titleForSection removeObjectAtIndex:indexPath.section];
			[index removeObjectAtIndex:indexPath.section];
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:YES];
		}
        
        //Remove Event from Calendar
        NSDate *startDate = [item.startDate dateByAddingTimeInterval:ONE_YEAR];
        NSDate *endDate = [item.endDate dateByAddingTimeInterval:ONE_YEAR];
        NSPredicate *predicateForEvents = [_eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:_cinequestCalendar]];
        //set predicate to search for an event of the calendar(you can set the startdate, enddate and check in the calendars other than the default Calendar)
        NSArray *events_Array = [_eventStore eventsMatchingPredicate: predicateForEvents];
        //get array of events from the eventStore
        
        for (EKEvent *eventToCheck in events_Array)
        {
            if( [eventToCheck.title isEqualToString:item.title] )
            {
                NSError *err;
                BOOL success = [_eventStore removeEvent:eventToCheck span:EKSpanThisEvent error:&err];
                [_arrCalendarItems removeObject:item.title];
                NSLog( @"event deleted success if value = 1 : %d", success );
                break;
            }
        }
    }
	
	[tableView endUpdates];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 62.0;
}

#pragma mark -
#pragma mark Access Calendar

// Check the authorization status of our application for Calendar
- (void) checkEventStoreAccessForCalendar
{
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
             MySchedulerViewController * __weak weakSelf = self;
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
    self.defaultCalendar = self.eventStore.defaultCalendarForNewEvents;
    [self checkAndCreateCalendar];
}

- (void) launchCalendar
{
    EKEventStore *store = [[EKEventStore alloc] init];
	
	[store requestAccessToEntityType:EKEntityTypeEvent completion:
	^(BOOL granted, NSError *error)
	{
		if(granted)
		{
			dispatch_async(dispatch_get_main_queue(),
			^{
				[self createEventAndPresentViewController:store];
			});
		}
	}];
}

- (void) createEventAndPresentViewController:(EKEventStore *)store
{
    EKEvent *event = [self findOrCreateEvent:store];
	
    EKEventEditViewController *controller = [[EKEventEditViewController alloc] init];
    controller.event = event;
    controller.eventStore = store;
    controller.editViewDelegate = self;
	
    [self presentViewController:controller animated:YES completion:nil];
}

- (void) eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (EKEvent*) findOrCreateEvent:(EKEventStore*)store
{
    EKEvent *event = [EKEvent eventWithEventStore:store];
    event.title = @"My event title";
    event.notes = @"My event notes";
    event.location = @"My event location";
    event.calendar = [store defaultCalendarForNewEvents];
	
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.hour = 4;
    event.startDate = [calendar dateByAddingComponents:components
                                                toDate:[NSDate date]
												options:0];
    components.hour = 1;
    event.endDate = [calendar dateByAddingComponents:components
												toDate:event.startDate
												options:0];
    return event;
}

@end


