//
//  Festival.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//


@class ProgramItem;
@class Film;
@class Special;
@class Forum;
@class CinequestItem;

@interface Festival : NSObject

@property (strong, nonatomic) NSMutableArray *programItems;
@property (strong, nonatomic) NSMutableArray *films;
@property (strong, nonatomic) NSMutableArray *schedules;
@property (strong, nonatomic) NSMutableArray *venueLocations;
//@property (strong, nonatomic) NSMutableArray *events;
@property (strong, nonatomic) NSString *lastChanged;

@property (strong, nonatomic) NSMutableArray *forums;
@property (strong, nonatomic) NSMutableArray *specials;

// data for Date segment in Films Tab
@property (strong, nonatomic) NSMutableDictionary *dateToFilmsDictionary;
@property (strong, nonatomic) NSMutableArray *sortedKeysInDateToFilmsDictionary;			// Sections
@property (strong, nonatomic) NSMutableArray *sortedIndexesInDateToFilmsDictionary;			// Films

// data for A-Z segment in Films Tab
@property (strong, nonatomic) NSMutableDictionary *alphabetToFilmsDictionary;				// Films
@property (strong, nonatomic) NSMutableArray *sortedKeysInAlphabetToFilmsDictionary;		// Sections

// data for Forums Tab
@property (strong, nonatomic) NSMutableDictionary *dateToForumsDictionary;
@property (strong, nonatomic) NSMutableArray *sortedKeysInDateToForumsDictionary;
@property (strong, nonatomic) NSMutableArray *sortedIndexesInDateToForumsDictionary;

// data for Events Tab
@property (strong, nonatomic) NSMutableDictionary *dateToSpecialsDictionary;
@property (strong, nonatomic) NSMutableArray *sortedKeysInDateToSpecialsDictionary;
@property (strong, nonatomic) NSMutableArray *sortedIndexesInDateToSpecialsDictionary;


- (NSMutableArray *) getSchedulesForDay:(NSString *)date;
- (Film *)getFilmForId:(NSString *)ID;
- (ProgramItem *) getProgramItemForId:(NSString *)ID;
- (Special *) getEventForId:(NSString *)ID;
- (Forum *) getForumForId:(NSString *)ID;
- (CinequestItem*) getScheduleItem:(NSString *)itemID;

@end
