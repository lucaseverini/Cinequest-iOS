//
//  ProgramItem.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestItem.h"

@interface ProgramItem : CinequestItem {
    NSMutableArray *films;
}

@property (strong, nonatomic) NSMutableArray *films;

@end
