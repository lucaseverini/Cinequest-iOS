//
//  EventDetailViewController.h
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@class Schedule;
@class CinequestAppDelegate;

@interface EventDetailViewController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
{
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	Schedule *myData;
	NSString *eventId;
	NSURL *dataLink;
	NSMutableDictionary *dataDictionary;
	UIButton *postThisButton;
	BOOL showNewsDetail;
	BOOL showEventDetail;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITableView *detailsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (id) initWithNews:(NSDictionary*)news;
- (id) initWithEvent:(NSString*)name andDataObject:(id)dataObject andId:(NSString*)eventID;

@end
