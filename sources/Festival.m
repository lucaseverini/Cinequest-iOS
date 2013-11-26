//
//  Festival.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "Festival.h"
#import "Schedule.h"
#import "Film.h"
#import "ProgramItem.h"


@implementation Festival

@synthesize programItems;
@synthesize films;
@synthesize schedules;
@synthesize venueLocations;
@synthesize lastChanged;
@synthesize events;

@synthesize sortedSchedules;
@synthesize sortedFilms;
@synthesize sortedSpecials;
@synthesize sortedForums;

- (id) init
{
	self = [super init];
	if(self != nil)
	{
		programItems = [[NSMutableArray alloc] init];
		films = [[NSMutableArray alloc] init];
		schedules = [[NSMutableArray alloc] init];
		venueLocations = [[NSMutableArray alloc] init];
		lastChanged = @"";
		events = [[NSMutableArray alloc] init];
        
        sortedSchedules = [[NSMutableDictionary alloc] init];
        sortedFilms = [[NSMutableDictionary alloc] init];
        sortedForums = [[NSMutableDictionary alloc] init];
        sortedSpecials = [[NSMutableDictionary alloc] init];
	}
	
    return self;
}

- (NSMutableArray *) getSchedulesForDay:(NSString *)date
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (int i = 0; i < [schedules count]; i++)
	{
        Schedule *schedule = (Schedule *) [schedules objectAtIndex:i];
        if ([schedule.startTime hasPrefix:date])
		{
            [result addObject:schedule];
        }
    }
	
    return result;
}

- (Film *) getFilmForId:(NSString *)ID
{
    for (int i = 0; i < [films count]; i++)
	{
        Film *film = (Film *) [films objectAtIndex:i];
        if ([film.ID isEqualToString:ID])
		{
            return film;
		}
    }
	
    return nil;
}

- (ProgramItem *) getProgramItemForId:(NSString *)ID
{
    for (int i = 0; i < [programItems count]; i++)
	{
        ProgramItem *item = (ProgramItem *) [programItems objectAtIndex:i];
        if ([item.ID isEqualToString:ID])
		{
            return item;
		}
    }
	
    return nil;
}

@end

