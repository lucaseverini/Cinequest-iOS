//
//  FilmsViewController.m
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FilmsViewController.h"
#import "NewsViewController.h"
#import "FilmDetail.h"
#import "CinequestAppDelegate.h"
#import "Schedule.h"
#import "DDXML.h"
#import "DataProvider.h"
#import "Schedule.h"
#import "Festival.h"
#import "Film.h"

#define VIEW_BY_DATE	0
#define VIEW_BY_TITLE	1

static NSString *const kDateCellIdentifier = @"DateCell";
static NSString *const kTitleCellIdentifier = @"TitleCell";


@implementation FilmsViewController

@synthesize switchTitle;
@synthesize filmsTableView;
@synthesize loadingLabel;
@synthesize activity;

#pragma mark - UIViewController Methods

- (void) viewDidLoad
{
	self.title = @"Films";
	
    [super viewDidLoad];
	
	delegate = appDelegate;
	mySchedule = delegate.mySchedule;
	
	// Initialize data
	data = [[NSMutableDictionary alloc] init];
	days = [[NSMutableArray alloc] init];
	index = [[NSMutableArray alloc] init];
	
	backedUpDays = [[NSMutableArray alloc] init];
	backedUpIndex = [[NSMutableArray alloc] init];
	backedUpData = [[NSMutableDictionary alloc] init];
	
	// Inialize titles and sorts
	titlesWithSort = [[NSMutableDictionary alloc] init];
	sorts = [[NSMutableArray alloc] init];
	
	if (delegate.isOffSeason)
	{
		[activity stopAnimating];
		
		loadingLabel.hidden = YES;
		self.navigationItem.titleView = nil;
		self.filmsTableView.hidden = YES;
		return;
	}
	
	switcher = VIEW_BY_DATE;
	// Load data
	[self reloadData:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    NSIndexPath *tableSelection = [self.filmsTableView indexPathForSelectedRow];
    [self.filmsTableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	[self syncTableDataWithScheduler];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (IBAction) switchTitle:(id)sender
{
	switcher = [sender selectedSegmentIndex];
	[self.filmsTableView reloadData];
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
			NSLog(@"%@ : %@ %@ added to my schedule", film.title, film.dateString, film.startTime);
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
				
				NSLog(@"%@ : %@ %@ removed from my schedule", film.title, film.dateString, film.startTime);
				break;
			}
		}
	}
	
	[self syncTableDataWithScheduler];
}

#pragma message "Do We really need this method?"
- (IBAction) reloadData:(id)sender
{
	// Hide everything, display activity indicator
	self.filmsTableView.hidden = YES;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	switchTitle.hidden = YES;
	
	[activity startAnimating];
	
	// Start parsing data
	[data removeAllObjects];
	[days removeAllObjects];
	[index removeAllObjects];
	[titlesWithSort removeAllObjects];
	[sorts removeAllObjects];
	
	[NSThread detachNewThreadSelector:@selector(prepareData) toTarget:self withObject:nil];
}

#pragma mark - Private Methods

- (void) prepareData
{
	// FILMS BY TIME
    [delegate.festival.schedules sortUsingDescriptors:[NSArray arrayWithObjects:
                                                       [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES],nil]];
    NSString *previousDay = @"empty";
	NSMutableArray *films = [NSMutableArray arrayWithCapacity:1000]; // fimls
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
    
    [delegate.festival.films sortUsingDescriptors:[NSArray arrayWithObjects:
                                                       [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES],nil]];
	NSString *pre = @"empty";
	NSMutableArray *temp = [[NSMutableArray alloc] init];
	
	for (Film *film in delegate.festival.films)
	{
		//NSArray *schedule = [self getSchedulesFromListByTime:films withProgId:[ID integerValue]];
		//if(schedule.count == 0)
		//{
		//	NSLog(@"***** Schedule %@ in ListByTitle is not present in ListByTime *****", ID);
		//	continue;
		//}
		
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
    
    // Display everything, hide activity indicator
	switchTitle.hidden = NO;
	loadingLabel.hidden = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	
	[activity stopAnimating];
	
	self.filmsTableView.hidden = NO;
	[self.filmsTableView reloadData];
	
	// back up current data
	//backedUpDays	= [[NSMutableArray alloc] initWithArray:days copyItems:YES];
	//backedUpIndex	= [[NSMutableArray alloc] initWithArray:index copyItems:YES];
	//backedUpData	= [[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES];
	
	[self syncTableDataWithScheduler];
	
	// Disable "Reload" button
	self.filmsTableView.tableHeaderView = nil;
    
}

- (NSArray *) getSchedulesFromListByTime:(NSArray*)films withProgId:(NSString*)progId
{
	NSMutableArray *schedules = [NSMutableArray array];
	
	for(Schedule *schedule in films)
	{
		if([schedule.itemID isEqualToString: progId])
		{
			[schedules addObject:schedule];
		}
	}
	
	return schedules;
}

- (void) syncTableDataWithScheduler
{
	NSUInteger count = [mySchedule count];
	NSLog(@"Scheduler count: %d",count);
	
	// Sync current data
	for (NSUInteger section = 0; section < [days count]; section++)
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];
        
		for (int row = 0; row < [rows count]; row++)
		{
			Schedule *film = [rows objectAtIndex:row];
			// film.isSelected = NO;
			for (NSUInteger idx = 0; idx < count; idx++)
			{
				Schedule *obj = [mySchedule objectAtIndex:idx];
				if (obj.ID == film.ID)
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
				if (obj.ID == film.ID)
				{
					//NSLog(@"BackedUp Data ... Already Added: %@.",obj.title);
					film.isSelected = YES;
				}
			}
		}
	}
}

- (void) removeDeletedObjects
{
	NSUInteger i, count = [mySchedule count];
	//NSLog(@"Scheduler count: %d",count);
	// Sync current data
    for (int section = 0; section < [days count]; section++)
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];
		for (int row = 0; row < [rows count]; row++)
		{
			Schedule *film = [rows objectAtIndex:row];
			//film.isSelected = NO;
			for(i = 0; i < count; i++)
			{
				Schedule *obj = [mySchedule objectAtIndex:i];
				if((obj.ID == film.ID) && [obj.title isEqualToString:film.title] && [obj.startDate compare:film.startDate] == NSOrderedSame)
				{
					//NSLog(@"Current Data ... Already Added: %@. Time: %@",obj.title,obj.startTime);
					film.isSelected = YES;
				}
				else
				{
					[rows removeObjectAtIndex:row];
				}
			}
		}
	}
}

- (void) checkBoxButtonTapped:(id)sender event:(id)touchEvent
{
	NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.filmsTableView];
	NSIndexPath *indexPath = [self.filmsTableView indexPathForRowAtPoint:currentTouchPosition];
	int row = [indexPath row];
	int section = [indexPath section];
	
	if(indexPath != nil)
	{
		Schedule *film = nil;
		
		if(switcher == VIEW_BY_DATE)
		{
			NSString *longDateString = [days objectAtIndex:section];
			film = [[data objectForKey:longDateString] objectAtIndex:row];
		}
		else
		{
			NSString *sort = [sorts objectAtIndex:section];
			NSArray *schedules = [[titlesWithSort objectForKey:sort] objectAtIndex:row];
			NSInteger filmIdx = [sender tag] - CELL_BUTTON_TAG;
			film = [schedules objectAtIndex:filmIdx];
		}
		
		// Set checkBox's status
		film.isSelected ^= YES;
		[self addOrRemoveFilm:film];
		
		UIButton *checkBoxButton = (UIButton*)sender;
		UIImage *buttonImage = (film.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
		[checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
	}
}

#pragma mark - Table View Datasource methods

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
	int count = 0;
	
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
	int count;
	
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
	CGRect rowRect = [tableView rectForRowAtIndexPath:indexPath];
	UITableViewCell *cell = nil;
	
	CGFloat labelFontSize = [UIFont labelFontSize];
	CGFloat fontSize = [UIFont systemFontSize];
	CGFloat smallFontSize = [UIFont smallSystemFontSize];
    
	switch(switcher)
	{
		case VIEW_BY_DATE:
		{
			// get film objects using date
			NSString *dateString = [days objectAtIndex:section];
			Schedule *film = [[data objectForKey:dateString] objectAtIndex:row];
			
			UIColor *textColor = [UIColor blackColor];
			NSString *displayString = [NSString stringWithFormat:@"%@", film.title];
			
			// check if current cell is already added to mySchedule
			NSUInteger idx, count = [mySchedule count];
			for(idx = 0; idx < count; idx++)
			{
				Schedule *obj = [mySchedule objectAtIndex:idx];
				if([obj.ID isEqualToString:film.ID])//&& [obj.title isEqualToString:film.title] && [obj.date compare:film.date] == NSOrderedSame
				{
					//NSLog(@"%@ was added.",obj.title);
					// textColor = [UIColor blueColor];
					film.isSelected = YES;
					break;
				}
			}
			
			// get reusable cell
			UITableViewCell *tempCell = [tableView dequeueReusableCellWithIdentifier:kDateCellIdentifier];
			UILabel *titleLabel;
			UILabel *timeLabel;
			UILabel *venueLabel;
			UIButton *checkButton;
			
			// Get checkbox status
			UIImage *buttonImage = (film.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
			
			if(tempCell == nil)
			{
				tempCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDateCellIdentifier];
				
				UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 2.0, 290.0, 20.0)];
				titleLabel.tag = CELL_TITLE_LABEL_TAG;
				titleLabel.font = [UIFont boldSystemFontOfSize:labelFontSize];
				titleLabel.textColor = textColor;
				[tempCell.contentView addSubview:titleLabel];
				
				timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 22.0, 250.0, 20.0)];
				timeLabel.tag = CELL_TIME_LABEL_TAG;
				timeLabel.font = [UIFont systemFontOfSize:fontSize];
				timeLabel.textColor = textColor;
				[tempCell.contentView addSubview:timeLabel];
				
				venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 40.0, 250.0, 20.0)];
				venueLabel.tag = CELL_VENUE_LABEL_TAG;
				venueLabel.font = [UIFont systemFontOfSize:fontSize];
				venueLabel.textColor = textColor;
				[tempCell.contentView addSubview:venueLabel];
				
				checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
				checkButton.frame = CGRectMake(4.0, 16.0, 48.0, 48.0);
				[checkButton addTarget:self action:@selector(checkBoxButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				checkButton.backgroundColor = [UIColor clearColor];
				checkButton.tag = CELL_BUTTON_TAG;
				[tempCell.contentView addSubview:checkButton];
			}
			
			titleLabel = (UILabel*)[tempCell viewWithTag:CELL_TITLE_LABEL_TAG];
			titleLabel.text = displayString;
			
			timeLabel = (UILabel*)[tempCell viewWithTag:CELL_TIME_LABEL_TAG];
			timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", film.dateString, film.startTime, film.endTime];
			
			venueLabel = (UILabel*)[tempCell viewWithTag:CELL_VENUE_LABEL_TAG];
			venueLabel.text = [NSString stringWithFormat:@"Venue: %@",film.venue];
			
			checkButton = (UIButton*)[tempCell viewWithTag:CELL_BUTTON_TAG];
			[checkButton setImage:buttonImage forState:UIControlStateNormal];
			
			cell = tempCell;
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];
			NSArray *schedules = [[titlesWithSort objectForKey:sort] objectAtIndex:row];
			NSInteger filmIdx = 0;
			Schedule *film = [schedules objectAtIndex:filmIdx];
			
			UIColor *textColor = [UIColor blackColor];
			NSString *displayString = [NSString stringWithFormat:@"%@", film.title];
			
			UITableViewCell *tempCell = [tableView dequeueReusableCellWithIdentifier:kTitleCellIdentifier];
			if(tempCell == nil)
			{
				tempCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTitleCellIdentifier];
			}
			else
			{
				[[tempCell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
			}
			
			UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 2.0, 290.0, 20.0)];
			titleLabel.tag = CELL_TITLE_LABEL_TAG;
			titleLabel.text = displayString;
			titleLabel.textColor = textColor;
			titleLabel.font = [UIFont boldSystemFontOfSize:labelFontSize];
			[tempCell.contentView addSubview:titleLabel];
			
			CGFloat hPos = 22.0;
			for(Schedule *schedule in schedules)
			{
				if(filmIdx > 0)
				{
					film = [schedules objectAtIndex:filmIdx];
				}
				
				UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, hPos, 250.0, 20.0)];
				timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", schedule.dateString, schedule.startTime, schedule.endTime];
				timeLabel.font = [UIFont systemFontOfSize:fontSize];
				timeLabel.textColor = textColor;
				timeLabel.tag = CELL_TIME_LABEL_TAG;
				[tempCell.contentView addSubview:timeLabel];
				
				UILabel *venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, hPos + 18.0, 250.0, 20.0)];
				venueLabel.text = [NSString stringWithFormat:@"Venue: %@", schedule.venue];
				venueLabel.font = [UIFont systemFontOfSize:fontSize];
				venueLabel.textColor = textColor;
				venueLabel.tag = CELL_VENUE_LABEL_TAG;
				[tempCell.contentView addSubview:venueLabel];
				
				UIButton *checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
				checkButton.frame = CGRectMake(4.0, hPos - 6.0, 48.0, 48.0);
				checkButton.backgroundColor = [UIColor clearColor];
				checkButton.tag = CELL_BUTTON_TAG + filmIdx;
				UIImage *buttonImage = (film.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
				[checkButton setImage:buttonImage forState:UIControlStateNormal];
				[checkButton addTarget:self action:@selector(checkBoxButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				[tempCell.contentView addSubview:checkButton];
				
				hPos += 38.0;
				filmIdx++;
			}
			
			cell = tempCell;
		}
			break;
			
		default:
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
	int section = [indexPath section];
	int row = [indexPath row];
	
	switch (switcher)
	{
		case VIEW_BY_DATE:
		{
			NSString *date = [days objectAtIndex:section];
			NSMutableArray *films = [data objectForKey:date];
			Schedule *film = [films objectAtIndex:row];
			FilmDetail *filmDetail = [[FilmDetail alloc] initWithTitle:@"Film Detail" andDataObject:film andId:film.itemID];
			
			[[self navigationController] pushViewController:filmDetail animated:YES];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];
			NSMutableArray *films = [titlesWithSort objectForKey:sort];
			Schedule *film = [[films objectAtIndex:row] objectAtIndex:0];
			FilmDetail *filmDetail = [[FilmDetail alloc] initWithTitle:@"Film Detail" andDataObject:film  andId:film.itemID];
			
			[[self navigationController] pushViewController:filmDetail animated:YES];
		}
			break;
			
		default:
			break;
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(switcher == VIEW_BY_DATE)
	{
		return 62.0;
	}
	else
	{
		NSString *sort = [sorts objectAtIndex:[indexPath section]];
		NSArray *schedules = [[titlesWithSort objectForKey:sort] objectAtIndex:[indexPath row]];
		
		return 24.0 + (38 * schedules.count);
	}
}

@end



