//
//  NewSchedule.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/6/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "Venue.h"

@interface Schedule : NSObject

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *itemID;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSDate *startDate;		// @"yyyy-MM-dd'T'HH:mm:ss"
@property (nonatomic, strong) NSString *startTime;		// @"h:mm a"
@property (nonatomic, strong) NSString *endTime;		// @"h:mm a"

@property (nonatomic, strong) NSString *venue;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *longDateString;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, strong) NSString *endTimeString;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, strong) Venue *venueItem;

/* From the old Schedule.h
 
 @property (readwrite) NSUInteger ID;
 @property (readwrite) NSUInteger prog_id;
 @property (nonatomic, strong) UIColor *fontColor;
 @property (nonatomic, strong) NSString *title;
 @property (nonatomic, strong) NSString *type;
 @property (nonatomic, strong) NSString *venue;
 @property (nonatomic, strong) NSDate *date;
 @property (nonatomic, strong) NSDate *endDate;
 @property (nonatomic, strong) NSString *dateString;
 @property (nonatomic, strong) NSString *longDateString;
 @property (nonatomic, strong) NSString *timeString;
 @property (nonatomic, strong) NSString *endTimeString;
 @property (readwrite) BOOL isSelected;
 
 */

@end
