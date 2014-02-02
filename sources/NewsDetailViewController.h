//
//  NewsDetailViewController.h
//  CineQuest
//
//  Created by Luca Severini on 1/24/14.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//


@class Special;
@class Schedule;
@class CinequestAppDelegate;

@interface NewsDetailViewController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, GPPSignInDelegate, GPPShareDelegate>
{
	CinequestAppDelegate *delegate;
	NSString *newsName;
	NSString *infoLink;
	UIFont *actionFont;
	UIFont *sectionFont;
	NSInteger googlePlusConnectionDone;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITableView *detailTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSDictionary *news;

- (id) initWithNews:(NSDictionary*)newsData;

@end
