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
#import "Festival.h"
#import "Film.h"

#define web @"<style type=\"text/css\">h1{font-size:23px;text-align:center;}p.image{text-align:center;}</style><h1>%@</h1><p class=\"image\"><img style=\"max-height:100px;max-width:150px;\"src=\"%@\"/></p><p>%@</p>"

#define VIEW_BY_DATE	0
#define VIEW_BY_TITLE	1

@interface FilmDetail (Private)

- (void)parseData;

- (IBAction)addAction:(id)sender;

@end

@implementation FilmDetail

@synthesize tableView = _tableView;
@synthesize webView;
@synthesize activityIndicator;
@synthesize film;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UIViewController Methods

static NSString *kGetSessionProxy = nil;
static NSString *kApiKey	= @"d944f2ee4f658052fd27137c0b9ff276";
static NSString *kApiSecret = @"e4070331e81e43de67c009c8f7ace326";

- (id) initWithTitle:(NSString*)name from:(NSUInteger)viewBy andId:(NSString *)ID
{
	self = [super init];
	if(self != nil)
	{
		self.navigationItem.title = name;
        delegate = appDelegate;
        if (viewBy == VIEW_BY_DATE) {
            // A Film already has an array of Schedules with it
            film = [delegate.festival getFilmForId:ID];
        } else { // I use this generic approach for now, will change it later.
            film = [delegate.festival getFilmForId:ID];
        }
    }
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	mySchedule = delegate.mySchedule;
	
	self.tableView.hidden = YES;
	self.view.userInteractionEnabled = NO;
	
    [self performSelectorOnMainThread:@selector(loadData) withObject:nil waitUntilDone:YES];
}

- (void) viewWillAppear:(BOOL)animated
{
	[self.tableView reloadData];
}

   
- (void)loadData
{
	NSString *weba = [NSString stringWithFormat:web,[film name],[film imageURL],[film description]];

    if (film.genre != nil)
        weba = [weba stringByAppendingFormat:@"Genre: %@<br/>",film.genre];
    if (film.director != nil)
        weba = [weba stringByAppendingFormat:@"Director: %@<br/>",film.director];
    if (film.producer != nil)
        weba = [weba stringByAppendingFormat:@"Producer: %@<br/>",film.producer];
    if (film.writer != nil)
        weba = [weba stringByAppendingFormat:@"Writer: %@<br/>",film.writer];
    if (film.cinematographer != nil)
        weba = [weba stringByAppendingFormat:@"Cinematographer: %@<br/>",film.cinematographer];
    if (film.editor != nil)
        weba = [weba stringByAppendingFormat:@"Editor: %@<br/>",film.editor];
    if (film.cast != nil)
        weba = [weba stringByAppendingFormat:@"Cast: %@<br/>",film.cast];
    if (film.country != nil)
        weba = [weba stringByAppendingFormat:@"Country: %@<br/>",film.country];
    if (film.language != nil)
        weba = [weba stringByAppendingFormat:@"Director: %@<br/>",film.language];
    if (film.filmInfo != nil)
        weba = [weba stringByAppendingFormat:@"Film Info: %@<br/>",film.filmInfo];
	
	[webView loadHTMLString:weba baseURL:nil];
}

#pragma mark - Actions

- (IBAction) addAction:(id)sender
{
	// get all schedules that has checked items
	NSMutableArray *schedules = [film schedules];
	
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
										   message:[NSString stringWithFormat:@"%@ is added to your schedule.",[film name]]
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

#pragma mark - UIWebView delegate

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
	self.view.userInteractionEnabled = YES;
}

#pragma mark - UITableView Datasource

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
			result = [[film schedules] count];
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
			NSMutableArray *schedules = [film schedules];
			Schedule *time = [schedules objectAtIndex:row];
			
			UIColor *textColor = [UIColor blackColor];
			BOOL userInteraction = YES;
			
			NSUInteger i, count = [mySchedule count];
			
			for (i = 0; i < count; i++) {
				Schedule *obj = [mySchedule objectAtIndex:i];
				if ([obj.ID isEqualToString:time.ID]) {
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
			timeLabel.text = [NSString stringWithFormat:@"Time: %@ - %@",time.startTime,time.endTime];
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
#pragma mark - UITableView delegate
- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	int section = [indexPath section];
	int row = [indexPath row];
	
	if (section == SCHEDULE_SECTION)
	{
		UITableViewCell *oldCell = [atableView cellForRowAtIndexPath:indexPath];
		
		NSMutableArray *schedules = [film schedules];
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
				NSString *messageBody = [NSString stringWithFormat:@"%@\n http://mobile.cinequest.org/event_view.php?eid=%@",friendlyMessage,[film ID]];
				controller.mailComposeDelegate = self;
				[controller setSubject:[film name]];
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
#pragma mark - UIAlertView Delegate
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

#pragma mark - MFMailComposeViewController Delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error; {
	if (result == MFMailComposeResultSent) {
		//NSLog(@"It's away!");
	}
	delegate.isPresentingModalView = NO;
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Social Media Sharing

- (IBAction)pressToShareToFacebook:(id)sender
{
    NSString *postString = [NSString stringWithFormat:@"I'm planning to go see %@", [film name]];
    
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
    NSString *tweetString = [NSString stringWithFormat:@"I'm planning to go see %@", [film name]];
    
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
