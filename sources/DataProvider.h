//
//  DataProvider.h
//  Cinequest
//
//  Created by Luca Severini on 11/8/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

extern NSString *const kUpdatedXMLFeedNotification;

@interface DataProvider : NSObject
{
	NSInteger connectionError;
	BOOL keepRunning;
	BOOL xmlFeedTimeStampChecked;
	NSMutableData *feedData;
	NSUInteger feedDataLen;
	BOOL xmlFeedHasBeenUpdated;
	BOOL xmlFeedHasBeenDownloaded;
	NSURL *cacheDir;
	NSTimer *checkFeedTimer;
	BOOL justChecking;
	BOOL gettingXmlFeed;
	NSURLConnection *checkConnection;
	NSFileManager *fileMgr;
	NSURL *queryDatesUrl;
	NSMutableDictionary *queryDates;
}

@property (atomic, assign) BOOL xmlFeedUpdated;
@property (atomic, strong) NSDate *xmlFeedDate;

- (NSData*) xmlFeed;
- (void) reset;
- (NSData*) filmsByTime;
- (NSData*) filmsByTitle;
- (NSData*) news;
- (NSData*) events;
- (NSData*) forums;
- (NSData*) mode;
- (NSData*) image:(NSURL*)imageUrl expiration:(NSDate*)expirationDate;
- (NSData*) filmDetail:(NSString*)filmId;
- (NSData*) eventDetail:(NSString*)eventId;

@end
