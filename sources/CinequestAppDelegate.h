//
//  CinequestAppDelegate.h
//  Cinequest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//


#define FILMSBYTIME		@"http://mobile.cinequest.org/mobileCQ.php?type=schedules&filmtitles&iphone"
#define FILMSBYTITLE	@"http://mobile.cinequest.org/mobileCQ.php?type=films&iphone"
#define OLD_NEWS		@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=ihome"
#define EVENTS			@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=ievents"
#define FORUMS			@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=iforums&iphone"
#define DVDs			@"http://mobile.cinequest.org/mobileCQ.php?type=dvds&distribution=none&iphone"
#define DETAILFORFILMID @"http://mobile.cinequest.org/mobileCQ.php?type=film&iphone&id="
#define DETAILFORDVDID	@"http://mobile.cinequest.org/mobileCQ.php?type=dvd&iphone&id="
#define DETAILFORPrgId	@"http://mobile.cinequest.org/mobileCQ.php?type=program_item&iphone&id="
#define DETAILFORITEM	@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=items&iphone&id="
#define MODE			@"http://mobile.cinequest.org/mobileCQ.php?type=mode"
#define NEWS_FEED		@"http://www.cinequest.org/news.php"
#define MAIN_FEED		@"http://payments.cinequest.org/websales/feed.ashx?guid=70d8e056-fa45-4221-9cc7-b6dc88f62c98&showslist=true"
#define VENUES			@"http://www.cinequest.org/venuelist.php"
#define CALENDAR_FILE   @"calendar.plist"

#define CELL_TITLE_LABEL_TAG	1
#define	CELL_TIME_LABEL_TAG		2
#define CELL_VENUE_LABEL_TAG	3
#define CELL_FACEBOOKBUTTON_TAG	4
#define CELL_RIGHTBUTTON_TAG	5
#define CELL_IMAGE_TAG			6
#define CELL_LEFTBUTTON_TAG		100

#define SHORT_PROGRAM_SECTION   0
#define SCHEDULE_SECTION        1
#define SOCIAL_MEDIA_SECTION	2
#define ACTION_SECTION			3

#define TICKET_LINE @"telprompt://1-408-295-3378"

#define CALENDAR_NAME @"Cinequest"
#define CINEQUEST_DATACACHE_FOLDER @"CinequestDataCache"

#define EMPTY 0
#define ONE_YEAR (60.0 * 60.0 * 24.0 * 365.0)

#define VIEW_BY_DATE	0
#define VIEW_BY_TITLE	1

#define NETWORK_CONNECTION_NONE  0
#define NETWORK_CONNECTION_WIFI  1
#define NETWORK_CONNECTION_PHONE 2

#define GOOGLEPLUS_CLIENTID	@"470208679525-9nYBufiT7puYS3jIkOe49Rv6.apps.googleusercontent.com";	// org.cinequest.mobileapp
// #define GOOGLEPLUS_CLIENTID	@"452265719636-qbqmhro0t3j9jip1npl69a3er7biidd2.apps.googleusercontent.com"; // com.google.GooglePlusPlatformSample

#define appDelegate ((CinequestAppDelegate*)[[UIApplication sharedApplication] delegate])
#define app [UIApplication sharedApplication]

@class NewsViewController;
@class Reachability;
@class DataProvider;

#import "Schedule.h"
#import "Festival.h"

@interface CinequestAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, NSXMLParserDelegate> 
{
	NSInteger curTabIndex;
}

@property (nonatomic, strong) NewsViewController *newsView;
@property (nonatomic, strong) NSMutableArray *mySchedule;
@property (readwrite) BOOL isPresentingModalView;
@property (readwrite) BOOL isLoggedInFacebook;
@property (readwrite) BOOL isOffSeason;
@property (nonatomic, strong) Festival *festival;
@property (nonatomic, strong) NSDictionary *venuesDictionary;
@property (nonatomic, strong) Reachability *reachability;
@property (atomic, assign) NSInteger networkConnection;	// 0: No connection, 1: WiFi, 2: Phone data
@property (nonatomic, strong) DataProvider *dataProvider;
@property (nonatomic, strong) NSString *OSVersion;
@property (nonatomic, assign) BOOL retinaDisplay;
@property (nonatomic, assign) BOOL iPhone4Display;
@property (nonatomic, assign) NSInteger deviceIdiom;
@property (atomic, assign) BOOL festivalParsed;
@property (atomic, assign) BOOL venuesParsed;

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UITabBarController *tabBar;

// For Calendar Events
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) EKCalendar *cinequestCalendar;
@property (nonatomic, strong) NSString *calendarIdentifier;
@property (nonatomic, strong) NSMutableArray *arrayCalendarItems;
@property (nonatomic, strong) NSMutableDictionary *dictSavedEventsInCalendar;
@property (nonatomic, strong) NSMutableArray *arrCalendarIdentifiers;

- (BOOL) connectedToNetwork;
- (void) startReachability:(NSString*)hostName;

- (void) addOrRemoveSchedule:(Schedule*)schedule;
- (void) addOrRemoveScheduleToCalendar:(Schedule*)schedule;
- (void) populateCalendarEntries;
- (void) checkEventStoreAccessForCalendar;
- (void) fetchVenues;

- (NSURL*) cachesDirectory;
- (NSURL*) documentsDirectory;

@end



