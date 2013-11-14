//
//  VenueLocation.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestItem.h"

@interface VenueLocation : CinequestItem

@property (strong, nonatomic) NSString *venueAbbreviation;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSString *directionsURL;

@end
