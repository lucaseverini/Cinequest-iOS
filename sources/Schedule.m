//
//  NewSchedule.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/6/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "Schedule.h"

@implementation Schedule

@synthesize ID;
@synthesize title;
@synthesize itemID;
@synthesize description;
@synthesize venue;
@synthesize startTime;
@synthesize endTime;
@synthesize startDate;
@synthesize endDate;
@synthesize dateString;
@synthesize longDateString;
@synthesize endTimeString;
@synthesize isSelected;

- (id) init
{
    self = [super init];
	if(self != nil)
	{
        if (!self.venueItem)
		{
            self.venueItem = [Venue new];
        }
    }
	
    return self;
}

@end
