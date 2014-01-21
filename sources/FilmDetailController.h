//
//  FilmDetailController.h
//  CineQuest
//
//  Created by Loc Phan on 10/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <GooglePlus/GooglePlus.h>
#import <GoogleOpenSource/GoogleOpenSource.h>


@class CinequestAppDelegate;
@class Schedule;
@class FBSession;
@class Film;
@class ProgramItem;

@interface FilmDetailController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, GPPSignInDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
{
	NSUInteger filmId;
	Schedule *myFilmData;
	FBSession *_session;
	UIButton *postThisButton;
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	UIFont *timeFont;
	UIFont *venueFont;
	UIFont *actionFont;
	GPPSignIn *googleSignIn;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITableView *detailsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) Film *film;

- (id) initWithTitle:(NSString*)name andId:(NSString*)filmID;

@end
