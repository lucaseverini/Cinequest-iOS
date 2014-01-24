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
#import "Special.h"
#import "ProgramItem.h"


@implementation Festival

@synthesize programItems;
@synthesize films;
@synthesize schedules;
@synthesize venueLocations;
@synthesize lastChanged;
//@synthesize events;

@synthesize forums;
@synthesize specials;

@synthesize dateToFilmsDictionary;
@synthesize sortedKeysInDateToFilmsDictionary;
@synthesize sortedIndexesInDateToFilmsDictionary;

@synthesize alphabetToFilmsDictionary;
@synthesize sortedKeysInAlphabetToFilmsDictionary;
//@synthesize sortedIndexesInAlphabetToFilmsDictionary;

@synthesize dateToForumsDictionary;
@synthesize sortedKeysInDateToForumsDictionary;
@synthesize sortedIndexesInDateToForumsDictionary;

@synthesize dateToSpecialsDictionary;
@synthesize sortedKeysInDateToSpecialsDictionary;
@synthesize sortedIndexesInDateToSpecialsDictionary;


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
        
        forums = [[NSMutableArray alloc]  init];
        specials = [[NSMutableArray alloc] init];
        
        dateToFilmsDictionary = [[NSMutableDictionary alloc] init];
        sortedKeysInDateToFilmsDictionary = [[NSMutableArray alloc] init];
        sortedIndexesInDateToFilmsDictionary = [[NSMutableArray alloc] init];
        
        alphabetToFilmsDictionary = [[NSMutableDictionary alloc] init];
        sortedKeysInAlphabetToFilmsDictionary = [[NSMutableArray alloc] init];
        sortedIndexesInDateToFilmsDictionary = [[NSMutableArray alloc] init];
        
        dateToForumsDictionary = [[NSMutableDictionary alloc] init];
        sortedKeysInDateToForumsDictionary = [[NSMutableArray alloc] init];
        sortedIndexesInDateToForumsDictionary = [[NSMutableArray alloc] init];
        
        dateToSpecialsDictionary = [[NSMutableDictionary alloc] init];
        sortedKeysInDateToSpecialsDictionary = [[NSMutableArray alloc] init];
        sortedIndexesInDateToSpecialsDictionary = [[NSMutableArray alloc] init];
	}
	
    return self;
}

- (NSMutableArray *) getSchedulesForDay:(NSString *)date
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (int i = 0; i < [schedules count]; i++)
	{
        Schedule *schedule = [schedules objectAtIndex:i];
        if ([schedule.startTime hasPrefix:date])
		{
            [result addObject:schedule];
        }
    }
	
    return result;
}

- (Special *) getEventForId:(NSString *)ID
{
    for (int i = 0; i < [specials count]; i++)
	{
        Special *event = [specials objectAtIndex:i];
        if ([event.ID isEqualToString:ID])
		{
            return event;
		}
    }
	
    return nil;
}

- (Film *) getFilmForId:(NSString *)ID
{
    for (int i = 0; i < [films count]; i++)
	{
        Film *film = [films objectAtIndex:i];
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

