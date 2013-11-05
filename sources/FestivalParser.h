//
//  FestivalParser.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/4/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FestivalParser : NSObject {
    NSMutableArray *shows;
}

@property (strong, nonatomic) NSMutableArray *shows;
- (NSMutableArray *)getShows;
- (void) parseShows:(NSString *) url;

@end
