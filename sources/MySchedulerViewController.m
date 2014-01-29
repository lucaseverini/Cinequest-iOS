//
//  MySchedulerViewController.m
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "MySchedulerViewController.h"
#import "FilmDetailViewController.h"
#import "EventDetailViewController.h"
#import "ForumDetailViewController.h"
#import "CinequestAppDelegate.h"
#import "Schedule.h"
#import "Film.h"
#import "Forum.h"
#import "Special.h"
#import "CinequestItem.h"

static NSString *const kScheduleCellIdentifier = @"ScheduleCell";


@implementation MySchedulerViewController

@synthesize switchTitle;
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
 		
    // display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];

	NSDictionary *attribute = [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:16.0f] forKey:NSFontAttributeName];
	[switchTitle setTitleTextAttributes:attribute forState:UIControlStateNormal];
	[switchTitle removeSegmentAtIndex:1 animated:NO];
	
	scheduleTableView.tableHeaderView = nil;
	scheduleTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
  	
    [self getDataForTable];
    [scheduleTableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark -
#pragma mark Private Methods

#pragma mark -
#pragma mark Actions

- (void) edit
{
	[scheduleTableView setEditing:YES animated:YES];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
	
	[self inEditMode:YES];
}

- (void) doneEditing
{
	[scheduleTableView setEditing:NO animated:YES];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
	if(mySchedule.count == 0)
	{
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
	
	[self inEditMode:NO];
}

- (void) getDataForTable
{
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
	[scheduleTableView reloadData];
	[self doneEditing];
    
	if(mySchedule.count == 0)
	{
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
}

- (void) calendarButtonTapped:(id)sender event:(id)touchEvent
{
	Schedule *schedule = [self getItemForSender:sender event:touchEvent];
	// NSLog(@"%@ : %@ : %@", schedule.ID, schedule.title, schedule.itemID);
	[self editEventForSchedule:schedule];
/*
	Schedule *schedule = [self getItemForSender:sender event:touchEvent];
    schedule.isSelected ^= YES;
    
    //Call to Appdelegate to Add/Remove from Calendar
    [delegate addScheduleToDeviceCalendar:schedule];
    [delegate addOrRemoveSchedule:schedule];
    
    for (Schedule *sch in mySchedule) 
	{
        NSLog(@"MySchedule :%@-%@",sch.itemID,sch.ID);
    }
    
    [self getDataForTable];
    [scheduleTableView reloadData];
*/
}

- (Schedule*) getItemForSender:(id)sender event:(id)touchEvent
{
    NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:scheduleTableView];
	NSIndexPath *indexPath = [scheduleTableView indexPathForRowAtPoint:currentTouchPosition];
    if (indexPath != nil)
	{
		NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
        NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
        return [rowsData objectAtIndex:indexPath.row];
    }
    
    return nil;
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
    if (self.cinequestCalendar) 
	{
        [scheduleTableView reloadData];
    }
}
*/

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
    return rowsData.count;
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
	Schedule *schedule = [rowsData objectAtIndex:indexPath.row];

	UILabel *titleLabel = nil;
	UILabel *timeLabel = nil;
	UILabel *venueLabel = nil;
	UIButton *calendarButton = nil;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kScheduleCellIdentifier];
 	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kScheduleCellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;

		titleLabel = [UILabel new];
		titleLabel.tag = CELL_TITLE_LABEL_TAG;
		titleLabel.font = titleFont;
		[cell.contentView addSubview:titleLabel];
		
		timeLabel = [UILabel new];
		timeLabel.tag = CELL_TIME_LABEL_TAG;
		timeLabel.font = timeFont;
		[cell.contentView addSubview:timeLabel];
				
		venueLabel = [UILabel new];
		venueLabel.tag = CELL_VENUE_LABEL_TAG;
		venueLabel.font = venueFont;
		[cell.contentView addSubview:venueLabel];
/*
        calendarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        calendarButton.tag = CELL_LEFTBUTTON_TAG;
        [calendarButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchDown];
        [cell.contentView addSubview:calendarButton];
*/
		calendarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        calendarButton.tag = CELL_LEFTBUTTON_TAG;
		[calendarButton setImage:[UIImage imageNamed:@"calendar_icon.png"] forState:UIControlStateNormal];
        [calendarButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchDown];
        [cell.contentView addSubview:calendarButton];
	}
	
	NSInteger titleNumLines = 1;
	titleLabel = (UILabel*)[cell viewWithTag:CELL_TITLE_LABEL_TAG];
	CGSize size = [schedule.title sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
	if(size.width < 256.0)
	{
		[titleLabel setFrame:CGRectMake(56.0, 6.0, 256.0, 20.0)];
	}
	else
	{
		[titleLabel setFrame:CGRectMake(56.0, 6.0, 256.0, 42.0)];
		titleNumLines = 2;
	}
	
	[titleLabel setNumberOfLines:titleNumLines];
	titleLabel.text = schedule.title;
	
	timeLabel = (UILabel*)[cell viewWithTag:CELL_TIME_LABEL_TAG];
	[timeLabel setFrame:CGRectMake(56.0, titleNumLines == 1 ? 28.0 : 50.0, 250.0, 20.0)];
	timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", schedule.dateString, schedule.startTime, schedule.endTime];
	
	venueLabel = (UILabel*)[cell viewWithTag:CELL_VENUE_LABEL_TAG];
	[venueLabel setFrame:CGRectMake(56.0, titleNumLines == 1 ? 46.0 : 68.0, 250.0, 20.0)];
	venueLabel.text = [NSString stringWithFormat:@"Venue: %@",schedule.venue];
	
	calendarButton = (UIButton*)[cell viewWithTag:CELL_LEFTBUTTON_TAG];
	[calendarButton setFrame:CGRectMake(8.0, titleNumLines == 1 ? 12.0 : 24.0, 40.0, 40.0)];
/*
	[calendarButton setFrame:CGRectMake(8.0, titleNumLines == 1 ? 12.0 : 24.0, 40.0, 40.0)];
    if([delegate.arrayCalendarItems containsObject:[NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID]])
	{
        [calendarButton setImage:[UIImage imageNamed:@"cal_selected"] forState:UIControlStateNormal];
    }
    else
	{
        [calendarButton setImage:[UIImage imageNamed:@"cal_unselected"] forState:UIControlStateNormal];
    }
*/
    return cell;
}

#pragma mark -
#pragma mark UITableView Delegate

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
	NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
	Schedule *schedule = [rowsData objectAtIndex:indexPath.row];
	
	// NSLog(@"%@ : %@ : %@", schedule.ID, schedule.title, schedule.itemID);
	
	CinequestItem *item = [delegate.festival getScheduleItem:schedule.itemID];
	assert(item != nil);
	
	if([item isKindOfClass:[Film class]])
	{
		FilmDetailViewController *filmDetail = [[FilmDetailViewController alloc] initWithFilm:schedule.itemID];
		[[self navigationController] pushViewController:filmDetail animated:YES];
	}
	else if([item isKindOfClass:[Special class]])
	{
		EventDetailViewController *eventDetail = [[EventDetailViewController alloc] initWithEvent:schedule.itemID];
		[[self navigationController] pushViewController:eventDetail animated:YES];
	}
	else if([item isKindOfClass:[Forum class]])
	{
		ForumDetailViewController *forumDetail = [[ForumDetailViewController alloc] initWithForum:schedule.itemID];
		[[self navigationController] pushViewController:forumDetail animated:YES];
	}
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
		
		// delete the row from the data source
		[mySchedule removeObject:item];
		
		// remove row from tableView
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		
		if ([rowsData count] == EMPTY)
		{
			[titleForSection removeObjectAtIndex:indexPath.section];
			[index removeObjectAtIndex:indexPath.section];
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:YES];
		}
        
        // remove Event from Calendar
        NSDate *startDate = [item.startDate dateByAddingTimeInterval:ONE_YEAR];
        NSDate *endDate = [item.endDate dateByAddingTimeInterval:ONE_YEAR];
        NSPredicate *predicateForEvents = [eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObject:cinequestCalendar]];
		
        // set predicate to search for an event of the calendar(you can set the startdate, enddate and check in the calendars other than the default Calendar)
        NSArray *events_Array = [eventStore eventsMatchingPredicate: predicateForEvents];
		
        // get array of events from the eventStore
        for (EKEvent *eventToCheck in events_Array)
        {
            if( [eventToCheck.title isEqualToString:item.title] )
            {
                NSError *err;
                BOOL success = [eventStore removeEvent:eventToCheck span:EKSpanThisEvent error:&err];
                [delegate addScheduleToDeviceCalendar:item];
                [delegate addOrRemoveSchedule:item];
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
	NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
	NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
	Schedule *schedule = [rowsData objectAtIndex:indexPath.row];
	
	CGSize size = [schedule.title sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
	if(size.width >= 256.0)
	{
		return 90.0;
	}
	else
	{
		return 68.0;
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.01;		// This creates a "invisible" footer
}

- (void) tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self inEditMode:YES];
}

- (void) tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self inEditMode:NO];
}

- (void) inEditMode:(BOOL)inEditMode
{
    if (inEditMode)
	{
        scheduleTableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;	// hide index while in edit mode
    }
	else
	{
		scheduleTableView.sectionIndexMinimumDisplayRowCount = NSIntegerMin;
    }
	
    [scheduleTableView reloadSectionIndexTitles];
}

#pragma mark -
#pragma mark Access Calendar

- (void) editEventForSchedule:(Schedule*)schedule
{
	[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:
	^(BOOL granted, NSError *error)
	{
		if(granted)
		{
			EKEvent *event = [self findEventForSchedule:schedule inStore:eventStore];
			if(event != nil)
			{
				NSLog(@"Event %@ : %@", event.title, event.eventIdentifier);

				dispatch_async(dispatch_get_main_queue(),
				^{
					EKEventEditViewController *controller = [[EKEventEditViewController alloc] init];
					controller.event = event;
					controller.eventStore = eventStore;
					controller.editViewDelegate = self;
					
					[self presentViewController:controller animated:YES completion:nil];
				});
			}
		}
	}];
}

- (void) eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
	// NSLog(@"%@", delegate.arrayCalendarItems);
	// NSLog(@"%@", delegate.dictSavedEventsInCalendar);

	if(action == EKEventEditViewActionDeleted)
	{
		Schedule *schedule = [self findScheduleForEvent:controller.event];
		if(schedule != nil)
		{
			[mySchedule removeObject:schedule];
			
			[delegate.arrayCalendarItems removeObject:[NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID]];
	
			NSArray *keys = [delegate.dictSavedEventsInCalendar allKeysForObject:controller.event.eventIdentifier];
			[delegate.dictSavedEventsInCalendar removeObjectsForKeys:keys];
		
			NSLog(@"Event and associated Schedule deleted");
		}
	}
	else if(action == EKEventEditViewActionSaved)
	{
		// Update and save the schedule
		
		NSLog(@"Event and associated Schedule updated");
	}
	
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (Schedule*) findScheduleForEvent:(EKEvent*)event
{
	NSArray *keys = [delegate.dictSavedEventsInCalendar allKeysForObject:event.eventIdentifier];
	if(keys.count > 0)
	{
		NSString *key = [keys firstObject];
		
		for(Schedule *schedule in mySchedule)
		{
			if([key isEqualToString:[NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID]])
			{
				return schedule;
			}
		}
	}

	return nil;
}

- (EKEvent*) findEventForSchedule:(Schedule*)schedule inStore:(EKEventStore*)store
{
	EKEvent *event = nil;
	
	NSString *eventIdentifier = [delegate.dictSavedEventsInCalendar objectForKey:[NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID]];
	if(eventIdentifier != nil)
	{
		EKEvent *event = [store eventWithIdentifier:eventIdentifier];
		if(event != nil)
		{
			return event;
		}
	}

    return event;
}

@end


