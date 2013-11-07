//
//  FilmsViewController.m
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FilmsViewController.h"
#import "LoadDataViewController.h"
#import "NewsViewController.h"
#import "FilmDetail.h"
#import "Festival.h"
#import "Reachability.h"

#import "CinequestAppDelegate.h"
#import "Schedule.h"
#import "DDXML.h"

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

#define VIEW_BY_DATE	0
#define VIEW_BY_TITLE	1

#define REFINE			0
#define BACK			1

#define kAccelerationThreadhold 2.2
#define kUpdateInterval			(1.0f/10.0f)

@interface FilmsViewController (Private)

- (void)loadDataFromDatabase;
- (void)loadFilmByTitle;
- (void)syncTableDataWithScheduler;
- (void)removeDeletedObjects;

@end
@implementation FilmsViewController
#pragma mark -
#pragma mark Memory Management
@synthesize switchTitle;
@synthesize tableView = _tableView;
@synthesize loadingLabel;
@synthesize activity;
@synthesize SJSUIcon;
@synthesize CQIcon;
@synthesize offSeasonLabel;

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark -
#pragma mark Actions
- (IBAction)switchTitle:(id)sender {
	switcher = [sender selectedSegmentIndex];
	switch (switcher) {
		case VIEW_BY_DATE: {
			if (self.navigationItem.rightBarButtonItem == nil) {
				// Create add button 
				self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
																						   style:UIBarButtonItemStyleDone
																						  target:self
																						  action:@selector(addFilms:)];
			}
			
			if(refineOrBack == BACK)
			{
				self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
																						  style:UIBarButtonItemStyleDone
																						 target:self
																						 action:@selector(back:)];
			}
			else if(refineOrBack == REFINE)
			{
				self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refine"
																						  style:UIBarButtonItemStylePlain
																						 target:self
																						 action:@selector(refine:)];
			}

			
		}
			break;
		case VIEW_BY_TITLE:
			if (self.navigationItem.leftBarButtonItem.style == UIBarButtonItemStylePlain) {
				refineOrBack = REFINE;
			}
			else if(self.navigationItem.leftBarButtonItem.style == UIBarButtonItemStyleDone){
				refineOrBack = BACK;
			}
			self.navigationItem.leftBarButtonItem = nil;
			self.navigationItem.rightBarButtonItem = nil;
			break;

		default:
			break;
	}
	[self.tableView reloadData];
}
- (IBAction)reloadData:(id)sender {
	if (switcher == VIEW_BY_DATE) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
																				   style:UIBarButtonItemStyleDone
																				  target:self
																				  action:@selector(addFilms:)];
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refine"
																				  style:UIBarButtonItemStylePlain
																				 target:self
																				 action:@selector(refine:)];
	} else {
		if (self.navigationItem.leftBarButtonItem.style == UIBarButtonItemStylePlain) {
			refineOrBack = REFINE;
		}
		else if(self.navigationItem.leftBarButtonItem.style == UIBarButtonItemStyleDone){
			refineOrBack = BACK;
		}
		self.navigationItem.rightBarButtonItem = nil;
		self.navigationItem.leftBarButtonItem = nil;
	}

	//Hide everything, display activity indicator
	self.tableView.hidden = YES;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	self.navigationItem.leftBarButtonItem.enabled = NO;
	switchTitle.hidden = YES;
	
	[activity startAnimating];
	
	SJSUIcon.alpha = 1.0;
	CQIcon.alpha = 1.0;
	loadingLabel.hidden = NO;
	
	//Start parsing data
	@autoreleasepool {
		[data removeAllObjects];
		[days removeAllObjects];
		[index removeAllObjects];
		[TitlesWithSort removeAllObjects];
		[sorts removeAllObjects];
		[NSThread detachNewThreadSelector:@selector(startParsingXML) toTarget:self withObject:nil];
	}
}
- (void)addFilms:(id)sender {
	int counter = 0;
	for (int section = 0; section < [days count]; section++) 
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];
		for (int row = 0; row < [rows count];row++ ) {
			Schedule *item = [rows objectAtIndex:row];
			if (item.isSelected) 
			{
				//NSLog(@"%@",item.title);
				Schedule *schedule = item;
				
				BOOL isAlreadyAdded = NO;
				for (int i=0; i < [mySchedule count]; i++) {
					Schedule *obj = [mySchedule objectAtIndex:i];
					if (obj.ID	== schedule.ID) {
						isAlreadyAdded = YES;
						//NSLog(@"%@ ID: %d",schedule.title,schedule.ID);
						break;
					}
				}
				if (!isAlreadyAdded) 
				{
					//NSLog(@"Adding: %@ ID:%d SchedulerCount: %d",schedule.title, schedule.ID,[mySchedule count]);
					[mySchedule addObject:schedule];
					counter++;
				}
			}
		}
	}
	[self syncTableDataWithScheduler];
	[self.tableView reloadData];
	
	if (counter != 0) {
		//jump to Scheduler after add
		[delegate jumpToScheduler];
	}
	
}
- (void)refine:(id)sender {	
	// Back button
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
																			 style:UIBarButtonItemStyleDone
																			target:self
																			action:@selector(back:)];
	
	
	
	// Remove rows
	NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
	NSMutableArray *itemsBeingDeleted = [[NSMutableArray alloc] init];
								   
	for (int section = 0; section < [days count]; section++)
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];
				
		for (int row = 0; row < [rows count]; row++) 
		{
			Schedule *item = [rows objectAtIndex:row];
			if (!item.isSelected) 
			{
				[indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
				[itemsBeingDeleted addObject:item];
			}
			else {
				//NSLog(@"%@ - %@",item.time,item.title);
			}

		}
		[rows removeObjectsInArray:itemsBeingDeleted];
		[itemsBeingDeleted removeAllObjects];
	}
	
	// Remove sections
	NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];

	int i = 0;
	for (NSString *day in days) 
	{
		NSMutableArray *rows = [data objectForKey:day];
		if ([rows count] == EMPTY) 
		{
			[data removeObjectForKey:day];
			[indexSet addIndex:i];
		}
		i++;
	}
	[days removeObjectsAtIndexes:indexSet];
	[index removeObjectsAtIndexes:indexSet];
	
	// Start updating table
	[self.tableView beginUpdates];
	
	[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:NO];
	
	[self.tableView deleteSections:indexSet withRowAnimation:NO];
	
	[self.tableView endUpdates];
	
	// add push animation
	CATransition *transition = [CATransition animation];
	transition.type = kCATransitionPush;
	transition.subtype = kCATransitionFromTop;
	transition.duration = 0.3;
	[[self.tableView layer] addAnimation:transition forKey:nil];
	
	// reload data
	[self.tableView reloadData];

}
- (void)back:(id)sender {
	// Refine button
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refine"
																			  style:UIBarButtonItemStylePlain
																			 target:self
																			 action:@selector(refine:)];
	
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
	[[self.tableView layer] addAnimation:transition forKey:nil];
	  
	// reload table data
	[self.tableView reloadData];

}

#pragma mark -
#pragma mark UIViewController Methods
- (void)viewDidLoad {
	self.title = @"Films";
	
    [super viewDidLoad];
	/*
	//Configure and start accelerometer
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:kUpdateInterval];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	*/
	delegate = appDelegate;
	mySchedule = delegate.mySchedule;
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:delegate.newsView];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
	delegate.isPresentingModalView = YES;
	
	// Initialize data
	data	= [[NSMutableDictionary alloc] init];
	days	= [[NSMutableArray alloc] init];
	index	= [[NSMutableArray alloc] init];
	
	backedUpDays	= [[NSMutableArray alloc] init];
	backedUpIndex	= [[NSMutableArray alloc] init];
	backedUpData	= [[NSMutableDictionary alloc] init];
	
	// Inialize titles and sorts
	TitlesWithSort	= [[NSMutableDictionary alloc] init];
	sorts			= [[NSMutableArray alloc] init];
	
	if (delegate.isOffSeason)
	{
		[activity stopAnimating];
		
		loadingLabel.hidden = YES;
		offSeasonLabel.hidden = NO;
		self.navigationItem.titleView = nil;
		self.tableView.hidden = YES;
		return;
	}
	
	switcher = VIEW_BY_DATE;
	// Load data
	[self reloadData:nil];
}
- (void)viewWillAppear:(BOOL)animated {
	//NSLog(@"films will appear.");
	app.networkActivityIndicatorVisible = NO;
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	[self syncTableDataWithScheduler];
	
	Festival *festival = [appDelegate festival];
	NSLog(@"%@", festival);
}

#pragma mark -
#pragma mark Private Methods
- (void)startParsingXML {
	@autoreleasepool {
	// FILMS BY TIME
		NSURL *link = [NSURL URLWithString:FILMSBYTIME];
		NSData *htmldata = [NSData dataWithContentsOfURL:link];
		DDXMLDocument *filmsXMLDoc = [[DDXMLDocument alloc] initWithData:htmldata options:0 error:nil];
		DDXMLNode *rootElement = [filmsXMLDoc rootElement];
		NSString *previousDay = @"empty";
		NSMutableArray *tempArray = [[NSMutableArray alloc] init];
		for (int i = 0; i < [rootElement childCount]; i++) {
			DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
			NSDictionary *attributes = [child attributesAsDictionary];
			
			NSString *ID		= [attributes objectForKey:@"id"];
			NSString *prg_id	= [attributes objectForKey:@"program_item_id"];
			NSString *type		= [attributes objectForKey:@"type"];
			NSString *title		= [attributes objectForKey:@"title"];
			NSString *start		= [attributes objectForKey:@"start_time"];
			NSString *end		= [attributes objectForKey:@"end_time"];
			NSString *venue		= [attributes objectForKey:@"venue"];
			
			Schedule *film	= [[Schedule alloc] init];
			
			film.ID			= [ID intValue];
			film.type		= type;
			film.prog_id	= [prg_id intValue];
			film.title		= title;
			film.venue		= venue;
			
			//Start Time
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			NSDate *date = [dateFormatter dateFromString:start];
			film.date = date;
			[dateFormatter setDateFormat:@"hh:mm a"];
			film.timeString = [dateFormatter stringFromDate:date];
			//Date
			[dateFormatter setDateFormat:@"EEEE, MMMM d"];
			NSString *dateString = [dateFormatter stringFromDate:date];
			film.dateString = dateString;
			//End Time
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			date = [dateFormatter dateFromString:end];
			film.endDate = date;
			[dateFormatter setDateFormat:@"hh:mm a"];
			film.endTimeString = [dateFormatter stringFromDate:date];
			
			if (![previousDay isEqualToString:dateString]) {
				[data setObject:tempArray forKey:previousDay];
				
				previousDay = [[NSString alloc] initWithString:dateString];
				[days addObject:previousDay];
				
				[index addObject:[[previousDay componentsSeparatedByString:@" "] objectAtIndex: 2]];
				
				tempArray = [[NSMutableArray alloc] init];
				[tempArray addObject:film];
				
			} else {
				[tempArray addObject:film];
			}
		}
		[data setObject:tempArray forKey:previousDay];
		
		// FILMS BY TITLES
		link = [NSURL URLWithString:FILMSBYTITLE];
		htmldata = [NSData dataWithContentsOfURL:link];
		DDXMLDocument *titleXMLDoc = [[DDXMLDocument alloc] initWithData:htmldata options:0 error:nil];
		rootElement = [titleXMLDoc rootElement];
		NSString *pre			= @"empty";
		NSMutableArray *temp	= [[NSMutableArray alloc] init];
		for (int i = 0; i < [rootElement childCount]; i++) {
			DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
			NSDictionary *attributes = [child attributesAsDictionary];
			
			NSString *ID		= [attributes objectForKey:@"id"];
			NSString *sort		= [attributes objectForKey:@"sort"];
			NSString *prog_id	= [attributes objectForKey:@"program_item_id"];
			
			DDXMLNode *titleTag = [child childAtIndex:0];
			
			NSString *title = [titleTag stringValue];
			
			Schedule *film		= [[Schedule alloc] init];
			
			film.ID			= [ID intValue];
			film.title		= title;
			film.prog_id	= [prog_id intValue];
			
			
			NSString *sortString = sort;
			
			if (![pre isEqualToString:sortString]) {
				[TitlesWithSort setObject:temp forKey:pre];
				
				pre = [NSString stringWithString:sortString];
				[sorts addObject:pre];
				
				temp = [[NSMutableArray alloc] init];
				[temp addObject:film];
			} else {
				[temp addObject:film];
			}
		}
		[TitlesWithSort setObject:temp forKey:pre];
		
		//Display everything, hide activity indicator
		switchTitle.hidden = NO;
		loadingLabel.hidden = YES;
		self.navigationItem.rightBarButtonItem.enabled = YES;
		self.navigationItem.leftBarButtonItem.enabled = YES;
		SJSUIcon.alpha = 0.2;
		CQIcon.alpha = 0.2;
		
		[activity stopAnimating];
		
		self.tableView.hidden = NO;
		[self.tableView reloadData];

		// back up current data
		backedUpDays	= [[NSMutableArray alloc] initWithArray:days copyItems:YES];
		backedUpIndex	= [[NSMutableArray alloc] initWithArray:index copyItems:YES];
		backedUpData	= [[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES];
		
		[self syncTableDataWithScheduler];
		
		//Disable "Reload" button
		self.tableView.tableHeaderView = nil;
	//[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
	//				 atScrollPosition:UITableViewScrollPositionTop 
	//						 animated:NO];
	}
}
- (void)syncTableDataWithScheduler {
	
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
			for (i = 0; i < count; i++) 
			{
				Schedule *obj = [mySchedule objectAtIndex:i];
				if (obj.ID == film.ID) 
				{
					//NSLog(@"Current Data ... Already Added: %@. Time: %@",obj.title,obj.timeString);
					film.isSelected = YES;
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
			Schedule *film = [rows objectAtIndex:row];
			//film.isSelected = NO;
			for (i = 0; i < count; i++) 
			{
				Schedule *obj = [mySchedule objectAtIndex:i];
				if (obj.ID == film.ID) 
				{
					//NSLog(@"BackedUp Data ... Already Added: %@.",obj.title);
					film.isSelected = YES;
				}
				

			}
			
		}
	}
}
- (void)removeDeletedObjects {
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
			for (i = 0; i < count; i++) 
			{
				Schedule *obj = [mySchedule objectAtIndex:i];
				if ((obj.ID == film.ID) && [obj.title isEqualToString:film.title] 
					&& [obj.date compare:film.date] == NSOrderedSame) 
				{
					//NSLog(@"Current Data ... Already Added: %@. Time: %@",obj.title,obj.timeString);
					film.isSelected = YES;
				}
				else {
					[rows removeObjectAtIndex:row];
				}

				
			}
		}
	}
}
- (void)checkBoxButtonTapped:(id)sender event:(id)touchEvent {
	
	NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.tableView];
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
	int row = [indexPath row];
	int section = [indexPath section];
	
	if (indexPath != nil)
	{
		// get date
		NSString *dateString = [days objectAtIndex:section];
		
		// get film objects using dateString
		NSMutableArray *films = [data objectForKey:dateString];
		Schedule *film = [films objectAtIndex:row];
		
		// set checkBox's status
		BOOL checked = film.isSelected;
		film.isSelected = !checked;
		
		// get the current cell and the checkbox button 
		UITableViewCell *currentCell = [self.tableView cellForRowAtIndexPath:indexPath];
		UIButton *checkBoxButton = (UIButton*)[currentCell viewWithTag:CELL_BUTTON_TAG];
		
		// set button's image
		UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"unchecked.png"] : [UIImage imageNamed:@"checked.png"];
		[checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
	}
}
#pragma mark -
#pragma mark Table View Datasource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	int count = 0;
	switch (switcher) 
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
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int count;
	
	switch(switcher)
	{
		case VIEW_BY_DATE:
		{
			NSString *day = [days objectAtIndex:section];
			NSMutableArray *films = [data objectForKey:day];
			count = [films count];
		}
			break;
		
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];
			NSMutableArray *titlesx = [TitlesWithSort objectForKey:sort];
			count = [titlesx count];
		}
			break;
	}
    return count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *DateCellIdentifier = @"DateCell";
	static NSString *TitleCellIdentifier = @"TitleCell";
	
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
    
	UITableViewCell *cell;
    
	switch(switcher) {
		case VIEW_BY_DATE: {
			// get date
			NSString *dateString = [days objectAtIndex:section];
			
			// get film objects using date
			NSMutableArray *films = [data objectForKey:dateString];
			Schedule *film = [films objectAtIndex:row];
			// create displayString
			NSString *displayString = [NSString stringWithFormat:@"%@",film.title];
			
			// set text color
			UIColor *textColor = [UIColor blackColor];
			
			// check if current cell is already added to mySchedule
			// if it is, display it as blue
			NSUInteger i, count = [mySchedule count];
			for (i = 0; i < count; i++) {
				Schedule *obj = [mySchedule objectAtIndex:i];
				
				if (obj.ID == film.ID)//&& [obj.title isEqualToString:film.title] && [obj.date compare:film.date] == NSOrderedSame
				{
					//NSLog(@"%@ was added.",obj.title);
					textColor = [UIColor blueColor];
					film.isSelected = YES;
					break;
				}
			}
			
			// get reusable cell
			UITableViewCell *tempCell = [tableView dequeueReusableCellWithIdentifier:DateCellIdentifier];
			UILabel *titleLabel;
			UILabel *timeLabel;
			UILabel *venueLabel;
			UIButton *checkButton;
			
			// get checkbox status
			BOOL checked = film.isSelected;
			UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
			
			if (tempCell == nil) {
				tempCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
												   reuseIdentifier:DateCellIdentifier];
				
				titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,2,230,20)];
				titleLabel.tag = CELL_TITLE_LABEL_TAG;
				[tempCell.contentView addSubview:titleLabel];
				
				timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,21,150,20)];
				timeLabel.tag = CELL_TIME_LABEL_TAG;
				[tempCell.contentView addSubview:timeLabel];
				
				venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(210,21,100,20)];
				venueLabel.tag = CELL_VENUE_LABEL_TAG;
				[tempCell.contentView addSubview:venueLabel];
				
				checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
				checkButton.frame = CGRectMake(0,0,50,50);
				[checkButton setImage:buttonImage forState:UIControlStateNormal];
				
				[checkButton addTarget:self 
								action:@selector(checkBoxButtonTapped:event:)
					  forControlEvents:UIControlEventTouchUpInside];
				
				checkButton.backgroundColor = [UIColor clearColor];
				checkButton.tag = CELL_BUTTON_TAG;
				[tempCell.contentView addSubview:checkButton];
	
			}
			
			titleLabel = (UILabel*)[tempCell viewWithTag:CELL_TITLE_LABEL_TAG];
			titleLabel.text = displayString;
			titleLabel.textColor = textColor;
			
			timeLabel = (UILabel*)[tempCell viewWithTag:CELL_TIME_LABEL_TAG];
			timeLabel.text = [NSString stringWithFormat:@"Time: %@ - %@",film.timeString,film.endTimeString];
			timeLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
			timeLabel.textColor = textColor;
			
			venueLabel = (UILabel*)[tempCell viewWithTag:CELL_VENUE_LABEL_TAG];
			venueLabel.text = [NSString stringWithFormat:@"Venue: %@",film.venue];
			venueLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
			venueLabel.textColor = textColor;
			
			checkButton = (UIButton*)[tempCell viewWithTag:CELL_BUTTON_TAG];
			[checkButton setImage:buttonImage forState:UIControlStateNormal];
			
			if (textColor == [UIColor blueColor]) {
				checkButton.userInteractionEnabled = NO;
			} else {
				checkButton.userInteractionEnabled = YES;
			}

			cell = tempCell;
		}
			break;
		case VIEW_BY_TITLE: {
			cell = [tableView dequeueReusableCellWithIdentifier:TitleCellIdentifier];
			
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TitleCellIdentifier];
			}
			
			NSString *sort = [sorts objectAtIndex:section];
			NSMutableArray *films = [TitlesWithSort objectForKey:sort];
			Schedule *film = [films objectAtIndex:row];
			
			cell.textLabel.font = [UIFont systemFontOfSize:16.0f];
			cell.textLabel.text = film.title;
			
		}
			break;
		default:
			break;
	}
    return cell;
}
- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *result;
	
	switch (switcher) {
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
- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView {
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
#pragma mark -
#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int section = [indexPath section];
	int row		= [indexPath row];
		
	app.networkActivityIndicatorVisible = YES;

	switch (switcher) {
		case VIEW_BY_DATE:
		{
			NSString *date = [days objectAtIndex:section];
			NSMutableArray *films = [data objectForKey:date];
			Schedule *film = [films objectAtIndex:row];
			
			NSString *prg_id = [NSString stringWithFormat:@"%d",film.prog_id];
			NSString *link = [[NSString alloc] initWithFormat:@"%@%@",DETAILFORFILMID,prg_id];
			
			FilmDetail *filmDetail = [[FilmDetail alloc] initWithTitle:@"Film Detail" 
														 andDataObject:film 
																andURL:[NSURL URLWithString:link]];
			
			//NSLog(@"%@ , schedule id %d",link,film.ID);
			
			[[self navigationController] pushViewController:filmDetail animated:YES];
		}
			break;
			
		case VIEW_BY_TITLE:
		{
			NSString *sort = [sorts objectAtIndex:section];
			NSMutableArray *films = [TitlesWithSort objectForKey:sort];
			Schedule *film = [films objectAtIndex:row];
			
			NSString *ID = [NSString stringWithFormat:@"%d",film.ID];
			
			NSString *link = [[NSString alloc] initWithFormat:@"%@%@",DETAILFORFILMID,ID];
			
			FilmDetail *filmDetail = [[FilmDetail alloc] initWithTitle:@"Film Detail" 
														 andDataObject:film 
																andURL:[NSURL URLWithString:link]];
			
			[[self navigationController] pushViewController:filmDetail animated:YES];
			
		}
			break;

		default:
			break;
	}
	
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 50;
}
#pragma mark -
#pragma mark UIAccelerometer Delegate
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	if (!delegate.isPresentingModalView) {
		if ((acceleration.x > kAccelerationThreadhold
			&& acceleration.y < kAccelerationThreadhold)
			|| acceleration.z > kAccelerationThreadhold) {
			delegate.isPresentingModalView = YES;
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:delegate.newsView];
			[self.navigationController presentModalViewController:navController animated:YES];
		}
	}
}
@end

