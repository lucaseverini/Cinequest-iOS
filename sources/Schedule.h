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


@property (nonatomic, retain) UIColor *fontColor;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *venue;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSString *dateString;
@property (nonatomic, retain) NSString *timeString;
@property (nonatomic, retain) NSString *endTimeString;

@end
