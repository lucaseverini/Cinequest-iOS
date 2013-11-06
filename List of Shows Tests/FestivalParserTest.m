//
//  FestivalParserTest.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FestivalParser.h"
#import "Festival.h"
#import "Film.h"
#import "VenueLocation.h"
#import "NewSchedule.h"

@interface FestivalParserTest : XCTestCase

@end

@implementation FestivalParserTest {
    Festival *festival;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    FestivalParser *festivalParser = [[FestivalParser alloc] init];
    festival = [festivalParser parseFestival:@"http://payments.cinequest.org/websales/feed.ashx?guid=70d8e056-fa45-4221-9cc7-b6dc88f62c98&showslist=true"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testShow6906
{
    Film *film = [festival getFilmForId:@"6906"];
    ProgramItem *item = [festival getProgramItemForId:@"6906"];
    XCTAssertTrue([@"7 Lives Of Chance" isEqualToString:film.name]);
    XCTAssertTrue([film isEqual:[item.films objectAtIndex:0]]);
    XCTAssertTrue([@"Jodi Chase, John Pelkey, Richard Regan Paul, Michele Feren, Maria Regan, John-Archer Ludgreen, Victoria Jelstrom Swilley, Samantha O'Hare, Olivia Miller, Banks Helfrich" isEqualToString: film.cast]);
}

- (void) testSchedulesFor6906
{
    int found = 0;
    for (id obj in [festival schedules]) {
        NewSchedule *schedule = (NewSchedule *) obj;
        if ([schedule.ID isEqualToString:@"7268"]) {
            XCTAssertTrue([@"6906" isEqualToString:schedule.itemID]);
            XCTAssertTrue([schedule.startTime hasPrefix:@"2013-02-28"]);
            XCTAssertTrue([schedule.endTime hasSuffix:@"20:41:00"]);
            XCTAssertTrue([@"C12S10" isEqualToString:[schedule venue]]);
        }
        if ([schedule.itemID isEqualToString:@"6906"]) found++;
    }
    XCTAssertTrue(3 == found);
}

- (void) testShortsProgram3
{
    ProgramItem *item = [festival getProgramItemForId:@"7117"];
    XCTAssertTrue([[item name] hasPrefix:@"Shorts Program 3: "]);
    XCTAssertTrue(8 == [[item films] count]);
    XCTAssertTrue([[[item.films objectAtIndex:0] name] isEqualToString:@"Abigail"]);
    
}

- (NewSchedule *) getScheduleForId:(NSString *)ID
{
    for (id obj in [festival schedules]) {
        NewSchedule *schedule = (NewSchedule *) obj;
        if ([schedule.ID isEqualToString:ID])
            return schedule;
    }
    return nil;
}

- (VenueLocation *) getVenueLocationForAbbrev:(NSString *) abbrev
{
    for (id obj in festival.venueLocations) {
        VenueLocation *venue = (VenueLocation *) obj;
        if ([venue.venueAbbreviation isEqualToString:abbrev])
            return venue;
    }
    return nil;
}

- (void) testScheduleForFilm6909
{
    Film *film = [festival getFilmForId:@"6909"];
    XCTAssertTrue(4 == [[film schedules] count]);
    XCTAssertTrue([[film schedules] containsObject:[self getScheduleForId:@"7346"]]);
    XCTAssertTrue([[film schedules] containsObject:[self getScheduleForId:@"7347"]]);
    XCTAssertTrue([[film schedules] containsObject:[self getScheduleForId:@"7348"]]);
    XCTAssertTrue([[film schedules] containsObject:[self getScheduleForId:@"8609"]]);
}

- (void) testScheduleForShortFilm
{
    ProgramItem *item = [festival getProgramItemForId:@"7121"];
    XCTAssertTrue(8 == [[item films] count]);
    for (Film *film in [item films]) {
        XCTAssertTrue(3 == [[film schedules] count]);
        XCTAssertTrue([[film schedules] containsObject:[self getScheduleForId:@"7375"]]);
    }
}

- (void) testVenues
{
    XCTAssertTrue(10 == [[festival venueLocations] count]);
    VenueLocation *venue = [self getVenueLocationForAbbrev:@"C12S7"];
    XCTAssertTrue([venue.name isEqualToString:@"Camera 12 - Screen 7"]);
    XCTAssertTrue([venue.location isEqualToString:@"201 S. Second Street"]);
    XCTAssertTrue([@"C12S7" isEqualToString:[self getScheduleForId:@"7373"].venue]);
}

@end

