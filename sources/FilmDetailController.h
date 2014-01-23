//
//  FilmDetailController.h
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//


@class CinequestAppDelegate;
@class Schedule;
@class FBSession;
@class Film;
@class ProgramItem;

@interface FilmDetailController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, GPPSignInDelegate, GPPShareDelegate>
{
	NSUInteger filmId;
	Schedule *myFilmData;
	FBSession *_session;
	UIButton *postThisButton;
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;
	UIFont *actionFont;
	NSInteger googlePlusConnectionDone;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITableView *detailsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) Film *film;

- (id) initWithTitle:(NSString*)title andId:(NSString*)filmID;

@end
