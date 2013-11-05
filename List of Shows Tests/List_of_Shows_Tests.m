//
//  List_of_Shows_Tests.m
//  List of Shows Tests
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//


#import <XCTest/XCTest.h>
#import "CinequestAppDelegate.h"
#import "FestivalParser.h"
#import "Show.h"
#import "Showing.h"
#import "Venue.h"

@interface List_of_Shows_Tests : XCTestCase

@end

@implementation List_of_Shows_Tests {
    NSMutableArray *shows;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    FestivalParser *festivalParser = [[FestivalParser alloc] init];
    [festivalParser parseShows:XML_FEED_URL];
    shows = [festivalParser getShows];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testShows
{
    XCTAssertTrue([shows count] > 0);
}

- (void) testFirstAndLastShow
{
    Show *show = [shows objectAtIndex:0];
    XCTAssertTrue([@"6906" isEqualToString:show.ID]);
    show = [shows objectAtIndex:(shows.count - 1)];
    XCTAssertTrue([@"7034" isEqualToString:show.ID]);
}

- (void) testVenue
{
    Show *show = [shows objectAtIndex:0];
    Showing *showing = [show.currentShowings objectAtIndex:0];
    Venue *venue = showing.venue;
    XCTAssertTrue([@"Camera 12 - Screen 10" isEqualToString:venue.name]);
    
    show = [shows objectAtIndex:([shows count] - 2)];
    showing = [show.currentShowings objectAtIndex:2];
    venue = showing.venue;
    XCTAssertTrue([@"Camera 12 - Screen 8" isEqualToString:venue.name]);
}

- (void) testCustomProperty
{
    Show *show = [shows objectAtIndex:0];
    NSMutableDictionary *customProperties = show.customProperties;
    NSMutableArray *values = [customProperties objectForKey:@"Category"];
    XCTAssertTrue([@"LAUGHS" isEqualToString:[values objectAtIndex:0]]);
}

- (void) testShowingTime
{
    Show *show = [shows objectAtIndex:([shows count] - 3)];
    Showing *showing = [show.currentShowings objectAtIndex:0];
    XCTAssertTrue([@"2013-03-02T10:00:00" isEqualToString:showing.startDate]);
}

@end
