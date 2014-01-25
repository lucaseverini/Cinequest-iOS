//
//  ForumDetailViewController.h
//  CineQuest
//
//  Created by Luca Severini on 1/24/14.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//


@class Forum;
@class Schedule;
@class CinequestAppDelegate;

@interface ForumDetailViewController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, GPPSignInDelegate, GPPShareDelegate>
{
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	NSString *eventName;
	NSString *infoLink;
	UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;
	UIFont *actionFont;
	NSInteger googlePlusConnectionDone;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITableView *detailTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) Forum *forum;

- (id) initWithTitle:(NSString*)title andId:(NSString*)Id;

@end
