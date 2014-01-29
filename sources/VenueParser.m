//
//  VenueParser.m
//  Cinequest
//
//  Created by Dhwanil Karwa on 11/20/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestAppDelegate.h"
#import "VenueParser.h"
#import "Venue.h"
#import "DDXML.h"
#import "DataProvider.h"

@implementation VenueParser

@synthesize venueDictionary;

- (id) init
{
 	self = [super init];
	if(self != nil)
	{
        venueDictionary = [[NSMutableDictionary alloc] init];
	}
	
    return self;
}

- (NSDictionary*) parseVenues
{
	NSData *responseData = [[appDelegate dataProvider] venues];
	
	NSString *myString = [[NSString alloc] initWithData:responseData encoding:NSISOLatin2StringEncoding];
	myString = [myString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	myString = [myString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	responseData = [myString dataUsingEncoding:NSISOLatin2StringEncoding];
	
	DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:responseData options:0 error:nil];
	DDXMLElement *atsFeed = [xmlDoc rootElement];
	
	for (int idx = 0; idx < [atsFeed childCount]; idx++)
	{
		DDXMLElement *showElement = (DDXMLElement*)[atsFeed childAtIndex:idx];
		Venue *venue1 = [[Venue alloc]init];
		
		for (int j = 0; j<[showElement childCount]; j++)
		{
			DDXMLElement *showChild = (DDXMLElement*)[showElement childAtIndex:j];
			if ([[showChild name] isEqualToString:@"ID"])
			{
				venue1.ID = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"Name"])
			{
				venue1.name = [showChild stringValue];
			}
            else if ([[showChild name] isEqualToString:@"ShortName"])
			{
				venue1.shortName = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"Address1"])
			{
				venue1.address1 = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"Address2"])
			{
				venue1.address2 = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"City"])
			{
				venue1.city = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"State"])
			{
				venue1.state = [showChild stringValue];
			}
            else if ([[showChild name] isEqualToString:@"Zip"])
			{
				venue1.zip = [showChild stringValue];
			}
            else if ([[showChild name] isEqualToString:@"location"])
			{
				venue1.location = [showChild stringValue];
			}
		}
		
        [self.venueDictionary setObject:venue1 forKey:venue1.ID];
	}
    
	appDelegate.venuesParsed = YES;

    return venueDictionary;
}

@end


