//
//  ForumsViewController.m
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "ForumsViewController.h"
#import "EventDetailViewController.h"
#import "Schedule.h"
#import "CinequestAppDelegate.h"
#import "DDXML.h"
#import "DataProvider.h"


static NSString *const kForumCellIdentifier = @"ForumCell";

@implementation ForumsViewController

@synthesize days;
@synthesize index;
@synthesize data;
@synthesize forumsTableView;
@synthesize activityIndicator;

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
	
	// Initialize data and days
	data = [[NSMutableDictionary alloc] init];
	days = [[NSMutableArray alloc] init];
	index = [[NSMutableArray alloc] init];
	backedUpDays = [[NSMutableArray alloc] init];
	backedUpIndex = [[NSMutableArray alloc] init];
	backedUpData = [[NSMutableDictionary alloc] init];

    titleFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	venueFont = timeFont;

	UISegmentedControl *switchTitle = [[UISegmentedControl alloc] initWithFrame:CGRectMake(98.5, 7.5, 123.0, 29.0)];
	[switchTitle insertSegmentWithTitle:@"Forums" atIndex:0 animated:NO];
	[switchTitle setSelectedSegmentIndex:0];
	NSDictionary *attribute = [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:16.0f] forKey:NSFontAttributeName];
	[switchTitle setTitleTextAttributes:attribute forState:UIControlStateNormal];
	self.navigationItem.titleView = switchTitle;

	[self reloadData:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
	[self syncTableDataWithScheduler];
}

#pragma mark -
#pragma mark Private Methods

- (void) syncTableDataWithScheduler
{
	NSUInteger count = [mySchedule count];
	
	// Sync current data
	for (int section = 0; section < [days count]; section++) 
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];
		for (int row = 0; row < [rows count]; row++) 
		{
			Schedule *event = [rows objectAtIndex:row];
			//event.isSelected = NO;
			for (int idx = 0; idx < count; idx++)
			{
				Schedule *obj = [mySchedule objectAtIndex:idx];
				//NSLog(@"obj id:%d, event id:%d",obj.ID,event.ID);
				if (obj.ID == event.ID) 
				{
					//NSLog(@"Added: %@. Time: %@",obj.title,obj.timeString);
					event.isSelected = YES;
				}
			}
		}
	}
	
	// Sync backedUp Data
	for (int section = 0; section < [days count]; section++) 
	{
		NSString *day = [days objectAtIndex:section];
		NSArray *rows = [backedUpData objectForKey:day];
		for (int row = 0; row < [rows count]; row++) 
		{
			Schedule *event = [rows objectAtIndex:row];
			//event.isSelected = NO;
			for (int idx = 0; idx < count; idx++)
			{
				Schedule *obj = [mySchedule objectAtIndex:idx];
				if (obj.ID == event.ID) 
				{
					//NSLog(@"Added: %@.",obj.title);
					event.isSelected = YES;
				}
			}
		}
	}
}

- (void) startParsingXML
{
	NSData *xmldata = [[appDelegate dataProvider] forums];
	
	DDXMLDocument *forumsxmlDoc = [[DDXMLDocument alloc] initWithData:xmldata options:0 error:nil];
	DDXMLNode *rootElement = [forumsxmlDoc rootElement];
	
	NSInteger childCount = [rootElement childCount];
	NSString *previousDay = @"empty";
	NSMutableArray *tempArray = [[NSMutableArray alloc] init];

	for (int i = 0; i < childCount; i++)
	{
		DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
		NSDictionary *attributes;
		if ([child respondsToSelector:@selector(attributesAsDictionary)])
		{
			attributes = [child attributesAsDictionary];
		}
		else
		{
			continue;
		}
		
		NSString *ID		= [attributes objectForKey:@"schedule_id"];
		NSString *prg_id	= [attributes objectForKey:@"program_item_id"];
		NSString *type		= [attributes objectForKey:@"type"];
		NSString *title		= [attributes objectForKey:@"title"];
		NSString *start		= [attributes objectForKey:@"start_time"];
		NSString *end		= [attributes objectForKey:@"end_time"];
		NSString *venue		= [attributes objectForKey:@"venue"];
		
		Schedule *forum		= [[Schedule alloc] init];
		forum.ID			= ID;
		forum.itemID		= prg_id;
		forum.type		= type;
		forum.title		= title;
		forum.venue		= venue;
		
		// Start time
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		NSDate *date = [dateFormatter dateFromString:start];
		forum.startDate = date;
		[dateFormatter setDateFormat:@"hh:mm a"];
		forum.startTime = [dateFormatter stringFromDate:date];
		// Date
		[dateFormatter setDateFormat:@"EEE, MMM d"];
		NSString *dateString = [dateFormatter stringFromDate:date];
		forum.dateString = dateString;
        [dateFormatter setDateFormat:@"EEEE, MMMM d"];
        forum.longDateString = [dateFormatter stringFromDate:date];
		// End Time
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		date = [dateFormatter dateFromString:end];
		forum.endDate = date;
		[dateFormatter setDateFormat:@"hh:mm a"];
		forum.endTime = [dateFormatter stringFromDate:date];
		
		if (![previousDay isEqualToString:forum.longDateString])
		{
			[data setObject:tempArray forKey:previousDay];
			previousDay = [[NSString alloc] initWithString:forum.longDateString];
			[days addObject:previousDay];
			
			[index addObject:[[previousDay componentsSeparatedByString:@" "] objectAtIndex: 2]];
			
			tempArray = [[NSMutableArray alloc] init];
			[tempArray addObject:forum];
		}
		else
		{
			[tempArray addObject:forum];
		}
	}
	
	[data setObject:tempArray forKey:previousDay];
	
	// back up current data
	backedUpDays	= [[NSMutableArray alloc] initWithArray:days copyItems:YES];
	backedUpIndex	= [[NSMutableArray alloc] initWithArray:index copyItems:YES];
    backedUpData	= [[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES];
    
    [delegate populateCalendarEntries];
    
	[self.forumsTableView reloadData];
	self.forumsTableView.hidden = NO;
	[activityIndicator stopAnimating];
	
	self.forumsTableView.tableHeaderView = nil;
}

- (void) checkBoxButtonTapped:(id)sender event:(id)touchEvent
{
	NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.forumsTableView];
	NSIndexPath *indexPath = [self.forumsTableView indexPathForRowAtPoint:currentTouchPosition];
	NSInteger row = [indexPath row];
	NSInteger section = [indexPath section];
	
	if (indexPath != nil)
	{
		// get date
		NSString *dateString = [days objectAtIndex:section];
		
		// get film objects using dateString
		NSMutableArray *events = [data objectForKey:dateString];
		Schedule *event = [events objectAtIndex:row];
		
		// set checkBox's status
		BOOL checked = event.isSelected;
		event.isSelected = !checked;
		
		// get the current cell and the checkbox button 
		UITableViewCell *currentCell = [self.forumsTableView cellForRowAtIndexPath:indexPath];
		UIButton *checkBoxButton = (UIButton*)[currentCell viewWithTag:CELL_LEFTBUTTON_TAG];
		
		// set button's image
        UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"cal_unselected.png"] : [UIImage imageNamed:@"cal_selected.png"];
		[checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
        NSLog(@"Schedule:ItemID-ID:%@-%@",event.itemID,event.ID);
        
		for (int section = 0; section < [days count]; section++) 
		{
			NSString *day = [days objectAtIndex:section];
			NSMutableArray *rows = [data objectForKey:day];
			for (int row = 0; row < [rows count]; row++) 
			{
				Schedule *aRandomEvent = [rows objectAtIndex:row];
				if (aRandomEvent.ID == event.ID)
				{
					aRandomEvent.isSelected = event.isSelected;
				}
			}
		}
	}
}

#pragma mark -
#pragma mark Actions

- (IBAction) reloadData:(id)sender
{
	[days removeAllObjects];
	[data removeAllObjects];
	[index removeAllObjects];
	
	self.forumsTableView.hidden = YES;
	
	[activityIndicator startAnimating];
	
	[self performSelectorOnMainThread:@selector(startParsingXML) withObject:nil waitUntilDone:NO];
}

- (void) back:(id)sender
{
	// reload data
	[days removeAllObjects];
	[index removeAllObjects];
	
	[days addObjectsFromArray:backedUpDays];
	[index addObjectsFromArray:backedUpIndex];
	
	for (int section = 0; section < [days count]; section++) 
	{
		NSString *day = [days objectAtIndex:section];
		NSArray *rows = [backedUpData objectForKey:day];
		NSMutableArray *array = [[NSMutableArray alloc] init];
		for (int row = 0; row < [rows count]; row++) 
		{
			Schedule *item = [rows objectAtIndex:row];
			[array addObject:item];
		}
		[data setObject:array forKey:day];
	}
	
	// push animation
	CATransition *transition = [CATransition animation];
	transition.type = kCATransitionPush;
	transition.subtype = kCATransitionFromBottom;
	transition.duration = 0.3;
	[[self.forumsTableView layer] addAnimation:transition forKey:nil];
	
	// reload table data
	[self.forumsTableView reloadData];
	
}

#pragma mark -
#pragma mark UITableView Datasource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [days count];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	NSString *day = [days objectAtIndex:section];
	NSMutableArray *forums = [data objectForKey:day];
	
    return [forums count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *date = [days objectAtIndex:section];
	NSMutableArray *events = [data objectForKey:date];
	Schedule *event = [events objectAtIndex:row];
	
	// check if current cell is already added to mySchedule
	NSUInteger count = [mySchedule count];
	for (int idx = 0; idx < count; idx++)
	{
		Schedule *obj = [mySchedule objectAtIndex:idx];
		
		if (obj.ID == event.ID) 
		{
			event.isSelected = YES;
			break;
		}
	}
	
    UIImage *buttonImage = (event.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
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
		
		[calendarButton addTarget:self action:@selector(checkBoxButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
		calendarButton.backgroundColor = [UIColor clearColor];
		calendarButton.tag = CELL_LEFTBUTTON_TAG;
		[cell.contentView addSubview:calendarButton];
	}
	
	titleLabel = (UILabel*)[cell viewWithTag:CELL_TITLE_LABEL_TAG];
	CGSize size = [event.title sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
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
    titleLabel.text = event.title;
    
    timeLabel = (UILabel*)[cell viewWithTag:CELL_TIME_LABEL_TAG];
	[timeLabel setFrame:CGRectMake(52.0, titleNumLines == 1 ? 28.0 : 50.0, 250.0, 20.0)];
    timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", event.dateString, event.startTime, event.endTime];
    
    venueLabel = (UILabel*)[cell viewWithTag:CELL_VENUE_LABEL_TAG];
	[venueLabel setFrame:CGRectMake(52.0, titleNumLines == 1 ? 46.0 : 68.0, 250.0, 20.0)];
    venueLabel.text = [NSString stringWithFormat:@"Venue: %@", event.venue];
    
    calendarButton = (UIButton*)[cell viewWithTag:CELL_LEFTBUTTON_TAG];
	[calendarButton setFrame:CGRectMake(8.0, titleNumLines == 1 ? 8.0 : 24.0, 44.0, 44.0)];
	[calendarButton setImage:buttonImage forState:UIControlStateNormal];
    
    return cell;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *day = [days objectAtIndex:section];
	return day;
}

- (NSArray*) sectionIndexTitlesForTableView:(UITableView*)tableView
{
	return index;
}

#pragma mark -
#pragma mark UITableView Delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *date = [days objectAtIndex:section];
	
	NSMutableArray *forums = [data objectForKey:date];
	
	Schedule *forum = [forums objectAtIndex:row];

	NSString *eventId = [NSString stringWithFormat:@"%@", forum.itemID];
	EventDetailViewController *eventDetail = [[EventDetailViewController alloc] initWithEvent:forum.title
																						andDataObject:forum
																						andId:eventId];
	[self.navigationController pushViewController:eventDetail animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
    
    NSString *dateString = [days objectAtIndex:section];
    Schedule *schedule = [[data objectForKey:dateString] objectAtIndex:row];
    
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


@end

