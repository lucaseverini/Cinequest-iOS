//
//  EventsViewController.m
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "EventsViewController.h"
#import "EventDetailViewController.h"
#import "CinequestAppDelegate.h"
#import "Schedule.h"
#import "NewsViewController.h"
#import "Special.h"
#import "DataProvider.h"


static NSString *const kEventCellIdentifier = @"EventCell";

@implementation EventsViewController

@synthesize switchTitle;
@synthesize eventsTableView;
@synthesize activityIndicator;
@synthesize dateToEventsDictionary;
@synthesize sortedKeysInDateToEventsDictionary;
@synthesize sortedIndexesInDateToEventsDictionary;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UIViewController Methods

- (void) viewDidLoad
{
    [super viewDidLoad];

	delegate = appDelegate;
	mySchedule = delegate.mySchedule;
		
	dateDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeDate error:nil];

	self.dateToEventsDictionary = [delegate.festival.dateToSpecialsDictionary mutableCopy];
	self.sortedKeysInDateToEventsDictionary = [delegate.festival.sortedKeysInDateToSpecialsDictionary mutableCopy];
	self.sortedIndexesInDateToEventsDictionary = [delegate.festival.sortedIndexesInDateToSpecialsDictionary mutableCopy];

    titleFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	sectionFont = [UIFont boldSystemFontOfSize:18.0];
	venueFont = timeFont;
  
	NSDictionary *attribute = [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:16.0f] forKey:NSFontAttributeName];
	[switchTitle setTitleTextAttributes:attribute forState:UIControlStateNormal];
	[switchTitle removeSegmentAtIndex:1 animated:NO];
	
	eventsTableView.tableHeaderView = nil;
	eventsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self syncTableDataWithScheduler];
	
    [self.eventsTableView reloadData];
}

#pragma mark -
#pragma mark Private Methods

- (NSDate*) dateFromString:(NSString*)string
{
	__block NSDate *detectedDate;
	
	[dateDetector enumerateMatchesInString:string options:kNilOptions range:NSMakeRange(0, string.length) usingBlock:
	 ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
	 {
		 detectedDate = result.date;
	 }];
	
	return detectedDate;
}

- (void) syncTableDataWithScheduler
{
    [delegate populateCalendarEntries];
    
	NSInteger sectionCount = [self.sortedKeysInDateToEventsDictionary count];
	NSInteger myScheduleCount = [mySchedule count];
	if(myScheduleCount == 0)
	{
		return;
	}
	
	// Sync current data
	for (NSUInteger section = 0; section < sectionCount; section++)
	{
		NSString *day = [self.sortedKeysInDateToEventsDictionary objectAtIndex:section];
		NSMutableArray *events =  [self.dateToEventsDictionary objectForKey:day];
		NSInteger eventCount = [events count];
		
		for (NSUInteger row = 0; row < eventCount; row++)
		{
			NSArray *schedules = [[events objectAtIndex:row] schedules];
			NSInteger scheduleCount = [schedules count];

			for (NSUInteger schedIdx = 0; schedIdx < scheduleCount; schedIdx++)
			{
				Schedule *schedule = [schedules objectAtIndex:schedIdx];

				NSUInteger idx;
				for (idx = 0; idx < myScheduleCount; idx++)
				{
					Schedule *selSchedule = [mySchedule objectAtIndex:idx];
					if ([selSchedule.ID isEqualToString:schedule.ID])
					{
						schedule.isSelected = YES;
						break;
					}
				}
				if(idx == myScheduleCount)
				{
					schedule.isSelected = NO;
				}
			}
		}
	}
}

- (void) calendarButtonTapped:(id)sender event:(id)touchEvent
{
    Schedule *schedule = [self getItemForSender:sender event:touchEvent];
    schedule.isSelected ^= YES;
    
    // Call to Appdelegate to Add/Remove from Calendar
    [delegate addOrRemoveScheduleToCalendar:schedule];
    [delegate addOrRemoveSchedule:schedule];
	
    [self syncTableDataWithScheduler];
    
    NSLog(@"Schedule:ItemID-ID:%@-%@", schedule.itemID, schedule.ID);
	
    UIButton *calendarButton = (UIButton*)sender;
    UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
    [calendarButton setImage:buttonImage forState:UIControlStateNormal];
}

- (Schedule*) getItemForSender:(id)sender event:(id)touchEvent
{
    NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.eventsTableView];
	NSIndexPath *indexPath = [self.eventsTableView indexPathForRowAtPoint:currentTouchPosition];
	NSInteger row = [indexPath row];
	NSInteger section = [indexPath section];
    Schedule *schedule = nil;
    
    if (indexPath != nil)
	{
		NSString *day = [self.sortedKeysInDateToEventsDictionary  objectAtIndex:section];
		NSDate *date = [self dateFromString:day];
		
		Special *event = [[self.dateToEventsDictionary objectForKey:day] objectAtIndex:row];
		
		for (schedule in event.schedules) {
			
            if ([self compareStartDate:schedule.startDate withSectionDate:date]) {
				break;
			}
		}
    }
	
    return schedule;
}

//Returns result of comparision between the StartDate of Schedule
//with the SectionDate of tableview using Calendar Components Day-Month-Year
- (BOOL)compareStartDate:(NSDate *)startDate withSectionDate:(NSDate *)sectionDate
{
    //Compare Date using Day-Month-year components excluding the time
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger components = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
    
    NSDateComponents *date1Components = [calendar components:components
                                                    fromDate: startDate];
    NSDateComponents *date2Components = [calendar components:components
                                                    fromDate: sectionDate];
    
    startDate = [calendar dateFromComponents:date1Components];
    sectionDate = [calendar dateFromComponents:date2Components];
    
    if ([startDate compare:sectionDate] >= NSOrderedSame) {
        return TRUE;
    } else {
        return FALSE;
    }
}

#pragma mark -
#pragma mark UITableView DataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sortedKeysInDateToEventsDictionary count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSString *day = [self.sortedKeysInDateToEventsDictionary objectAtIndex:section];
	return [[self.dateToEventsDictionary objectForKey:day] count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *day = [self.sortedKeysInDateToEventsDictionary objectAtIndex:section];
	NSDate *date = [self dateFromString:day];

	Special *event = [[self.dateToEventsDictionary objectForKey:day] objectAtIndex:row];

	Schedule *schedule = nil;
	for (schedule in event.schedules) {
        
        if ([self compareStartDate:schedule.startDate withSectionDate:date]) {
			break;
		}
	}

	BOOL selected = NO;
	NSUInteger count = [mySchedule count];
	for(int idx = 0; idx < count; idx++)
	{
		Schedule *selSchedule = [mySchedule objectAtIndex:idx];
		if(schedule.ID == selSchedule.ID)
		{
			selected = YES;
			break;
		}
	}

	UIImage *buttonImage = selected ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
	UILabel *titleLabel = nil;
	UILabel *timeLabel = nil;
	UILabel *venueLabel = nil;
	UIButton *calendarButton = nil;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kEventCellIdentifier];
    if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kEventCellIdentifier];
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
		[calendarButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
		[cell.contentView addSubview:calendarButton];
	}
	
	NSInteger titleNumLines = 1;
	titleLabel = (UILabel*)[cell viewWithTag:CELL_TITLE_LABEL_TAG];
	CGSize size = [event.name sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
    if(size.width < 256.0)
    {
        [titleLabel setFrame:CGRectMake(52.0, 6.0, 256.0, 20.0)];
    }
    else
    {
        [titleLabel setFrame:CGRectMake(52.0, 6.0, 256.0, 42.0)];
        titleNumLines = 2;
    }
    
    [titleLabel setNumberOfLines:titleNumLines];
    titleLabel.text = event.name;
    
	timeLabel = (UILabel*)[cell viewWithTag:CELL_TIME_LABEL_TAG];
	[timeLabel setFrame:CGRectMake(52.0, titleNumLines == 1 ? 28.0 : 50.0, 250.0, 20.0)];
	timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", schedule.dateString, schedule.startTime, schedule.endTime];
	
	venueLabel = (UILabel*)[cell viewWithTag:CELL_VENUE_LABEL_TAG];
	[venueLabel setFrame:CGRectMake(52.0, titleNumLines == 1 ? 46.0 : 68.0, 250.0, 20.0)];
	venueLabel.text = [NSString stringWithFormat:@"Venue: %@", schedule.venue];
	
	calendarButton = (UIButton*)[cell viewWithTag:CELL_LEFTBUTTON_TAG];
	[calendarButton setFrame:CGRectMake(8.0, titleNumLines == 1 ? 12.0 : 24.0, 40.0, 40.0)];
	[calendarButton setImage:buttonImage forState:UIControlStateNormal];
	
    return cell;
}

- (NSArray*) sectionIndexTitlesForTableView:(UITableView*)tableView
{
#pragma message "** OS bug **"
	// Temporary fix for crash in [self.filmsTableView reloadData] usually caused by Google+-related code
	// http://stackoverflow.com/questions/18918986/uitableview-section-index-related-crashes-under-ios-7
	// return nil;
	
	return self.sortedIndexesInDateToEventsDictionary;
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
	
	label.text = [NSString stringWithFormat:@"  %@", [self.sortedKeysInDateToEventsDictionary objectAtIndex:section]];
	
	return view;
}

#pragma mark -
#pragma mark UITableView delegate

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.01;		// This creates a "invisible" footer
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 28.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];

	NSString *day = [self.sortedKeysInDateToEventsDictionary  objectAtIndex:section];
	NSDate *date = [self dateFromString:day];
	
	Special *event = [[self.dateToEventsDictionary objectForKey:day] objectAtIndex:row];
	
	for(Schedule *schedule in event.schedules) {
        
        if ([self compareStartDate:schedule.startDate withSectionDate:date]) {
			EventDetailViewController *eventDetail = [[EventDetailViewController alloc] initWithEvent:schedule.itemID];
			[self.navigationController pushViewController:eventDetail animated:YES];

			break;
		}
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
    
	NSString *day = [self.sortedKeysInDateToEventsDictionary  objectAtIndex:section];
	Special *event = [[self.dateToEventsDictionary objectForKey:day] objectAtIndex:row];
    
    CGSize size = [event.name sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
    if(size.width >= 256.0)
    {
        return 90.0;
    }
    else
    {
        return 68.0;
    }
}

@end

