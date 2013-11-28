//
//  Film.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "Film.h"

@implementation Film

@synthesize tagline;
@synthesize genre;
@synthesize director;
@synthesize producer;
@synthesize writer;
@synthesize cinematographer;
@synthesize editor;
@synthesize cast;
@synthesize country;
@synthesize language;
@synthesize filmInfo;

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
