//
//  NewFestivalParser.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/28/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Festival;
@class CinequestAppDelegate;

@interface NewFestivalParser : NSObject
{
    CinequestAppDelegate *delegate;
}

@property (strong, nonatomic) NSMutableArray *shows;

- (NSMutableArray *)getShows;
- (void) parseShows;
- (Festival*) parseFestival;

@end
