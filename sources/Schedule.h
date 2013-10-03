//
//  Schedule.h
//  CineQuest
//
//  Created by Loc Phan on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Schedule : NSObject 
{
	NSUInteger ID;
	NSUInteger prog_id;
	NSString *title;
	NSString *type;
	NSString *venue;
	
	UIColor *fontColor;
	
	NSDate *date;
	NSDate *endDate;
	
	NSString *dateString;
	NSString *timeString;
	NSString *endTimeString;
	
	BOOL isSelected;
	
}

@property (readwrite) NSUInteger ID;
@property (readwrite) NSUInteger prog_id;
@property (readwrite) BOOL isSelected;


@property (nonatomic, strong) UIColor *fontColor;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *venue;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, strong) NSString *endTimeString;

@end
