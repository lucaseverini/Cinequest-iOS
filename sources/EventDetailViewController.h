//
//  EventDetailViewController.h
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//


@class Special;
@class Schedule;
@class CinequestAppDelegate;

@interface EventDetailViewController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, GPPSignInDelegate, GPPShareDelegate>
{
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	NSString *eventName;
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
@property (nonatomic, strong) Special *event;

- (id) initWithNews:(NSDictionary*)news;
- (id) initWithTitle:(NSString*)title andId:(NSString*)Id;

@end
