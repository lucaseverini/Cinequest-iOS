//
//  Showing.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/4/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Venue.h"

@interface Showing : NSObject {
    NSString *ID;
    NSString *startDate;
    NSString *endDate;
    NSString *shortDescription;
    Venue *venue;
}

@property (strong, nonatomic) NSString *ID;
@property (strong, nonatomic) NSString *startDate;
@property (strong, nonatomic) NSString *endDate;
@property (strong, nonatomic) NSString *shortDescription;
@property (strong, nonatomic) Venue *venue;

@end
