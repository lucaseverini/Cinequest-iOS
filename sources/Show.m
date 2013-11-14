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
// Map<String, ArrayList<String>>
@synthesize customProperties;
// List<Showing>
@synthesize currentShowings;


- (id)init
{
    customProperties = [[NSMutableDictionary alloc] init];
    currentShowings = [[NSMutableArray alloc] init];
    return self;
}

@end
