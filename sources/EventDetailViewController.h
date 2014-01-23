//
//  EventDetailViewController.h
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//


@class Schedule;
@class CinequestAppDelegate;

@interface EventDetailViewController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, GPPSignInDelegate, GPPShareDelegate>
{
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	Schedule *myData;
	NSString *eventId;
	NSString *infoLink;
	NSMutableDictionary *dataDictionary;
	BOOL showNewsDetail;
	BOOL showEventDetail;
	UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;
	UIFont *actionFont;
	NSInteger googlePlusConnectionDone;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITableView *detailsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (id) initWithNews:(NSDictionary*)news;
- (id) initWithEvent:(NSString*)name andDataObject:(id)dataObject andId:(NSString*)eventID;

@end
