//
//  FilmDetail.h
//  CineQuest
//
//  Created by Loc Phan on 10/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "CinequestAppDelegate.h"

@class Schedule;
@class FBSession;

@interface FilmDetail : UIViewController <UIWebViewDelegate,
						FBDialogDelegate, FBSessionDelegate, FBRequestDelegate, 
						MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
{
	NSURL								*myLink;
	Schedule							*myFilmData;
	NSMutableDictionary					*dataDictionary;
	
	IBOutlet UIWebView					*webView;
	IBOutlet UITableView				*_tableView;
	IBOutlet UIActivityIndicatorView	*activityIndicator;
	
	BOOL isDVD;
	
	FBSession *_session;
	FBUID facebookID;
	UIButton *postThisButton;
	
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
}

@property (readwrite) BOOL isDVD;
@property (nonatomic, retain) IBOutlet UIWebView				*webView;
@property (nonatomic, retain) IBOutlet UITableView				*tableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView  *activityIndicator;
@property (nonatomic, retain) NSMutableDictionary				*dataDictionary;


- (id)initWithTitle:(NSString*)name andDataObject:(id)dataObject andURL:(NSURL*)link;

@end
