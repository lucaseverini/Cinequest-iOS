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
#import "Venue.h"
#import "MapViewController.h"

#define web @"<style type=\"text/css\">h1{font-size:23px;text-align:center;}p.image{text-align:center;}</style><h1>%@</h1><p class=\"image\"><img style=\"max-height:200px;max-width:250px;\"src=\"%@\"/></p><p>%@</p>"

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

	actionFont = [UIFont systemFontOfSize:16.0f];
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
    [self.detailsTableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)] withRowAnimation:UITableViewRowAnimationAutomatic];    
}

- (void) loadData
{
	NSString *cachedImage = [appDelegate.dataProvider cacheImage:[film imageURL]];

	NSString *weba = [NSString stringWithFormat:web, [film name], cachedImage, [film description]];

    if (film.genre != nil && ![film.genre isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Genre</b>: %@<br/>",film.genre];
	}
	
    if (film.director != nil && ![film.genre isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Director</b>: %@<br/>",film.director];
	}
	
    if (film.producer != nil && ![film.producer isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Producer</b>: %@<br/>",film.producer];
	}
	
    if (film.writer != nil && ![film.writer isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Writer</b>: %@<br/>",film.writer];
	}
	
    if (film.cinematographer != nil && ![film.cinematographer isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Cinematographer</b>: %@<br/>",film.cinematographer];
	}
	
    if (film.editor != nil && ![film.editor isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Editor</b>: %@<br/>",film.editor];
	}
	
    if (film.cast != nil && ![film.cast isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Cast</b>: %@<br/>",film.cast];
	}
	
    if (film.country != nil && ![film.country isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Country</b>: %@<br/>",film.country];
	}
	
    if (film.language != nil && ![film.language isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Language</b>: %@<br/>",film.language];
	}
	
    if (film.filmInfo != nil && ![film.filmInfo isEqualToString:@""])
	{
        weba = [weba stringByAppendingFormat:@"<b>Film Info</b>: %@<br/>",film.filmInfo];
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
			return 1;
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
			answer = @"Share Film Detail";
			break;
			
		case CALL_N_EMAIL_SECTION:
			answer = @"Ticket Information";
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
			return 70.0;
			break;
			
		case CALL_N_EMAIL_SECTION:
			return 70.0;
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
			
			UILabel *timeLabel = nil;
			UILabel *venueLabel = nil;
			UIButton *calButton = nil;
			UIButton *mapsButton = nil;
			
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
				calButton.tag = CELL_LEFTBUTTON_TAG;
				[calButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				[cell.contentView addSubview:calButton];

				mapsButton = [UIButton buttonWithType:UIButtonTypeCustom];
				mapsButton.frame = CGRectMake(274.0, 5.0, 32.0, 32.0);
				mapsButton.tag = CELL_RIGHTBUTTON_TAG;
				[mapsButton setImage:[UIImage imageNamed:@"maps.png"] forState:UIControlStateNormal];
				[mapsButton addTarget:self action:@selector(mapsButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				[cell.contentView addSubview:mapsButton];
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
                fbButton.frame = CGRectMake(24.0, 10.0, 32.0, 32.0);
                [fbButton addTarget:self action:@selector(pressToShareToFacebook:) forControlEvents:UIControlEventTouchDown];
                [fbButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:fbButton];
                
                UILabel *lblFacebook = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 42.0, 56.0, 20)];
                lblFacebook.text = @"Facebook";
                [lblFacebook setFont:[UIFont systemFontOfSize:12.0]];
                [lblFacebook setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblFacebook];
                
                UIButton *twButton = [UIButton buttonWithType:UIButtonTypeCustom];
				twButton.frame = CGRectMake(104.0, 10.0, 32.0, 32.0);
				[twButton addTarget:self action:@selector(pressToShareToTwitter:) forControlEvents:UIControlEventTouchDown];
                [twButton setImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:twButton];

                UILabel *lblTwitter = [[UILabel alloc] initWithFrame:CGRectMake(92.0, 42.0, 56.0, 20)];
                lblTwitter.text = @"Twitter";
                [lblTwitter setFont:[UIFont systemFontOfSize:12.0]];
                [lblTwitter setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblTwitter];

				UIButton *googleButton = [UIButton buttonWithType:UIButtonTypeCustom];
				googleButton.frame = CGRectMake(192.0, 10.0, 32.0, 32.0);
				[googleButton addTarget:self action:@selector(shareToGooglePlus:) forControlEvents:UIControlEventTouchDown];
                [googleButton setImage:[UIImage imageNamed:@"googleplus.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:googleButton];
                
                UILabel *lblGoogle = [[UILabel alloc] initWithFrame:CGRectMake(180.0, 42.0, 56.0, 20)];
                lblGoogle.text = @"Google+";
                [lblGoogle setFont:[UIFont systemFontOfSize:12.0]];
                [lblGoogle setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblGoogle];

				UIButton *mailButton = [UIButton buttonWithType:UIButtonTypeCustom];
				mailButton.frame = CGRectMake(272.0, 10.0, 32.0, 32.0);
				[mailButton addTarget:self action:@selector(shareToMail:) forControlEvents:UIControlEventTouchDown];
                [mailButton setImage:[UIImage imageNamed:@"mail.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:mailButton];
                
                UILabel *lblMail = [[UILabel alloc] initWithFrame:CGRectMake(260.0, 42.0, 56.0, 20)];
                lblMail.text = @"Email";
                [lblMail setFont:[UIFont systemFontOfSize:12.0]];
                [lblMail setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblMail];
                
			}
			
			break;
		}
			
		case CALL_N_EMAIL_SECTION:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:ActionsIdentifier];
			if (cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActionsIdentifier];

				UIButton *phoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
				phoneButton.frame = CGRectMake(20.0, 10.0, 32.0, 32.0);
				[phoneButton addTarget:self action:@selector(callTicketLine:) forControlEvents:UIControlEventTouchDown];
                [phoneButton setImage:[UIImage imageNamed:@"phone-Ticket.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:phoneButton];
                
                UILabel *lblPhone = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 42.0, 56.0, 20)];
                lblPhone.text = @"Call CQ";
                [lblPhone setFont:[UIFont systemFontOfSize:12.0]];
                [lblPhone setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblPhone];
				
				UIButton *linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
				linkButton.frame = CGRectMake(110.0, 10.0, 32.0, 32.0);
				[linkButton addTarget:self action:@selector(goTicketLink:) forControlEvents:UIControlEventTouchDown];
                [linkButton setImage:[UIImage imageNamed:@"link-Ticket.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:linkButton];
                
                UILabel *lblWebsite = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 42.0, 56.0, 20)];
                lblWebsite.text = @"Website";
                [lblWebsite setFont:[UIFont systemFontOfSize:12.0]];
                [lblWebsite setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblWebsite];
			}
		}
			break;
			
		default:
			break;
	}
	
    return cell;
}

#pragma mark -
#pragma mark UITableView delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark -
#pragma mark MFMailComposeViewController Delegate

- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	delegate.isPresentingModalView = NO;
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Social Media Sharing

- (IBAction) pressToShareToFacebook:(id)sender
{
    NSString *postString = [NSString stringWithFormat:@"I'm planning to go see %@", [film name]];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *faceSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
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

- (IBAction) pressToShareToTwitter:(id)sender
{
    NSString *tweetString = [NSString stringWithFormat:@"I'm planning to go see %@", [film name]];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
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

- (IBAction) shareToMail:(id)sender
{
	MFMailComposeViewController *controller = [MFMailComposeViewController new];
	NSString *friendlyMessage = @"Hey,\nI found an interesting film from Cinequest festival.\nCheck it out!";
	NSString *messageBody = [NSString stringWithFormat:@"%@\n http://mobile.cinequest.org/event_view.php?eid=%@", friendlyMessage, [film ID]];
	controller.mailComposeDelegate = self;
	[controller setSubject:[film name]];
	[controller setMessageBody:messageBody isHTML:NO];
	
	delegate.isPresentingModalView = YES;
	[self.navigationController presentViewController:controller animated:YES completion:nil];
	[[[[controller viewControllers] lastObject] navigationItem] setTitle:@"Set the title"];
}

- (IBAction) shareToGooglePlus:(id)sender
{
}

- (IBAction) callTicketLine:(id)sender
{
}

- (IBAction) goTicketLink:(id)sender
{
}

- (void) mapsButtonTapped:(id)sender event:(id)touchEvent
{
	Schedule *schedule = [self getItemForSender:sender event:touchEvent];
	if(schedule != nil)
	{
		[self showMapWithVenue:schedule.venueItem];
	}
	else
	{
		NSLog(@"Schedule is nil!!");
	}
}

- (void) calendarButtonTapped:(id)sender event:(id)touchEvent
{
	Schedule *schedule = [self getItemForSender:sender event:touchEvent];
    schedule.isSelected ^= YES;
    
    //Call to Delegate to Add/Remove from Calendar
    [delegate addToDeviceCalendar:schedule];
    [delegate addOrRemoveFilm:schedule];
    
    NSLog(@"Schedule:ID+ItemID:%@-%@",schedule.ID,schedule.itemID);
    UIButton *checkBoxButton = (UIButton*)sender;
    UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
    [checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
}

- (Schedule*) getItemForSender:(id)sender event:(id)touchEvent
{
    NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.detailsTableView];
	NSIndexPath *indexPath = [self.detailsTableView indexPathForRowAtPoint:currentTouchPosition];
	NSInteger row = [indexPath row];
	Schedule *schedule = nil;
	if(indexPath != nil)
	{
		NSMutableArray *schedules = [film schedules];
		schedule = [schedules objectAtIndex:row];
    }
    
    return schedule;
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

- (void) showMapWithVenue:(Venue*)venue
{
	MapViewController *mapViewController = [[MapViewController alloc] initWithNibName:@"MapViewController" andVenue:venue];
	mapViewController.hidesBottomBarWhenPushed = YES;
	[[self navigationController] pushViewController:mapViewController animated:YES];
}

@end






