//
//  EventDetailViewController.m
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "EventDetailViewController.h"
#import "CinequestAppDelegate.h"
#import "Schedule.h"
#import "Special.h"
#import "DataProvider.h"
#import "MapViewController.h"
#import "GPlusDialogView.h"
#import "GPlusDialogViewController.h"


#define web @"<style type=\"text/css\">h1{font-size:23px;text-align:center;}p.image{text-align:center;}</style><h1>%@</h1><p class=\"image\"><img style=\"max-height:200px;max-width:250px;\"src=\"%@\"/></p><p>%@</p>"

static NSString *kScheduleCellID = @"ScheduleCell";
static NSString *kSocialMediaCellID = @"SocialMediaCell";
static NSString *kActionsCellID	= @"ActionsCell";


@implementation EventDetailViewController

@synthesize detailTableView;
@synthesize webView;
@synthesize activityIndicator;
@synthesize event;

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UIViewController

- (id) initWithEvent:(NSString*)eventId
{
	self = [super init];
	if(self != nil)
	{
		delegate = appDelegate;
		mySchedule = delegate.mySchedule;
		
		self.navigationItem.title = @"Event";
		
		event = [delegate.festival getEventForId:eventId];
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

	delegate = appDelegate;
	mySchedule = delegate.mySchedule;

	self.detailTableView.hidden = YES;
	self.view.userInteractionEnabled = NO;

	self.activityIndicator.color = [UIColor grayColor];

	timeFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	sectionFont = [UIFont boldSystemFontOfSize:18.0];
	venueFont = timeFont;
	actionFont = [UIFont systemFontOfSize:12.0];

	UISegmentedControl *switchTitle = [[UISegmentedControl alloc] initWithFrame:CGRectMake(98.5, 7.5, 123.0, 29.0)];
	[switchTitle insertSegmentWithTitle:@"Detail" atIndex:0 animated:NO];
	[switchTitle setSelectedSegmentIndex:0];
	NSDictionary *attribute = [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:16.0f] forKey:NSFontAttributeName];
	[switchTitle setTitleTextAttributes:attribute forState:UIControlStateNormal];
	self.navigationItem.titleView = switchTitle;

	[(UIWebView*)self.detailTableView.tableHeaderView setSuppressesIncrementalRendering:YES]; // Avoids scrolling problems when the WebView is showed

	[self.activityIndicator startAnimating];

	[self performSelectorInBackground:@selector(loadData) withObject:nil];
	
	[self.detailTableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	viewWillDisappear = NO;
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	viewWillDisappear = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [self.detailTableView reloadSections:[NSIndexSet indexSetWithIndex:SCHEDULE_SECTION] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) loadData
{
	NSString *cachedImage = [appDelegate.dataProvider cacheImage:[event imageURL]];
	
	// Don't execute unuseful code if the view is going to disappear shortly
	if(!viewWillDisappear)
	{
		NSString *weba = [NSString stringWithFormat:web, [event name], cachedImage, [event description]];
		weba = [self htmlEntityDecode:weba];
		
		[webView loadHTMLString:weba baseURL:nil];
	}
}

- (Schedule*) getItemForSender:(id)sender event:(id)touchEvent
{
    NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.detailTableView];
	NSIndexPath *indexPath = [self.detailTableView indexPathForRowAtPoint:currentTouchPosition];
	NSInteger row = [indexPath row];
	Schedule *schedule = nil;
	
	if(indexPath != nil)
	{
		NSMutableArray *schedules = [event schedules];
		schedule = [schedules objectAtIndex:row];
    }
    
    return schedule;
}

#pragma mark - UIWebView delegate

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
	// Updates the WebView and force it to redisplay correctly
	[self.detailTableView.tableHeaderView sizeToFit];
	[self.detailTableView setTableHeaderView:self.detailTableView.tableHeaderView];
	
	[self.activityIndicator stopAnimating];
	
	self.view.userInteractionEnabled = YES;
	self.detailTableView.hidden = NO;
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

#pragma mark - UITableView Datasource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case SCHEDULE_SECTION:
			return 1;
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

- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
	CGFloat width = tableView.bounds.size.width;
	CGFloat height = 24.0;
	
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    view.userInteractionEnabled = NO;
	
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];
    label.backgroundColor = [UIColor redColor];
    label.textColor = [UIColor whiteColor];
    label.font = sectionFont;
    [view addSubview:label];
	
	switch(section)
	{
		case SCHEDULE_SECTION:
			label.text = [NSString stringWithFormat:@"  %@", @"Schedule"];
			break;
			
		case SOCIAL_MEDIA_SECTION:
			label.text =  [NSString stringWithFormat:@"  %@", @"Share Event Detail"];
			break;
			
		case ACTION_SECTION:
			label.text = [NSString stringWithFormat:@"  %@", @"Information & Ticket"];
			break;
	}
	
    return view;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = [indexPath section];
	UITableViewCell *cell = nil;
	
	switch(section)
	{
		case SCHEDULE_SECTION:
		{
			NSInteger row = [indexPath row];
			
			// get all schedules
			NSMutableArray *schedules = [event schedules];
			Schedule *schedule = [schedules objectAtIndex:row];
			
			NSUInteger count = [mySchedule count];
            
            if (count) {
                for (int idx = 0; idx < count; idx++)
                {
                    Schedule *obj = [mySchedule objectAtIndex:idx];
                    if ([obj.ID isEqualToString:schedule.ID])
                    {
                        schedule.isSelected = YES;
                    }
                }
                
            } else {
                schedule.isSelected = NO;
            }
			
			UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
			UILabel *timeLabel = nil;
			UILabel *venueLabel = nil;
			UIButton *calButton = nil;
			UIButton *mapsButton = nil;

			cell = [tableView dequeueReusableCellWithIdentifier:kScheduleCellID];
			if (cell == nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kScheduleCellID];
				cell.accessoryType = UITableViewCellAccessoryNone;
							
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
				mapsButton.enabled = appDelegate.locationServicesON;
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
			if(cell == nil)
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
				[lblFacebook setFont:actionFont];
				[lblFacebook setTextAlignment:NSTextAlignmentCenter];
				[cell.contentView addSubview:lblFacebook];
				
				UIButton *twButton = [UIButton buttonWithType:UIButtonTypeCustom];
				twButton.frame = CGRectMake(80.0, 6.0, 40.0, 40.0);
				[twButton addTarget:self action:@selector(shareToTwitter:) forControlEvents:UIControlEventTouchDown];
				[twButton setImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
				[cell.contentView addSubview:twButton];
				
				UILabel *lblTwitter = [[UILabel alloc] initWithFrame:CGRectMake(72.0, 46.0, 56.0, 20)];
				lblTwitter.text = @"Twitter";
				[lblTwitter setFont:actionFont];
				[lblTwitter setTextAlignment:NSTextAlignmentCenter];
				[cell.contentView addSubview:lblTwitter];
				
				UIButton *googleButton = [UIButton buttonWithType:UIButtonTypeCustom];
				googleButton.frame = CGRectMake(140.0, 6.0, 40.0, 40.0);
				[googleButton addTarget:self action:@selector(shareToGooglePlus:) forControlEvents:UIControlEventTouchDown];
				[googleButton setImage:[UIImage imageNamed:@"googleplus.png"] forState:UIControlStateNormal];
				[cell.contentView addSubview:googleButton];
				
				UILabel *lblGoogle = [[UILabel alloc] initWithFrame:CGRectMake(132.0, 46.0, 56.0, 20)];
				lblGoogle.text = @"Google+";
				[lblGoogle setFont:actionFont];
				[lblGoogle setTextAlignment:NSTextAlignmentCenter];
				[cell.contentView addSubview:lblGoogle];
				
				UIButton *mailButton = [UIButton buttonWithType:UIButtonTypeCustom];
				mailButton.frame = CGRectMake(200.0, 6.0, 40.0, 40.0);
				[mailButton addTarget:self action:@selector(shareToMail:) forControlEvents:UIControlEventTouchDown];
				[mailButton setImage:[UIImage imageNamed:@"mail.png"] forState:UIControlStateNormal];
				[cell.contentView addSubview:mailButton];
				
				UILabel *lblMail = [[UILabel alloc] initWithFrame:CGRectMake(192.0, 46.0, 56.0, 20)];
				lblMail.text = @"Email";
				[lblMail setFont:actionFont];
				[lblMail setTextAlignment:NSTextAlignmentCenter];
				[cell.contentView addSubview:lblMail];
				
				UIButton *messageButton = [UIButton buttonWithType:UIButtonTypeCustom];
				messageButton.frame = CGRectMake(263.0, 8.0, 35.0, 35.0);
				[messageButton addTarget:self action:@selector(shareToMessage:) forControlEvents:UIControlEventTouchDown];
				[messageButton setImage:[UIImage imageNamed:@"messages_icon.png"] forState:UIControlStateNormal];
				[cell.contentView addSubview:messageButton];
				
				UILabel *lblMessage = [[UILabel alloc] initWithFrame:CGRectMake(252.0, 46.0, 56.0, 20)];
				lblMessage.text = @"Message";
				[lblMessage setFont:actionFont];
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
				[linkButton setImage:[UIImage imageNamed:@"safari_icon.png"] forState:UIControlStateNormal];
				[cell.contentView addSubview:linkButton];
				
				UILabel *lblWebsite = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 46.0, 56.0, 20)];
				lblWebsite.text = @"Website";
				[lblWebsite setFont:actionFont];
				[lblWebsite setTextAlignment:NSTextAlignmentCenter];
				[cell.contentView addSubview:lblWebsite];
				
				UIButton *phoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
				phoneButton.frame = CGRectMake(80.0,6.0, 40.0, 40.0);
				[phoneButton addTarget:self action:@selector(callTicketLine:) forControlEvents:UIControlEventTouchDown];
				[phoneButton setImage:[UIImage imageNamed:@"phone.png"] forState:UIControlStateNormal];
				[cell.contentView addSubview:phoneButton];
				
				UILabel *lblPhone = [[UILabel alloc] initWithFrame:CGRectMake(72.0, 46.0, 56.0, 20)];
				lblPhone.text = @"Call CQ";
				[lblPhone setFont:actionFont];
				[lblPhone setTextAlignment:NSTextAlignmentCenter];
				[cell.contentView addSubview:lblPhone];
			}
			
			break;
		}
	}
	
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.01;		// This creates a "invisible" footer
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

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(section == SHORT_PROGRAM_SECTION)
	{
		return 0.0;
	}
	else
	{
		return 28.0;
	}
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// NSInteger section = [indexPath section];
	// NSInteger row = [indexPath row];
}

#pragma mark - UIAlertView Delegate

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
	
	NSIndexPath *tableSelection = [self.detailTableView indexPathForSelectedRow];
    [self.detailTableView deselectRowAtIndexPath:tableSelection animated:YES];
}

#pragma mark - Calendar Integration

- (void) calendarButtonTapped:(id)sender event:(id)touchEvent
{
	Schedule *schedule = [self getItemForSender:sender event:touchEvent];
    schedule.isSelected ^= YES;
    
    // Call to Delegate to Add/Remove from Calendar
    [delegate addOrRemoveScheduleToCalendar:schedule];
    [delegate addOrRemoveSchedule:schedule];
    
    NSLog(@"Schedule:ID+ItemID:%@-%@", schedule.ID, schedule.itemID);
	
    UIButton *calendarButton = (UIButton*)sender;
    UIImage *buttonImage = (schedule.isSelected) ? [UIImage imageNamed:@"cal_selected.png"] : [UIImage imageNamed:@"cal_unselected.png"];
    [calendarButton setImage:buttonImage forState:UIControlStateNormal];
}

#pragma mark - Maps Integration

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

- (void) showMapWithVenue:(Venue*)venue
{
	MapViewController *mapViewController = [[MapViewController alloc] initWithNibName:@"MapViewController" andVenue:venue];
	mapViewController.hidesBottomBarWhenPushed = YES;
	[[self navigationController] pushViewController:mapViewController animated:YES];
}

#pragma mark - Mail Sharing Delegate

- (IBAction) shareToMail:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
	{
        MFMailComposeViewController *controller = [MFMailComposeViewController new];
        controller.mailComposeDelegate = self;
		
        NSString *friendlyMessage = @"Hey,\nI found an interesting event from Cinequest festival.\nCheck it out!";
        NSString *messageBody = [NSString stringWithFormat:@"%@\n%@\n%@", friendlyMessage, event.name, event.infoLink];
        
		[controller setSubject:event.name];
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

#pragma mark - Message Sharing Delegate

- (IBAction) shareToMessage:(id)sender
{
	if([MFMessageComposeViewController canSendText])
	{
        MFMessageComposeViewController *controller = [MFMessageComposeViewController new];
        controller.messageComposeDelegate = self;
		
        NSString *friendlyMessage = @"Hey,\nI found an interesting event from Cinequest festival.\nCheck it out!";
        NSString *messageBody = [NSString stringWithFormat:@"%@\n%@\n%@", friendlyMessage, event.name, event.infoLink];
        
		if([controller respondsToSelector:@selector(setSubject:)])
		{
			[controller setSubject:event.name];
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

#pragma mark - Social Media Sharing

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
    
	NSString *postString = [NSString stringWithFormat:@"I'm planning to attend the event %@\n%@", event.name, event.infoLink];
    
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
    NSString *postString = [NSString stringWithFormat:@"I'm planning to attend the event %@\n%@", event.name, event.infoLink];
    
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
    NSString *postString = [NSString stringWithFormat:@"I'm planning to attend the event %@\n%@", event.name, event.infoLink];
	
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

#pragma mark - Browser integration

- (IBAction) goTicketLink:(id)sender
{
    [app openURL:[NSURL URLWithString:event.infoLink]];
}

#pragma mark - Phone call integration

- (IBAction) callTicketLine:(id)sender
{
	[app openURL:[NSURL URLWithString:TICKET_LINE]];
}

#pragma mark - Decode NSString for HTML

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


