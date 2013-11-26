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

static NSString *const kDateCellIdentifier = @"DateCell";
static NSString *const kTitleCellIdentifier = @"TitleCell";
static char *const kAssociatedScheduleKey = "Schedule";


@implementation FilmsViewController

@synthesize switchTitle;
@synthesize filmsTableView;
@synthesize activity;
@synthesize filmSearchBar;

#pragma mark -
#pragma mark Actions

- (void) calendarButtonTapped:(id)sender event:(id)touchEvent
{
    Schedule *schedule = [self getItemForSender:sender event:touchEvent];
    schedule.isSelected ^= YES;
    
    //Call to Appdelegate to Add/Remove from Calendar
    [delegate addToDeviceCalendar:schedule];
    [delegate addOrRemoveFilm:schedule];
    [self syncTableDataWithScheduler];
    
    NSLog(@"Schedule:ItemID-ID:%@-%@\nSchedule Array:%@",schedule.itemID,schedule.ID,mySchedule);
    UIButton *checkBoxButton = (UIButton*)sender;
    UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
    [checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
}

- (Schedule*) getItemForSender:(id)sender event:(id)touchEvent
{
    NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.filmsTableView];
	NSIndexPath *indexPath = [self.filmsTableView indexPathForRowAtPoint:currentTouchPosition];
	NSInteger row = [indexPath row];
	NSInteger section = [indexPath section];
    Schedule *schedule = nil;
    
    if (indexPath != nil)
	{
		if(switcher == VIEW_BY_DATE)
		{
			NSString *date = [days objectAtIndex:section];
			NSMutableArray *films = [data objectForKey:date];
			schedule = [films objectAtIndex:row];
		}
		else // VIEW_BY_TITLE
		{
            UIButton *btnSelected = (UIButton*)sender;
			NSString *sort = [sorts objectAtIndex:section];
			NSMutableArray *films = [titlesWithSort objectForKey:sort];
			Film *film = [films objectAtIndex:row];
			schedule = (Schedule*)[film.schedules objectAtIndex:btnSelected.tag-CELL_LEFTBUTTON_TAG];
		}
    }
    
    return schedule;
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
	
	FilmDetailController *filmDetail = [[FilmDetailController alloc] initWithTitle:@"Detail" andId:schedule.itemID];
	[[self navigationController] pushViewController:filmDetail animated:YES];
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

- (IBAction) loadData:(id)sender
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
	cinequestCalendar = delegate.cinequestCalendar;
    eventStore = delegate.eventStore;
	
	curSchedules = delegate.festival.schedules;
 	curFilms = delegate.festival.films;
   
	// Initialize data
	data = [[NSMutableDictionary alloc] init];
	days = [[NSMutableArray alloc] init];
	index = [[NSMutableArray alloc] init];
	
	// Inialize titles and sorts
	titlesWithSort = [[NSMutableDictionary alloc] init];
	sorts = [[NSMutableArray alloc] init];
	
	titleFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	venueFont = timeFont;
	
	switcher = VIEW_BY_DATE;
	
	self.filmsTableView.tableHeaderView = filmSearchBar;
	self.filmsTableView.tableFooterView = nil;
    
    [switchTitle setTitle:@"Date" forSegmentAtIndex:0];
    [switchTitle setTitle:@"A-Z" forSegmentAtIndex:1];
 
	[self loadData:nil];
}

- (void) test
{
 	curFilms = delegate.festival.films;
 	curSchedules = delegate.festival.schedules;
	
	[activity startAnimating];

	if(NO)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", @"Ginger"];
		NSMutableArray *foundFilms = [NSMutableArray arrayWithArray:[curFilms filteredArrayUsingPredicate:predicate]];
		
		NSMutableArray *filmsToRemove = [NSMutableArray arrayWithArray:curFilms];
		[filmsToRemove removeObjectsInArray:foundFilms];
		
		for(Film *film in filmsToRemove)
		{
			[curSchedules removeObjectsInArray:film.schedules];
		}
		
		curFilms = foundFilms;
	}
	
	// Start parsing data
	[data removeAllObjects];
	[days removeAllObjects];
	[index removeAllObjects];
	[titlesWithSort removeAllObjects];
	[sorts removeAllObjects];
	
	[self prepareData];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self.filmsTableView reloadData];
}

#pragma mark - Private Methods

- (void) prepareData
{
	// FILMS BY DATE
    [curSchedules sortUsingDescriptors:[NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES], nil]];
    NSString *previousDay = @"empty";
	NSMutableArray *tempArray = [NSMutableArray array];
    
    [delegate populateCalendarEntries];
    
	for (Schedule *schedule in curSchedules)
	{
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
    [curFilms sortUsingDescriptors:[NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES],nil]];
	NSString *pre = @"empty";
	NSMutableArray *temp = [[NSMutableArray alloc] init];
	
	for (Film *film in curFilms)
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
			
			UILabel *titleLabel = nil;
			UILabel *timeLabel = nil;
			UILabel *venueLabel = nil;
			UIButton *calendarButton = nil;
			
			UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
			
			cell = [tableView dequeueReusableCellWithIdentifier:kDateCellIdentifier];
			if(cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDateCellIdentifier];
				
				UILabel *titleLabel = [UILabel new];
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
				[calendarButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				calendarButton.tag = CELL_LEFTBUTTON_TAG;
				[cell.contentView addSubview:calendarButton];
			}
			
			NSInteger titleNumLines = 1;
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
			[timeLabel setFrame:CGRectMake(52.0, titleNumLines == 1 ? 28.0 : 50.0, 250.0, 20.0)];
			timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", schedule.dateString, schedule.startTime, schedule.endTime];
			
			venueLabel = (UILabel*)[cell viewWithTag:CELL_VENUE_LABEL_TAG];
			[venueLabel setFrame:CGRectMake(52.0, titleNumLines == 1 ? 46.0 : 68.0, 250.0, 20.0)];
			venueLabel.text = [NSString stringWithFormat:@"Venue: %@",schedule.venue];
			
			calendarButton = (UIButton*)[cell viewWithTag:CELL_LEFTBUTTON_TAG];
			[calendarButton setFrame:CGRectMake(11.0, titleNumLines == 1 ? 16.0 : 28.0, 32.0, 32.0)];
			[calendarButton setImage:buttonImage forState:UIControlStateNormal];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];

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
			
			CGFloat hPos = titleNumLines == 1 ? 28.0 : 50.0;
			for(Schedule *schedule in schedules)
			{
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
				UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];;
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
			[self showFilmDetails:schedule];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];
			NSMutableArray *films = [titlesWithSort objectForKey:sort];
			Film *film = [films objectAtIndex:row];
			Schedule *schedule = [film.schedules objectAtIndex:0];
            [self showFilmDetails:schedule];
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

#pragma mark Content Filtering

-(void) filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
#pragma warning "CHECK correct usage of films and schedules arrays"
	curFilms = [NSMutableArray arrayWithArray:delegate.festival.films];
	curSchedules = [NSMutableArray arrayWithArray:delegate.festival.schedules];
	
	if(searchText.length != 0)
	{
		NSMutableArray *foundFilms = [NSMutableArray array];
		if(searchText.length != 0)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", searchText];
			foundFilms = [NSMutableArray arrayWithArray:[curFilms filteredArrayUsingPredicate:predicate]];
		}
		
		NSMutableArray *filmsToRemove = [NSMutableArray arrayWithArray:curFilms];
		
		[filmsToRemove removeObjectsInArray:foundFilms];
				
		for(Film *film in filmsToRemove)
		{
			[curSchedules removeObjectsInArray:film.schedules];
		}
		
		curFilms = foundFilms;
	}
	
	[data removeAllObjects];
	[days removeAllObjects];
	[index removeAllObjects];
	[titlesWithSort removeAllObjects];
	[sorts removeAllObjects];
	
	[self prepareData];
}

#pragma mark - UISearchDisplayController Delegate Methods

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	
	// Tells the table data source to reload when text changes
	
    [self filterContentForSearchText:searchString scope:
	 
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
	
	// Return YES to cause the search result table view to be reloaded.
	
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	
	// Tells the table data source to reload when scope bar selection changes
	
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
	 
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
	
	// Return YES to cause the search result table view to be reloaded.
	
    return YES;
}

@end



