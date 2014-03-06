//
//  FilmDetailViewController.h
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

@interface FilmDetailViewController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, GPPSignInDelegate, GPPShareDelegate>
{
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;
	UIFont *sectionFont;
	UIFont *actionFont;
	NSInteger googlePlusConnectionDone;
	BOOL viewWillDisappear;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITableView *detailTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) Film *film;

- (id) initWithFilm:(NSString*)filmId;
- (id) initWithShortFilm:(NSString*)shortFilmId;

@end
