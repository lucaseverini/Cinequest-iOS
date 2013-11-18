//
//  NewSchedule.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/6/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@interface Schedule : NSObject

@property (strong, nonatomic) NSString *ID;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *itemID;
@property (strong, nonatomic) NSString *venue;
@property (strong, nonatomic) NSDate *startDate; // @"yyyy-MM-dd'T'HH:mm:ss"
@property (strong, nonatomic) NSDate *endDate; // @"yyyy-MM-dd'T'HH:mm:ss"]
@property (strong, nonatomic) NSString *startTime; // @"h:mm a"
@property (strong, nonatomic) NSString *endTime; // @"h:mm a"
@property (strong, nonatomic) NSString *dateString; // @"EEE, MMM d"
@property (strong, nonatomic) NSString *longDateString; // @"EEEE, MMMM d"

@property (nonatomic, strong) UIColor *fontColor;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *venue;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *longDateString;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, strong) NSString *endTimeString;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL presentInScheduler;
@property (nonatomic, assign) BOOL presentInCalendar;

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
