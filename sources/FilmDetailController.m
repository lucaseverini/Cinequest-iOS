//
//  FilmDetailController.m
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
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
#import "GPlusDialogView.h"
#import "GPlusDialogViewController.h"


#define web @"<style type=\"text/css\">h1{font-size:23px;text-align:center;}p.image{text-align:center;}</style><h1>%@</h1><p class=\"image\"><img style=\"max-height:200px;max-width:250px;\"src=\"%@\"/></p><p>%@</p>"

static char *const kAssociatedScheduleKey = "Schedule";
static NSString *kShortProgCellID = @"ShortProgCell";
static NSString *kScheduleCellID = @"ScheduleCell";
static NSString *kSocialMediaCellID = @"SocialMediaCell";
static NSString *kActionsCellID	= @"ActionsCell";


@implementation NSString (GTMNSStringURLArgumentsAdditions)

- (NSString*) gtm_stringByEscapingForURLArgument
{
	// Encode all the reserved characters, per RFC 3986 (<http://www.ietf.org/rfc/rfc3986.txt>)
	CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (CFStringRef)self,
                                            NULL,
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8);
	return CFBridgingRelease(escaped);
}

- (NSString*) gtm_stringByUnescapingFromURLArgument
{
	NSMutableString *resultString = [NSMutableString stringWithString:self];
	[resultString replaceOccurrencesOfString:@"+"
										withString:@" "
										options:NSLiteralSearch
										range:NSMakeRange(0, [resultString length])];
	
	return [resultString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end


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

- (id) initWithTitle:(NSString*)title andId:(NSString*)Id
{
	self = [super init];
	if(self != nil)
	{
		delegate = appDelegate;
		mySchedule = delegate.mySchedule;
		
		self.navigationItem.title = title;
		
		film = [delegate.festival getFilmForId:Id];
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[GPPSignIn sharedInstance].delegate = self;
	[GPPSignIn sharedInstance].clientID = GOOGLEPLUS_CLIENTID;
	[GPPSignIn sharedInstance].shouldFetchGooglePlusUser = YES;
	[GPPSignIn sharedInstance].shouldFetchGoogleUserEmail = YES;
	[GPPSignIn sharedInstance].shouldFetchGoogleUserID = YES;
	[GPPSignIn sharedInstance].scopes = @[ kGTLAuthScopePlusLogin ];

	self.detailsTableView.hidden = YES;
	self.view.userInteractionEnabled = NO;
    
	titleFont = [UIFont systemFontOfSize:14.0];
	actionFont = [UIFont systemFontOfSize:16.0];
	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	venueFont = timeFont;
	
	UISegmentedControl *switchTitle = [[UISegmentedControl alloc] initWithFrame:CGRectMake(98.5, 7.5, 123.0, 29.0)];
	[switchTitle insertSegmentWithTitle:[NSString stringWithFormat:@"%@ Detail", self.navigationItem.title] atIndex:0 animated:NO];
	[switchTitle setSelectedSegmentIndex:0];
	NSDictionary *attribute = [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:16.0f] forKey:NSFontAttributeName];
	[switchTitle setTitleTextAttributes:attribute forState:UIControlStateNormal];
	self.navigationItem.titleView = switchTitle;
	
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

    if (film.genre.length)
	{
        weba = [weba stringByAppendingFormat:@"<b>Genre</b>: %@<br/>",film.genre];
	}
	
    if (film.director.length != 0)
	{
        weba = [weba stringByAppendingFormat:@"<b>Director</b>: %@<br/>",film.director];
	}
	
    if (film.producer.length)
	{
        weba = [weba stringByAppendingFormat:@"<b>Producer</b>: %@<br/>",film.producer];
	}
	
    if (film.writer.length)
	{
        weba = [weba stringByAppendingFormat:@"<b>Writer</b>: %@<br/>",film.writer];
	}
	
    if (film.cinematographer.length)
	{
        weba = [weba stringByAppendingFormat:@"<b>Cinematographer</b>: %@<br/>",film.cinematographer];
	}
	
    if (film.editor.length)
	{
        weba = [weba stringByAppendingFormat:@"<b>Editor</b>: %@<br/>",film.editor];
	}
	
    if (film.cast.length)
	{
        weba = [weba stringByAppendingFormat:@"<b>Cast</b>: %@<br/>",film.cast];
	}
	
    if (film.country.length)
	{
        weba = [weba stringByAppendingFormat:@"<b>Country</b>: %@<br/>",film.country];
	}
	
    if (film.language.length)
	{
        weba = [weba stringByAppendingFormat:@"<b>Language</b>: %@<br/>", film.language];
	}
	
    if (film.filmInfo.length)
	{
        weba = [weba stringByAppendingFormat:@"<b>Film Info</b>: %@<br/>", film.filmInfo];
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
	return 4;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case SHORT_PROGRAM_SECTION:
			return [[film shortItems] count];
			break;

		case SCHEDULE_SECTION:
			return [[film schedules] count];
			break;
			
		case SOCIAL_MEDIA_SECTION:
			return 1;
			break;
			
		case ACTION_SECTION:
			return 1;
			break;
	}
	
	return 0;
}

#pragma mark -
#pragma mark UITableView delegate

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;
	
	switch(section)
	{
		case SHORT_PROGRAM_SECTION:
			if([[film shortItems] count] > 0)
			{
				title = @"Short Programs";
			}
			break;
			
		case SCHEDULE_SECTION:
			title = @"Schedule";
			break;
			
		case SOCIAL_MEDIA_SECTION:
			title = @"Share Film Detail";
			break;
			
		case ACTION_SECTION:
			title = @"Information & Ticket";
			break;
	}
	
    return title;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = [indexPath section];
	switch (section)
	{
		case SHORT_PROGRAM_SECTION:
		{
			NSInteger row = [indexPath row];
			
			Film *shortFilm = [[film shortItems] objectAtIndex:row];
			assert(shortFilm);

			CGSize size = [shortFilm.name sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
			if(size.width >= 292.0)
			{
				return 42.0;
			}
			else
			{
				return 26.0;
			}
		}
			break;

		case SCHEDULE_SECTION:
			return 50.0;
			break;
			
		case SOCIAL_MEDIA_SECTION:
			return 70.0;
			break;
			
		case ACTION_SECTION:
			return 70.0;
			break;
			
		default:
			return 50.0;
			break;
	}
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
	NSInteger section = [indexPath section];
	
	switch (section)
	{
		case SHORT_PROGRAM_SECTION:
		{
			NSInteger row = [indexPath row];
			
			Film *shortFilm = [[film shortItems] objectAtIndex:row];
			assert(shortFilm);

			cell = [tableView dequeueReusableCellWithIdentifier:kShortProgCellID];
			if (cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kShortProgCellID];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			else
			{
				[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
			}

			NSInteger titleNumLines = 1;
			CGSize size = [shortFilm.name sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
			if(size.width >= 292.0)
			{
				titleNumLines = 2;
			}
			
			UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleNumLines == 1 ? CGRectMake(16.0, 4.0, 292.0, 18.0) : CGRectMake(16.0, 4.0, 292.0, 34.0)];
			titleLabel.tag = CELL_TITLE_LABEL_TAG;
			[titleLabel setNumberOfLines:titleNumLines];
			titleLabel.font = titleFont;
			titleLabel.text = shortFilm.name;
			[cell.contentView addSubview:titleLabel];

			break;
		}
			
		case SCHEDULE_SECTION:
		{
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

			cell = [tableView dequeueReusableCellWithIdentifier:kScheduleCellID];
			if (cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kScheduleCellID];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				
				timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 4.0, 250.0, 20.0)];
				timeLabel.tag = CELL_TIME_LABEL_TAG;
				timeLabel.font = timeFont;
				[cell.contentView addSubview:timeLabel];
				
				venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(52.0, 23.0, 250.0, 20.0)];
				venueLabel.tag = CELL_VENUE_LABEL_TAG;
				venueLabel.font = venueFont;
				[cell.contentView addSubview:venueLabel];
				
				calButton = [UIButton buttonWithType:UIButtonTypeCustom];
				calButton.frame = CGRectMake(11.0, 5.0, 40.0, 40.0);
				calButton.tag = CELL_LEFTBUTTON_TAG;
				[calButton addTarget:self action:@selector(calendarButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
				[cell.contentView addSubview:calButton];

				mapsButton = [UIButton buttonWithType:UIButtonTypeCustom];
				mapsButton.frame = CGRectMake(274.0, 5.0, 40.0, 40.0);
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
			cell = [tableView dequeueReusableCellWithIdentifier:kSocialMediaCellID];
			if (cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSocialMediaCellID];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				
                UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
                fbButton.frame = CGRectMake(20.0, 6.0, 40.0, 40.0);
                [fbButton addTarget:self action:@selector(shareToFacebook:) forControlEvents:UIControlEventTouchDown];
                [fbButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:fbButton];
                
                UILabel *lblFacebook = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 46.0, 56.0, 20)];
                lblFacebook.text = @"Facebook";
                [lblFacebook setFont:[UIFont systemFontOfSize:12.0]];
                [lblFacebook setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblFacebook];
                
                UIButton *twButton = [UIButton buttonWithType:UIButtonTypeCustom];
				twButton.frame = CGRectMake(80.0, 6.0, 40.0, 40.0);
				[twButton addTarget:self action:@selector(shareToTwitter:) forControlEvents:UIControlEventTouchDown];
                [twButton setImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:twButton];

                UILabel *lblTwitter = [[UILabel alloc] initWithFrame:CGRectMake(72.0, 46.0, 56.0, 20)];
                lblTwitter.text = @"Twitter";
                [lblTwitter setFont:[UIFont systemFontOfSize:12.0]];
                [lblTwitter setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblTwitter];

				UIButton *googleButton = [UIButton buttonWithType:UIButtonTypeCustom];
				googleButton.frame = CGRectMake(140.0, 6.0, 40.0, 40.0);
				[googleButton addTarget:self action:@selector(shareToGooglePlus:) forControlEvents:UIControlEventTouchDown];
                [googleButton setImage:[UIImage imageNamed:@"googleplus.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:googleButton];
                
                UILabel *lblGoogle = [[UILabel alloc] initWithFrame:CGRectMake(132.0, 46.0, 56.0, 20)];
                lblGoogle.text = @"Google+";
                [lblGoogle setFont:[UIFont systemFontOfSize:12.0]];
                [lblGoogle setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblGoogle];

				UIButton *mailButton = [UIButton buttonWithType:UIButtonTypeCustom];
				mailButton.frame = CGRectMake(200.0, 6.0, 40.0, 40.0);
				[mailButton addTarget:self action:@selector(shareToMail:) forControlEvents:UIControlEventTouchDown];
                [mailButton setImage:[UIImage imageNamed:@"mail.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:mailButton];
                
                UILabel *lblMail = [[UILabel alloc] initWithFrame:CGRectMake(192.0, 46.0, 56.0, 20)];
                lblMail.text = @"Email";
                [lblMail setFont:[UIFont systemFontOfSize:12.0]];
                [lblMail setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblMail];

				UIButton *messageButton = [UIButton buttonWithType:UIButtonTypeCustom];
				messageButton.frame = CGRectMake(260.0, 6.0, 40.0, 40.0);
				[messageButton addTarget:self action:@selector(shareToMessage:) forControlEvents:UIControlEventTouchDown];
                [messageButton setImage:[UIImage imageNamed:@"message.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:messageButton];

				UILabel *lblMessage = [[UILabel alloc] initWithFrame:CGRectMake(252.0, 46.0, 56.0, 20)];
                lblMessage.text = @"Message";
                [lblMessage setFont:[UIFont systemFontOfSize:12.0]];
                [lblMessage setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblMessage];
			}
			
			break;
		}
			
		case ACTION_SECTION:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kActionsCellID];
			if (cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionsCellID];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;

				UIButton *linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
				linkButton.frame = CGRectMake(20.0, 6.0, 40.0, 40.0);
				[linkButton addTarget:self action:@selector(goTicketLink:) forControlEvents:UIControlEventTouchDown];
                [linkButton setImage:[UIImage imageNamed:@"browser.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:linkButton];
                
                UILabel *lblWebsite = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 46.0, 56.0, 20)];
                lblWebsite.text = @"Website";
                [lblWebsite setFont:[UIFont systemFontOfSize:12.0]];
                [lblWebsite setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblWebsite];

				UIButton *phoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
				phoneButton.frame = CGRectMake(80.0,6.0, 40.0, 40.0);
				[phoneButton addTarget:self action:@selector(callTicketLine:) forControlEvents:UIControlEventTouchDown];
                [phoneButton setImage:[UIImage imageNamed:@"phone.png"] forState:UIControlStateNormal];
                [cell.contentView addSubview:phoneButton];
                
                UILabel *lblPhone = [[UILabel alloc] initWithFrame:CGRectMake(72.0, 46.0, 56.0, 20)];
                lblPhone.text = @"Call CQ";
                [lblPhone setFont:[UIFont systemFontOfSize:12.0]];
                [lblPhone setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:lblPhone];
			}
		}
			break;
			
		default:
			NSLog(@"Unknown section %ld", section);
			break;
	}
	
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case SHORT_PROGRAM_SECTION:
		{
			Film *shortFilm = [[film shortItems] objectAtIndex:row];
			[self showShortFilmDetails:shortFilm];
			break;
		}
	}
}

- (void) showShortFilmDetails:(Film*)shortFilm
{
	FilmDetailController *filmDetail = [[FilmDetailController alloc] initWithTitle:@"Short Film" andId:shortFilm.ID];
	[[self navigationController] pushViewController:filmDetail animated:YES];
}

#pragma mark -
#pragma mark Browser integration

- (IBAction) goTicketLink:(id)sender
{
    [app openURL:[NSURL URLWithString:[film infoLink]]];
}

#pragma mark -
#pragma mark Phone call integration

- (IBAction) callTicketLine:(id)sender
{
/*
	// Test to try return to the app after the phone call
	UIWebView *callWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0)];
	[[sender superview] addSubview:callWebView];
	
	NSURL *telURL = [NSURL URLWithString:TICKET_LINE];
	[callWebView loadRequest:[NSURLRequest requestWithURL:telURL]];
*/
	[app openURL:[NSURL URLWithString:TICKET_LINE]];
}

#pragma mark -
#pragma mark Calendar Integration

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

#pragma mark -
#pragma mark Maps Integration

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

- (void) showMapWithVenue:(Venue*)venue
{
	MapViewController *mapViewController = [[MapViewController alloc] initWithNibName:@"MapViewController" andVenue:venue];
	mapViewController.hidesBottomBarWhenPushed = YES;
	[[self navigationController] pushViewController:mapViewController animated:YES];
}

#pragma mark -
#pragma mark Mail Sharing Delegate

- (IBAction) shareToMail:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
	{
        MFMailComposeViewController *controller = [MFMailComposeViewController new];
        controller.mailComposeDelegate = self;
		
        NSString *friendlyMessage = @"Hey,\nI found an interesting film from Cinequest festival.\nCheck it out!";
        NSString *messageBody = [NSString stringWithFormat:@"%@\n%@\n%@", friendlyMessage, [film name], [film infoLink]];
        
		[controller setSubject:[film name]];
        [controller setMessageBody:messageBody isHTML:NO];
        
        delegate.isPresentingModalView = YES;
        [self.navigationController presentViewController:controller animated:YES completion:nil];
        [[[[controller viewControllers] lastObject] navigationItem] setTitle:@"Set the title"];
    }
    else
	{
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send an email right now, make sure your device has an internet connection and you have at least one Email account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles: nil];
        [alertView show];
    }
}

- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	delegate.isPresentingModalView = NO;
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Message Sharing Delegate

- (IBAction) shareToMessage:(id)sender
{
	if([MFMessageComposeViewController canSendText])
	{
        MFMessageComposeViewController *controller = [MFMessageComposeViewController new];
        controller.messageComposeDelegate = self;
		
        NSString *friendlyMessage = @"Hey,\nI found an interesting film from Cinequest festival.\nCheck it out!";
        NSString *messageBody = [NSString stringWithFormat:@"%@\n%@\n%@", friendlyMessage, [film name], [film infoLink]];
        
		if([controller respondsToSelector:@selector(setSubject:)])
		{
			[controller setSubject:[film name]];
		}
		
        [controller setBody:messageBody];
        
        delegate.isPresentingModalView = YES;
        [self.navigationController presentViewController:controller animated:YES completion:nil];
    }
    else
	{
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a message right now, make sure your device has a phone or an internet connection"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles: nil];
        [alertView show];
    }
}

- (void) messageComposeViewController:(MFMessageComposeViewController*)controller didFinishWithResult:(MessageComposeResult)result
{
    switch(result)
	{
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send message!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Social Media Sharing integration

- (IBAction) shareToFacebook:(id)sender
{
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
	{
		UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
		NSLog(@"%@", NSStringFromCGRect(rootViewController.view.frame));
		UIView *view = (UIView*)[rootViewController.view.subviews firstObject];
		UIView *subview = (UIView*)[view.subviews firstObject];
		UIView *subview2 = (UIView*)[subview.subviews firstObject];
		UIView *subview3 = (UIView*)[subview2.subviews firstObject];
		NSLog(@"%@", subview3.subviews);
    });
    
	NSString *postString = [NSString stringWithFormat:@"I'm planning to go see %@\n%@", [film name], [film infoLink]];
    
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
        [alertView show];
    }
}

- (IBAction) shareToTwitter:(id)sender
{
	// [[GPPSignIn sharedInstance] signOut];
	//  return;
	
    NSString *postString = [NSString stringWithFormat:@"I'm planning to go see %@\n%@", [film name], [film infoLink]];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:postString];
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

- (IBAction) shareToGooglePlus:(id)sender
{
    NSString *postString = [NSString stringWithFormat:@"I'm planning to go see %@\n%@", [film name], [film infoLink]];

	googlePlusConnectionDone = 0;
	if(![[GPPSignIn sharedInstance] trySilentAuthentication])
	{
		[self loginAndPost:postString];
	}
	else
	{
		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		while(googlePlusConnectionDone == 0)
		{
			[runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}

		id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
		[shareBuilder setPrefillText:postString];
		[shareBuilder open];
	}
}

- (void) finishedWithAuth:(GTMOAuth2Authentication*)auth error:(NSError*)error
{
	if (error != nil)
	{
		NSLog(@"Google+ Authentication error: %@", error);
		
		googlePlusConnectionDone = -1;
	}
	else
	{
		NSLog(@"Google+ Authentication OK");
		
		googlePlusConnectionDone = 1;
	}
}

- (void) didDisconnectWithError:(NSError*)error
{
	if (error != nil)
	{
		NSLog(@"Google+ Failed to disconnect: %@", error);
	}
	else
	{
		NSLog(@"Google+ Disconnected");
	}
}

- (void) finishedSharingWithError:(NSError*)error
{
	NSLog(@"Google+ Sharing error: %@", error);
}

- (void) finishedSharing:(BOOL)shared
{
	if (shared)
	{
		NSLog(@"Google+ Post shared");
	}
	else
	{
		NSLog(@"Google+ Podst canceled");
	}
}

- (void) willPresentAlertView:(UIAlertView*)alertView
{
	NSLog(@"%@", alertView.subviews);
}

- (void) didPresentAlertView:(UIAlertView*)alertView
{
	NSLog(@"%@", alertView.subviews);
}

- (void) loginAndPost:(NSString*)postString
{
	GPlusDialogViewController *viewController = [[GPlusDialogViewController alloc] initWithNibName:@"GPlusDialogViewController" bundle:nil];
	viewController.postMessage = postString;
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
	[navController.view setFrame:CGRectMake(0, 0, viewController.view.frame.size.width, navController.view.frame.size.height)];
	
	GPlusDialogView *dialogView = [[GPlusDialogView alloc] initWithContent:navController];
	
    [dialogView show];
}

@end






