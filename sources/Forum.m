//
//  Forum.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/26/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "Forum.h"

@implementation Forum

- (id) init
{
	self = [super init];
	if(self != nil)
	{
		super.shortItems = [[NSMutableArray alloc] init];
        super.schedules = [[NSMutableArray alloc] init];
	}
	
    return self;
}

- (void) dealloc
{
    super.shortItems = nil;
	super.schedules = nil;
}

@end

