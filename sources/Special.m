//
//  Special.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/26/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "Special.h"

@implementation Special

- (id) init
{
	self = [super init];
	if(self != nil)
	{
		super.schedules = [[NSMutableArray alloc] init];
	}
	
    return self;
}

- (void) dealloc
{
	super.schedules = nil;
}

@end
