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
	BOOL newsFeedTimeStampChecked;
	NSMutableData *feedData;
	NSUInteger feedDataLen;
	BOOL newsFeedHasBeenUpdated;
	BOOL newsFeedHasBeenDownloaded;
	NSURL *cacheDir;
	NSTimer *checkFeedTimer;
	NSTimer *checkFolderTimer;
	BOOL justChecking;
	BOOL gettingNewsFeed;
	NSURLConnection *checkConnection;
	NSFileManager *fileMgr;
	NSURL *queryDatesUrl;
	NSMutableDictionary *queryDates;
	NSDate *cacheFolderDate;
}

@property (atomic, assign) BOOL newsFeedUpdated;
@property (atomic, strong) NSDate *newsFeedDate;

- (NSData*) mainFeed;
- (NSData*) newsFeed;
- (NSData*) filmsByTime;
- (NSData*) filmsByTitle;
- (NSData*) events;
- (NSData*) forums;
- (NSData*) venues;
- (NSData*) mode;
- (NSData*) image:(NSURL*)imageUrl expiration:(NSDate*)expirationDate;
- (NSData*) filmDetail:(NSString*)filmId;
- (NSData*) eventDetail:(NSString*)eventId;
- (NSString*) cacheImage:(NSString*)imageUrl;
- (void) reset;

@end
