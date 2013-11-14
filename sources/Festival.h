//
//  Festival.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "NewSchedule.h"
#import "Film.h"
#import "ProgramItem.h"

@interface Festival : NSObject

@property (strong, nonatomic) NSMutableArray *programItems;
@property (strong, nonatomic) NSMutableArray *films;
@property (strong, nonatomic) NSMutableArray *schedules;
@property (strong, nonatomic) NSMutableArray *venueLocations;
@property (strong, nonatomic) NSString *lastChanged;
@property (strong, nonatomic) NSMutableArray *events;

- (NSMutableArray *) getSchedulesForDay:(NSString *)date;
- (Film *) getFilmForId:(NSString *)ID;
- (ProgramItem *) getProgramItemForId:(NSString *)ID;

@end
