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
/*
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) EKCalendar *defaultCalendar;
@property (nonatomic, strong) EKCalendar *cinequestCalendar;
@property (nonatomic, copy) NSString *calendarIdentifier;
@property (nonatomic, strong) NSMutableArray *arrCalendarItems;
*/
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
    eventStore = delegate.eventStore;
    cinequestCalendar = delegate.cinequestCalendar;
    [delegate populateCalendarEntries];
	
	// initialize variables
	index = [[NSMutableArray alloc] init];
	displayData = [[NSMutableDictionary alloc] init];
	titleForSection = [[NSMutableArray alloc] init];

    titleFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	venueFont = timeFont;
    
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
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
	delegate = appDelegate;
	if (delegate.isOffSeason)
	{
		return;
	}
	
    [self getDataForTable];
    [self reloadCalendarItems];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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

-(void) getDataForTable{
    
    NSSortDescriptor *sortTime = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
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

- (void) addItemToCalendar:(id)sender event:(id)touchEvent
{
	Schedule *schedule = [self getItemForSender:sender event:touchEvent];
    schedule.isSelected ^= YES;
    
    //Call to Appdelegate to Add/Remove from Calendar
    [delegate addToDeviceCalendar:schedule];
    [delegate addOrRemoveFilm:schedule];
    
    for (Schedule *sch in mySchedule) {
        NSLog(@"MySchedule :%@-%@",sch.itemID,sch.ID);
    }
    
    [self getDataForTable];
    [self reloadCalendarItems];
}

-(Schedule*)getItemForSender:(id)sender event:(id)touchEvent{
    
    NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.scheduleTableView];
	NSIndexPath *indexPath = [self.scheduleTableView indexPathForRowAtPoint:currentTouchPosition];
    Schedule *film = nil;
    
    if (indexPath != nil)
	{
		NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
        NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
        film = [rowsData objectAtIndex:indexPath.row];
    }
    
    return film;
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

// Below Method Commented for now
/*
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
    if (self.cinequestCalendar) {
        [self reloadCalendarItems];
    }
}
*/
- (void) reloadCalendarItems
{
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
		titleLabel.font = titleFont;
		[tempCell.contentView addSubview:titleLabel];
		
		timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 22.0, 250.0, 20.0)];
		timeLabel.tag = CELL_TIME_LABEL_TAG;
		timeLabel.font = timeFont;
		[tempCell.contentView addSubview:timeLabel];
				
		venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 40.0, 250.0, 20.0)];
		venueLabel.tag = CELL_VENUE_LABEL_TAG;
		venueLabel.font = venueFont;
		[tempCell.contentView addSubview:venueLabel];
        
        calendarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [calendarButton addTarget:self action:@selector(addItemToCalendar:event:) forControlEvents:UIControlEventTouchDown];
        calendarButton.frame = CGRectMake(256.0, 16.0, 32.0, 32.0);
        calendarButton.tag = CELL_LEFTBUTTON_TAG;
        [tempCell.contentView addSubview:calendarButton];
	}
	
	titleLabel = (UILabel*)[tempCell viewWithTag:CELL_TITLE_LABEL_TAG];
	titleLabel.text = film.title;
	
    calendarButton = (UIButton *)[tempCell viewWithTag:CELL_LEFTBUTTON_TAG];
    
    if([delegate.arrayCalendarItems containsObject:[NSString stringWithFormat:@"%@-%@",film.itemID,film.ID]])
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
	
    return tempCell;
}

#pragma mark -
#pragma mark UITableView Delegate

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
//	[self launchCalendar];	
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
        NSPredicate *predicateForEvents = [eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:cinequestCalendar]];
        //set predicate to search for an event of the calendar(you can set the startdate, enddate and check in the calendars other than the default Calendar)
        NSArray *events_Array = [eventStore eventsMatchingPredicate: predicateForEvents];
        //get array of events from the eventStore
        
        for (EKEvent *eventToCheck in events_Array)
        {
            if( [eventToCheck.title isEqualToString:item.title] )
            {
                NSError *err;
                BOOL success = [eventStore removeEvent:eventToCheck span:EKSpanThisEvent error:&err];
                [delegate addToDeviceCalendar:item];
                [delegate addOrRemoveFilm:item];
                [delegate.arrayCalendarItems removeObject:item.title];
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


