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

#define web @"<style type=\"text/css\">h1{font-size:23px;text-align:center;}p.image{text-align:center;}</style><h1>%@</h1><p>%@</p>"


@interface EventDetailViewController (Private)

- (void)parseData;
- (IBAction)addAction:(id)sender;

@end

@implementation EventDetailViewController

#pragma mark -
#pragma mark Memory Management

@synthesize tableView = _tableView;
@synthesize webView = _webView;
@synthesize activity;
@synthesize displayAddButton;

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UIViewController
static NSString *kGetSessionProxy = nil;
static NSString *kApiKey	= @"d944f2ee4f658052fd27137c0b9ff276";
static NSString *kApiSecret = @"e4070331e81e43de67c009c8f7ace326";

- (id)initWithTitle:(NSString*)name andDataObject:(Schedule*)dataObject andURL:(NSURL*)link {
    if (self = [super init]) 
	{
		self.title = @"Event Detail";
		dataLink = link;
		dataDictionary = [[NSMutableDictionary  alloc] init];
		
		myData = [[Schedule alloc] init];
		myData.ID = dataObject.ID;
		myData.title = dataObject.title;
		myData.prog_id = dataObject.prog_id;
		
		if (kGetSessionProxy) {
			_session = [FBSession sessionForApplication:kApiKey 
										 getSessionProxy:kGetSessionProxy
												delegate:self];
		} else {
			_session = [FBSession sessionForApplication:kApiKey secret:kApiSecret delegate:self];
		}
    }
    return self;
}
- (void)viewDidLoad {
	self.tableView.hidden = YES;
	self.view.userInteractionEnabled = NO;
	if (displayAddButton) {
		UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add"
																	   style:UIBarButtonItemStyleDone
																	  target:self
																	  action:@selector(addAction:)];
		self.navigationItem.rightBarButtonItem = addButton;
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
	if ([appDelegate connectedToNetwork]) {
		[NSThread detachNewThreadSelector:@selector(parseData) toTarget:self withObject:nil];
	} else {
		//alert
	}

	[super viewDidLoad];
	
	delegate = appDelegate;
	mySchedule = delegate.mySchedule;
}
- (void)viewWillAppear:(BOOL)animated {
	[self.tableView reloadData];
}
- (void)parseData {
    
	@autoreleasepool {
        
        NSData *data = [NSData dataWithContentsOfURL:dataLink];
        DDXMLDocument *xmlDocument = [[DDXMLDocument alloc] initWithData:data
                                                                 options:0
                                                                   error:nil];
        
        DDXMLNode *rootElement = [xmlDocument rootElement];
        //NSLog(@"%d",[rootElement childCount]);
        
        for (int i=0;i<[rootElement childCount]; i++) {
            DDXMLNode *element = [rootElement childAtIndex:i];
            NSString *elementName = [element name];
            //NSLog(@"elementName: %@",elementName);
            if ([elementName isEqualToString:@"title"]) {
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
                        event.ID		= [ID integerValue];
                        event.prog_id	= [prg_item_id integerValue];
                        event.type		= @"event";
                        event.venue		= venue;
                        
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
    }
	
	app.networkActivityIndicatorVisible = NO;
	
	[self performSelectorOnMainThread:@selector(loadData) withObject:nil waitUntilDone:YES];
}
- (void)loadData {
	NSString *weba = [NSString stringWithFormat:web,[dataDictionary objectForKey:@"Title"]
					  ,[dataDictionary objectForKey:@"Description"]];
	
	//NSLog(@"%@",weba);
    
	weba = [self htmlEntityDecode:weba];    //Render HTML properly
	weba = [weba stringByAppendingString:@"<br/>"];
	[self.webView loadHTMLString:weba baseURL:nil];	
}

#pragma mark -
#pragma mark UIWebView delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {
	
	UIWebView *webview = (UIWebView*) self.tableView.tableHeaderView;
	//NSLog(@"BEFORE: %f",webview.frame.origin.x);
	
	[webview sizeToFit];
	double height = webview.frame.size.height;
	double width = webview.frame.size.width;
	[webview setFrame:CGRectMake(0,0,width,height)];
	
	//NSLog(@"AFTER: %f Wanted: %f",webview.frame.size.height,height);
	
	[self.tableView setTableHeaderView:webview];
	[activity stopAnimating];
	[self.tableView reloadData];
	self.navigationItem.rightBarButtonItem.enabled = YES;
	self.tableView.hidden = NO;
	self.view.userInteractionEnabled = YES;
}
#pragma mark -
#pragma mark Actions
- (void)postToFacebook:(id)sender {
	postThisButton.enabled = NO;
	[self session:_session didLogin:facebookID];
}
- (IBAction)addAction:(id)sender {
	
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
	[self.tableView reloadData];
	
	UIAlertView *alert;
	if (addedCount > 0) 
	{
		alert = [[UIAlertView alloc] initWithTitle:@"Attention!"
										   message:[NSString stringWithFormat:@"%@ is added to your schedule.",myData.title]
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
#pragma mark UITableView Datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (displayAddButton) return 3;
    return 0;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int result = 1;
	switch (section) {
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
- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *answer;
	
	switch (section) {
		case SCHEDULE_SECTION:
			answer = @"Schedules";
			break;
		case SOCIAL_MEDIA_SECTION:
			answer = @"Facebook";
			break;
		case CALL_N_EMAIL_SECTION:
			answer = @"Actions";
			break;
	}
	
    return answer;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 50;
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
			UIButton *postButton;
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FacebookIdentifier];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				
				FBLoginButton *loginButton = [[FBLoginButton alloc] initWithFrame:CGRectMake(40,15,100,20)];
				loginButton.style = FBLoginButtonStyleWide;
				[cell.contentView addSubview:loginButton];
				
				postButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
				postButton.tag = CELL_FACEBOOKBUTTON_TAG;
				postButton.frame = CGRectMake(200,10,100,30);
				[postButton setTitle:@"Post This" forState:UIControlStateNormal];
				[postButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
				[postButton addTarget:self action:@selector(postToFacebook:) forControlEvents:UIControlEventTouchUpInside];
				postThisButton = postButton;
				[cell.contentView addSubview:postButton];
			}
			postButton = (UIButton*)[cell.contentView viewWithTag:CELL_FACEBOOKBUTTON_TAG];
			if (!delegate.isLoggedInFacebook) postButton.enabled = NO;
			else postButton.enabled = YES;
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
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int section = [indexPath section];
	int row = [indexPath row];
	
	if (section == SCHEDULE_SECTION) {
		UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:indexPath];
		
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
		
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
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
				NSString *messageBody = [NSString stringWithFormat:@"%@\n http://mobile.cinequest.org/event_view.php?eid=%d",friendlyMessage,myData.prog_id];
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
#pragma mark FBSession Delegate
- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	delegate.isLoggedInFacebook = YES;
	facebookID = uid;
	NSString *fql = [NSString stringWithFormat:
					 @"select uid,name from user where uid == %lld", session.uid];
	
	NSDictionary* params = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	[[FBRequest requestWithDelegate:self] call:@"facebook.fql.query" params:params];
}
#pragma mark -
#pragma mark FBRequest Delegate
- (void)request:(FBRequest*)request didLoad:(id)result {
	postThisButton.enabled = YES;
	NSString *attachment = [NSString stringWithFormat:@"{\"name\":\"%@\",\"href\":\"http://mobile.cinequest.org/event_view.php?eid=%d\",\"description\":\"Hey, I found an interesting film from Cinequest. Check it out!\"}",myData.title,myData.prog_id];
	FBStreamDialog* dialog = [[FBStreamDialog alloc] init];
	dialog.delegate = self;
	dialog.userMessagePrompt = @"I'm going to see this awesome movie. Check it out!";
	dialog.attachment = attachment;
	[dialog show];
}
- (void)sessionDidLogout:(FBSession*)session {
	postThisButton.enabled = NO;
	delegate.isLoggedInFacebook = NO;
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Decode NSString for HTML

-(NSString *)htmlEntityDecode:(NSString *)string
{
//    string = [string stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
//    string = [string stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    string = [string stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    string = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    
    return string;
}

@end
