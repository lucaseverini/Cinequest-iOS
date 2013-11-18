//
//  Schedule.h
//  CineQuest
//
//  Created by Loc Phan on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

@interface Schedule : NSObject 

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
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL presentInScheduler;
@property (nonatomic, assign) BOOL presentInCalendar;

@end
