//
//  LoadDataViewController.m
//  CineQuest
//
//  Created by Loc Phan on 10/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LoadDataViewController.h"
#import "CineQuestAppDelegate.h"
#import "NewsViewController.h"
#import "DDXML.h"
#import <SystemConfiguration/SCNetworkReachability.h>

#include <netinet/in.h>


#pragma mark -

@interface LoadDataViewController (Private)

- (void)loadFILMSBYTIME;
- (void)loadFILMSBYTITLE;
- (void)loadDVDs;
- (void)loadFORUMS;
- (void)loadEVENTS;
- (void)loadNEWS;


- (BOOL)connectedToNetwork;
- (void)setOffSeason;

@end

@implementation LoadDataViewController

@synthesize activity;
@synthesize statusLabel;

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark UIViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
	[activity startAnimating];	
		
	//Open Database
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *dataFile = [documentsDirectory stringByAppendingPathComponent:@"database.sql"];
	
	int result = sqlite3_open([dataFile UTF8String], &database);
	
	
	if(result == SQLITE_OK)
	{
		NSLog(@"Load Data: Opened DB");
		
		char *errorMsg;
		
		char *createSQL ="CREATE TABLE IF NOT EXISTS FilmsByTime (id integer, prg_id integer, type varchar(10), title text, start_time varchar(50), venue varchar(10));";
		result = sqlite3_exec(database, createSQL, NULL, NULL, &errorMsg);
		if (result != SQLITE_OK)
		{
			sqlite3_free(errorMsg);			
		}
		
		createSQL ="CREATE TABLE IF NOT EXISTS FilmsByTitle (id integer, title text, sort varchar(5));";
		result = sqlite3_exec(database, createSQL, NULL, NULL, &errorMsg);
		if (result != SQLITE_OK)
		{
			sqlite3_free(errorMsg);			
		}
		
		createSQL ="CREATE TABLE IF NOT EXISTS Events (id integer, prg_id integer, type varchar(10), title text, start_time varchar(50), venue varchar(10));";
		result = sqlite3_exec(database, createSQL, NULL, NULL, &errorMsg);
		if (result != SQLITE_OK)
		{
			sqlite3_free(errorMsg);			
		}
		
		createSQL ="CREATE TABLE IF NOT EXISTS Forums (id integer, prg_id integer, type varchar(10), title text, start_time varchar(50), venue varchar(10));";
		result = sqlite3_exec(database, createSQL, NULL, NULL, &errorMsg);
		if (result != SQLITE_OK)
		{
			sqlite3_free(errorMsg);			
		}
		
		createSQL ="CREATE TABLE IF NOT EXISTS DVDs (id integer, title text, sort varchar(5));";
		result = sqlite3_exec(database, createSQL, NULL, NULL, &errorMsg);
		if (result != SQLITE_OK)
		{
			sqlite3_free(errorMsg);			
		}
		
		createSQL ="CREATE TABLE IF NOT EXISTS News (section text, title text, date text, link text, imgurl text);";
		result = sqlite3_exec(database, createSQL, NULL, NULL, &errorMsg);
		if (result != SQLITE_OK)
		{
			sqlite3_free(errorMsg);			
		}
	}
	else 
	{
		NSAssert(0, @"Failed to open database");
	}
	[NSThread detachNewThreadSelector:@selector(checkNetWorkAndLoadData)
							 toTarget:self
						   withObject:nil];
}

#pragma mark -
#pragma mark Private Methods

- (BOOL)checkNetWorkAndLoadData {
	@autoreleasepool {
        
        statusLabel.text = @"Loading...";
        
        if ([self connectedToNetwork]) {
            NSLog(@"Checking connectivity... COMPLETE!");
            
            [self setOffSeason];
            NSLog(@"Is OffSeason? %d",offSeason);
            
            NSLog(@"Loading... new data....");
            
            if (!offSeason)
            {
                // Load online data to database
                
                // NSString *NEWS = @"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=home&iphone";
                
                // FILMSBYTIME = @"http://mobile.cinequest.org/mobileCQ.php?type=schedules&filmtitles&iphone";
                [self loadFILMSBYTIME];
                
                // Films by Title: http://mobile.cinequest.org/mobileCQ.php?type=films&iphone
                [self loadFILMSBYTITLE];
                
                // Events: http://mobile.cinequest.org/mobileCQ.php?type=xml&name=ievents&iphone
                [self loadEVENTS];
                
                // Forums: http://mobile.cinequest.org/mobileCQ.php?type=xml&name=iforums&iphone
                [self loadFORUMS];
                
                // DVD List: http://mobile.cinequest.org/mobileCQ.php?type=dvds&distribution=none&iphone
                [self loadDVDs];
                
                [self loadNEWS];
                // DVD New Release: http://mobile.cinequest.org/mobileCQ.php?type=dvd&iphone&release
                // DVD Pick Of The Week: http://mobile.cinequest.org/mobileCQ.php?type=dvd&iphone&pick
                //
                //
                // Detail for Film Id: http://mobile.cinequest.org/mobileCQ.php?type=film&iphone&id=
                // Detail for DVD Id: http://mobile.cinequest.org/mobileCQ.php?type=dvd&iphone&id=
                //
                // Detail for Program Item: http://mobile.cinequest.org/mobileCQ.php?type=program_item&iphone&id=
                // Detail for Item: http://mobile.cinequest.org/mobileCQ.php?type=xml&name=items&iphone&id=
                
                // Done Loading Data... return.
                [activity stopAnimating];
                NSLog(@"Done.");
                statusLabel.text = @"Done.";
            }
            
            
        }
        else 
        {
            // alert
        }
        sqlite3_close(database);
        
    }
	//CinequestAppDelegate *delegate = (CinequestAppDelegate*)[[UIApplication sharedApplication] delegate];
	//[delegate loadTabBarController];
	return YES;
}
- (void)loadEVENTS {
	NSURL *link = [NSURL URLWithString:EVENTS];
	NSData *data = [NSData dataWithContentsOfURL:link];
	
	DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
	DDXMLNode *rootElement = [[xmlDoc rootElement] childAtIndex:1];
	
	NSLog(@"Loading events...");
	
	NSString *delete = @"DELETE FROM Events;";
	char *error;
	if(sqlite3_exec(database, [delete UTF8String], NULL, NULL, &error) != SQLITE_OK)
	{
		NSAssert(0, @"Failed to delete rows");
		sqlite3_free(error);
	}
	
	int childCount = [rootElement childCount];
	
	//NSLog(@"Events child count: %d",childCount);

	for (int i = 0; i < childCount; i++) 
	{
		DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
		NSDictionary *attributes = [child attributesAsDictionary];
		
		NSString *ID		= [attributes objectForKey:@"schedule_id"];
		NSString *prg_id	= [attributes objectForKey:@"program_item_id"];
		NSString *type		= [attributes objectForKey:@"type"];
		NSString *title		= [attributes objectForKey:@"title"];
		NSString *start		= [attributes objectForKey:@"start_time"];
		NSString *venue		= [attributes objectForKey:@"venue"];
		
		char *errorMsg;
		
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO Events VALUES (%@, %@, \"%@\", \"%@\", \"%@\", \"%@\");", 
						   ID, prg_id, type, title, start, venue];
		
		//NSLog(@"Query: %@", query);
		
		if(sqlite3_exec(database, [query UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK)
		{
			NSAssert(0, @"Failed to insert row");
			sqlite3_free(errorMsg);
		}
		
		
	}
}
- (void)loadFORUMS {
	NSURL *link = [NSURL URLWithString:FORUMS];
	NSData *data = [NSData dataWithContentsOfURL:link];
	
	DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
	DDXMLNode *rootElement = [xmlDoc rootElement];
	
	NSLog(@"Loading forums...");

	
	NSString *delete = @"DELETE FROM Forums;";
	char *error;
	if(sqlite3_exec(database, [delete UTF8String], NULL, NULL, &error) != SQLITE_OK)
	{
		NSAssert(0, @"Failed to delete rows");
		sqlite3_free(error);
	}
	
	int childCount = [rootElement childCount];
		
	for (int i = 0; i < childCount; i++) 
	{
		DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
		NSDictionary *attributes = [child attributesAsDictionary];
		
		NSString *ID		= [attributes objectForKey:@"schedule_id"];
		NSString *prg_id	= [attributes objectForKey:@"program_item_id"];
		NSString *type		= [attributes objectForKey:@"type"];
		NSString *title		= [attributes objectForKey:@"title"];
		NSString *start		= [attributes objectForKey:@"start_time"];
		NSString *venue		= [attributes objectForKey:@"venue"];
		//NSLog(@"%@",title);
		char *errorMsg;
		
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO Forums VALUES (%@, %@, \"%@\", \"%@\", \"%@\", \"%@\");", 
						   ID, prg_id, type, title, start, venue];
		
		
		if(sqlite3_exec(database, [query UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK)
		{
			NSAssert(0, @"Failed to insert row");
			sqlite3_free(errorMsg);
		}
		
		
		
	}
}
- (void)loadDVDs {
	NSURL *link = [NSURL URLWithString:DVDs];
	NSData *data = [NSData dataWithContentsOfURL:link];
	
	DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
	DDXMLNode *rootElement = [xmlDoc rootElement];
	
	NSLog(@"Loading dvds...");

	
	// Clear Table before insert new data
	NSString *delete = @"DELETE FROM DVDs;";
	char *error;
	if(sqlite3_exec(database, [delete UTF8String], NULL, NULL, &error) != SQLITE_OK)
	{
		NSAssert(0, @"Failed to delete rows");
		sqlite3_free(error);
	}
	
	
	int childCount = [rootElement childCount];
	for (int i = 0; i < childCount; i++) 
	{
		DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
		NSDictionary *attributes = [child attributesAsDictionary];
		
		NSString *ID		= [attributes objectForKey:@"id"];
		NSString *sort		= [attributes objectForKey:@"sort"];
		
		DDXMLNode *titleTag = [child childAtIndex:0];
		
		NSString *title = [titleTag stringValue];
		
		char *errorMsg;
		
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO DVDs VALUES (%@, \"%@\", \"%@\");", 
						   ID, title, sort];
		
		if(sqlite3_exec(database, [query UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK)
		{
			NSAssert(0, @"Failed to insert row");
			sqlite3_free(errorMsg);
		}
		
		
	}
}
- (void)loadFILMSBYTITLE {
	NSURL *link = [NSURL URLWithString:FILMSBYTITLE];
	NSData *data = [NSData dataWithContentsOfURL:link];
	
	NSLog(@"Loading filmsbytitle...");

	
	DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
	DDXMLNode *rootElement = [xmlDoc rootElement];
	
	// Clear Table before insert new data
	NSString *delete = @"DELETE FROM FilmsByTitle;";
	char *error;
	if(sqlite3_exec(database, [delete UTF8String], NULL, NULL, &error) != SQLITE_OK)
	{
		NSAssert(0, @"Failed to delete rows");
		sqlite3_free(error);
	}
	
	
	int childCount = [rootElement childCount];
	for (int i = 0; i < childCount; i++) 
	{
		DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
		NSDictionary *attributes = [child attributesAsDictionary];
		
		NSString *ID		= [attributes objectForKey:@"id"];
		NSString *sort		= [attributes objectForKey:@"sort"];
		
		DDXMLNode *titleTag = [child childAtIndex:0];
		
		NSString *title = [titleTag stringValue];
		
		char *errorMsg;
		
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO FilmsByTitle VALUES (%@, \"%@\", \"%@\");", 
						   ID, title, sort];
		
		if(sqlite3_exec(database, [query UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK)
		{
			NSAssert(0, @"Failed to insert row");
			sqlite3_free(errorMsg);
		}
		
		
	}
	
}
- (void)loadFILMSBYTIME {
	NSURL *link = [NSURL URLWithString:FILMSBYTIME];
	NSData *data = [NSData dataWithContentsOfURL:link];
	
	DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
	DDXMLNode *rootElement = [xmlDoc rootElement];
	
	/*
	NSLog(@"Loading filmsbytime...");

	
	NSString *delete = @"DELETE FROM FilmsByTime;";
	char *error;
	if(sqlite3_exec(database, [delete UTF8String], NULL, NULL, &error) != SQLITE_OK)
	{
	 NSAssert(0, @"Failed to delete rows");
	 sqlite3_free(error);
	}
	*/
	int childCount = [rootElement childCount];
	for (int i = 0; i < childCount; i++) 
	{
		DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
		NSDictionary *attributes = [child attributesAsDictionary];
		
		NSString *ID		= [attributes objectForKey:@"id"];
		NSString *prg_id	= [attributes objectForKey:@"program_item_id"];
		NSString *type		= [attributes objectForKey:@"type"];
		NSString *title		= [attributes objectForKey:@"title"];
		NSString *start		= [attributes objectForKey:@"start_time"];
		NSString *venue		= [attributes objectForKey:@"venue"];
		
		char *errorMsg;
		
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO FilmsByTime VALUES (%@, %@, \"%@\", \"%@\", \"%@\", \"%@\");", 
						   ID, prg_id, type, title, start, venue];
		
		
		if(sqlite3_exec(database, [query UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK)
		{
			NSAssert(0, @"Failed to insert row");
			sqlite3_free(errorMsg);
		}
		
		
	}
}
- (void)loadNEWS {
	NSURL *link = [NSURL URLWithString:NEWS];
	NSData *data = [NSData dataWithContentsOfURL:link];
	
	DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
	DDXMLElement *rootElement = [xmlDoc rootElement];
	
	NSLog(@"Loading news...");
	
	
	NSString *delete = @"DELETE FROM News;";
	char *error;
	if(sqlite3_exec(database, [delete UTF8String], NULL, NULL, &error) != SQLITE_OK)
	{
		NSAssert(0, @"Failed to delete rows");
		sqlite3_free(error);
	}
	
	int childCount = [rootElement childCount];
	//NSLog(@"%d",childCount);
	for (int i=0; i<childCount-1; i++) 
	{
		DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
		NSDictionary *attributes = [child attributesAsDictionary];
		
		NSString *section = [attributes objectForKey:@"name"];
		DDXMLElement *item = (DDXMLElement*)[child childAtIndex:0];
		//NSLog(@"%@",section);
		NSString *title = @"";
		NSString *date = @"";
		NSString *link = @"";
		NSString *imgurl = @"";
		
		for (int j=0; j<[item childCount]; j++) 
		{
			DDXMLElement *node = (DDXMLElement*)[item childAtIndex:j];
			if ([[node name] isEqualToString:@"title"]) {
				title = [node stringValue];
				//NSLog(@"%@",title);
			}
			if ([[node name] isEqualToString:@"date"]) {
				date = [node stringValue];
			}
			if ([[node name] isEqualToString:@"imageURL"]) {
				imgurl = [node stringValue];
				
			}
			if ([[node name] isEqualToString:@"link"]) {
				NSDictionary *nodeAttributes = [node attributesAsDictionary];
				link = [nodeAttributes objectForKey:@"id"];
			}
		}
		//NSLog(@"section: %@, title:%@, date: %@, link:%@, imgurl: %@",section,title,date,link,imgurl);
		char *errorMsg;
		
		if ([section isEqualToString:@"Header"]) {
			DDXMLElement *node = (DDXMLElement*)[item childAtIndex:0];
			imgurl = [node stringValue];
		}
		
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO News VALUES (\"%@\", \"%@\", \"%@\", \"%@\", \"%@\");", 
						   section, title, date, link, imgurl];
		
		
		if(sqlite3_exec(database, [query UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK)
		{
			NSAssert(0, @"Failed to insert row");
			sqlite3_free(errorMsg);
		}
		
	}
	
	
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
- (BOOL)connectedToNetwork {
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
	
	NSURL *testURL = [NSURL URLWithString:@"http://mobile.cinequest.org/mobileCQ.php?type=mode"];
	NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
	NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
	
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}


#pragma mark -
#pragma mark ActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 0:
			NSLog(@"0");
			break;
		case 1:
			NSLog(@"1");
			break;
		default:
			break;
	}
}



@end
