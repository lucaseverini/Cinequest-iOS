//
//  DataProvider.m
//  Cinequest
//
//  Created by Luca Severini on 11/8/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "DataProvider.h"
#import "CinequestAppDelegate.h"


#define NEWSFEED_TIMESTAMP_ENDPOSITION	256						// News feed time-stamp is contained within that number of bytes
#define NEWSFEED_CHECK_INTERVAL			120.0					// Interval in seconds between checking for an updated news feed
#define NEWSFEED_TIMEOUT				30.0					// Timeout in seconds for downloading the news feed
#define NEWSFEED_CHECK_RETRYINTERVAL	60.0					// Interval in seconds before retrying to download the news feed
#define CACHEFOLDER_CHECKINTERVAL		120.0					// Interval in seconds between checking the size of cache folder
#define CACHEFOLDER_MAXSIZE				(20L * 1024L * 1024L)	// Size upper limit for the cache folder. 20 MBytes
#define CACHEFOLDER_MINSIZE				(15L * 1024L * 1024L)	// Size lower limit for the cache folder. 15 MBytes
#define MAINFEED_FILE					@"MainFeed.xml"
#define FILMSBYTIME_FILE				@"FilmsByTime.xml"
#define FILMSBYTITLE_FILE				@"FilmsByTitle.xml"
#define NEWSFEED_FILE					@"NewsFeed.xml"
#define EVENTS_FILE						@"Events.xml"
#define FORUMS_FILE						@"Forums.xml"
#define VENUES_FILE						@"Venues.xml"
#define MODE_FILE						@"Mode.xml"
#define FILMDETAIL_FILE					@"FilmDetail.%d.xml"
#define EVENTDETAIL_FILE				@"EventDetail.%@.xml"
#define PROGRAMDETAIL_FILE				@"ProgramDetail.%d.xml"

@interface NSData (Private)

+ (id) dataWithNetURLShowingActivity:(NSURL*)url;

@end

@implementation NSData (Private)

+ (id) dataWithNetURLShowingActivity:(NSURL*)url
{
	app.networkActivityIndicatorVisible = YES;

	NSData *data = [NSData dataWithContentsOfURL:url];
	
	app.networkActivityIndicatorVisible = NO;

	return data;
}

@end


@implementation DataProvider

@synthesize newsFeedUpdated;
@synthesize newsFeedDate;

- (id) init
{
	self = [super init];
	if(self != nil)
	{
		fileMgr = [NSFileManager defaultManager];
		cacheDir = [NSURL URLWithString:CINEQUEST_DATACACHE_FOLDER relativeToURL:[appDelegate cachesDirectory]];
		
		if(![fileMgr fileExistsAtPath:[cacheDir path] isDirectory:nil])
		{
			if(![fileMgr createDirectoryAtPath:[cacheDir path] withIntermediateDirectories:YES attributes:nil error:nil])
			{
				NSLog(@"Error creating cache folder %@", [cacheDir path]);
				
				cacheDir = [appDelegate cachesDirectory]; // This can't fail...
			}
		}
		
		NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:NEWSFEED_FILE];
		NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL:fileUrl error:nil];
		NSData *xmlData = [file readDataOfLength:512];
		if(xmlData != nil)
		{
			self.newsFeedDate = [self getFeedTimeStamp:xmlData];
			NSLog(@"News Feed date:%@", self.newsFeedDate);
			
			newsFeedHasBeenDownloaded = YES;
		}
		[file closeFile];
		
		queryDatesUrl = [cacheDir URLByAppendingPathComponent:@"queryDates.plist"];
		queryDates = [NSMutableDictionary dictionaryWithContentsOfURL:queryDatesUrl];
		if(queryDates == nil)
		{
			queryDates = [NSMutableDictionary dictionaryWithCapacity:1000];
		}

		checkFeedTimer = [NSTimer timerWithTimeInterval:NEWSFEED_CHECK_INTERVAL target:self selector:@selector(checkNewsFeed) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:checkFeedTimer forMode:NSRunLoopCommonModes];
		[checkFeedTimer fire];

		checkFolderTimer = [NSTimer timerWithTimeInterval:CACHEFOLDER_CHECKINTERVAL target:self selector:@selector(checkCacheFolder) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:checkFolderTimer forMode:NSRunLoopCommonModes];
		[checkFolderTimer fire];
	}
	
	return self;
}

- (void) dealloc
{
	[queryDates writeToURL:queryDatesUrl atomically:YES];
	
	[checkFeedTimer invalidate];
}

- (void) reset
{
	[fileMgr removeItemAtURL:[cacheDir URLByAppendingPathComponent:MAINFEED_FILE] error:nil];

	self.newsFeedUpdated = NO;
	self.newsFeedDate = nil;

	// Remove all files from cache folder. Should be smarter
	NSDirectoryEnumerator *dirEnum = [fileMgr enumeratorAtPath:[cacheDir path]];
	NSString *fileName;
	while(fileName = [dirEnum nextObject])
	{
		NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:fileName];
		[fileMgr removeItemAtURL:fileUrl error:nil];
	}
	
	[checkFeedTimer fire];
}

- (NSData*) newsFeed
{
    NSLog(@"Getting news feed...");

	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:NEWSFEED_FILE];

	if(![appDelegate connectedToNetwork])
	{
		NSData *xmlData = [NSData dataWithContentsOfURL:fileUrl];
		NSLog(@"NO CONNECTION. Old news Feed data:%ld bytes", (unsigned long)[xmlData length]);
		
		return xmlData;
	}
	
	gettingNewsFeed = YES;

	feedData = [[NSMutableData alloc] init];
	feedDataLen = 0;
	newsFeedTimeStampChecked = NO;
	newsFeedHasBeenUpdated = NO;
	justChecking = NO;
	connectionError = noErr;
		
	NSURL *url = [NSURL URLWithString:NEWS_FEED];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:NEWSFEED_TIMEOUT];
    if([NSURLConnection canHandleRequest:urlRequest])
    {
        NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:NO];
		
		app.networkActivityIndicatorVisible = YES;

		[urlConnection start];
		
		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		
        keepRunning = YES;
        while(keepRunning)
        {
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        }
		
		[urlConnection cancel];
		
		app.networkActivityIndicatorVisible = NO;
		
		if(!newsFeedHasBeenUpdated || connectionError != noErr)
		{
			feedData = nil;
			
			if(newsFeedHasBeenDownloaded)
			{
				NSData *xmlData = [NSData dataWithContentsOfURL:fileUrl];
				
				if(connectionError != noErr)
				{
					NSLog(@"NO CONNECTION. Old news Feed data:%ld bytes", (unsigned long)[xmlData length]);
				}
				else
				{
					NSLog(@"Old news Feed data:%ld bytes", (unsigned long)[xmlData length]);
				}
				
				gettingNewsFeed = NO;
				
				return xmlData;
			}
			else
			{
				gettingNewsFeed = NO;
				
				return nil;
			}
		}
	}
	
	NSLog(@"NEW news Feed data:%ld bytes", (unsigned long)feedDataLen);
	
	[feedData writeToURL:fileUrl atomically:YES];
	
	NSData *xmlData = [NSData dataWithData:feedData];
	feedData = nil;
	
	newsFeedHasBeenDownloaded = YES;
	
	self.newsFeedUpdated = NO;
		
	gettingNewsFeed = NO;

	return xmlData;
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	if(connection == checkConnection)
	{
		if(gettingNewsFeed)
		{
			return;		// Abort checking if xml feed is being downloaded
		}
	}
	
	[feedData appendData:data];
	feedDataLen += [data length];
	
	if(feedDataLen >= NEWSFEED_TIMESTAMP_ENDPOSITION && !newsFeedTimeStampChecked)
	{
		NSDate *date = [self getFeedTimeStamp:data];
		if(date != nil)
		{
			newsFeedTimeStampChecked = YES;
			
			if(justChecking)
			{
				if(self.newsFeedDate == nil || [self.newsFeedDate compare:date] != NSOrderedSame)
				{
					self.newsFeedDate = date;
					newsFeedHasBeenUpdated = YES;
				}
				else
				{
					newsFeedHasBeenUpdated = NO;
				}

				keepRunning = NO;
			}
			else if(!newsFeedHasBeenDownloaded)
			{
				if(self.newsFeedDate == nil || [self.newsFeedDate compare:date] != NSOrderedSame)
				{
					self.newsFeedDate = date;
				}

				newsFeedHasBeenUpdated = YES;
			}
			else
			{
				if(self.newsFeedDate == nil || [self.newsFeedDate compare:date] != NSOrderedSame)
				{
					self.newsFeedDate = date;
					newsFeedHasBeenUpdated = YES;
				}
				else
				{
					newsFeedHasBeenUpdated = NO;
					keepRunning = NO;
				}
			}
		}
	}
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    NSLog(@"didFailWithError: %@", [error localizedDescription]);
	
	connectionError = [error code];
	
	keepRunning = NO;
}

- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
	keepRunning = NO;
}

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response
{
	if([response statusCode] >= 400)
	{
		NSLog(@"didReceiveResponse: Status Code:%ld", (long)[response statusCode]);

		keepRunning = NO;
	}
}

- (NSDate*) getFeedTimeStamp:(NSData*)data
{
	NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSInteger dataLen = [dataStr length];
	
	NSRange timeStampStart = [dataStr rangeOfString:@"<LastUpdated><![CDATA[" options:0];
	if(timeStampStart.location != NSNotFound)
	{
		NSInteger rangeStart = timeStampStart.location + timeStampStart.length;
		NSInteger rangeLen = dataLen - rangeStart;
		NSRange timeStampEnd = [dataStr rangeOfString:@"]]></LastUpdated>" options:0 range:NSMakeRange(rangeStart, rangeLen)];
		if(timeStampEnd.location != NSNotFound)
		{
			rangeStart = timeStampStart.location + timeStampStart.length;
			rangeLen = timeStampEnd.location - rangeStart;
			NSString *dateTimeStr = [dataStr substringWithRange:NSMakeRange(rangeStart, rangeLen)];
			
			NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
			[dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
			NSDate *date = [dateFormat dateFromString:dateTimeStr];
			
			return date;
		}
	}
	
	return nil;
}

- (void) checkCacheFolder
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		NSString *folderPath = [cacheDir path];
		NSDictionary *dirAttrib = [fileMgr attributesOfItemAtPath:folderPath error:nil];
		if(![cacheFolderDate isEqualToDate:[dirAttrib fileModificationDate]])
		{
			cacheFolderDate = [dirAttrib fileModificationDate];
			
			[NSThread sleepForTimeInterval:4.0];
			
			NSArray *files = [fileMgr subpathsOfDirectoryAtPath:folderPath error:nil];
			NSEnumerator *filesEnumerator = [files objectEnumerator];
			NSString *fileName;
			NSUInteger folderSize = 0;
			while(fileName = [filesEnumerator nextObject])
			{
				NSDictionary *fileAttrib = [fileMgr attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
				folderSize += [fileAttrib fileSize];
			}
			
			NSLog(@"CacheFolder size: %ld", (unsigned long)folderSize);
			
			if(folderSize > CACHEFOLDER_MAXSIZE)
			{
				NSLog(@"Cleaning cache folder...");

				files = [files sortedArrayUsingComparator:
				^(id fileA, id fileB)
				{
					NSDictionary *fileAttrib = [fileMgr attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileA] error:nil];
					NSDate *fileDateA = [fileAttrib fileModificationDate];

					fileAttrib = [fileMgr attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileB] error:nil];
					NSDate *fileDateB = [fileAttrib fileModificationDate];

					if([fileDateA earlierDate:fileDateB] == fileDateA)
					{
						return NSOrderedAscending;
					}
					else if([fileDateB earlierDate:fileDateA] == fileDateB)
					{
						return NSOrderedDescending;
					}
					else
					{
						return NSOrderedSame;
					}
				}];

				filesEnumerator = [files objectEnumerator];
				while(fileName = [filesEnumerator nextObject])
				{
					NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
					NSDictionary *fileAttrib = [fileMgr attributesOfItemAtPath:filePath error:nil];
					
					if([fileMgr removeItemAtPath:filePath error:nil])
					{
						folderSize -= [fileAttrib fileSize];
						if(folderSize < CACHEFOLDER_MINSIZE)
						{
							break;
						}
					}
				}
				
				NSLog(@"Cache folder cleaned.");
			}
		}
	});
}

- (void) checkNewsFeed
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		if(![appDelegate connectedToNetwork])
		{
			[checkFeedTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:NEWSFEED_CHECK_RETRYINTERVAL]];
			return;
		}
		else
		{
			[checkFeedTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:NEWSFEED_CHECK_INTERVAL]];
		}
		
		if(gettingNewsFeed)
		{
			return;
		}

		NSLog(@"Checking news feed...");
		
		NSURL *url = [NSURL URLWithString:NEWS_FEED];
		
		feedData = [[NSMutableData alloc] init];
		feedDataLen = 0;
		newsFeedTimeStampChecked = NO;
		newsFeedHasBeenUpdated = NO;
		justChecking = YES;
		connectionError = noErr;
		
		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:NEWSFEED_TIMEOUT];
		if([NSURLConnection canHandleRequest:urlRequest])
		{
			checkConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:NO];
			
			app.networkActivityIndicatorVisible = YES;

			[checkConnection start];
			
			NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
			
			keepRunning = YES;
			while(keepRunning)
			{
				[runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
			}
			
			[checkConnection cancel];

			app.networkActivityIndicatorVisible = NO;

			feedData = nil;
			
			if(gettingNewsFeed) // If the feed is being get the check can be aborted
			{
				return;
			}
			
			if(newsFeedHasBeenUpdated)
			{
				newsFeedHasBeenDownloaded = NO;

				if(!self.newsFeedUpdated)
				{
					self.newsFeedUpdated = YES;
				}
			}
		}
		
		NSLog(@"newsFeedUpdated:%@  Date:%@", self.newsFeedUpdated ? @"YES" : @"NO", self.newsFeedDate);
		
		if(self.newsFeedUpdated)
		{
			[appDelegate fetchFestival];
			[appDelegate fetchVenues];

			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:appDelegate.festival, @"festival", appDelegate.venuesDictionary, @"venues", nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:FEED_UPDATED_NOTIFICATION object:nil userInfo:userInfo];
			
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NewsUpdated"];
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FilmsUpdated"];
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"EventsUpdated"];
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ForumsUpdated"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	});
}

- (NSData*) filmsByTime
{
	NSLog(@"Getting filmsByTime...");

	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:FILMSBYTIME_FILE];
	NSString *key = @"FilmsByTimeDate";
	NSDate *queryDate = [queryDates objectForKey:key];
	
	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD filmsByTime...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(queryDate != nil && [queryDate compare:self.newsFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD filmsByTime...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.newsFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:FILMSBYTIME]];
	if(queryData != nil)
	{
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (NSData*) filmsByTitle
{
	NSLog(@"Getting filmsByTitle...");

	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:FILMSBYTITLE_FILE];
	NSString *key = @"FilmsByTitleDate";
	NSDate *queryDate = [queryDates objectForKey:key];
	
	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD filmsByTitle...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(queryDate != nil && [queryDate compare:self.newsFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD filmsByTitle...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.newsFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:FILMSBYTITLE]];
	if(queryData != nil)
	{
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (NSData*) mainFeed
{
	NSLog(@"Getting main feed...");

	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:MAINFEED_FILE];
	NSString *key = @"MainFeedDate";
	NSDate *queryDate = [queryDates objectForKey:key];
	
	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD news...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(queryDate != nil && [queryDate compare:self.newsFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD news...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.newsFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:MAIN_FEED]];
	if(queryData != nil)
	{
		// Temporary set the feed data for Debug
		if(queryData.length < 1024)
		{
			NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Fake_MainFeed" ofType:@"xml"];
			queryData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
			return queryData;
		}
		
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (NSData*) events
{
	NSLog(@"Getting events...");
	
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:EVENTS_FILE];
	NSString *key = @"EventsDate";
	NSDate *queryDate = [queryDates objectForKey:key];
	
	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD events...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(queryDate != nil && [queryDate compare:self.newsFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD events...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.newsFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:EVENTS]];
	if(queryData != nil)
	{
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (NSData*) forums
{
	NSLog(@"Getting forums...");
	
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:FORUMS_FILE];
	NSString *key = @"ForumsDate";
	NSDate *queryDate = [queryDates objectForKey:key];
	
	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD forums...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(queryDate != nil && [queryDate compare:self.newsFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD forums...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.newsFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:FORUMS]];
	if(queryData != nil)
	{
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (NSData*) venues
{
	NSLog(@"Getting venues...");
	
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:VENUES_FILE];
	NSString *key = @"VenuesDate";
	NSDate *queryDate = [queryDates objectForKey:key];
	
	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD venues...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(queryDate != nil && [queryDate compare:self.newsFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD venues...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.newsFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:VENUES]];
	if(queryData != nil)
	{
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (NSData*) mode
{
	NSLog(@"Getting mode...");
	
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:MODE_FILE];
	NSString *key = @"ModeDate";
	NSDate *queryDate = [queryDates objectForKey:key];
	
	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD mode...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(queryDate != nil && [queryDate compare:self.newsFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD mode...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.newsFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:MODE]];
	if(queryData != nil)
	{
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (void) saveQueryDates
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		[queryDates writeToURL:queryDatesUrl atomically:YES];
	});
}

- (void) saveQueryDate:(NSDate*)date forKey:(NSString*)key
{
	if(date != nil)
	{
		[queryDates setObject:date forKey:key];
	}
	else
	{
		[queryDates removeObjectForKey:key];
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		[queryDates writeToURL:queryDatesUrl atomically:YES];
	});
}

- (NSData*) image:(NSURL*)imageUrl expiration:(NSDate*)expirationDate
{
	NSString *imgPath = [[[imageUrl path] substringFromIndex:1] stringByReplacingOccurrencesOfString:@"/" withString:@"."];
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:imgPath];
	NSString *key = imgPath;
	NSDate *imageDate = [queryDates objectForKey:key];

	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD image...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(imageDate != nil || expirationDate != nil)
	{
		if(imageDate != nil && [imageDate compare:expirationDate] == NSOrderedAscending)
		{
			if([fileMgr fileExistsAtPath:[fileUrl path]])
			{
				NSLog(@"Getting OLD image...");
				
				return [NSData dataWithContentsOfURL:fileUrl];
			}
		}
		else
		{
			imageDate = expirationDate;
			[self saveQueryDate:imageDate forKey:key];
		}
	}
	else
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD image...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:imageUrl];
	if(queryData != nil)
	{
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (NSData*) filmDetail:(NSString *)filmId
{
	NSLog(@"Getting detail for film %@...", filmId);
	
	NSString *url = [NSString stringWithFormat:@"%@%@", DETAILFORFILMID, filmId];
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@",FILMDETAIL_FILE, filmId]];
	NSString *key = [NSString stringWithFormat:@"FilmDetail.%@", filmId];
	NSDate *queryDate = [queryDates objectForKey:key];
	
	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD detail...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(queryDate != nil && [queryDate compare:self.newsFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD detail...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.newsFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:url]];
	if(queryData != nil)
	{
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (NSData*) eventDetail:(NSString*)eventId
{
	NSLog(@"Getting detail for event %@...", eventId);
	
	NSString *url = [NSString stringWithFormat:@"%@%@", DETAILFORITEM, eventId];
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:[NSString stringWithFormat:EVENTDETAIL_FILE, eventId]];
	NSString *key = [NSString stringWithFormat:@"EventDetail.%@", eventId];
	NSDate *queryDate = [queryDates objectForKey:key];
	
	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD detail...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
		else
		{
			return nil;
		}
	}
	
	if(queryDate != nil && [queryDate compare:self.newsFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD detail...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.newsFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:url]];
	if(queryData != nil)
	{
		[queryData writeToURL:fileUrl atomically:YES];
		
		return queryData;
	}
	else
	{
		return [NSData dataWithContentsOfURL:fileUrl];
	}
}

- (NSString*) cacheImage:(NSString*)imageUrl
{
	if(imageUrl == nil)
	{
		return [[[NSBundle mainBundle] URLForResource:@"cqthumb" withExtension:@"jpg"] absoluteString]; // return the file url to placeholder image
	}
	
	BOOL imageCached = NO;
	
	imageUrl = [imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    // imageUrl = [imageUrl stringByReplacingOccurrencesOfString:@"\\" withString:@"/"]; // Cleanup to avoid errors in getting an NSURL
    
	NSURL *url = [NSURL URLWithString:imageUrl];
	NSString *fileName = [imageUrl lastPathComponent];
    
    // If url or imageURL is nil return URL of Placeholder Image
    if (url == nil || fileName.length == 0)
	{
		return [[[NSBundle mainBundle] URLForResource:@"cqthumb" withExtension:@"jpg"] absoluteString]; // return the file url to placeholder image
    }
    
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:fileName];
	NSString *filePath = [fileUrl path];

	if(![appDelegate connectedToNetwork])
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"NO CONNECTION. Getting OLD image...");
			
			return [fileUrl absoluteString];
		}
		else
		{
			return [[[NSBundle mainBundle] URLForResource:@"cqthumb" withExtension:@"jpg"] absoluteString]; // return the file url to placeholder image
		}
	}

	if([fileMgr fileExistsAtPath:filePath])
	{
		imageCached = YES;
		
		NSDictionary *fileAttrib = [fileMgr attributesOfItemAtPath:filePath error:nil];
		NSDate *imageDate = [fileAttrib fileModificationDate];
		
		// If the imageDate is the laterDate return the cached image
		if([imageDate laterDate:appDelegate.dataProvider.newsFeedDate] == imageDate)
		{
			return [fileUrl absoluteString];
		}
	}

	// Image either not cached or earlier than last news feed to download it
	NSData *imgData = [NSData dataWithContentsOfURL:url];
	if(imgData != nil)
	{
		[imgData writeToFile:filePath atomically:YES];
		
		return [fileUrl absoluteString];
	}
	else
	{
		if(imageCached)
		{
			return [fileUrl absoluteString];
		}
		else
		{
			return [[[NSBundle mainBundle] URLForResource:@"cqthumb" withExtension:@"jpg"] absoluteString]; // return the file url to placeholder image
		}
	}
}

@end



