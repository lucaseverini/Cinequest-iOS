//
//  MySchedulerViewController.m
//  CineQuest
//
//  Created by someone on 11/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MySchedulerViewController.h"
#import "LoadDataViewController.h"
#import "FilmDetail.h"
#import "EventDetailViewController.h"
#import "LogInViewController.h"
#import "CinequestAppDelegate.h"
#import "Schedule.h"

@interface MySchedulerViewController (Private)
- (void)doneEditing;

@end


@implementation MySchedulerViewController

#pragma mark -
#pragma mark Memory Management

@synthesize tableView = _tableView; 
@synthesize username;
@synthesize password;
@synthesize retrievedTimeStamp;
@synthesize status;
@synthesize xmlStatus;
@synthesize CQIcon;
@synthesize SJSUIcon;
@synthesize offSeasonLabel;

NSMutableArray *confirmedList, *movedList, *removedList, *currentList;
NSArray *MASTERLIST;	// contains all the lists (confirmed, moved, removed)
UIColor *currentColor;	// used to help color code the removed,confirmed,moved state of films (NSXMLPARSER Delegate)
NSDate *previousEndDate;	// a pointer to a previous date to compare schedule conflicts
UITableViewCell *previousCell;



- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark UIViewController
// Resets some variables when the users moves to a different screen
- (void)viewDidDisappear:(BOOL)animated {	
	status = @"none";
	previousCell = nil;
	previousEndDate = nil;
}
- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Get mySchedule array
	delegate = appDelegate;
	mySchedule = delegate.mySchedule;
	
	// initialize variables
	index = [[NSMutableArray alloc] init];
	displayData = [[NSMutableDictionary alloc] init];
	titleForSection = [[NSMutableArray alloc] init];

	if (delegate.isOffSeason) {
		offSeasonLabel.hidden = NO;
		self.tableView.hidden = YES;
		return;
	}
	
    //display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
																							target:self
																							action:@selector(edit)];
	
	// Sync button
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sync"
																			 style:UIBarButtonItemStyleBordered
																			target:self
																			action:@selector(logIn:)];
	CQIcon.alpha = 0.2;
	SJSUIcon.alpha = 0.2;
	// harold's variables
	xmlStatus		= [[NSString alloc] init];
	confirmedList	= [[NSMutableArray alloc] init];
	movedList		= [[NSMutableArray alloc] init];
	removedList		= [[NSMutableArray alloc] init];	
	currentColor	= [UIColor blackColor];
	MASTERLIST		= [NSArray arrayWithObjects:confirmedList,movedList,removedList,nil];
}
- (void)viewWillAppear:(BOOL)animated {
	delegate = appDelegate;
	if (delegate.isOffSeason) return;
	
	
	NSSortDescriptor *sortTime = [[NSSortDescriptor alloc] initWithKey:@"date" 
															 ascending:YES];
	
	[mySchedule sortUsingDescriptors:[NSArray arrayWithObjects:sortTime,nil]];
	
	[displayData removeAllObjects];
	[index removeAllObjects];
	[titleForSection removeAllObjects];
	
	NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	
	NSString *lastDateString = @"";
	for (Schedule *item in mySchedule) 
	{
		if ([item.dateString isEqualToString:lastDateString]) 
		{
			[tempArray addObject:item];
		}
		else 
		{
			[displayData setObject:tempArray forKey:lastDateString];
			
			lastDateString = item.dateString;
			
			[titleForSection addObject:lastDateString];
			//NSLog(lastDateString);
			[index addObject:[[lastDateString componentsSeparatedByString:@" "] objectAtIndex: 2]];
			
			tempArray = [[NSMutableArray alloc] init];
			[tempArray addObject:item];
		}

	}
	[displayData setObject:tempArray forKey:lastDateString];
	
	
	// reload tableView data
	[self.tableView reloadData];
	[self doneEditing];
    [super viewWillAppear:animated];
}
#pragma mark -
#pragma mark Actions
- (void)edit {
	[self.tableView setEditing:YES animated:YES];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							target:self
																							action:@selector(doneEditing)];
}
- (void)doneEditing {
	[self.tableView setEditing:NO animated:YES];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
																							target:self
																							action:@selector(edit)];
}
- (IBAction)logIn:(id)sender {	
	LogInViewController *loginScreen = [[LogInViewController alloc] init];	
	[loginScreen setParent:self];
	[self.navigationController pushViewController:loginScreen animated:YES];
}
// This function will attempt to login using provided credentials via POST to the cinequest script page
// PRECOND: have a valid username/password -- protocolType should be SLGET?
// PSTCOND: sends a request to the mobileCQ.php page, and parses the response XML and loads to local variables (arrays)
- (void)processLogin {	
	[confirmedList removeAllObjects];
	[removedList removeAllObjects];
	[movedList removeAllObjects];
	
	NSString *post = [NSString stringWithFormat:@"type=%@&username=%@&password=%@", @"SLGET", username, password];
	NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	
	NSURL *myURL = [NSURL URLWithString:@"http://mobile.cinequest.org/mobileCQ.php"];
	
	NSMutableURLRequest *myRequest = [[NSMutableURLRequest alloc] init];
	[myRequest setURL:myURL];
	[myRequest setHTTPMethod:@"POST"];	
	[myRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[myRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[myRequest setHTTPBody:postData];
	
	NSURLResponse *response;
	NSError *error;
	NSData *myReturn = [NSURLConnection sendSynchronousRequest:myRequest returningResponse:&response error:&error];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:myReturn];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	
	status = @"SLGET";
	
	[parser parse];	
	
	
	if( [confirmedList count] > 0 ) {
		// means there are some things to add into loc's array 'mySchedule' -- delegate
		[mySchedule removeAllObjects];
		
		Schedule *previousData;
		
		for (Schedule *data in confirmedList) {
			// add only confirmed films into the delegate array
			
			// checks to see if there is schedule conflict
			if (previousEndDate != nil) {
				if ([data.date isEqualToDate:[data.date earlierDate:previousData.endDate]]) {
					data.fontColor = [UIColor blueColor];
					previousData.fontColor = [UIColor blueColor];
				}
			}			
			
			previousEndDate = data.endDate;
			previousData = data;
			
			[mySchedule	addObject:data];
		}
	}
	else {
		
		if([xmlStatus isEqualToString:@"good"]) {
		
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:@"No Schedule Present" 
								  message:@"You currently have no schedule saved" 
								  delegate:nil 
								  cancelButtonTitle:@"Okay" 
								  otherButtonTitles:nil];
			[alert show];
		}
	}
}
// Attempts to call the mobileCQ protocal "SLPUT" with supplied timestamp updated.
// PRECOND: Must have a valid time saved into 'retrievedTimeStamp' also should
//			contain something in the 'titleForSection/displayData' arrays
// PSTCOND: Sends the films to be updated, will also run the delegate XMLParser as a result
- (void)saveFilms {
	// generate the list of films to add, by extracting the ID of the current list of schedules
	NSString *listofIDs = [[NSString alloc] init];
	
	// flag to catch the "LAST" filmID - to truncate the last comma on the CSV
	BOOL flag = NO;
	
	for (Schedule *time in mySchedule) {		
		NSString *currentID = [[NSString alloc] initWithFormat:@"%d,",time.ID];		
		//NSLog(@"adding: %d", time.ID);
		
		listofIDs = [listofIDs stringByAppendingString:currentID];
		flag = YES;
	}
	
	if (flag)
		listofIDs = [listofIDs substringToIndex:([listofIDs length]-1)];
	
	//NSLog(@"listofFilmsToADD: %@",listofIDs);	
		
	// DATE FORMAT for Cinequest stamp: YYYY-MM-DD HH:MM:SS -- call to function to increment by 1 sec.
	NSString *newTime;
	
	if(retrievedTimeStamp == nil)
		newTime = [[NSString alloc] initWithFormat:@"%d",0];
	else
		newTime = [MySchedulerViewController incrementCQTime:retrievedTimeStamp];	
	
	NSString *post = [NSString stringWithFormat:@"type=%@&username=%@&password=%@&lastChanged=%@&items=%@",
					  @"SLPUT", username, password,newTime,listofIDs];
	
	NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];	
	NSURL *myURL = [NSURL URLWithString:@"http://mobile.cinequest.org/mobileCQ.php"];
	
	NSMutableURLRequest *myRequest = [[NSMutableURLRequest alloc] init];
	[myRequest setURL:myURL];
	[myRequest setHTTPMethod:@"POST"];	
	[myRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[myRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[myRequest setHTTPBody:postData];
	
	NSURLResponse *response;
	NSError *error;
	NSData *myReturn = [NSURLConnection sendSynchronousRequest:myRequest returningResponse:&response error:&error];
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:myReturn];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	
	status = @"SLPUT";
	
	[parser parse];	
}
#pragma mark Utility Methods
// This method helps increment the timestamp supplied
// PRECOND: the format should be similiar to the one used in the CQ XML
// PSTCOND: Will return the string with exactly 1 second incremented from the supplie time
+(NSString *)incrementCQTime:(NSString *)CQdateTime{	
	//NSLog(@"CQdateTime: %@", CQdateTime);
	if(CQdateTime == nil)
		return @"0";
	
	NSDateFormatter *CQDateFormat = [[NSDateFormatter alloc] init];	
	[CQDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	
	NSDate *parsedDate = [CQDateFormat dateFromString:CQdateTime];
//	parsedDate = [parsedDate addTimeInterval:1];    //DEPRECATED
    parsedDate = [parsedDate dateByAddingTimeInterval:1];   //New
	
	NSString *returnString = [CQDateFormat stringFromDate:parsedDate];	
	
	return returnString;
}
#pragma mark -
#pragma mark UITableView DataSource
// There are multiple ways to load this table, one is to load the "scheduler list" of added films
// the second is to display the return of "SLGET" (confirmed,moved,removed)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [titleForSection count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	NSString *sectionTitle = [titleForSection objectAtIndex:section];
	NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
    return [rowsData count];
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {	
	return [titleForSection objectAtIndex:section];
}
// not too sure what this does, hopefully does not affect the "SLGET";
// it is one of the implemented functions for the "scheduler list"
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return index;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// Loading Schedule into the TabelViewCells
	NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
	NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];		
	Schedule *time = [rowsData objectAtIndex:indexPath.row];
	
	
    static NSString *CellIdentifier = @"Cell";   
    UITableViewCell *tempCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	UILabel *titleLabel;
	UILabel *timeLabel;
	UILabel *venueLabel;
	
	
	if (tempCell == nil) {
		tempCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
										   reuseIdentifier:CellIdentifier];
		
		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,2,300,20)];
		titleLabel.tag = CELL_TITLE_LABEL_TAG;
		[tempCell.contentView addSubview:titleLabel];
		
		timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,21,150,20)];
		timeLabel.tag = CELL_TIME_LABEL_TAG;
		[tempCell.contentView addSubview:timeLabel];
		
		
		venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(170,21,100,20)];
		
		venueLabel.tag = CELL_VENUE_LABEL_TAG;
		[tempCell.contentView addSubview:venueLabel];
	}
	
	titleLabel = (UILabel*)[tempCell viewWithTag:CELL_TITLE_LABEL_TAG];
	titleLabel.text = time.title;
	
	timeLabel = (UILabel*)[tempCell viewWithTag:CELL_TIME_LABEL_TAG];
	
	NSString *endTime = @"";	
	if ( time.endTimeString != nil ) {		
		endTime = [endTime stringByAppendingString:@" - "];
		endTime = [endTime stringByAppendingString:time.endTimeString];
	}
	
	timeLabel.text = [NSString stringWithFormat:@"Time: %@%@",time.timeString,endTime];
	timeLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	
	venueLabel = (UILabel*)[tempCell viewWithTag:CELL_VENUE_LABEL_TAG];
	venueLabel.text = [NSString stringWithFormat:@"Venue: %@",time.venue];
	venueLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	
	if(time.fontColor == nil) {
		titleLabel.textColor = [UIColor blackColor];
		timeLabel.textColor = [UIColor blackColor];
		venueLabel.textColor = [UIColor blackColor];
	} else {
		titleLabel.textColor = time.fontColor;
		timeLabel.textColor = time.fontColor;
		venueLabel.textColor = time.fontColor;
	}

	if(time.fontColor == [UIColor blueColor]) {
		timeLabel.textColor = [UIColor grayColor];
		venueLabel.textColor = [UIColor blackColor];
		timeLabel.font = [UIFont italicSystemFontOfSize:[UIFont smallSystemFontSize]];
	}
	 	
	tempCell.selectionStyle = UITableViewCellSelectionStyleNone;

    return tempCell;
}
#pragma mark -
#pragma mark UITableView Delegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView beginUpdates];
    if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		
		NSString *sectionTitle = [titleForSection objectAtIndex:indexPath.section];
		NSMutableArray *rowsData = [displayData objectForKey:sectionTitle];
		
		Schedule *item = [rowsData objectAtIndex:indexPath.row];
		[rowsData removeObjectAtIndex:indexPath.row];
		
		// Delete the row from the data source
		[mySchedule removeObject:item];
		
		// remove row from tableView
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		
		if ([rowsData count] == EMPTY) {
			[titleForSection removeObjectAtIndex:indexPath.section];
			[index removeObjectAtIndex:indexPath.section];
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:YES];
		}
    }  
	[tableView endUpdates];
    
}
#pragma mark -
#pragma mark NSXMLParser
// This delegate will look through "starting" tags of the parser obj.
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
	attributes:(NSDictionary *)attributeDict {	
	
	if ( [status isEqualToString:@"SLPUT"] ) {		
		//NSLog(@"START:%@",elementName);		
		if([elementName isEqualToString:@"userschedule"])  {
			// updates the current timestamp with updated one from the server (AFTER UPLOAD)
			retrievedTimeStamp = [[NSString alloc] initWithString:[attributeDict objectForKey:@"lastChanged"]];
			
			// needs to check if upload was sucessful
			NSString *uploadSucessful = [attributeDict objectForKey:@"updated"];
			
			if([uploadSucessful isEqualToString:@"false"]) {
				
				xmlStatus = @"scheduleconflict";
				
				UIAlertView *alertView = [[UIAlertView alloc]
										  initWithTitle:@"Schedule Conflict" 
										  message:@"We have a saved schedule on record for you, would you like to retrieve or overwrite it?" 
										  delegate:self 
										  cancelButtonTitle:nil  
										  otherButtonTitles:@"Retrieve", @"Overwrite", nil];
										 
				[alertView show];
			}
			
			//[uploadSucessful release];
		}
		
	}
	
	// the SLGET codeblock - for retrieving the list off the server + updating time
	else if ( [status isEqualToString:@"SLGET"] ) {
		
		// saves and stores the retrieved timestamp into 'retrievedTimeStamp'
		if([elementName isEqualToString:@"userschedule"]) 
			retrievedTimeStamp = [[NSString alloc] initWithString:[attributeDict objectForKey:@"lastChanged"]];	
		
		// Assigns the correct array to add Objects to 'currentList'
		else if([elementName isEqualToString:@"confirmed"]) {
			currentList = confirmedList;
			currentColor = [UIColor blackColor];
		}
		else if([elementName isEqualToString:@"moved"]) {
			//currentList = movedList;
			currentColor = [UIColor redColor];
		}
		else if([elementName isEqualToString:@"removed"]) {
			//currentList = removedList;
			currentColor = [UIColor grayColor];
		}
		
		
		// this block will parse the schedules and put them into the appropriate array.
		else if([elementName isEqualToString:@"schedule"]) {
			Schedule *newData = [[Schedule alloc] init];

			NSString *startTime = [attributeDict objectForKey:@"start_time"];
			NSString *endTime = [attributeDict objectForKey:@"end_time"];			
			newData.ID = [[attributeDict objectForKey:@"id"] integerValue];
			newData.prog_id = [[attributeDict objectForKey:@"program_item_id"] integerValue];			
			newData.venue = [attributeDict objectForKey:@"venue"];			
			newData.title = [attributeDict objectForKey:@"title"];
			newData.type = [attributeDict objectForKey:@"type"];		
			newData.fontColor = currentColor;			
			
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			
			// weird case where schedules are near empty but show up in SLGET.
			// will just skip all the following steps to avoid crashes if startTime does not exist
			if(startTime != nil) {
				NSDate *date = [dateFormatter dateFromString:startTime];
				newData.date = date;
			
				NSDate *date2 = [dateFormatter dateFromString:endTime];
				newData.endDate = date2;			
			
				[dateFormatter setDateFormat:@"hh:mm a"];
				newData.timeString = [dateFormatter stringFromDate:date];
				newData.endTimeString = [dateFormatter stringFromDate:date2];			
			
				[dateFormatter setDateFormat:@"EEEE, MMMM d"];
				NSString *dateString = [dateFormatter stringFromDate:date];
				newData.dateString = dateString;			
			}
			
			if(currentList == nil)
				currentList = [[NSMutableArray alloc] init];	
			
			if(newData.date != nil)
			[currentList addObject:newData];
			
		}
	}
	
}
// This delegate will start parsing the characters in-between tags.
// Good for interpreting the error messages from the CQ server
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	//NSLog(@"body: %@",string);	
	if([string isEqualToString:@"Item Id Not Present"])
	{				
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"No Films to add" 
							  message:@"You currently don't have any films to add" 
							  delegate:nil 
							  cancelButtonTitle:@"Okay" 
							  otherButtonTitles:nil];
		[alert show];
	}
	else if( [string isEqualToString:@"Authentication Failure"]  )
	{
		// means the username / password doesn't exist, set the 'isLogged' to NO
		xmlStatus = @"badLogin";
	}
	else if( [string isEqualToString:@"No Schedule Present"]  )
	{
		// means the username / password doesn't exist, set the 'isLogged' to NO
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"No Schedule Present" 
							  message:@"You currently have no schedule created" 
							  delegate:nil 
							  cancelButtonTitle:@"Okay" 
							  otherButtonTitles:nil];
		[alert show];
	} 
}

// This delegate will only parse through the "ending" tags of parser obj.
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {	
	//NSLog(@"END:%@",elementName);
}


#pragma mark UIActionSheet
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
		xmlStatus = @"overwriteSchedule";
		[self saveFilms];
		[self.navigationController popViewControllerAnimated:YES];
    }
    
    if (buttonIndex == 0) {
        xmlStatus = @"good";
		[self processLogin];
		[self.navigationController popViewControllerAnimated:YES];
    }
}

@end