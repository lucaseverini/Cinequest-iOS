//
//  EventDetailViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CinequestAppDelegate.h"

#import "FBConnect.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@class Schedule;

@interface EventDetailViewController : UIViewController 
	<UIWebViewDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate, FBDialogDelegate, FBSessionDelegate, FBRequestDelegate>
{
	IBOutlet UIWebView *_webView;
	IBOutlet UITableView *_tableView;
	IBOutlet UIActivityIndicatorView *activity;
	
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	
	Schedule *myData;
	
	NSURL *dataLink;
	NSMutableDictionary *dataDictionary;
	
	BOOL displayAddButton;
	
	FBSession *_session;
	FBUID facebookID;
	UIButton *postThisButton;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activity;
@property (readwrite) BOOL displayAddButton;

- (id)initWithTitle:(NSString*)name andDataObject:(id)dataObject andURL:(NSURL*)link;


@end
