//
//  DataProvider.m
//  Cinequest
//
//  Created by Luca Severini on 11/8/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "DataProvider.h"
#import "CinequestAppDelegate.h"

NSString *const kXmlFeedUpdatedNotification = @"XmlFeedUpdatedNotification";

#define XMLFEED_TIMESTAMP_ENDPOSITION	512				// XML feed time-stamp is contained within that number of bytes
#define XMLFEED_CHECK_INTERVAL			60				// In seconds
#define XMLFEED_TIMEOUT					30				// In seconds
#define XMLFEED_CHECK_RETRYINTERVAL		10.0			// 10 second retry interval
#define XMLFEED_FILE					@"XmlFeed.xml"
#define FILMSBYTIME_FILE				@"FilmsByTime.xml"
#define FILMSBYTITLE_FILE				@"FilmsByTitle.xml"
#define NEWS_FILE						@"News.xml"
#define EVENTS_FILE						@"Events.xml"
#define FORUMS_FILE						@"Forums.xml"
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

@synthesize xmlFeedUpdated;
@synthesize xmlFeedDate;

- (id) init
{
	self = [super init];
	if(self != nil)
	{
		fileMgr = [NSFileManager defaultManager];
		cacheDir = [appDelegate cachesDirectory];
		
		NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:XMLFEED_FILE];
		NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL:fileUrl error:nil];
		NSData *xmlData = [file readDataOfLength:512];
		if(xmlData != nil)
		{
			self.xmlFeedDate = [self getFeedTimeStamp:xmlData];
			NSLog(@"XML Feed date:%@", self.xmlFeedDate);
			
			xmlFeedHasBeenDownloaded = YES;
		}
		[file closeFile];
		
		queryDatesUrl = [cacheDir URLByAppendingPathComponent:@"queryDates.plist"];
		queryDates = [NSMutableDictionary dictionaryWithContentsOfURL:queryDatesUrl];
		if(queryDates == nil)
		{
			queryDates = [NSMutableDictionary dictionaryWithCapacity:1000];
		}

		checkFeedTimer = [NSTimer timerWithTimeInterval:XMLFEED_CHECK_INTERVAL target:self selector:@selector(checkXmlFeed) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:checkFeedTimer forMode:NSRunLoopCommonModes];
		
		[checkFeedTimer fire];
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
	[fileMgr removeItemAtURL:[cacheDir URLByAppendingPathComponent:XMLFEED_FILE] error:nil];

	self.xmlFeedUpdated = NO;
	self.xmlFeedDate = nil;

	// Remove all files from cache folder. Should be smarter
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[cacheDir path]];
	NSString *fileName;
	while(fileName = [dirEnum nextObject])
	{
		NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:fileName];
		[fileMgr removeItemAtURL:fileUrl error:nil];
	}
	
	[checkFeedTimer fire];
}

- (NSData*) xmlFeed;
{
    NSLog(@"Getting xml feed...");

	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:XMLFEED_FILE];

	if(![appDelegate connectedToNetwork])
	{
		NSData *xmlData = [NSData dataWithContentsOfURL:fileUrl];
		NSLog(@"NO CONNECTION. OLD XML Feed data:%d bytes", [xmlData length]);
		
		return xmlData;
	}
	
	gettingXmlFeed = YES;

	feedData = [[NSMutableData alloc] init];
	feedDataLen = 0;
	xmlFeedTimeStampChecked = NO;
	xmlFeedHasBeenUpdated = NO;
	justChecking = NO;
	connectionError = noErr;
		
	NSURL *url = [NSURL URLWithString:XML_FEED_URL];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:XMLFEED_TIMEOUT];
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
		
		if(!xmlFeedHasBeenUpdated || connectionError != noErr)
		{
			feedData = nil;
			
			if(xmlFeedHasBeenDownloaded)
			{
				NSData *xmlData = [NSData dataWithContentsOfURL:fileUrl];
				
				if(connectionError != noErr)
				{
					NSLog(@"NO CONNECTION. OLD XML Feed data:%d bytes", [xmlData length]);
				}
				else
				{
					NSLog(@"OLD XML Feed data:%d bytes", [xmlData length]);
				}
				
				gettingXmlFeed = NO;
				
				return xmlData;
			}
			else
			{
				gettingXmlFeed = NO;
				
				return nil;
			}
		}
	}
	
	NSLog(@"NEW XML Feed data:%d bytes", feedDataLen);
	
	[feedData writeToURL:fileUrl atomically:YES];
	
	NSData *xmlData = [NSData dataWithData:feedData];
	feedData = nil;
	
	xmlFeedHasBeenDownloaded = YES;
	
	self.xmlFeedUpdated = NO;
		
	gettingXmlFeed = NO;

	return xmlData;
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	if(connection == checkConnection)
	{
		if(gettingXmlFeed)
		{
			return;		// Abort checking if xml feed is being downloaded
		}
	}
	
	[feedData appendData:data];
	feedDataLen += [data length];
	
	if(feedDataLen >= XMLFEED_TIMESTAMP_ENDPOSITION && !xmlFeedTimeStampChecked)
	{
		NSDate *date = [self getFeedTimeStamp:data];
		if(date != nil)
		{
			xmlFeedTimeStampChecked = YES;
			
			if(justChecking)
			{
				if(self.xmlFeedDate == nil || [self.xmlFeedDate compare:date] != NSOrderedSame)
				{
					self.xmlFeedDate = date;
					xmlFeedHasBeenUpdated = YES;
				}
				else
				{
					xmlFeedHasBeenUpdated = NO;
				}

				keepRunning = NO;
			}
			else if(!xmlFeedHasBeenDownloaded)
			{
				if(self.xmlFeedDate == nil || [self.xmlFeedDate compare:date] != NSOrderedSame)
				{
					self.xmlFeedDate = date;
				}

				xmlFeedHasBeenUpdated = YES;
			}
			else
			{
				if(self.xmlFeedDate == nil || [self.xmlFeedDate compare:date] != NSOrderedSame)
				{
					self.xmlFeedDate = date;
					xmlFeedHasBeenUpdated = YES;
				}
				else
				{
					xmlFeedHasBeenUpdated = NO;
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
    NSLog(@"connectionDidFinishLoading");
	
	keepRunning = NO;
}

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response
{
	if([response statusCode] >= 400)
	{
		NSLog(@"didReceiveResponse: Status Code:%d", [response statusCode]);

		keepRunning = NO;
	}
}

- (NSDate*) getFeedTimeStamp:(NSData*)data
{
	NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSInteger dataLen = [dataStr length];
	
	NSRange timeStampStart = [dataStr rangeOfString:@"<LastUpdated " options:0];
	if(timeStampStart.location != NSNotFound)
	{
		NSInteger rangeStart = timeStampStart.location + timeStampStart.length;
		NSInteger rangeLen = dataLen - rangeStart;
		NSRange timeStampEnd = [dataStr rangeOfString:@"</LastUpdated>" options:0 range:NSMakeRange(rangeStart, rangeLen)];
		if(timeStampEnd.location != NSNotFound)
		{
			rangeStart = timeStampStart.location + timeStampStart.length;
			rangeLen = timeStampEnd.location - rangeStart;
			timeStampStart = [dataStr rangeOfString:@">" options:0 range:NSMakeRange(rangeStart, rangeLen)];
			
			rangeStart = timeStampStart.location + 1;
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

- (void) checkXmlFeed
{
	if(![appDelegate connectedToNetwork])
	{
		[checkFeedTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:XMLFEED_CHECK_RETRYINTERVAL]];
		return;
	}
	else
	{
		[checkFeedTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:XMLFEED_CHECK_INTERVAL]];
	}
	
	if(gettingXmlFeed)
	{
		return;
	}

    NSLog(@"Checking xml feed...");
	
	NSURL *url = [NSURL URLWithString:XML_FEED_URL];
	
	feedData = [[NSMutableData alloc] init];
	feedDataLen = 0;
	xmlFeedTimeStampChecked = NO;
	xmlFeedHasBeenUpdated = NO;
	justChecking = YES;
	connectionError = noErr;
	
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:XMLFEED_TIMEOUT];
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
		
		if(gettingXmlFeed) // If the feed is being get the check can be aborted
		{
			return;
		}
		
		if(xmlFeedHasBeenUpdated)
		{
			xmlFeedHasBeenDownloaded = NO;

			if(!self.xmlFeedUpdated)
			{
				self.xmlFeedUpdated = YES;
			}
		}
	}
	
	NSLog(@"xmlFeedUpdated:%@  Date:%@", self.xmlFeedUpdated ? @"YES" : @"NO", self.xmlFeedDate);
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
	
	if(queryDate != nil && [queryDate compare:self.xmlFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD filmsByTime...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.xmlFeedDate;
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
	
	if(queryDate != nil && [queryDate compare:self.xmlFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD filmsByTitle...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.xmlFeedDate;
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

- (NSData*) news
{
	NSLog(@"Getting news...");

	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:NEWS_FILE];
	NSString *key = @"NewsDate";
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
	
	if(queryDate != nil && [queryDate compare:self.xmlFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD news...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.xmlFeedDate;
		[self saveQueryDate:queryDate forKey:key];
	}
	
	NSData *queryData = [NSData dataWithNetURLShowingActivity:[NSURL URLWithString:NEWS]];
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
	
	if(queryDate != nil && [queryDate compare:self.xmlFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD events...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.xmlFeedDate;
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
	
	if(queryDate != nil && [queryDate compare:self.xmlFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD forums...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.xmlFeedDate;
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
	
	if(queryDate != nil && [queryDate compare:self.xmlFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD mode...");

			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.xmlFeedDate;
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
	NSLog(@"Getting image %@...", [imageUrl path]);

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

- (NSData*) filmDetail:(NSUInteger)filmId
{
	NSLog(@"Getting detail for film %d...", filmId);
	
	NSString *url = [NSString stringWithFormat:@"%@%d", DETAILFORFILMID, filmId];
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:[NSString stringWithFormat:FILMDETAIL_FILE, filmId]];
	NSString *key = [NSString stringWithFormat:@"FilmDetail.%d", filmId];
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
	
	if(queryDate != nil && [queryDate compare:self.xmlFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD detail...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.xmlFeedDate;
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
	
	if(queryDate != nil && [queryDate compare:self.xmlFeedDate] == NSOrderedSame)
	{
		if([fileMgr fileExistsAtPath:[fileUrl path]])
		{
			NSLog(@"Getting OLD detail...");
			
			return [NSData dataWithContentsOfURL:fileUrl];
		}
	}
	else
	{
		queryDate = self.xmlFeedDate;
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

@end



