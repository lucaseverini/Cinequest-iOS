//
//  NewSchedule.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/6/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewSchedule : NSObject {
    NSString *ID;
    NSString *title;
    NSString *itemID;
    NSString *venue;
    NSString *startTime;
    NSString *endTime;
}

@property (strong, nonatomic) NSString *ID;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *itemID;
@property (strong, nonatomic) NSString *venue;
@property (strong, nonatomic) NSString *startTime;
@property (strong, nonatomic) NSString *endTime;

@end
