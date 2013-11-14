//
//  Showing.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/4/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "Showing.h"
#import "Venue.h"


@implementation Showing

@synthesize ID;
@synthesize startDate;
@synthesize endDate;
@synthesize shortDescription;
@synthesize venue;

- (id) init
{
 	self = [super init];
	if(self != nil)
	{
		venue = [[Venue alloc] init];
	}
	
    return self;
}

@end

