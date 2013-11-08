//
//  CinequestAppDelegate.m
//  Cinequest
//
//  Created by Loc Phan on 1/10/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "CinequestAppDelegate.h"
#import "NewsViewController.h"
#import "FestivalParser.h"
#import "Reachability.h"
#import "MainViewController.h"

NSString *const kUpdatedXMLFeedNotification = @"UpdatedXMLFeedNotification";

@interface CinequestAppDelegate (Private)

- (void) setOffSeason;

@end


@implementation CinequestAppDelegate 

@synthesize window;
@synthesize tabBarController;
@synthesize mySchedule;
@synthesize isPresentingModalView;
@synthesize isLoggedInFacebook;
@synthesize isOffSeason;
@synthesize newsView;
@synthesize festival;
@synthesize reachability;
@synthesize networkConnection;

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	[self startReachability:XML_FEED_URL];

	mySchedule = [[NSMutableArray alloc] init];
	newsView = [[NewsViewController alloc] init];
	
	if ([self connectedToNetwork])
	{
		[self setOffSeason];
		// isOffSeason = YES;
		// NSLog(@"IS OFFSEASON? %@",(isOffSeason) ? @"YES" : @"NO");
	}
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    // saving an NSString
    if (![prefs stringForKey:@"CalendarID"]) {
        [prefs setObject:@"" forKey:@"CalendarID"];
    }
	
    FestivalParser *festivalParser = [[FestivalParser alloc] init];
	festival = [festivalParser parseFestival:XML_FEED_URL];
	
	MainViewController *mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mainViewController];

    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];

	return YES;
}

- (void) setOffSeason
{
	NSURL *url = [NSURL URLWithString:MODE];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	
	[parser setDelegate: self];
	[parser setShouldProcessNamespaces: NO];
	[parser setShouldReportNamespacePrefixes: NO];
	[parser setShouldResolveExternalEntities: NO];
	
	[parser parse];
}

- (void) jumpToScheduler
{
	tabBarController.selectedIndex = 4;
}

- (BOOL) connectedToNetwork
{
	return [self.reachability isReachable];
}

#pragma mark -
#pragma mark Mode XML parser delegate
- (void) parserDidStartDocument:(NSXMLParser *)parser
{
	NSLog(@"Getting mode...");
}

- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	NSString * errorString = [NSString stringWithFormat:@"Unable to get mode (Error code %i ).", [parseError code]];
	NSLog(@"Error parsing XML: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading content" 
												message:errorString
												delegate:self
												cancelButtonTitle:@"OK" 
												otherButtonTitles:nil];
	[errorAlert show];

}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if ([string isEqualToString:@"home"]) {
		isOffSeason = NO;
	} else {
		isOffSeason = YES;
	}	
}

- (void) startReachability:(NSString*)hostName
{
	if(hostName == nil)
	{
		return;
	}

	NSRange range = [hostName rangeOfString:@"://"];
	NSString *cleanHostName = range.location == NSNotFound ? hostName : [hostName substringFromIndex:NSMaxRange(range)];
	range = [cleanHostName rangeOfString:@"/"];
	cleanHostName = range.location == NSNotFound ? hostName : [cleanHostName substringToIndex:NSMaxRange(range) - 1];
	
	if(reachability != nil)
	{
		[reachability stopNotifier];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
	}
	
	reachability = [Reachability reachabilityWithHostname:cleanHostName];
	[reachability startNotifier];
}

- (void) reachabilityDidChange:(NSNotification*)note
{
    Reachability *reach = [note object];
	if([reach isReachable])
	{
		SCNetworkReachabilityFlags flags = [reach reachabilityFlags];
		if(kSCNetworkReachabilityFlagsTransientConnection)
		{
			networkConnection = NETWORK_CONNECTION_PHONE;
		}
		else if(flags & kSCNetworkReachabilityFlagsReachable)
		{
			networkConnection = NETWORK_CONNECTION_WIFI;
		}
		else
		{
			networkConnection = NETWORK_CONNECTION_NONE;
		}
	}
	else
	{
		networkConnection = NETWORK_CONNECTION_NONE;
	}
	
	NSLog(@"Network Connection: %s", networkConnection == 1 ? "DialUp" : networkConnection == 2 ? "WiFi" : "None");
}

- (NSData*) getXMLFeed;
{
	NSURL *url = [NSURL URLWithString:XML_FEED_URL];
	NSData *data = [NSData dataWithContentsOfURL:url];
	
	return data;
}

- (BOOL) updatedXMLFeedAvailable
{
	return YES;
}

@end

