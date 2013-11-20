//
//  FilmsViewController.m
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FilmsViewController.h"
#import "NewsViewController.h"
#import "FilmDetailController.h"
#import "CinequestAppDelegate.h"
#import "Schedule.h"
#import "DDXML.h"
#import "DataProvider.h"
#import "Film.h"
#import "Festival.h"

#define VIEW_BY_DATE	0
#define VIEW_BY_TITLE	1

static NSString *const kDateCellIdentifier = @"DateCell";
static NSString *const kTitleCellIdentifier = @"TitleCell";
static char *const kAssociatedScheduleKey = "Schedule";


@implementation FilmsViewController

@synthesize switchTitle;
@synthesize filmsTableView;
@synthesize activity;

#pragma mark -
#pragma mark Actions

- (void) calendarButtonTapped:(id)sender event:(id)touchEvent
{
	NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.filmsTableView];
	NSIndexPath *indexPath = [self.filmsTableView indexPathForRowAtPoint:currentTouchPosition];
	NSInteger row = [indexPath row];
	NSInteger section = [indexPath section];
	
	if(indexPath != nil)
	{
		Schedule *schedule = nil;
		
		if(switcher == VIEW_BY_DATE)
		{
			NSString *date = [days objectAtIndex:section];
			NSMutableArray *films = [data objectForKey:date];
			schedule = [films objectAtIndex:row];
		}
		else // VIEW_BY_TITLE
		{
			NSString *sort = [sorts objectAtIndex:section];
			NSMutableArray *films = [titlesWithSort objectForKey:sort];
			Film *film = [films objectAtIndex:row];
			schedule = [film.schedules objectAtIndex:0];
		}
		
		schedule.isSelected ^= YES;
		
		UIButton *checkBoxButton = (UIButton*)sender;
		UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
		[checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
	}
}

- (void) infoButtonTapped:(id)sender event:(id)touchEvent
{
	NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.filmsTableView];
	NSIndexPath *indexPath = [self.filmsTableView indexPathForRowAtPoint:currentTouchPosition];
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch(switcher)
	{
		case VIEW_BY_DATE:
		{
			NSString *date = [days objectAtIndex:section];
			NSMutableArray *films = [data objectForKey:date];
			Schedule *schedule = [films objectAtIndex:row];
			[self showFilmDetails:schedule];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];
			NSMutableArray *films = [titlesWithSort objectForKey:sort];
			Film *film = [films objectAtIndex:row];
			
			NSLog(@"%@", film.genre);
			
			Schedule *schedule = [film.schedules objectAtIndex:0];
			[self showFilmDetails:schedule];
		}
			break;
	}
}

- (void) launchMaps
{
	// Create an MKMapItem to pass to the Maps app
	CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(16.775, -3.009);
	MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
	MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
	[mapItem setName:@"Cinequest - Venue C12"];
	
	// Pass the map item to the Maps app
	[mapItem openInMapsWithLaunchOptions:nil];
}

- (IBAction) switchTitle:(id)sender
{
	switcher = [sender selectedSegmentIndex];
	switch (switcher)
	{
		case VIEW_BY_DATE:
			listByTitleOffset = [self.filmsTableView contentOffset].y;
			[self.filmsTableView setContentOffset:CGPointMake(0.0, listByDateOffset) animated:NO];
			break;
			
		case VIEW_BY_TITLE:
			listByDateOffset = [self.filmsTableView contentOffset].y;
			[self.filmsTableView setContentOffset:CGPointMake(0.0, listByTitleOffset) animated:NO];
			break;
			
		default:
			break;
	}
	
	[self.filmsTableView reloadData];
}

- (void) showFilmDetails:(Schedule*)schedule
{
	NSLog(@"Showing details for schedule \"%@\" (ID %@)", schedule.title, schedule.itemID);
	
	FilmDetailController *filmDetail = [[FilmDetailController alloc] initWithTitle:@"Film Detail" andId:schedule.itemID];
	[[self navigationController] pushViewController:filmDetail animated:YES];
}

- (void) actionForFilm:(Schedule*)film
{
	film.presentInScheduler = !film.isSelected;
	film.presentInCalendar = !film.isSelected;
	
	NSString *choice1 = nil;
	NSString *choice2 = nil;
	NSString *choice3 = nil;
	NSString *choice4 = nil;
	NSString *choice5 = nil;

	if(film.presentInScheduler)
	{
		choice1 = film.presentInCalendar ? @"Remove from My Schedule & Calendar" : @"Remove from My Schedule";
		choice2 = film.presentInCalendar ? @"Show in Calendar" : @"Add to Calendar";
		choice3 = @"Show Venue location in Maps";
		choice4 = @"Film Detail";
	}
	else
	{
		choice1 = @"Add to My Schedule";
		choice2 = @"Add to My Schedule and Calendar";
		choice3 = @"Show in Calendar";
		choice4 = @"Show Venue location in Maps";
		choice5 = @"Film Detail";
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self
												cancelButtonTitle:@"Cancel"
												otherButtonTitles:choice1, choice2, choice3, choice4, choice5, nil];
	
	objc_setAssociatedObject(alert, kAssociatedScheduleKey, film, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[alert show];
}

- (void) alertView:(UIAlertView*)alert clickedButtonAtIndex:(NSInteger)buttonIndex
{
	Schedule *film = objc_getAssociatedObject(alert, kAssociatedScheduleKey);

	switch(buttonIndex)
	{
		case 1:			// choice1
			break;

		case 2:			// choice2
			break;

		case 3:			// choice3
			if(film.presentInScheduler)
			{
				[self launchMaps];
			}
			else
			{
				// Open calendar
			}
			break;

		case 4:			// choice4
			if(film.presentInScheduler)
			{
				[self showFilmDetails:film];
			}
			else
			{
				[self launchMaps];
			}
			break;

		case 5:			// choice5
			[self showFilmDetails:film];
			break;

		default:		// Cancel
			break;
	}
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
	
	[self syncTableDataWithScheduler];
}

- (IBAction) reloadData:(id)sender
{
	// Hide everything, display activity indicator
	self.filmsTableView.hidden = YES;
	
	[activity startAnimating];
	
	// Start parsing data
	[data removeAllObjects];
	[days removeAllObjects];
	[index removeAllObjects];
	[titlesWithSort removeAllObjects];
	[sorts removeAllObjects];
	
	[self performSelectorOnMainThread:@selector(prepareData) withObject:nil waitUntilDone:NO];
}

#pragma mark - UIViewController Methods

- (void) viewDidLoad
{
	self.title = @"Films";
	
    [super viewDidLoad];
	
	delegate = appDelegate;
	mySchedule = [appDelegate mySchedule];
	
	// Initialize data
	data = [[NSMutableDictionary alloc] init];
	days = [[NSMutableArray alloc] init];
	index = [[NSMutableArray alloc] init];
	
	// backedUpDays = [[NSMutableArray alloc] init];
	// backedUpIndex = [[NSMutableArray alloc] init];
	// backedUpData = [[NSMutableDictionary alloc] init];
	
	// Inialize titles and sorts
	titlesWithSort = [[NSMutableDictionary alloc] init];
	sorts = [[NSMutableArray alloc] init];

	if (delegate.isOffSeason)
	{
		self.filmsTableView.hidden = YES;
		return;
	}
	
	titleFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	venueFont = timeFont;
	
	switcher = VIEW_BY_DATE;
	
	self.filmsTableView.tableHeaderView = nil;
	self.filmsTableView.tableFooterView = nil;

	[self reloadData:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Methods

- (void) prepareData
{
	// FILMS BY TIME
    [delegate.festival.schedules sortUsingDescriptors:[NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES], nil]];
    NSString *previousDay = @"empty";
	NSMutableArray *tempArray = [NSMutableArray array];
    
	for (Schedule *schedule in delegate.festival.schedules)
	{
		//[films addObject:film];
		
		if (![previousDay isEqualToString:schedule.longDateString])
		{
			[data setObject:tempArray forKey:previousDay];
			
			previousDay = [[NSString alloc] initWithString:schedule.longDateString];
			[days addObject:previousDay];
			
			[index addObject:[[previousDay componentsSeparatedByString:@" "] objectAtIndex: 2]];
			
			tempArray = [[NSMutableArray alloc] init];
			[tempArray addObject:schedule];
		}
		else
		{
			[tempArray addObject:schedule];
		}
	}
	[data setObject:tempArray forKey:previousDay];
    
	// FILMS BY TITLES
    
    [delegate.festival.films sortUsingDescriptors:[NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES],nil]];
	NSString *pre = @"empty";
	NSMutableArray *temp = [[NSMutableArray alloc] init];
	
	for (Film *film in delegate.festival.films)
	{
		NSString *sortString = [film.name substringToIndex:1];
		if(![pre isEqualToString:sortString])
		{
			[titlesWithSort setObject:temp forKey:pre];
			
			pre = [NSString stringWithString:sortString];
			[sorts addObject:pre];
			
			temp = [[NSMutableArray alloc] init];
			[temp addObject:film];
		}
		else
		{
			[temp addObject:film];
		}
	}
	
	[titlesWithSort setObject:temp forKey:pre];
    
	[activity stopAnimating];
	
	self.filmsTableView.hidden = NO;
	[self.filmsTableView reloadData];
	
	// back up current data
    // backedUpDays	= [[NSMutableArray alloc] initWithArray:days copyItems:YES];
	// backedUpIndex = [[NSMutableArray alloc] initWithArray:index copyItems:YES];
	// backedUpData	= [[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES];
	
	[self syncTableDataWithScheduler];
}

- (NSArray *) getSchedulesFromListByTime:(NSArray*)films withProgId:(NSString*)progId
{
	NSMutableArray *schedules = [NSMutableArray array];
	
	for(Schedule *schedule in films)
	{
		if([schedule.itemID isEqualToString:progId])
		{
			[schedules addObject:schedule];
		}
	}
	
	return schedules;
}

- (void) syncTableDataWithScheduler
{
	NSInteger count = [mySchedule count];
	NSLog(@"Scheduler count: %ld", (long)count);
	
	// Sync current data
	for (NSUInteger section = 0; section < [days count]; section++)
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];   
		for (NSUInteger row = 0; row < [rows count]; row++)
		{
			Schedule *film = [rows objectAtIndex:row];
			// film.isSelected = NO;
			for (NSUInteger idx = 0; idx < count; idx++)
			{
				Schedule *obj = [mySchedule objectAtIndex:idx];
				if ([obj.ID isEqualToString:film.ID])
				{
					//NSLog(@"Current Data ... Already Added: %@. Time: %@",obj.title,obj.timeString);
					film.isSelected = YES;
				}
			}
		}
	}
	
	// Sync backedUp Data
	for (NSUInteger section = 0; section < [days count]; section++)
	{
		NSString *day = [days objectAtIndex:section];
		NSArray *rows = [backedUpData objectForKey:day];
		for (int row = 0; row < [rows count]; row++)
		{
			Schedule *film = [rows objectAtIndex:row];
			//film.isSelected = NO;
			for (NSUInteger idx = 0; idx < count; idx++)
			{
				Schedule *obj = [mySchedule objectAtIndex:idx];
				if ([obj.ID isEqualToString:film.ID])
				{
					//NSLog(@"BackedUp Data ... Already Added: %@.",obj.title);
					film.isSelected = YES;
				}
			}
		}
	}
}

#pragma mark - Table View Datasource methods

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
	NSInteger count = 0;
	
	switch(switcher)
	{
		case VIEW_BY_DATE:
			count = [days count];
			break;
			
		case VIEW_BY_TITLE:
			count = [sorts count];
			break;
			
		default:
			break;
	}
	
	return count;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger count = 0;
	
	switch(switcher)
	{
		case VIEW_BY_DATE:
		{
            NSString *day = [days objectAtIndex:section];
			count = [[data objectForKey:day] count];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];
			count = [[titlesWithSort objectForKey:sort] count];
		}
			break;
	}
	
    return count;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	UITableViewCell *cell = nil;
	
	switch(switcher)
	{
		case VIEW_BY_DATE:
		{
			// get film objects using date
			NSString *dateString = [days objectAtIndex:section];
			Schedule *schedule = [[data objectForKey:dateString] objectAtIndex:row];
			
			// check if current cell is already added to mySchedule
			NSUInteger idx, count = [mySchedule count];
			for(idx = 0; idx < count; idx++)
			{
				Schedule *obj = [mySchedule objectAtIndex:idx];
				if(obj.ID == schedule.ID)//&& [obj.title isEqualToString:film.title] && [obj.date compare:film.date] == NSOrderedSame
				{
					schedule.isSelected = YES;
					break;
				}
			}
			
			UILabel *titleLabel, *timeLabel, *venueLabel;
			UIButton *calButton, *infoButton;
			
			// Get checkbox status
			UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
			NSInteger titleNumLines = 1;
			
			cell = [tableView dequeueReusableCellWithIdentifier:kDateCellIdentifier];
			if(cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDateCellIdentifier];
				
				UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 6.0, 250.0, 20.0)];
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
				
				infoButton = [UIButton buttonWithType: [appDelegate OSVersion] < 7.0 ? UIButtonTypeInfoDark : UIButtonTypeInfoLight];
				infoButton.frame = CGRectMake(15.0, 4.0, 24.0, 24.0);
				[infoButton addTarget:self action:@selector(infoButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				infoButton.tag = CELL_RIGHTBUTTON_TAG;
				[cell.contentView addSubview:infoButton];
				
				calButton = [UIButton buttonWithType:UIButtonTypeCustom];
				calButton.frame = CGRectMake(11.0, 32.0, 32.0, 32.0);
				[calButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				calButton.tag = CELL_LEFTBUTTON_TAG;
				[cell.contentView addSubview:calButton];
			}
			
			titleLabel = (UILabel*)[cell viewWithTag:CELL_TITLE_LABEL_TAG];
			CGSize size = [schedule.title sizeWithFont:titleFont];
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
			titleLabel.text = schedule.title;
			
			timeLabel = (UILabel*)[cell viewWithTag:CELL_TIME_LABEL_TAG];
			if(titleNumLines == 1)
			{
				[timeLabel setFrame:CGRectMake(52.0, 28.0, 250.0, 20.0)];
			}
			else
			{
				[timeLabel setFrame:CGRectMake(52.0, 50.0, 250.0, 20.0)];
			}
			timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", schedule.dateString, schedule.startTime, schedule.endTime];
			
			venueLabel = (UILabel*)[cell viewWithTag:CELL_VENUE_LABEL_TAG];
			if(titleNumLines == 1)
			{
				[venueLabel setFrame:CGRectMake(52.0, 46.0, 250.0, 20.0)];
			}
			else
			{
				[venueLabel setFrame:CGRectMake(52.0, 68.0, 250.0, 20.0)];
			}
			venueLabel.text = [NSString stringWithFormat:@"Venue: %@",schedule.venue];
			
			infoButton = (UIButton*)[cell viewWithTag:CELL_RIGHTBUTTON_TAG];
			if(titleNumLines == 1)
			{
				[infoButton setFrame:CGRectMake(15.0, 4.0, 24.0, 24.0)];
			}
			else
			{
				[infoButton setFrame:CGRectMake(15.0, 15.0, 24.0, 24.0)];
			}
			
			calButton = (UIButton*)[cell viewWithTag:CELL_LEFTBUTTON_TAG];
			if(titleNumLines == 1)
			{
				[calButton setFrame:CGRectMake(11.0, 32.0, 32.0, 32.0)];
			}
			else
			{
				[calButton setFrame:CGRectMake(11.0, 54.0, 32.0, 32.0)];
			}
			[calButton setImage:buttonImage forState:UIControlStateNormal];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];
/*
			NSArray *schedules = [[titlesWithSort objectForKey:sort] objectAtIndex:row];
			Schedule *film = [schedules objectAtIndex:filmIdx];
*/
			NSInteger filmIdx = 0;
			NSArray *films = [titlesWithSort objectForKey:sort];
			Film *film = [films objectAtIndex:[indexPath row]];
			NSArray *schedules = film.schedules;
			
			cell = [tableView dequeueReusableCellWithIdentifier:kTitleCellIdentifier];
			if(cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTitleCellIdentifier];
			}
			else
			{
				[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
			}
			
			NSInteger titleNumLines = 1;
			CGSize size = [film.name sizeWithFont:titleFont];
			if(size.width >= 256.0)
			{
				titleNumLines = 2;
			}
			
			UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleNumLines == 1 ? CGRectMake(52.0, 6.0, 256.0, 20.0) : CGRectMake(52.0, 6.0, 256.0, 42.0)];
			titleLabel.tag = CELL_TITLE_LABEL_TAG;
			[titleLabel setNumberOfLines:titleNumLines];
			titleLabel.font = titleFont;
			titleLabel.text = film.name;
			[cell.contentView addSubview:titleLabel];
			
			UIButton *infoButton = [UIButton buttonWithType: [appDelegate OSVersion] < 7.0 ? UIButtonTypeInfoDark : UIButtonTypeInfoLight];
			if(titleNumLines == 1)
			{
				[infoButton setFrame:CGRectMake(15.0, 4.0, 24.0, 24.0)];
			}
			else
			{
				[infoButton setFrame:CGRectMake(15.0, 15.0, 24.0, 24.0)];
			}
			[infoButton addTarget:self action:@selector(infoButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
			infoButton.tag = CELL_RIGHTBUTTON_TAG;
			[cell.contentView addSubview:infoButton];
			
			CGFloat hPos = titleNumLines == 1 ? 28.0 : 50.0;
			for(Schedule *schedule in schedules)
			{
				if(filmIdx > 0)
				{
					film = [schedules objectAtIndex:filmIdx];
				}
				
				UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, hPos, 250.0, 20.0)];
				timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", schedule.dateString, schedule.startTime, schedule.endTime];
				timeLabel.font = timeFont;
				timeLabel.tag = CELL_TIME_LABEL_TAG;
				[cell.contentView addSubview:timeLabel];
				
				UILabel *venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, hPos + 18.0, 250.0, 20.0)];
				venueLabel.text = [NSString stringWithFormat:@"Venue: %@", schedule.venue];
				venueLabel.font = venueFont;
				venueLabel.tag = CELL_VENUE_LABEL_TAG;
				[cell.contentView addSubview:venueLabel];
				
				UIButton *calButton = [UIButton buttonWithType:UIButtonTypeCustom];
				calButton.frame = CGRectMake(11.0, hPos + 4, 32.0, 32.0);
				calButton.tag = CELL_LEFTBUTTON_TAG + filmIdx;
				UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
				[calButton setImage:buttonImage forState:UIControlStateNormal];
				[calButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				[cell.contentView addSubview:calButton];
				
				hPos += 38.0;
				filmIdx++;
			}
		}
			break;
	}
	
    return cell;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *result;
	
	switch (switcher)
	{
		case VIEW_BY_DATE:
			result = [days objectAtIndex:section];
			break;
			
		case VIEW_BY_TITLE:
			result = [sorts objectAtIndex:section];
			break;
			
		default:
			break;
	}
	
	return result;
}

- (NSArray*) sectionIndexTitlesForTableView:(UITableView*)tableView
{
	NSArray *result;
	
	switch (switcher)
	{
		case VIEW_BY_DATE:
			result = index;
			break;
			
		case VIEW_BY_TITLE:
			result = sorts;
			break;
			
		default:
			break;
	}
	
	return result;
}

#pragma mark - UITableView Delegate

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	
	switch (switcher)
	{
		case VIEW_BY_DATE:
		{
			NSString *date = [days objectAtIndex:section];
			NSMutableArray *films = [data objectForKey:date];
			Schedule *schedule = [films objectAtIndex:row];
			[self actionForFilm:schedule];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];
			NSMutableArray *films = [titlesWithSort objectForKey:sort];
			Film *film = [films objectAtIndex:row];
			Schedule *schedule = [film.schedules objectAtIndex:0];
			[self actionForFilm:schedule];
		}
			break;
			
		default:
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];

	if(switcher == VIEW_BY_DATE)
	{
		NSString *dateString = [days objectAtIndex:section];
		Schedule *schedule = [[data objectForKey:dateString] objectAtIndex:row];
		
		CGSize size = [schedule.title sizeWithFont:titleFont];
		if(size.width >= 256.0)
		{
			return 88.0;
		}
		else
		{
			return 66.0;
		}
	}
	else // VIEW_BY_TITLE
	{
		NSString *sort = [sorts objectAtIndex:[indexPath section]];
		NSArray *films = [titlesWithSort objectForKey:sort];
        Film *film = [films objectAtIndex:[indexPath row]];

		CGSize size = [film.name sizeWithFont:titleFont];
		if(size.width >= 256.0)
		{
			return 50.0 + (38 * film.schedules.count);
		}
		else
		{
			return 28.0 + (38 * film.schedules.count);
		}
	}
}

@end



