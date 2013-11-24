//
//  VenueParser.h
//  Cinequest
//
//  Created by Dhwanil Karwa on 11/20/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@class Venue;

@interface VenueParser : NSObject

@property (strong, nonatomic) NSMutableDictionary *venueDictionary;

- (NSDictionary *) parseVenues;

@end
