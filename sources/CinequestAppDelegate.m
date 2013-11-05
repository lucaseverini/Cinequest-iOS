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

@interface CinequestAppDelegate (Private)
- (void)setOffSeason;
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

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	mySchedule = [[NSMutableArray alloc] init];
	newsView = [[NewsViewController alloc] init];
	if ([self connectedToNetwork:[NSURL URLWithString:MODE]])
	{
		[self setOffSeason];
		//isOffSeason = YES;
		//NSLog(@"IS OFFSEASON? %@",(isOffSeason) ? @"YES" : @"NO");
	}
	
	//NSLog(@"Application has finished launching...");
    // Add the tab bar controller's current view as a subview of the window
    // [window addSubview:tabBarController.view];
	
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
	
	festival = [FestivalParser parseFestival:XML_FEED_URL];
	
	return YES;
}

- (void)setOffSeason {
	NSURL *url = [NSURL URLWithString:MODE];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	
	[parser setDelegate: self];
	[parser setShouldProcessNamespaces: NO];
	[parser setShouldReportNamespacePrefixes: NO];
	[parser setShouldResolveExternalEntities: NO];
	
	[parser parse];
}
- (void)jumpToScheduler {
	tabBarController.selectedIndex = 4;
}
- (BOOL)connectedToNetwork:(NSURL*)URL {
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
	
	NSURLRequest *testRequest = [NSURLRequest requestWithURL:URL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
	NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
	
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}
#pragma mark -
#pragma mark Mode XML parser delegate
- (void)parserDidStartDocument:(NSXMLParser *)parser {
	NSLog(@"Getting mode...");
}
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	NSString * errorString = [NSString stringWithFormat:@"Unable to get mode (Error code %i ).", [parseError code]];
	NSLog(@"Error parsing XML: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading content" 
														  message:errorString 
														 delegate:self 
												cancelButtonTitle:@"OK" 
												otherButtonTitles:nil];
	[errorAlert show];

}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if ([string isEqualToString:@"home"]) {
		isOffSeason = NO;
	} else {
		isOffSeason = YES;
	}	
}

@end

