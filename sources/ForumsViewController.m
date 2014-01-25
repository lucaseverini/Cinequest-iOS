//
//  ForumsViewController.m
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestAppDelegate.h"
#import "ForumsViewController.h"
#import "ForumDetailViewController.h"
#import "Forum.h"
#import "Schedule.h"
#import "DataProvider.h"


static NSString *const kForumCellIdentifier = @"ForumCell";

@implementation ForumsViewController

@synthesize switchTitle;
@synthesize forumsTableView;
@synthesize activityIndicator;
@synthesize dateToForumsDictionary;
@synthesize sortedKeysInDateToForumsDictionary;
@synthesize sortedIndexesInDateToForumsDictionary;

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	delegate = appDelegate;
	mySchedule = delegate.mySchedule;
	
	self.dateToForumsDictionary = [delegate.festival.dateToForumsDictionary mutableCopy];
	self.sortedKeysInDateToForumsDictionary = [delegate.festival.sortedKeysInDateToForumsDictionary mutableCopy];
	self.sortedIndexesInDateToForumsDictionary = [delegate.festival.sortedIndexesInDateToForumsDictionary mutableCopy];

    titleFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	venueFont = timeFont;

	NSDictionary *attribute = [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:16.0f] forKey:NSFontAttributeName];
	[switchTitle setTitleTextAttributes:attribute forState:UIControlStateNormal];
	[switchTitle removeSegmentAtIndex:1 animated:NO];

	forumsTableView.tableHeaderView = nil;
	forumsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
	[self syncTableDataWithScheduler];

	// [self.ForumsTableView reloadData];

#pragma message "Must Update Calendar Icons..."
}

#pragma mark -
#pragma mark Private Methods

- (void) syncTableDataWithScheduler
{
    [delegate populateCalendarEntries];
    
	NSInteger sectionCount = [self.sortedKeysInDateToForumsDictionary count];
	NSInteger myScheduleCount = [mySchedule count];
	if(myScheduleCount == 0)
	{
		return;
	}
	
	// Sync current data
	for (NSUInteger section = 0; section < sectionCount; section++)
	{
		NSString *day = [self.sortedKeysInDateToForumsDictionary objectAtIndex:section];
		NSMutableArray *events =  [self.dateToForumsDictionary objectForKey:day];
		NSInteger forumCount = [events count];
		
		for (NSUInteger row = 0; row < forumCount; row++)
		{
			NSArray *schedules = [[events objectAtIndex:row] schedules];
			NSInteger scheduleCount = [schedules count];
			
			for (NSUInteger schedIdx = 0; schedIdx < scheduleCount; schedIdx++)
			{
				Schedule *schedule = [schedules objectAtIndex:schedIdx];
				
				for (NSUInteger idx = 0; idx < myScheduleCount; idx++)
				{
					Schedule *mySched = [mySchedule objectAtIndex:idx];
					if ([mySched.ID isEqualToString:schedule.ID])
					{
						schedule.isSelected = YES;
					}
				}
			}
		}
	}
}

- (Schedule*) getItemForSender:(id)sender event:(id)touchEvent
{
    NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.forumsTableView];
	NSIndexPath *indexPath = [self.forumsTableView indexPathForRowAtPoint:currentTouchPosition];
	NSInteger row = [indexPath row];
	NSInteger section = [indexPath section];
    Schedule *schedule = nil;
    
    if (indexPath != nil)
	{
		NSString *day = [self.sortedKeysInDateToForumsDictionary  objectAtIndex:section];
		Forum *forum = [[self.dateToForumsDictionary objectForKey:day] objectAtIndex:row];
		schedule = [forum.schedules objectAtIndex:0];
    }
    
    return schedule;
}


#pragma mark - Actions

- (void) calendarButtonTapped:(id)sender event:(id)touchEvent
{
    Schedule *schedule = [self getItemForSender:sender event:touchEvent];
    schedule.isSelected ^= YES;
    
    // Call to Appdelegate to Add/Remove from Calendar
    [delegate addToDeviceCalendar:schedule];
    [delegate addOrRemoveFilm:schedule];
    [self syncTableDataWithScheduler];
    
    NSLog(@"Schedule:ItemID-ID:%@-%@\nSchedule Array:%@", schedule.itemID, schedule.ID, mySchedule);
    UIButton *calendarButton = (UIButton*)sender;
    UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
    [calendarButton setImage:buttonImage forState:UIControlStateNormal];
}

#pragma mark - UITableView Datasource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sortedKeysInDateToForumsDictionary count];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	NSString *day = [self.sortedKeysInDateToForumsDictionary objectAtIndex:section];
	return [[self.dateToForumsDictionary objectForKey:day] count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];

	NSString *day = [self.sortedKeysInDateToForumsDictionary objectAtIndex:section];
	Forum *forum = [[self.dateToForumsDictionary objectForKey:day] objectAtIndex:row];
	Schedule *schedule = [forum.schedules objectAtIndex:0];
	
	// check if current cell is already added to mySchedule
	NSUInteger count = [mySchedule count];
	for (int idx = 0; idx < count; idx++)
	{
		Schedule *obj = [mySchedule objectAtIndex:idx];
		if(obj.ID == schedule.ID)
		{
			schedule.isSelected = YES;
			break;
		}
	}
	
    UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
    NSInteger titleNumLines = 1;
	UILabel *titleLabel = nil;
	UILabel *timeLabel = nil;
	UILabel *venueLabel = nil;
	UIButton *calendarButton = nil;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kForumCellIdentifier];
    if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kForumCellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;

		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 6.0, 250.0, 20.0)];
		titleLabel.tag = CELL_TITLE_LABEL_TAG;
        titleLabel.font = titleFont;
		[cell.contentView addSubview:titleLabel];
		
		timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 28.0, 250.0, 20.0)];
		timeLabel.tag = CELL_TIME_LABEL_TAG;
        timeLabel.font = timeFont;
		[cell.contentView addSubview:timeLabel];
		
		venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 46.0, 250.0, 20.0)];
		venueLabel.tag = CELL_VENUE_LABEL_TAG;
        venueLabel.font = venueFont;
		[cell.contentView addSubview:venueLabel];
		
		calendarButton = [UIButton buttonWithType:UIButtonTypeCustom];
		calendarButton.frame = CGRectMake(11.0, 16.0, 32.0, 32.0);
		[calendarButton setImage:buttonImage forState:UIControlStateNormal];
		
		[calendarButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
		calendarButton.backgroundColor = [UIColor clearColor];
		calendarButton.tag = CELL_LEFTBUTTON_TAG;
		[cell.contentView addSubview:calendarButton];
	}
	
	titleLabel = (UILabel*)[cell viewWithTag:CELL_TITLE_LABEL_TAG];
	CGSize size = [forum.name sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
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
    titleLabel.text = forum.name;
    
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

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	return [self.sortedKeysInDateToForumsDictionary objectAtIndex:section];
}

- (NSArray*) sectionIndexTitlesForTableView:(UITableView*)tableView
{
#pragma message "** OS bug **"
	// Temporary fix for crash in [self.filmsTableView reloadData] usually caused by Google+-related code
	// http://stackoverflow.com/questions/18918986/uitableview-section-index-related-crashes-under-ios-7
	// return nil;
	
	return self.sortedIndexesInDateToForumsDictionary;
}

#pragma mark -
#pragma mark UITableView Delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *day = [self.sortedKeysInDateToForumsDictionary  objectAtIndex:section];
	Forum *forum = [[self.dateToForumsDictionary objectForKey:day] objectAtIndex:row];
	Schedule *schedule = [forum.schedules objectAtIndex:0];

	ForumDetailViewController *eventDetail = [[ForumDetailViewController alloc] initWithTitle:@"Forum" andId:schedule.itemID];
	[self.navigationController pushViewController:eventDetail animated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
    
	NSString *day = [self.sortedKeysInDateToForumsDictionary  objectAtIndex:section];
	Forum *forum = [[self.dateToForumsDictionary objectForKey:day] objectAtIndex:row];
    
    CGSize size = [forum.name sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
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

@end

