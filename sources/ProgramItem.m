//
//  ProgramItem.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestItem.h"
#import "ProgramItem.h"
#import "Film.h"

@implementation ProgramItem

@synthesize films;

- (id) init
{
	self = [super init];
	if(self != nil)
	{
		films = [[NSMutableArray alloc] init];
	}
	
    return self;
}

- (NSString *) getImageURL
{
    NSString *url = [super imageURL];
    if (url != nil) return url;
    if ([films count] > 0)
	{
        for (int i = 0; i < [films count]; i++)
		{
            Film *film = (Film *) [films objectAtIndex:i];
            url = [film imageURL];
            if (url != nil) return url;
        }
    }
    return nil;
}

@end
