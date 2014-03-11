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

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UIViewController

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
	sectionFont = [UIFont boldSystemFontOfSize:18.0];
	venueFont = timeFont;
 
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
		
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
	self.navigationItem.rightBarButtonItem.enabled = (mySchedule.count != 0);

    [scheduleTableView reloadData];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
	
	if(scheduleTableView.isEditing)
	{
		[scheduleTableView setEditing:NO animated:NO];
	}
}

#pragma mark - Private Methods

- (void) inEditMode:(BOOL)inEditMode
{
	if (inEditMode)
	{
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
		
        scheduleTableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;	// hide index while in edit mode
    }
	else
	{
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
		
		scheduleTableView.sectionIndexMinimumDisplayRowCount = NSIntegerMin;
		
		editActivatedFromButton = NO;
    }
	
	self.navigationItem.rightBarButtonItem.enabled = (mySchedule.count != 0);
	
    [scheduleTableView reloadSectionIndexTitles];
}

#pragma mark - Actions

- (void) edit
{
	editActivatedFromButton = YES;
	
	[scheduleTableView setEditing:YES animated:YES];
	
	[self inEditMode:YES];
}

- (void) doneEditing
{
	[scheduleTableView setEditing:NO animated:YES];

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
}

- (void) calendarButtonTapped:(id)sender event:(id)touchEvent
{
	if(appDelegate.cinequestCalendar != nil)
	{
		Schedule *schedule = [self getItemForSender:sender event:touchEvent];
		NSLog(@"Editing Event associated to Schedule %@ %@-%@", schedule.title, schedule.itemID, schedule.ID);
		
		[self editEventForSchedule:schedule];
	}
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

#pragma mark - UITableView DataSource

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

    return cell;
}

- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
	CGFloat width = tableView.bounds.size.width - 17.0;
	CGFloat height = 24.0;
	
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
	view.userInteractionEnabled = NO;
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];
	label.backgroundColor = [UIColor redColor];
	label.textColor = [UIColor whiteColor];
	label.font = sectionFont;
	[view addSubview:label];
	
	label.text = [NSString stringWithFormat:@"  %@", [titleForSection objectAtIndex:section]];
	
	return view;
}

#pragma mark - UITableView Delegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 28.0;
}

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
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
		NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
		
		Schedule *schedule = [rowsData objectAtIndex:indexPath.row];
		if(schedule != nil)
		{
			NSLog(@"Deleting Schedule %@ %@-%@ and associated Event...", schedule.title, schedule.itemID, schedule.ID);

			if(appDelegate.cinequestCalendar != nil)
			{
				EKEvent *event = [self findEventForSchedule:schedule inStore:eventStore];
				if(event != nil)
				{
					[delegate addOrRemoveScheduleToCalendar:schedule];

					[mySchedule removeObject:schedule];

					[self getDataForTable];
					schedule.isSelected = NO;
					[scheduleTableView reloadData];
					
					NSLog(@"Schedule and associated Event deleted");
				}
			}
			else
			{
				[delegate addOrRemoveScheduleToCalendar:schedule];
				
				[mySchedule removeObject:schedule];
				
				[self getDataForTable];
				schedule.isSelected = NO;
				[scheduleTableView reloadData];
				
				NSLog(@"Schedule deleted");
			}
		}

		if(mySchedule.count == 0 || !editActivatedFromButton)
		{
			[scheduleTableView setEditing:NO animated:NO];

			[self inEditMode:NO];
		}
		
		self.navigationItem.rightBarButtonItem.enabled = (mySchedule.count != 0);
	}
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
	NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
	NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
	
	Schedule *schedule = [rowsData objectAtIndex:indexPath.row];
	if(schedule != nil)
	{
		NSLog(@"Selected Schedule %@ %@-%@ for deletion...", schedule.title, schedule.itemID, schedule.ID);
	}
	
	self.navigationItem.rightBarButtonItem.enabled = NO;

	scheduleTableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;	// hide index while in edit mode
	[scheduleTableView reloadSectionIndexTitles];
}

- (void) tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.navigationItem.rightBarButtonItem.enabled = (mySchedule.count != 0);

	scheduleTableView.sectionIndexMinimumDisplayRowCount = NSIntegerMin;
	[scheduleTableView reloadSectionIndexTitles];
}

#pragma mark - Access Calendar

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
				NSLog(@"Edit Event %@ : %@", event.title, event.eventIdentifier);

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
    [self dismissViewControllerAnimated:YES completion:
	^{
		// NSLog(@"%@", delegate.arrayCalendarItems);
		// NSLog(@"%@", delegate.dictSavedEventsInCalendar);
		
		if(action == EKEventEditViewActionDeleted)
		{
			Schedule *schedule = [self findScheduleForEvent:controller.event];
			if(schedule != nil)
			{
				NSLog(@"Deleting Schedule %@ %@-%@ and associated Event...", schedule.title, schedule.itemID, schedule.ID);
				
				[delegate addOrRemoveScheduleToCalendar:schedule];
				
				[mySchedule removeObject:schedule];
				
				[self getDataForTable];
				
				[scheduleTableView reloadData];

				NSLog(@"Event and associated Schedule deleted");
			}
		}
		else if(action == EKEventEditViewActionSaved)
		{
			// Update and save the schedule
			
			NSLog(@"Event and associated Schedule updated");
		}
	}];
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
	NSString *eventIdentifier = [delegate.dictSavedEventsInCalendar objectForKey:[NSString stringWithFormat:@"%@-%@", schedule.itemID, schedule.ID]];
	if(eventIdentifier != nil)
	{
		EKEvent *event = [store eventWithIdentifier:eventIdentifier];
		return event;
	}

    return nil;
}

@end


