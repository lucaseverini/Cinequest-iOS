//
//  DataProvider.h
//  Cinequest
//
//  Created by Luca Severini on 11/8/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataProvider : NSObject
{
	BOOL keepRunning;
	BOOL xmlFeedTimeStampChecked;
	NSMutableData *feedData;
	NSUInteger feedDataLen;
	BOOL updatedXmlFeed;
	NSDate *xmlFeedDate;
	NSURL *cacheDir;
}

- (NSData*) getXMLFeed;
- (BOOL) updatedXMLFeedAvailable;

@end
