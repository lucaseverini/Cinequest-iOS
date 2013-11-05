//
//  CinequestAppDelegate.h
//  Cinequest
//
//  Created by Loc Phan on 1/10/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>

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

#define XML_FEED_URL             @"http://payments.cinequest.org/websales/feed.ashx?guid=70d8e056-fa45-4221-9cc7-b6dc88f62c98&showslist=true"

#define CELL_BUTTON_TAG			1
#define CELL_TITLE_LABEL_TAG	2
#define	CELL_TIME_LABEL_TAG		3
#define CELL_VENUE_LABEL_TAG	4
#define CELL_FACEBOOKBUTTON_TAG	5

#define SCHEDULE_SECTION	0
#define FACEBOOK_SECTION	1
#define CALL_N_EMAIL_SECTION 2

#define TICKET_LINE @"tel://1-408-295-3378"

#define EMPTY 0

@class NewsViewController;
@class Festival;

@interface CinequestAppDelegate : NSObject 
	<UIApplicationDelegate, UITabBarControllerDelegate, NSXMLParserDelegate> 
{
    UIWindow *window;
    UITabBarController *tabBarController;
	NewsViewController *newsView;
	NSMutableArray *mySchedule;
	BOOL isPresentingModalView;
	BOOL isLoggedInFacebook;
	BOOL isOffSeason;
}

@property (nonatomic, strong) NewsViewController *newsView;
@property (nonatomic, strong) NSMutableArray *mySchedule;
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UITabBarController *tabBarController;
@property (readwrite) BOOL isPresentingModalView;
@property (readwrite) BOOL isLoggedInFacebook;
@property (readwrite) BOOL isOffSeason;

@property (nonatomic, strong) Festival* festival;

- (void)jumpToScheduler;
- (BOOL)connectedToNetwork:(NSURL*)URL;
@end
