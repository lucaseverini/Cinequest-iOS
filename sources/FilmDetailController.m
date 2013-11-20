//
//  FilmDetailController.m
//  CineQuest
//
//  Created by Loc Phan on 10/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FilmDetailController.h"
#import "DDXML.h"
#import "Schedule.h"
#import "CinequestAppDelegate.h"
#import "DataProvider.h"
#import "Festival.h"
#import "Film.h"

#define web @"<style type=\"text/css\">h1{font-size:23px;text-align:center;}p.image{text-align:center;}</style><h1>%@</h1><p class=\"image\"><img style=\"max-height:100px;max-width:150px;\"src=\"%@\"/></p><p>%@</p>"

static NSString *kGetSessionProxy = nil;
static NSString *kApiKey	= @"d944f2ee4f658052fd27137c0b9ff276";
static NSString *kApiSecret = @"e4070331e81e43de67c009c8f7ace326";
static char *const kAssociatedScheduleKey = "Schedule";

@implementation FilmDetailController

@synthesize detailsTableView;
@synthesize webView;
@synthesize activityIndicator;
@synthesize film;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UIViewController Methods

- (id) initWithTitle:(NSString*)name andId:(NSString*)Id
{
	self = [super init];
	if(self != nil)
	{
		delegate = appDelegate;
		mySchedule = delegate.mySchedule;
		
		self.navigationItem.title = name;
		
		film = [delegate.festival getFilmForId:Id];
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.detailsTableView.hidden = YES;
	self.view.userInteractionEnabled = NO;

	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	venueFont = timeFont;

	self.activityIndicator.color = [UIColor grayColor];
	
	[(UIWebView*)self.detailsTableView.tableHeaderView setSuppressesIncrementalRendering:YES]; // Avoids scrolling problems when the WebView is showed

	[self.activityIndicator startAnimating];

    [self performSelectorOnMainThread:@selector(loadData) withObject:nil waitUntilDone:NO];
	
	[self.detailsTableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void) loadData
{
	NSString *weba = [NSString stringWithFormat:web,[film name],[film imageURL],[film description]];

    if (film.genre != nil)
	{
        weba = [weba stringByAppendingFormat:@"Genre: %@<br/>",film.genre];
	}
	
    if (film.director != nil)
	{
        weba = [weba stringByAppendingFormat:@"Director: %@<br/>",film.director];
	}
	
    if (film.producer != nil)
	{
        weba = [weba stringByAppendingFormat:@"Producer: %@<br/>",film.producer];
	}
	
    if (film.writer != nil)
	{
        weba = [weba stringByAppendingFormat:@"Writer: %@<br/>",film.writer];
	}
	
    if (film.cinematographer != nil)
	{
        weba = [weba stringByAppendingFormat:@"Cinematographer: %@<br/>",film.cinematographer];
	}
	
    if (film.editor != nil)
	{
        weba = [weba stringByAppendingFormat:@"Editor: %@<br/>",film.editor];
	}
	
    if (film.cast != nil)
	{
        weba = [weba stringByAppendingFormat:@"Cast: %@<br/>",film.cast];
	}
	
    if (film.country != nil)
	{
        weba = [weba stringByAppendingFormat:@"Country: %@<br/>",film.country];
	}
	
    if (film.language != nil)
	{
        weba = [weba stringByAppendingFormat:@"Director: %@<br/>",film.language];
	}
	
    if (film.filmInfo != nil)
	{
        weba = [weba stringByAppendingFormat:@"Film Info: %@<br/>",film.filmInfo];
	}
	
	[webView loadHTMLString:weba baseURL:nil];
}

#pragma mark -
#pragma mark UIWebView delegate

- (void) webViewDidFinishLoad:(UIWebView *)_webView
{
	// Updates the WebView and force it to redisplay correctly 
	[self.detailsTableView.tableHeaderView sizeToFit];
	[self.detailsTableView setTableHeaderView:self.detailsTableView.tableHeaderView];

	[self.activityIndicator stopAnimating];
	
	self.view.userInteractionEnabled = YES;
	self.detailsTableView.hidden = NO;
}

#pragma mark - UITableView Datasource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		default:
			return 1;
			break;

		case SCHEDULE_SECTION:
			return [[film schedules] count];
			break;
			
		case SOCIAL_MEDIA_SECTION:
			return 1;
			break;
			
		case CALL_N_EMAIL_SECTION:
			return 2;
			break;
	}
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *answer = nil;
	
	switch(section)
	{
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

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = [indexPath section];
	switch (section)
	{
		case SCHEDULE_SECTION:
			return 42.0;
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
	static NSString *ScheduleCellID		= @"ScheduleCell";
	static NSString *FacebookIdentifier = @"FBCell";
	static NSString *ActionsIdentifier	= @"ActCell";
	
	NSInteger section = [indexPath section];
	
	UITableViewCell *cell;
	switch (section)
	{
		case SCHEDULE_SECTION:
		{
			// get row number
			NSInteger row = [indexPath row];
			
			// get all schedules
			NSMutableArray *schedules = [film schedules];
			Schedule *schedule = [schedules objectAtIndex:row];
						
			NSUInteger idx, count = [mySchedule count];
			for (idx = 0; idx < count; idx++)
			{
				Schedule *obj = [mySchedule objectAtIndex:idx];
				if (obj.ID == schedule.ID)
				{
					schedule.isSelected = YES;
				}
			}
			
			UILabel *timeLabel;
			UILabel *venueLabel;
			UIButton *calButton;

			UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];

			cell = [tableView dequeueReusableCellWithIdentifier:ScheduleCellID];
			if (cell == nil)
			{
				// init cell
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ScheduleCell"];
				
				timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 2.0, 250.0, 20.0)];
				timeLabel.tag = CELL_TIME_LABEL_TAG;
				timeLabel.font = timeFont;
				[cell.contentView addSubview:timeLabel];
				
				venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 21.0, 250.0, 20.0)];
				venueLabel.tag = CELL_VENUE_LABEL_TAG;
				venueLabel.font = venueFont;
				[cell.contentView addSubview:venueLabel];
				
				calButton = [UIButton buttonWithType:UIButtonTypeCustom];
				calButton.frame = CGRectMake(11.0, 5.0, 32.0, 32.0);
				[calButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				calButton.tag = CELL_LEFTBUTTON_TAG;
				[cell.contentView addSubview:calButton];
			}
			
			timeLabel = (UILabel*)[cell viewWithTag:CELL_TIME_LABEL_TAG];
			timeLabel.text = [NSString stringWithFormat:@"%@ %@ - %@", schedule.dateString, schedule.startTime, schedule.endTime];

			venueLabel = (UILabel*)[cell viewWithTag:CELL_VENUE_LABEL_TAG];
			venueLabel.text = [NSString stringWithFormat:@"Venue: %@", schedule.venue];
			
			calButton = (UIButton*)[cell viewWithTag:CELL_LEFTBUTTON_TAG];
			[calButton setImage:buttonImage forState:UIControlStateNormal];

			break;
		}
		
		case SOCIAL_MEDIA_SECTION:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:FacebookIdentifier];
			if (cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FacebookIdentifier];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				
                UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [fbButton addTarget:self action:@selector(pressToShareToFacebook:) forControlEvents:UIControlEventTouchDown];
                
                [fbButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
                [fbButton setImage:[UIImage imageNamed:@"facebook-pressed.png"] forState:UIControlStateHighlighted];
                [fbButton setBackgroundColor:[UIColor clearColor]];
                fbButton.frame = CGRectMake(40, 10, 32, 32);
                [cell.contentView addSubview:fbButton];
                
                UIButton *twButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [twButton addTarget:self action:@selector(pressToShareToTwitter:) forControlEvents:UIControlEventTouchDown];
                
                [twButton setImage:[UIImage imageNamed:@"twitter"] forState:UIControlStateNormal];
                [twButton setImage:[UIImage imageNamed:@"twitter-pressed.png"] forState:UIControlStateHighlighted];
                [twButton setBackgroundColor:[UIColor clearColor]];
                twButton.frame = CGRectMake(92, 10, 32, 32);
                [cell.contentView addSubview:twButton];
            }
			break;
		}
			
		case CALL_N_EMAIL_SECTION:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:ActionsIdentifier];
			if (cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActionsIdentifier];
			}
			
			switch (indexPath.row)
			{
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	
	if (section == SCHEDULE_SECTION)
	{
		NSMutableArray *schedules = [film schedules];
		Schedule *schedule = [schedules objectAtIndex:row];
		
		[self actionForFilm:schedule];
	}
	else if (section == CALL_N_EMAIL_SECTION)
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
				alert.tag = 2;
				[alert show];
				break;
			}
				
			case 1:
			{
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
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UIAlertView Delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(alertView.tag == 1)
	{
		[[self navigationController] popToRootViewControllerAnimated:YES];
		return;
	}
	else if(alertView.tag == 2)
	{
		Schedule *schedule = objc_getAssociatedObject(alertView, kAssociatedScheduleKey);
		
		switch(buttonIndex)
		{
			case 1:			// choice1
				break;
				
			case 2:			// choice2
				break;
				
			case 3:			// choice3
				if(schedule.presentInScheduler)
				{
					[self launchMaps];
				}
				else
				{
					// Open calendar
				}
				break;
				
			case 4:			// choice4
				if(!schedule.presentInScheduler)
				{
					[self launchMaps];
				}
				break;
				
			default:		// Cancel
				break;
		}
	}
	
	if (buttonIndex == 1)
	{
		[app openURL:[NSURL URLWithString:TICKET_LINE]];
	}
	else
	{
	}
	
	NSIndexPath *tableSelection = [self.detailsTableView indexPathForSelectedRow];
    [self.detailsTableView deselectRowAtIndexPath:tableSelection animated:YES];
}

#pragma mark -
#pragma mark MFMailComposeViewController Delegate

- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	if (result == MFMailComposeResultSent)
	{
		//NSLog(@"It's away!");
	}
	
	delegate.isPresentingModalView = NO;
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Social Media Sharing

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
		alertView.tag = 3;
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
		alertView.tag = 4;
        [alertView show];
    }
}

- (void) calendarButtonTapped:(id)sender event:(id)touchEvent
{
	NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.detailsTableView];
	NSIndexPath *indexPath = [self.detailsTableView indexPathForRowAtPoint:currentTouchPosition];
	NSInteger row = [indexPath row];
	
	if(indexPath != nil)
	{
		NSMutableArray *schedules = [film schedules];
		Schedule *schedule = [schedules objectAtIndex:row];

		schedule.isSelected ^= YES;
		
		UIButton *checkBoxButton = (UIButton*)sender;
		UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
		[checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
	}
}

- (void) actionForFilm:(Schedule*)schedule
{
	schedule.presentInScheduler = !schedule.isSelected;
	schedule.presentInCalendar = !schedule.isSelected;
	
	NSString *choice1 = nil;
	NSString *choice2 = nil;
	NSString *choice3 = nil;
	NSString *choice4 = nil;
	
	if(schedule.presentInScheduler)
	{
		choice1 = schedule.presentInCalendar ? @"Remove from My Schedule & Calendar" : @"Remove from My Schedule";
		choice2 = schedule.presentInCalendar ? @"Show in Calendar" : @"Add to Calendar";
		choice3 = @"Show Venue location in Maps";
	}
	else
	{
		choice1 = @"Add to My Schedule";
		choice2 = @"Add to My Schedule and Calendar";
		choice3 = @"Show in Calendar";
		choice4 = @"Show Venue location in Maps";
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:choice1, choice2, choice3, choice4, nil];
	
	objc_setAssociatedObject(alert, kAssociatedScheduleKey, schedule, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	alert.tag = 2;
	[alert show];
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

@end
