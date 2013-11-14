//
//  CinequestAppDelegate.h
//  Cinequest
//
//  Created by Loc Phan on 1/10/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#define FILMSBYTIME		@"http://mobile.cinequest.org/mobileCQ.php?type=schedules&filmtitles&iphone"
#define FILMSBYTITLE	@"http://mobile.cinequest.org/mobileCQ.php?type=films&iphone"
#define NEWS			@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=ihome"
#define EVENTS			@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=ievents"
#define FORUMS			@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=iforums&iphone"
#define DVDs			@"http://mobile.cinequest.org/mobileCQ.php?type=dvds&distribution=none&iphone"
#define DETAILFORFILMID @"http://mobile.cinequest.org/mobileCQ.php?type=film&iphone&id="
#define DETAILFORDVDID	@"http://mobile.cinequest.org/mobileCQ.php?type=dvd&iphone&id="
#define DETAILFORPrgId	@"http://mobile.cinequest.org/mobileCQ.php?type=program_item&iphone&id="
#define DETAILFORITEM	@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=items&iphone&id="
#define MODE			@"http://mobile.cinequest.org/mobileCQ.php?type=mode"

#define XML_FEED_URL    @"http://payments.cinequest.org/websales/feed.ashx?guid=70d8e056-fa45-4221-9cc7-b6dc88f62c98&showslist=true"

#define CELL_BUTTON_TAG			100
#define CELL_TITLE_LABEL_TAG	2
#define	CELL_TIME_LABEL_TAG		3
#define CELL_VENUE_LABEL_TAG	4
#define CELL_FACEBOOKBUTTON_TAG	5
#define CELL_BUTTON_CALENDAR	6

#define SCHEDULE_SECTION         0
#define SOCIAL_MEDIA_SECTION	 1
#define CALL_N_EMAIL_SECTION     2

#define TICKET_LINE @"tel://1-408-295-3378"

#define EMPTY 0

#define NETWORK_CONNECTION_NONE  0
#define NETWORK_CONNECTION_WIFI  1
#define NETWORK_CONNECTION_PHONE 2

#define appDelegate (CinequestAppDelegate*)[[UIApplication sharedApplication] delegate]
#define app [UIApplication sharedApplication]

@class NewsViewController;
@class Festival;
@class Reachability;
@class Festival;
@class DataProvider;

@interface CinequestAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, NSXMLParserDelegate> 

@property (nonatomic, strong) NewsViewController *newsView;
@property (nonatomic, strong) NSMutableArray *mySchedule;
@property (readwrite) BOOL isPresentingModalView;
@property (readwrite) BOOL isLoggedInFacebook;
@property (readwrite) BOOL isOffSeason;
@property (nonatomic, strong) Festival* festival;
@property (nonatomic, strong) Reachability *reachability;
@property (atomic, assign) NSInteger networkConnection;	// 0: No connection, 1: WiFi, 2: Phone data
@property (nonatomic, strong) DataProvider *dataProvider;

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UITabBarController *tabBarController;

- (void) setOffSeason;
- (void) jumpToScheduler;
- (BOOL) connectedToNetwork;
- (void) startReachability:(NSString*)hostName;

- (NSURL*) cachesDirectory;
- (NSURL*) documentsDirectory;

@end

