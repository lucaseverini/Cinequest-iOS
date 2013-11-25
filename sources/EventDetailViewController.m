//
//  EventDetailViewController.m
//  CineQuest
//
//  Created by Loc Phan on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EventDetailViewController.h"
#import "CinequestAppDelegate.h"
#import "DDXML.h"
#import "Schedule.h"
#import "DataProvider.h"

static NSString *kScheduleCellIdentifier = @"ScheduleCell";
static NSString *kSocialCellIdentifier = @"SocialCell";
static NSString *kActionsCellIdentifier= @"ActionCell";

#define web_news @"<style type=\"text/css\">h1{font-size:23px;text-align:center;}p.image{text-align:center;}</style><h1>%@</h1><p class=\"image\"><img style=\"max-height:200px;max-width:250px;\"src=\"%@\"/></p><p>%@</p>"
#define web @"<style type=\"text/css\">h1{font-size:23px;text-align:center;}p.image{text-align:center;}</style><h1>%@</h1><p>%@</p>"
#define web_paragraph @"<p>%@</p>"


@implementation EventDetailViewController

@synthesize detailsTableView;
@synthesize webView;
@synthesize activityIndicator;

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UIViewController

- (id) initWithNews:(NSDictionary*)news
{
	self = [super init];
	if(self != nil)
	{
		self.title = @"Detail";

		showNewsDetail = YES;
		
		dataDictionary = [NSMutableDictionary dictionaryWithDictionary:news];
    }
	
    return self;
}

- (id) initWithEvent:(NSString*)name andDataObject:(Schedule*)dataObject andId:(NSString*)eventID;
{
	self = [super init];
	if(self != nil)
	{
		self.title = @"Detail";
		
		showEventDetail = YES;
		
		eventId = eventID;
		dataDictionary = [[NSMutableDictionary  alloc] init];
		
		myData = [[Schedule alloc] init];
		myData.ID = dataObject.ID;
		myData.title = dataObject.title;
		myData.itemID = dataObject.itemID;
    }
	
    return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	delegate = appDelegate;
	mySchedule = delegate.mySchedule;

	self.detailsTableView.hidden = YES;
	self.view.userInteractionEnabled = NO;

	self.activityIndicator.color = [UIColor grayColor];
	
	[(UIWebView*)self.detailsTableView.tableHeaderView setSuppressesIncrementalRendering:YES]; // Avoids scrolling problems when the WebView is showed

	[self.activityIndicator startAnimating];

	if(showNewsDetail)
	{
		[self performSelectorOnMainThread:@selector(parseNewsData) withObject:nil waitUntilDone:NO];
	}
	else if(showEventDetail)
	{
		[self performSelectorOnMainThread:@selector(parseEventData) withObject:nil waitUntilDone:NO];
	}
	
	[self.detailsTableView reloadData];
}

- (void) parseNewsData
{
	NSString *name = [dataDictionary objectForKey:@"name"];
	NSString *image = [appDelegate.dataProvider cacheImage:[dataDictionary objectForKey:@"image"]];
	NSString *description = [dataDictionary objectForKey:@"description"];
	NSString *info = [[dataDictionary objectForKey:@"info"] lowercaseString];
	NSString *weba = [NSString stringWithFormat:web_news, name, image, description];
	if(info.length != 0 && [info hasPrefix:@"http"])
	{
		weba = [weba stringByAppendingString:[NSString stringWithFormat:web_paragraph, info]];
	}
	else
	{
		NSLog(@"Show event %@", info);
	}
	weba = [self htmlEntityDecode:weba];
	
	[self.webView loadHTMLString:weba baseURL:nil];
}

- (void) parseEventData
{
	NSData *data = [[appDelegate dataProvider] eventDetail:eventId];
	
	DDXMLDocument *xmlDocument = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
	DDXMLNode *rootElement = [xmlDocument rootElement];
	//NSLog(@"%d",[rootElement childCount]);
	
	for (int i=0;i<[rootElement childCount]; i++) {
		DDXMLNode *element = [rootElement childAtIndex:i];
		NSString *elementName = [element name];
		//NSLog(@"elementName: %@",elementName);
		if ([elementName isEqualToString:@"title"])
		{
			NSString *theTitle = [element stringValue];
			[dataDictionary setObject:theTitle forKey:@"Title"];
			continue;
		}
		if ([elementName isEqualToString:@"schedules"]) {
			NSMutableArray *schedules	= [[NSMutableArray alloc] init];
			for (int j=0;j<[element childCount]; j++) {
				DDXMLElement *scheduleNode = (DDXMLElement*)[element childAtIndex:j];
				if([[scheduleNode name] isEqualToString:@"schedule"])
				{
					NSDictionary *atts = [scheduleNode attributesAsDictionary];
					
					NSString *ID			= [atts objectForKey:@"id"];
					NSString *prg_item_id	= [atts objectForKey:@"program_item_id"];
					NSString *start_time	= [atts objectForKey:@"start_time"];
					NSString *end_time		= [atts objectForKey:@"end_time"];
					NSString *venue			= [atts objectForKey:@"venue"];
					
					Schedule *event = [[Schedule alloc] init];
					event.title		= [dataDictionary objectForKey:@"Title"];
					event.ID		= ID;
					event.itemID	= prg_item_id;
					event.type		= @"event";
					event.venue		= venue;
					
					//Start Time
					NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
					[inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
					NSDate *formatterDate = [inputFormatter dateFromString:start_time];
					event.startDate = formatterDate;
					[inputFormatter setDateFormat:@"hh:mm a"];
					event.startTime = [inputFormatter stringFromDate:formatterDate];
					//Date
					[inputFormatter setDateFormat:@"EEEE, MMMM d"];
					event.dateString = [inputFormatter stringFromDate:formatterDate];
					
					//End Time
					[inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
					formatterDate = [inputFormatter dateFromString:end_time];
					event.endDate = formatterDate;
					[inputFormatter setDateFormat:@"hh:mm a"];
					event.endTime = [inputFormatter stringFromDate:formatterDate];
					
					[schedules addObject:event];
				}
			}
			[dataDictionary setObject:schedules forKey:@"Schedules"];
			continue;
		}
		if ([elementName isEqualToString:@"description"] 
			&& ![[element stringValue] isEqualToString:@""]) {
			NSString *description = [element stringValue];
			[dataDictionary setObject:description forKey:@"Description"];
			continue;
		}
		if ([elementName isEqualToString:@"film"]) {
			for (int j=0; j<[element childCount]; j++) {
				DDXMLNode *childOfElement = [element childAtIndex:j];
				if ([[childOfElement name] isEqualToString:@"description"]) {
					NSString *description = [childOfElement stringValue];
					[dataDictionary setObject:description forKey:@"Description"];
				}
			}
		}
	}
	
	NSString *weba = [NSString stringWithFormat:web, [dataDictionary objectForKey:@"Title"], [dataDictionary objectForKey:@"Description"]];	
	weba = [self htmlEntityDecode:weba]; // Render HTML properly
	
	[self.webView loadHTMLString:weba baseURL:nil];
}

#pragma mark -
#pragma mark UIWebView delegate

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
	// Updates the WebView and force it to redisplay correctly
	[self.detailsTableView.tableHeaderView sizeToFit];
	[self.detailsTableView setTableHeaderView:self.detailsTableView.tableHeaderView];
	
	[self.activityIndicator stopAnimating];
	
	self.view.userInteractionEnabled = YES;
	self.detailsTableView.hidden = NO;
}

- (BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    if(inType == UIWebViewNavigationTypeLinkClicked)
	{
        [app openURL:[inRequest URL]];
		
        return NO;
    }
	
    return YES;
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
				Schedule * scheduleInMySchedule= [mySchedule objectAtIndex:j];
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
	
	[self.detailsTableView reloadData];
	
	UIAlertView *alert;
	if (addedCount > 0) 
	{
		alert = [[UIAlertView alloc] initWithTitle:@"Attention!"
											message:[NSString stringWithFormat:@"%@ is added to your schedule.",myData.title]
											delegate:nil
											cancelButtonTitle:@"OK"
											otherButtonTitles:nil];
	}	
	else
	{
		alert = [[UIAlertView alloc] initWithTitle:@"Attention!"
											message:[NSString stringWithFormat:@"Nothing is added. Please choose a time."]
											delegate:nil
											cancelButtonTitle:@"OK"
											otherButtonTitles:nil];
	}
	
	[alert show];
}

#pragma mark -
#pragma mark UITableView Datasource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	if(showNewsDetail)
	{
		return 2;
	}
	else
	{
		return 3;
	}
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(showNewsDetail)
	{
		switch (section)
		{
			case 0:
				return 1;
				break;
				
			case 1:
				return 2;
				break;
		}
	}
	else
	{
		switch (section)
		{
			case SCHEDULE_SECTION:
				return 1; //[[dataDictionary objectForKey:@"Schedules"] count];
				break;
				
			case SOCIAL_MEDIA_SECTION:
				return 1;
				break;
				
			case CALL_N_EMAIL_SECTION:
				return 2;
				break;
		}
	}
	
	return 1;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	if(showNewsDetail)
	{
		switch(section)
		{
			case 0:
				return  @"Share to Social Media";
				break;
				
			case 1:
				return  @"Actions";
				break;
		}
	}
	else
	{
		switch(section)
		{
			case SCHEDULE_SECTION:
				return @"Schedules";
				break;
				
			case SOCIAL_MEDIA_SECTION:
				return  @"Share to Social Media";
				break;
				
			case CALL_N_EMAIL_SECTION:
				return  @"Actions";
				break;
		}
	}
	
	return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = [indexPath section];
	switch (section)
	{
		case SCHEDULE_SECTION:
			return 50.0;
			break;
			
		case SOCIAL_MEDIA_SECTION:
			return 50.0;
			break;
			
		case CALL_N_EMAIL_SECTION:
			return 50.0;
			break;
			
		default:
			return 50.0;
			break;
	}
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = [indexPath section];
	UITableViewCell *cell = nil;
	
	if(showEventDetail && section == 0)
	{
		// get row number
		NSInteger row = [indexPath row];
		
		// get all schedules
		NSMutableArray *schedules = [dataDictionary objectForKey:@"Schedules"];
		Schedule *time = [schedules objectAtIndex:row];
		
		NSUInteger i, count = [mySchedule count];
		
		for (i = 0; i < count; i++)
		{
			Schedule *obj = [mySchedule objectAtIndex:i];
			if (obj.ID == time.ID)
			{
				time.isSelected = YES;
			}
		}
		
		UILabel *label;
		UILabel *timeLabel;
		UILabel *venueLabel;
		UIButton *checkButton;

		UIImage *buttonImage = (time.isSelected) ? [UIImage imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
		
		cell = [tableView dequeueReusableCellWithIdentifier:kScheduleCellIdentifier];
		if (cell == nil)
		{
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kScheduleCellIdentifier];
			cell.accessoryType = UITableViewCellAccessoryNone;
			
			label = [[UILabel alloc] initWithFrame:CGRectMake(50,2,230,20)];
			label.tag = CELL_TITLE_LABEL_TAG;
			label.font = [UIFont systemFontOfSize:14.0f];
			[cell.contentView addSubview:label];
			
			timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,21,150,20)];
			timeLabel.tag = CELL_TIME_LABEL_TAG;
			timeLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
			[cell.contentView addSubview:timeLabel];
			
			venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(210,21,100,20)];
			venueLabel.tag = CELL_VENUE_LABEL_TAG;
			venueLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
			[cell.contentView addSubview:venueLabel];
			
			checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
			checkButton.frame = CGRectMake(0,0,50,48);
			checkButton.tag = CELL_LEFTBUTTON_TAG;
			[cell.contentView addSubview:checkButton];
		}
		
		label = (UILabel*)[cell viewWithTag:CELL_TITLE_LABEL_TAG];
		label.text = [NSString stringWithFormat:@"Date: %@",time.dateString];
		
		timeLabel = (UILabel*)[cell viewWithTag:CELL_TIME_LABEL_TAG];
		timeLabel.text = [NSString stringWithFormat:@"Time: %@ - %@",time.startTime,time.endTime];
		
		venueLabel = (UILabel*)[cell viewWithTag:CELL_VENUE_LABEL_TAG];
		venueLabel.text = [NSString stringWithFormat:@"Venue: %@",time.venue];
		
		checkButton = (UIButton*)[cell viewWithTag:CELL_LEFTBUTTON_TAG];
		[checkButton setImage:buttonImage forState:UIControlStateNormal];
	}
	else if((showEventDetail && section == 1) || (showNewsDetail && section == 0))
	{
		cell = [tableView dequeueReusableCellWithIdentifier:kSocialCellIdentifier];
		if(cell == nil)
		{
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSocialCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[fbButton addTarget:self action:@selector(pressToShareToFacebook:) forControlEvents:UIControlEventTouchDown];
						
			[fbButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
			[fbButton setImage:[UIImage imageNamed:@"facebook-pressed.png"] forState:UIControlStateHighlighted];
			fbButton.frame = CGRectMake(40, 10, 32, 32);
			[cell.contentView addSubview:fbButton];
			
			UIButton *twButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[twButton addTarget:self action:@selector(pressToShareToTwitter:) forControlEvents:UIControlEventTouchDown];
			
			[twButton setImage:[UIImage imageNamed:@"twitter"] forState:UIControlStateNormal];
			[twButton setImage:[UIImage imageNamed:@"twitter-pressed.png"] forState:UIControlStateHighlighted];
			twButton.frame = CGRectMake(92, 10, 32, 32);
			[cell.contentView addSubview:twButton];
		}
	}
	else if((showEventDetail && section == 2) || (showNewsDetail && section == 1))
	{
		cell = [tableView dequeueReusableCellWithIdentifier:kActionsCellIdentifier];
		if (cell == nil)
		{
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionsCellIdentifier];
			
			cell.textLabel.font = [UIFont systemFontOfSize:16.0f];
		}
		
		switch (indexPath.row)
		{
			case 0:
				cell.textLabel.text = @"Call Cinequest Ticketing Line";
				break;
				
			case 1:
				cell.textLabel.text = @"Email Event Detail";
				break;
				
			default:
				break;
		}
	}
	
    return cell;
}

#pragma mark -
#pragma mark UITableView delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	
	if(showEventDetail && section == 0)
	{
		UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:indexPath];
		
		NSMutableArray *schedules = [dataDictionary objectForKey:@"Schedules"];
		Schedule *time = [schedules objectAtIndex:row];
		
		// set checkBox's status
		BOOL checked = time.isSelected;
		time.isSelected = !checked;
		
		// get the current cell and the checkbox button 
		UIButton *checkBoxButton = (UIButton*)[oldCell viewWithTag:CELL_LEFTBUTTON_TAG];
		
		// set button's image
		UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"unchecked.png"] : [UIImage imageNamed:@"checked.png"];
		[checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
		
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
	else if ((showEventDetail && section == 2) || (showNewsDetail && section == 1))
	{
		switch (row)
		{
			case 0:
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Application will now exit."
															message:@"Are you sure?"
															delegate:self
															cancelButtonTitle:@"Cancel"
															otherButtonTitles:@"OK",nil];
				[alert show];
				break;
			}
				
			case 1:
			{
				MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
				NSString *friendlyMessage = @"Hey, I found an interesting film from Cinequest. Check it out!";
				NSString *messageBody = [NSString stringWithFormat:@"%@\n http://mobile.cinequest.org/event_view.php?eid=%@",friendlyMessage,myData.itemID];
				controller.mailComposeDelegate = self;
				[controller setSubject:myData.title];
				[controller setMessageBody:messageBody isHTML:NO]; 
				delegate.isPresentingModalView = YES;
				[self.navigationController presentViewController:controller animated:YES completion:nil];
				break;
			}
				
			default:
				break;
		}
		
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

#pragma mark -
#pragma mark UIAlertView Delegate

- (void) alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1)
	{
		// NSLog(@"CALL!");
		[app openURL:[NSURL URLWithString:TICKET_LINE]];
	}
	else
	{
		// NSLog(@"cancel");
	}
	
	NSIndexPath *tableSelection = [self.detailsTableView indexPathForSelectedRow];
    [self.detailsTableView deselectRowAtIndexPath:tableSelection animated:YES];
}

#pragma mark -
#pragma mark MFMailComposeViewController Delegate

- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
{
	if (result == MFMailComposeResultSent)
	{
		// NSLog(@"It's away!");
	}
	
	delegate.isPresentingModalView = NO;
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Social Media Sharing

- (IBAction) pressToShareToFacebook:(id)sender
{
    NSString *postString = [NSString stringWithFormat:@"I'm planning to go see %@", myData.title];
    
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

- (IBAction) pressToShareToTwitter:(id)sender
{
    NSString *tweetString = [NSString stringWithFormat:@"I'm planning to go see %@", myData.title];
    
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

#pragma mark -
#pragma mark Decode NSString for HTML

- (NSString *) htmlEntityDecode:(NSString *)string
{
	// string = [string stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
	// string = [string stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    string = [string stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    string = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    
    return string;
}

@end
