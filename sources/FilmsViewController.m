//
//  FilmsViewController.m
//  CineQuest
//
//  Created by Luca Severini on 10/9/09.
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
    
    // Call to Appdelegate to Add/Remove from Calendar
    [delegate addToDeviceCalendar:schedule];
    [delegate addOrRemoveFilm:schedule];
    [self syncTableDataWithScheduler];
    
    NSLog(@"Schedule:ItemID-ID:%@-%@\nSchedule Array:%@", schedule.itemID, schedule.ID, mySchedule);
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
		if(switcher == VIEW_BY_DATE) // VIEW_BY_DATE
		{
			NSString *day = [appDelegate.festival.sortedKeysInDateToFilmsDictionary  objectAtIndex:section];
			Film *film = [[appDelegate.festival.dateToFilmsDictionary objectForKey:day] objectAtIndex:row];
			schedule = [film.schedules firstObject];
		}
		else // VIEW_BY_TITLE
		{
			NSString *sort = [appDelegate.festival.sortedKeysInAlphabetToFilmsDictionary objectAtIndex:section];
			NSArray *films = [appDelegate.festival.alphabetToFilmsDictionary objectForKey:sort];
			Film *film = [films objectAtIndex:[indexPath row]];
			schedule = (Schedule*)[film.schedules objectAtIndex:[(UIButton*)sender tag] - CELL_LEFTBUTTON_TAG];
		}
    }
    
    return schedule;
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

#pragma mark - UIViewController Methods

- (void) viewDidLoad
{
	self.title = @"Films";
	
    [super viewDidLoad];
	
	delegate = appDelegate;
	mySchedule = [delegate mySchedule];
	cinequestCalendar = delegate.cinequestCalendar;
    eventStore = delegate.eventStore;
	
	curSchedules = delegate.festival.schedules;
 	curFilms = delegate.festival.films;
   	
	titleFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	venueFont = timeFont;
	
	switcher = VIEW_BY_DATE;
	
	self.filmsTableView.tableHeaderView = filmSearchBar;
	self.filmsTableView.tableFooterView = nil;
    
    filmSearchBar.delegate = self;
    
    [self setSearchKeyAsDone];
    
    [switchTitle setTitle:@"Date" forSegmentAtIndex:0];
    [switchTitle setTitle:@"A-Z" forSegmentAtIndex:1];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self syncTableDataWithScheduler];
	
    [self.filmsTableView reloadData];
}

#pragma mark - Private Methods

- (void) syncTableDataWithScheduler
{
    [delegate populateCalendarEntries];
    
	NSInteger sectionCount = [delegate.festival.sortedKeysInDateToFilmsDictionary count];
	NSInteger myScheduleCount = [mySchedule count];
	if(myScheduleCount == 0)
	{
		return;
	}

	// Sync current data
	for (NSUInteger section = 0; section < sectionCount; section++)
	{
		NSString *day = [delegate.festival.sortedKeysInDateToFilmsDictionary objectAtIndex:section];
		NSMutableArray *films =  [delegate.festival.dateToFilmsDictionary objectForKey:day];
		NSInteger filmsCount = [films count];

		for (NSUInteger row = 0; row < filmsCount; row++)
		{
			NSArray *schedules = [[films objectAtIndex:row] schedules];
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

#pragma mark - Table View Datasource methods

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
	switch(switcher)
	{
		case VIEW_BY_DATE:
			return [delegate.festival.sortedKeysInDateToFilmsDictionary count];
			break;
			
		case VIEW_BY_TITLE:
			return [delegate.festival.sortedKeysInAlphabetToFilmsDictionary count];
			break;
			
		default:
			return 0;
			break;
	}
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(switcher)
	{
		case VIEW_BY_DATE:
		{
            NSString *day = [delegate.festival.sortedKeysInDateToFilmsDictionary objectAtIndex:section];
			return [[delegate.festival.dateToFilmsDictionary objectForKey:day] count];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [delegate.festival.sortedKeysInAlphabetToFilmsDictionary objectAtIndex:section];
			return [[delegate.festival.alphabetToFilmsDictionary objectForKey:sort] count];
		}
			break;

		default:
			return 0;
			break;
	}
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
			NSString *day = [delegate.festival.sortedKeysInDateToFilmsDictionary  objectAtIndex:section];
			Film *film = [[delegate.festival.dateToFilmsDictionary objectForKey:day] objectAtIndex:row];
			Schedule *schedule = [film.schedules firstObject];
			
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
			CGSize size = [film.name sizeWithFont:titleFont];
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
			titleLabel.text = film.name;
			
			timeLabel = (UILabel*)[cell viewWithTag:CELL_TIME_LABEL_TAG];
			[timeLabel setFrame:CGRectMake(52.0, titleNumLines == 1 ? 28.0 : 50.0, 250.0, 20.0)];
			timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", schedule.dateString, schedule.startTime, schedule.endTime];
			
			venueLabel = (UILabel*)[cell viewWithTag:CELL_VENUE_LABEL_TAG];
			[venueLabel setFrame:CGRectMake(52.0, titleNumLines == 1 ? 46.0 : 68.0, 250.0, 20.0)];
			venueLabel.text = [NSString stringWithFormat:@"Venue: %@",schedule.venue];
            
			calendarButton = (UIButton*)[cell viewWithTag:CELL_LEFTBUTTON_TAG];
			[calendarButton setFrame:CGRectMake(8.0, titleNumLines == 1 ? 8.0 : 24.0, 44.0, 44.0)];
			[calendarButton setImage:buttonImage forState:UIControlStateNormal];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [delegate.festival.sortedKeysInAlphabetToFilmsDictionary objectAtIndex:section];
			NSArray *films = [delegate.festival.alphabetToFilmsDictionary objectForKey:sort];
			Film *film = [films objectAtIndex:[indexPath row]];
			NSArray *schedules = film.schedules;
			
			NSInteger filmIdx = 0;

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
				calButton.frame = CGRectMake(11.0, hPos, 40.0, 40.0);
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
			result = [delegate.festival.sortedKeysInDateToFilmsDictionary objectAtIndex:section];
			break;
			
		case VIEW_BY_TITLE:
			result = [delegate.festival.sortedKeysInAlphabetToFilmsDictionary objectAtIndex:section];
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
			result = delegate.festival.sortedIndexesInDateToFilmsDictionary;
			break;
			
		case VIEW_BY_TITLE:
			result = delegate.festival.sortedKeysInAlphabetToFilmsDictionary;
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
			NSString *day = [delegate.festival.sortedKeysInDateToFilmsDictionary  objectAtIndex:section];
			Film *film = [[delegate.festival.dateToFilmsDictionary objectForKey:day] objectAtIndex:row];
			Schedule *schedule = [film.schedules firstObject];
			
			[self showFilmDetails:schedule];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [delegate.festival.sortedKeysInAlphabetToFilmsDictionary objectAtIndex:section];
			NSArray *films = [delegate.festival.alphabetToFilmsDictionary objectForKey:sort];
			Film *film = [films objectAtIndex:[indexPath row]];
			
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
		NSString *day = [delegate.festival.sortedKeysInDateToFilmsDictionary  objectAtIndex:section];
		Film *film = [[delegate.festival.dateToFilmsDictionary objectForKey:day] objectAtIndex:row];
		
		CGSize size = [film.name sizeWithFont:titleFont];
		if(size.width >= 256.0)
		{
			return 90.0;
		}
		else
		{
			return 68.0;
		}
	}
	else // VIEW_BY_TITLE
	{
		NSString *sort = [delegate.festival.sortedKeysInAlphabetToFilmsDictionary objectAtIndex:section];
		NSArray *films = [delegate.festival.alphabetToFilmsDictionary objectForKey:sort];
		Film *film = [films objectAtIndex:[indexPath row]];

		CGSize size = [film.name sizeWithFont:titleFont];
		if(size.width >= 256.0)
		{
			return 52.0 + (38 * film.schedules.count);
		}
		else
		{
			return 30.0 + (38 * film.schedules.count);
		}
	}
}

#pragma mark Content Filtering

-(void) filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSLog(@"Searching:%d",isSearching);
    NSMutableDictionary *dictSortKeyForSearch = [delegate.festival.sortedKeysInDateToFilmsDictionary mutableCopy];
    NSMutableDictionary *dictDateToFilm = [delegate.festival.dateToFilmsDictionary mutableCopy];
    
    
//    Film *film = [[delegate.festival.dateToFilmsDictionary objectForKey:day] objectAtIndex:row];
//    Schedule *schedule = [film.schedules firstObject];
    
#pragma warning "CHECK correct usage of films and schedules arrays"
	curFilms = [NSMutableArray arrayWithArray:delegate.festival.films];
	curSchedules = [NSMutableArray arrayWithArray:delegate.festival.schedules];
	
	if(searchText.length != 0)
	{
		NSMutableArray *foundFilms = [NSMutableArray array];
		if(searchText.length != 0)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name beginswith[c] %@", searchText];
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
}

#pragma mark - UISearchDisplayController Delegate Methods

-(BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	    NSLog(@"shouldReloadTableForSearchString Searching:%d",isSearching);
	// Tells the table data source to reload when text changes
	
    [self filterContentForSearchText:searchString scope:
	 
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
	
	// Return YES to cause the search result table view to be reloaded.
	
    return YES;
}

-(BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	    NSLog(@"shouldReloadTableForSearchScope Searching:%d",isSearching);
	// Tells the table data source to reload when scope bar selection changes
	
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
	 
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
	
	// Return YES to cause the search result table view to be reloaded.
	
    return YES;
}

- (void) setSearchKeyAsDone
{
    for (UIView *subview in self.filmSearchBar.subviews)
    {
        for (UIView *subSubview in subview.subviews)
        {
            if ([subSubview conformsToProtocol:@protocol(UITextInputTraits)])
            {
                UITextField *textField = (UITextField *)subSubview;
                [textField setKeyboardAppearance: UIKeyboardAppearanceAlert];
                textField.returnKeyType = UIReturnKeyDone;
                break;
            }
        }
    }
    
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    isSearching = NO;
    curFilms = [NSMutableArray arrayWithArray:delegate.festival.films];
	curSchedules = [NSMutableArray arrayWithArray:delegate.festival.schedules];
    NSLog(@"Searching:%d",isSearching);
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    isSearching = NO;
    [searchBar resignFirstResponder];
    [self.view endEditing:YES];
    [self.searchDisplayController setActive:NO animated:YES];
    NSLog(@"Searching:%d",isSearching);
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    isSearching = YES;
    NSLog(@"Searching:%d",isSearching);
    return YES;
}

@end



