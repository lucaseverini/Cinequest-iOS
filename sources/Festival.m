//
//  Festival.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "Festival.h"


@implementation Festival

@synthesize programItems;
@synthesize films;
@synthesize schedules;
@synthesize venueLocations;
@synthesize lastChanged;
@synthesize events;

- (id)init {
    programItems = [[NSMutableArray alloc] init];
    films = [[NSMutableArray alloc] init];
    schedules = [[NSMutableArray alloc] init];
    venueLocations = [[NSMutableArray alloc] init];
    lastChanged = @"";
    events = [[NSMutableArray alloc] init];
    return self;
}

- (NSMutableArray *) getSchedulesForDay:(NSString *)date
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (int i = 0; i < [schedules count]; i++) {
        NewSchedule *schedule = (NewSchedule *) [schedules objectAtIndex:i];
        if ([schedule.startTime hasPrefix:date]) {
            [result addObject:schedule];
        }
    }
    return result;
}

- (Film *) getFilmForId:(NSString *)ID
{
    for (int i = 0; i < [films count]; i++) {
        Film *film = (Film *) [films objectAtIndex:i];
        if ([film.ID isEqualToString:ID])
            return film;
    }
    return nil;
}

- (ProgramItem *) getProgramItemForId:(NSString *)ID
{
    for (int i = 0; i < [programItems count]; i++) {
        ProgramItem *item = (ProgramItem *) [programItems objectAtIndex:i];
        if ([item.ID isEqualToString:ID])
            return item;
    }
    return nil;
}


@end
