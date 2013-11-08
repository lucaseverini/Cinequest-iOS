//
//  DataProvider.m
//  Cinequest
//
//  Created by Luca Severini on 11/8/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "DataProvider.h"
#import "CinequestAppDelegate.h"

@implementation DataProvider

- (id) init
{
	self = [super init];
	if(self != nil)
	{
		cacheDir = [appDelegate cachesDirectory];
		
		NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:XML_FEED_FILE];
		NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL:fileUrl error:nil];
		NSData *xmlData = [file readDataOfLength:512];
		if(xmlData != nil)
		{
			xmlFeedDate = [self getFeedTimeStamp:xmlData];
		}
		[file closeFile];
	}
	
	return self;
}

- (NSData*) getXMLFeed;
{
	NSURL *url = [NSURL URLWithString:XML_FEED_URL];
	
	feedData = [[NSMutableData alloc] init];
	feedDataLen = 0;
	xmlFeedTimeStampChecked = NO;
	updatedXmlFeed = NO;
	
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
    if([NSURLConnection canHandleRequest:urlRequest])
    {
        NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:NO];
		
		[urlConnection start];
		
		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		
        keepRunning = YES;
        while(keepRunning)
        {
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        }
		
		[urlConnection cancel];
		
		if(!updatedXmlFeed)
		{
			feedData = nil;
			
			NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:XML_FEED_FILE];
			NSData *xmlData = [NSData dataWithContentsOfURL:fileUrl];
			NSLog(@"OLD XML Feed data:%d bytes", [xmlData length]);
			
			return xmlData;
		}
	}
	
	NSLog(@"NEW XML Feed data:%d bytes", feedDataLen);
	
	NSURL *fileUrl = [cacheDir URLByAppendingPathComponent:XML_FEED_FILE];
	[feedData writeToURL:fileUrl atomically:YES];
	
	NSData *xmlData = [NSData dataWithData:feedData];
	feedData = nil;
	
	return xmlData;
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	[feedData appendData:data];
	feedDataLen += [data length];
	
	if(feedDataLen >= 512 && !xmlFeedTimeStampChecked)
	{
		NSDate *date = [self getFeedTimeStamp:data];
		if(date != nil)
		{
			xmlFeedTimeStampChecked = YES;
			
			if(xmlFeedDate == nil || [xmlFeedDate compare:date] != NSOrderedSame)
			{
				xmlFeedDate = date;
				updatedXmlFeed = YES;
			}
			else
			{
				updatedXmlFeed = NO;
				keepRunning = NO;
			}
		}
	}
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    NSLog(@"didFailWithError: %@", [error localizedDescription]);
	
	keepRunning = NO;
}

- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
    NSLog(@"connectionDidFinishLoading");
	
	keepRunning = NO;
}

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    NSLog(@"didReceiveResponse: length:%lld", [response expectedContentLength]);
}

- (BOOL) updatedXMLFeedAvailable
{
	return updatedXmlFeed;
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

@end
