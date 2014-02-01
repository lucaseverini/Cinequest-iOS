//
//  Show.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/4/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "Show.h"

@implementation Show

@synthesize ID;
@synthesize name;
@synthesize duration;
@synthesize shortDescription;
@synthesize thumbImageURL;
@synthesize eventImageURL;
@synthesize infoLink;
@synthesize customProperties;
@synthesize currentShowings;
@synthesize sequenceDictionary;

- (id) init
{
	self = [super init];
	if(self != nil)
	{
		customProperties = [[NSMutableDictionary alloc] init];
		currentShowings = [[NSMutableArray alloc] init];
        sequenceDictionary = [NSMutableDictionary dictionary];
	}
	
    return self;
}

@end
