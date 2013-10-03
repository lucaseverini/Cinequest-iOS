//
//  EventsViewController.m
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EventsViewController.h"
#import "EventDetailViewController.h"

#import "CinequestAppDelegate.h"
#import "Schedule.h"

#import "NewsViewController.h"
#import "LoadDataViewController.h"
#import "DDXML.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

@interface EventsViewController (Private)
- (void)loadDataFromDatabase;
- (void)syncTableDataWithScheduler;
@end

@implementation EventsViewController
#pragma mark -
#pragma mark Memory Management
@synthesize data;
@synthesize days;
@synthesize tableView = _tableView;
@synthesize index;
@synthesize loadingLabel;
@synthesize activity;
@synthesize CQIcon;
@synthesize SJSUIcon;
@synthesize offSeasonLabel;

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark -
#pragma mark UIViewController Methods
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Events";
	
	delegate = (CinequestAppDelegate*)[UIApplication sharedApplication].delegate;
	mySchedule = delegate.mySchedule;
	
	// Initialize data and days
	data = [[NSMutableDictionary alloc] init];
	days = [[NSMutableArray alloc] init];
	index = [[NSMutableArray alloc] init];
	backedUpDays	= [[NSMutableArray alloc] init];
	backedUpIndex	= [[NSMutableArray alloc] init];
	backedUpData	= [[NSMutableDictionary alloc] init];

	if (delegate.isOffSeason) {
		[activity stopAnimating];
		loadingLabel.hidden = YES;
		offSeasonLabel.hidden = NO;
		self.tableView.hidden = YES;
		return;
	}
	
	// Create add button 
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
																			   style:UIBarButtonItemStyleDone
																			  target:self
																			  action:@selector(addEvents:)];
	
	// Refine button
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refine"
																			  style:UIBarButtonItemStylePlain
																			 target:self
																			 action:@selector(refine:)];
	
	[self reloadData:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	[self syncTableDataWithScheduler];
	
	[self.tableView reloadData];
}
#pragma mark -
#pragma mark Actions
- (IBAction)reloadData:(id)sender {
	self.tableView.hidden = YES;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	self.navigationItem.leftBarButtonItem.enabled = NO;
	[activity startAnimating];
	loadingLabel.hidden = NO;
	
	@autoreleasepool {
		[data removeAllObjects];
		[days removeAllObjects];
		[index removeAllObjects];
		//[self performSelectorOnMainThread:@selector(startParsingXML) withObject:nil waitUntilDone:YES];
		[NSThread detachNewThreadSelector:@selector(startParsingXML) toTarget:self withObject:nil];
	}
	//[pool release];
}
- (void)addEvents:(id)sender {
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
					if (obj.ID == schedule.ID) {
						isAlreadyAdded = YES;
						//NSLog(@"%@ ID: %d",schedule.title,schedule.ID);
						break;
					}
				}
				if (!isAlreadyAdded) 
				{
					[mySchedule addObject:schedule];
					counter++;
				}
				//[schedule release];
			}
		}
	}
	[self syncTableDataWithScheduler];
	[self.tableView reloadData];
	if (counter != 0) {
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
#pragma mark Private Methods
- (void)startParsingXML {
	@autoreleasepool {
	
		NSURL *link = [[NSURL alloc] initWithString:EVENTS];
		
		NSData *xmlDocData = [NSData dataWithContentsOfURL:link];
		DDXMLDocument *eventXMLDoc = [[DDXMLDocument alloc] initWithData:xmlDocData
																 options:0
																   error:nil];
		DDXMLNode *rootElement = [eventXMLDoc rootElement];
		if ([rootElement childCount] == 2) {
			rootElement = [rootElement childAtIndex:1];
		} else {
			rootElement = [rootElement childAtIndex:3];
		}
		
		NSString *previousDay = @"empty";
		NSMutableArray *tempArray = [[NSMutableArray alloc] init];
		//NSLog(@"Child count: %d",[rootElement childCount]);
		for (int i = 0; i < [rootElement childCount]; i++) {
			DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
			NSDictionary *attributes;
			if ([child respondsToSelector:@selector(attributesAsDictionary)]) {
				attributes = [child attributesAsDictionary];
			} else {
				continue;
			}
			
			NSString *ID		= [attributes objectForKey:@"schedule_id"];
			NSString *prg_id	= [attributes objectForKey:@"program_item_id"];
			NSString *type		= [attributes objectForKey:@"type"];
			NSString *title		= [attributes objectForKey:@"title"];
			NSString *start		= [attributes objectForKey:@"start_time"];
			NSString *end		= [attributes objectForKey:@"end_time"];
			NSString *venue		= [attributes objectForKey:@"venue"];
					
			Schedule *event	= [[Schedule alloc] init];
			
			event.ID		= [ID intValue];
			event.prog_id	= [prg_id intValue];
			event.type		= type;
			event.title		= title;
			event.venue		= venue;
			
			//Start Time
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setLocale:usLocale];
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			NSDate *date = [dateFormatter dateFromString:start];
			event.date = date;
			[dateFormatter setDateFormat:@"hh:mm a"];
			event.timeString = [dateFormatter stringFromDate:date];
			//Date
			[dateFormatter setDateFormat:@"EEEE, MMMM d"];
			NSString *dateString = [dateFormatter stringFromDate:date];
			event.dateString = dateString;
			//End Time
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			date = [dateFormatter dateFromString:end];
			event.endDate = date;
			[dateFormatter setDateFormat:@"hh:mm a"];
			event.endTimeString = [dateFormatter stringFromDate:date];
			if (![previousDay isEqualToString:dateString]) 
			{
				[data setObject:tempArray forKey:previousDay];
				previousDay = [[NSString alloc] initWithString:dateString];
				[days addObject:previousDay];
				
				[index addObject:[[previousDay componentsSeparatedByString:@" "] objectAtIndex: 2]];
				
				tempArray = [[NSMutableArray alloc] init];
				[tempArray addObject:event];
			} else {
				[tempArray addObject:event];
			}
			
			
		}
		[data setObject:tempArray forKey:previousDay];
		
		// back up current data
		backedUpDays	= [[NSMutableArray alloc] initWithArray:days copyItems:YES];
		backedUpIndex	= [[NSMutableArray alloc] initWithArray:index copyItems:YES];
		backedUpData	= [[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES];
		
		[activity stopAnimating];
		loadingLabel.hidden = YES;
		CQIcon.alpha = 0.2;
		SJSUIcon.alpha = 0.2;
		self.navigationItem.rightBarButtonItem.enabled = YES;
		self.navigationItem.leftBarButtonItem.enabled = YES;
		[self.tableView reloadData];
		self.tableView.hidden = NO;
		//Disable "Reload" button
		self.tableView.tableHeaderView = nil;
	//[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
	//					 atScrollPosition:UITableViewScrollPositionTop
	//							 animated:NO];
	}
}
- (void)syncTableDataWithScheduler {
	NSUInteger i, count = [mySchedule count];
	
	// Sync current data
	for (int section = 0; section < [days count]; section++) 
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];
		for (int row = 0; row < [rows count]; row++) 
		{
			Schedule *event = [rows objectAtIndex:row];
			//event.isSelected = NO;
			for (i = 0; i < count; i++) 
			{
				Schedule *obj = [mySchedule objectAtIndex:i];
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
			for (i = 0; i < count; i++) 
			{
				Schedule *obj = [mySchedule objectAtIndex:i];
				if (obj.ID == event.ID) 
				{
					//NSLog(@"Added: %@.",obj.title);
					event.isSelected = YES;
					
				}
			}
			
		}
	}
}
#pragma mark -
#pragma mark UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [days count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *day = [days objectAtIndex:section];
	NSMutableArray *events = [data objectForKey:day];
	
    return [events count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
	
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *date = [days objectAtIndex:section];
	NSMutableArray *events = [data objectForKey:date];
	Schedule *event = [events objectAtIndex:row];
	// get title
	NSString *displayString = [NSString stringWithFormat:@"%@",event.title];
    // set text color
	UIColor *textColor = [UIColor blackColor];
	
	// check if current cell is already added to mySchedule
	// if it is, display it as blue
	NSUInteger i, count = [mySchedule count];
	for (i = 0; i < count; i++) {
		Schedule *obj = [mySchedule objectAtIndex:i];
		
		if (obj.ID == event.ID) 
		{
			//NSLog(@"%@ was added.",obj.title);
			textColor = [UIColor blueColor];
			event.isSelected = YES;
			break;
		}
	}
	
	// get checkbox status
	BOOL checked = event.isSelected;
	UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
	
	UILabel *titleLabel;
	UILabel *timeLabel;
	UILabel *venueLabel;
	UIButton *checkButton;
	
	UITableViewCell *tempCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (tempCell == nil) {
		tempCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
										   reuseIdentifier:CellIdentifier];
		
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
	timeLabel.text = [NSString stringWithFormat:@"Time: %@ - %@",event.timeString,event.endTimeString];
	timeLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	timeLabel.textColor = textColor;
	
	venueLabel = (UILabel*)[tempCell viewWithTag:CELL_VENUE_LABEL_TAG];
	venueLabel.text = [NSString stringWithFormat:@"Venue: %@",event.venue];
	venueLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	venueLabel.textColor = textColor;
	
	checkButton = (UIButton*)[tempCell viewWithTag:CELL_BUTTON_TAG];
	[checkButton setImage:buttonImage forState:UIControlStateNormal];
	
	
	if (textColor == [UIColor blueColor]) {
		checkButton.userInteractionEnabled = NO;
	} else {
		checkButton.userInteractionEnabled = YES;
	}
	
    return tempCell;
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
		NSMutableArray *events = [data objectForKey:dateString];
		Schedule *event = [events objectAtIndex:row];
		
		// set checkBox's status
		BOOL checked = event.isSelected;
		event.isSelected = !checked;
		
		// get the current cell and the checkbox button 
		UITableViewCell *currentCell = [self.tableView cellForRowAtIndexPath:indexPath];
		UIButton *checkBoxButton = (UIButton*)[currentCell viewWithTag:CELL_BUTTON_TAG];
		
		// set button's image
		UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"unchecked.png"] : [UIImage imageNamed:@"checked.png"];
		[checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
		
		for (int section = 0; section < [days count]; section++) 
		{
			NSString *day = [days objectAtIndex:section];
			NSMutableArray *rows = [data objectForKey:day];
			for (int row = 0; row < [rows count]; row++) 
			{
				Schedule *aRandomEvent = [rows objectAtIndex:row];
				if (aRandomEvent.ID == event.ID) {
					aRandomEvent.isSelected = event.isSelected;
				}
				
			}
		}
		[self.tableView reloadData];
	}
	
}
- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *day = [days objectAtIndex:section];
	return day;
}
- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView {
	return index;
}
#pragma mark -
#pragma mark UITableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *date = [days objectAtIndex:section];
	
	NSMutableArray *events = [data objectForKey:date];
	
	Schedule *event = [events objectAtIndex:row];
	
	NSString *link = [NSString stringWithFormat:@"%@%d",DETAILFORITEM, event.prog_id];
	
	//NSLog(@"%@",link);
	
	EventDetailViewController *eventDetail = [[EventDetailViewController alloc] initWithTitle:event.title
																				andDataObject:event
																					   andURL:[NSURL URLWithString:link]];
	eventDetail.displayAddButton = YES;
	UIApplication *app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = YES;
	
	[self.navigationController pushViewController:eventDetail animated:YES];
}

@end

