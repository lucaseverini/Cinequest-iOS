//
//  FilmDetail.m
//  CineQuest
//
//  Created by Loc Phan on 10/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FilmDetail.h"
#import "DDXML.h"
#import "Schedule.h"
#import "DVD.h"
#import "CinequestAppDelegate.h"
#import "DataProvider.h"

#define web @"<style type=\"text/css\">h1{font-size:23px;text-align:center;}p.image{text-align:center;}</style><h1>%@</h1><p class=\"image\"><img style=\"max-height:100px;max-width:150px;\"src=\"%@\"/></p><p>%@</p>"

@interface FilmDetail (Private)

- (void)parseData;

- (IBAction)addAction:(id)sender;

@end

@implementation FilmDetail

@synthesize tableView = _tableView;
@synthesize webView;
@synthesize dataDictionary;
@synthesize activityIndicator;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UIViewController Methods

static NSString *kGetSessionProxy = nil;
static NSString *kApiKey	= @"d944f2ee4f658052fd27137c0b9ff276";
static NSString *kApiSecret = @"e4070331e81e43de67c009c8f7ace326";

- (id) initWithTitle:(NSString*)name andDataObject:(Schedule*)dataObject andId:(NSUInteger)filmID
{
	if (self = [super init]) 
	{
		self.navigationItem.title = name;
		filmId = filmID;
		
		dataDictionary	= [[NSMutableDictionary alloc] init];

		myFilmData = [[Schedule alloc] init];
		myFilmData.title = dataObject.title;
		myFilmData.ID = dataObject.ID;
		myFilmData.prog_id = dataObject.prog_id;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	delegate = appDelegate;
	mySchedule = delegate.mySchedule;
	
	self.tableView.hidden = YES;
	self.view.userInteractionEnabled = NO;

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
																				style:UIBarButtonItemStyleDone
																				target:self
																				action:@selector(addAction:)];
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	[NSThread detachNewThreadSelector:@selector(parseData) toTarget:self withObject:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
	[self.tableView reloadData];
}

- (void) parseData
{
	NSData *data = [[appDelegate dataProvider] filmDetail:filmId];
	if (data == nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attention!"
														message:@"Please connect to the internet."
														delegate:nil
														cancelButtonTitle:@"OK"
														otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	DDXMLDocument *xmlDocument = [[DDXMLDocument alloc] initWithData:data
															 options:0
															   error:nil];
	DDXMLNode *rootElement = [xmlDocument rootElement];
	NSString *titleString = [NSString stringWithString:[[rootElement childAtIndex:0] stringValue]];
	NSArray *infoArray = [rootElement children];
	for (DDXMLNode *node in infoArray) {
		NSString *value = [[NSString alloc] initWithString:[node stringValue]];
		NSString *name = [[NSString alloc] initWithString:[node name]];
		//NSLog(@"%@ %@",name, value);
		if ([name isEqualToString:@"schedules"])
		{
			DDXMLNode *scheduleNodes = node;
			NSMutableArray *schedules	= [[NSMutableArray alloc] init];
			for (int i=0; i<[scheduleNodes childCount]; i++) {
				DDXMLElement *scheduleNode = (DDXMLElement*)[scheduleNodes childAtIndex:i];
				NSDictionary *atts = [scheduleNode attributesAsDictionary];
				
				NSString *ID			= [atts objectForKey:@"id"];
				NSString *prg_item_id	= [atts objectForKey:@"program_item_id"];
				NSString *start_time	= [atts objectForKey:@"start_time"];
				NSString *end_time		= [atts objectForKey:@"end_time"];
				NSString *venue			= [atts objectForKey:@"venue"];
				
				Schedule *event = [[Schedule alloc] init];
				event.title		= titleString;
				event.ID		= [ID integerValue];
				event.prog_id	= [prg_item_id integerValue];
				event.type		= @"film";
				event.venue		= venue;
				
				if (event.ID == myFilmData.ID) {
					myFilmData.prog_id = event.prog_id;
				}
				//Start Time
				NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
				[inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
				NSDate *formatterDate = [inputFormatter dateFromString:start_time];
				event.date = formatterDate;
				[inputFormatter setDateFormat:@"hh:mm a"];
				event.timeString = [inputFormatter stringFromDate:formatterDate];
				//Date
				[inputFormatter setDateFormat:@"EEEE, MMMM d"];
				event.dateString = [inputFormatter stringFromDate:formatterDate];
				//End Time
				[inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
				formatterDate = [inputFormatter dateFromString:end_time];
				event.endDate = formatterDate;
				[inputFormatter setDateFormat:@"hh:mm a"];
				event.endTimeString = [inputFormatter stringFromDate:formatterDate];
				
				
				[schedules addObject:event];
			}
			[dataDictionary setObject:schedules forKey:@"Schedules"];
		}
		[dataDictionary setObject:value forKey:name];
	}

	[self performSelectorOnMainThread:@selector(loadData) withObject:nil waitUntilDone:YES];
}
   
- (void)loadData
{
	NSString *weba = [NSString stringWithFormat:web,[dataDictionary objectForKey:@"title"]
					  ,[dataDictionary objectForKey:@"imageURL"]
					  ,[dataDictionary objectForKey:@"description"]];
	
	NSArray *keys = [dataDictionary allKeys];
	for (NSString *key in keys) {
		NSString *obj = [dataDictionary objectForKey:key];
		if (![obj isKindOfClass:[NSString class]] 
			|| [obj isEqualToString:@""] || [key isEqualToString:@"imageURL"]
			|| [key isEqualToString:@"description"] || [key isEqualToString:@"title"])
		{
			continue;
		}
		else if ([key isEqualToString:@"trailer"]) {
			NSString *youtubeLink = [dataDictionary objectForKey:@"trailer"];
			NSString *htmlString = @"";
			htmlString = [htmlString stringByAppendingString:@"<div><object width=\"50\" height=\"50\">"];
			htmlString = [htmlString stringByAppendingString:@"<param name=\"movie\" value=\"%@\"></param>"];
			htmlString = [htmlString stringByAppendingString:@"<param name=\"wmode\" value=\"transparent\"></param>"];
			htmlString = [htmlString stringByAppendingFormat:@"<embed src=\"%@\"",youtubeLink];
			htmlString = [htmlString stringByAppendingString:@"type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"50\" height=\"50\"></embed>"];
			htmlString = [htmlString stringByAppendingString:@"</object></div>"];
			
			weba = [weba stringByAppendingFormat:@"Trailer: %@ <br/>",htmlString];
			continue;
		}
		
		if ([key isEqualToString:@"genre"])				weba = [weba stringByAppendingFormat:@"Genre: %@<br/>",obj];
		if ([key isEqualToString:@"director"])			weba = [weba stringByAppendingFormat:@"Director: %@<br/>",obj];
		if ([key isEqualToString:@"producer"])			weba = [weba stringByAppendingFormat:@"Producer: %@<br/>",obj];
		if ([key isEqualToString:@"writer"])			weba = [weba stringByAppendingFormat:@"Writer: %@<br/>",obj];
		if ([key isEqualToString:@"cinematographer"])	weba = [weba stringByAppendingFormat:@"Cinematographer: %@<br/>",obj];
		if ([key isEqualToString:@"editor"])			weba = [weba stringByAppendingFormat:@"Editor: %@<br/>",obj];
		if ([key isEqualToString:@"cast"])				weba = [weba stringByAppendingFormat:@"Cast: %@<br/>",obj];
		if ([key isEqualToString:@"country"])			weba = [weba stringByAppendingFormat:@"Country: %@<br/>",obj];
		if ([key isEqualToString:@"language"])			weba = [weba stringByAppendingFormat:@"Director: %@<br/>",obj];
		if ([key isEqualToString:@"film_info"])			weba = [weba stringByAppendingFormat:@"Film Info: %@<br/>",obj];
	}
	
	[webView loadHTMLString:weba baseURL:nil];
}

#pragma mark -
#pragma mark Actions

- (IBAction) addAction:(id)sender
{
	// get all schedules that has checked items
	NSMutableArray *schedules = [dataDictionary objectForKey:@"Schedules"];
	
	int addedCount = 0;
	NSUInteger i, count = [schedules count];
	for (i = 0; i < count; i++) 
	{
		Schedule *currentCheckedItem = [schedules objectAtIndex:i];
		if (currentCheckedItem.isSelected) 
		{
			
			BOOL isAlreadyAdded = NO;
			NSUInteger j, count2 = [mySchedule count];
			for (j = 0; j < count2; j++) 
			{
				Schedule * scheduleInMySchedule = [mySchedule objectAtIndex:j];
				if (currentCheckedItem.ID == scheduleInMySchedule.ID) 
				{
					isAlreadyAdded = YES;
					//NSLog(@"Already added %@",currentCheckedItem.title);
					break;
				}
			}
			if (!isAlreadyAdded) 
			{
				[mySchedule addObject:currentCheckedItem];
				addedCount++;
				//NSLog(@"ADDED schedule id: %d",currentCheckedItem.ID);

			}
		}
	}
	[self.tableView reloadData];
	
	UIAlertView *alert;
	if (addedCount > 0) 
	{
		alert = [[UIAlertView alloc] initWithTitle:@"Attention!"
										   message:[NSString stringWithFormat:@"%@ is added to your schedule.",myFilmData.title]
										  delegate:nil
								 cancelButtonTitle:@"OK"
								 otherButtonTitles:nil];
	}
	
	else {
		alert = [[UIAlertView alloc] initWithTitle:@"Attention!"
										   message:[NSString stringWithFormat:@"Nothing is added. Please choose a time."]
										  delegate:nil
								 cancelButtonTitle:@"OK"
								 otherButtonTitles:nil];
	}

	[alert show];
}

#pragma mark -
#pragma mark UIWebView delegate

- (void) webViewDidFinishLoad:(UIWebView *)_webView
{
	UIWebView *webview = (UIWebView*) self.tableView.tableHeaderView;

	[webview sizeToFit];
	double height = webview.frame.size.height + 30.0f;

	double width = webview.frame.size.width;
	[webview setFrame:CGRectMake(0,0,width,height)];
	
	[self.tableView setTableHeaderView:webview];
	[self.tableView reloadData];
	[activityIndicator stopAnimating];
	self.tableView.hidden = NO;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	self.view.userInteractionEnabled = YES;
}

#pragma mark -
#pragma mark UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	int result = 1;
	
	switch (section)
	{
		case SCHEDULE_SECTION:
		{
			NSMutableArray *array = [dataDictionary objectForKey:@"Schedules"];
			result = [array count];
			break;
		}
		case SOCIAL_MEDIA_SECTION:
			break;
			
		case CALL_N_EMAIL_SECTION:
			result = 2;
			break;
	}
	
	return result;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *answer;
	
	switch (section) {
		case SCHEDULE_SECTION:
			answer = @"Schedules";
			break;
		case SOCIAL_MEDIA_SECTION:
			answer = @"Share to Social Media";
			break;
		case CALL_N_EMAIL_SECTION:
			answer = @"Actions";
			break;
	}
	
    return answer;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	int section = [indexPath section];
	int height = 50;
		
	switch (section) {
		case SCHEDULE_SECTION:
			height = 50;
			break;
		case SOCIAL_MEDIA_SECTION:
			height = 50;
			break;
		case CALL_N_EMAIL_SECTION:
			break;
		default:
			break;
	}
				   
    return height;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *ScheduleCellID		= @"ScheduleCell";
	static NSString *FacebookIdentifier = @"FBCell";
	static NSString *ActionsIdentifier	= @"ActCell";
	
	int section = [indexPath section];
	
	UITableViewCell *cell;
	switch (section) {
		case SCHEDULE_SECTION: {
			cell = [tableView dequeueReusableCellWithIdentifier:ScheduleCellID];
			
			// get row number
			int row = [indexPath row];
			
			// get all schedules
			NSMutableArray *schedules = [dataDictionary objectForKey:@"Schedules"];
			Schedule *time = [schedules objectAtIndex:row];
			
			UIColor *textColor = [UIColor blackColor];
			BOOL userInteraction = YES;
			
			NSUInteger i, count = [mySchedule count];
			
			for (i = 0; i < count; i++) {
				Schedule *obj = [mySchedule objectAtIndex:i];
				if (obj.ID == time.ID) {
					textColor = [UIColor blueColor];
					userInteraction = NO;
					time.isSelected = YES;
				}
			}
			
			UILabel *label;
			UILabel *timeLabel;
			UILabel *venueLabel;
			UIButton *checkButton;

			BOOL checked = time.isSelected;
			UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
			if (cell == nil) {
				// init cell
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ScheduleCell"];
				cell.accessoryType = UITableViewCellAccessoryNone;
				
				label = [[UILabel alloc] initWithFrame:CGRectMake(50,2,230,20)];
				label.tag = CELL_TITLE_LABEL_TAG;
				[cell.contentView addSubview:label];
				
				timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,21,150,20)];
				timeLabel.tag = CELL_TIME_LABEL_TAG;
				[cell.contentView addSubview:timeLabel];
				
				venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(210,21,100,20)];
				venueLabel.tag = CELL_VENUE_LABEL_TAG;
				[cell.contentView addSubview:venueLabel];
				
				checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
				checkButton.frame = CGRectMake(0,0,50,48);
				checkButton.userInteractionEnabled = NO;
				[checkButton setImage:buttonImage forState:UIControlStateNormal];
				checkButton.backgroundColor = [UIColor clearColor];
				checkButton.tag = CELL_BUTTON_TAG;
				[cell.contentView addSubview:checkButton];
			}
			// set the cell's text
			label = (UILabel*)[cell viewWithTag:CELL_TITLE_LABEL_TAG];
			label.text = [NSString stringWithFormat:@"Date: %@",time.dateString];
			label.textColor = textColor;
			label.font = [UIFont systemFontOfSize:14.0f];
			
			timeLabel = (UILabel*)[cell viewWithTag:CELL_TIME_LABEL_TAG];
			timeLabel.text = [NSString stringWithFormat:@"Time: %@ - %@",time.timeString,time.endTimeString];
			timeLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
			timeLabel.textColor = textColor;
			
			venueLabel = (UILabel*)[cell viewWithTag:CELL_VENUE_LABEL_TAG];
			venueLabel.text = [NSString stringWithFormat:@"Venue: %@",time.venue];
			venueLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
			venueLabel.textColor = textColor;
			
			checkButton = (UIButton*)[cell viewWithTag:CELL_BUTTON_TAG];
			[checkButton setImage:buttonImage forState:UIControlStateNormal];
			
			cell.userInteractionEnabled = userInteraction;
			
			break;
		}
		case SOCIAL_MEDIA_SECTION: {
			cell = [tableView dequeueReusableCellWithIdentifier:FacebookIdentifier];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FacebookIdentifier];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				
                UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [fbButton addTarget:self
                           action:@selector(pressToShareToFacebook:)
                 forControlEvents:UIControlEventTouchDown];
                
                
                [fbButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
                [fbButton setImage:[UIImage imageNamed:@"facebook-pressed.png"] forState:UIControlStateHighlighted];
                [fbButton setBackgroundColor:[UIColor clearColor]];
                fbButton.frame = CGRectMake(40, 10, 32, 32);
                [cell.contentView addSubview:fbButton];
                
                UIButton *twButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [twButton addTarget:self
                             action:@selector(pressToShareToTwitter:)
                   forControlEvents:UIControlEventTouchDown];
                
                
                [twButton setImage:[UIImage imageNamed:@"twitter"] forState:UIControlStateNormal];
                [twButton setImage:[UIImage imageNamed:@"twitter-pressed.png"] forState:UIControlStateHighlighted];
                [twButton setBackgroundColor:[UIColor clearColor]];
                twButton.frame = CGRectMake(92, 10, 32, 32);
                [cell.contentView addSubview:twButton];
                
            }

			break;
		}
		case CALL_N_EMAIL_SECTION: {
			cell = [tableView dequeueReusableCellWithIdentifier:ActionsIdentifier];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActionsIdentifier];
			}
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = @"Call Cinequest Ticketing Line";
					break;
				case 1:
					cell.textLabel.text = @"Email Film Detail";
					break;
				default:
					break;
			}
		}
			break;
		default:
			break;
	}
	cell.textLabel.font = [UIFont systemFontOfSize:16.0f];
    return cell;
}
#pragma mark -
#pragma mark UITableView delegate
- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	int section = [indexPath section];
	int row = [indexPath row];
	
	if (section == SCHEDULE_SECTION)
	{
		UITableViewCell *oldCell = [atableView cellForRowAtIndexPath:indexPath];
		
		NSMutableArray *schedules = [dataDictionary objectForKey:@"Schedules"];
		Schedule *time = [schedules objectAtIndex:row];
		
		// set checkBox's status
		BOOL checked = time.isSelected;
		time.isSelected = !checked;
		
		// get the current cell and the checkbox button 
		UIButton *checkBoxButton = (UIButton*)[oldCell viewWithTag:CELL_BUTTON_TAG];
		
		// set button's image
		UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"unchecked.png"] : [UIImage imageNamed:@"checked.png"];
		[checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
		
		[atableView deselectRowAtIndexPath:indexPath animated:NO];
	}
	if (section == CALL_N_EMAIL_SECTION) {
		switch (row) {
			case 0: {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Application will now exit."
												   message:@"Are you sure?"
												  delegate:self
										 cancelButtonTitle:@"Cancel"
										 otherButtonTitles:@"OK",nil];
				[alert show];
				break;
			}
			case 1: {
				MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
				NSString *friendlyMessage = @"Hey, I found an interesting film from Cinequest. Check it out!";
				NSString *messageBody = [NSString stringWithFormat:@"%@\n http://mobile.cinequest.org/event_view.php?eid=%d",friendlyMessage,myFilmData.prog_id];
				controller.mailComposeDelegate = self;
				[controller setSubject:myFilmData.title];
				[controller setMessageBody:messageBody isHTML:NO]; 
				delegate.isPresentingModalView = YES;
				    [self.navigationController presentViewController:controller animated:YES completion:nil];
				break;
			}
			default:
				break;
		}
	}
}
#pragma mark -
#pragma mark UIAlertView Delegate
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		//NSLog(@"CALL!");
		[app openURL:[NSURL URLWithString:TICKET_LINE]];
	} else {
		//NSLog(@"cancel");
	}
	NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
}
#pragma mark -
#pragma mark MFMailComposeViewController Delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error; {
	if (result == MFMailComposeResultSent) {
		//NSLog(@"It's away!");
	}
	delegate.isPresentingModalView = NO;
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
#pragma mark Social Media Sharing

- (IBAction)pressToShareToFacebook:(id)sender
{
    NSString *postString = [NSString stringWithFormat:@"I'm planning to go see %@", myFilmData.title];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *faceSheet = [SLComposeViewController
                                              composeViewControllerForServiceType:SLServiceTypeFacebook];
        [faceSheet setInitialText:postString];
        [self presentViewController:faceSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't post on Facebook right now, make sure your device has an internet connection and you have at least one FB account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (IBAction)pressToShareToTwitter:(id)sender
{
    NSString *tweetString = [NSString stringWithFormat:@"I'm planning to go see %@", myFilmData.title];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:tweetString];
        [self presentViewController:tweetSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

@end
