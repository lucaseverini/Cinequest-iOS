//
//  Venue.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/4/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Venue : NSObject {
    NSString *ID;
    NSString *name;
    NSString *address;
}

@property (strong, nonatomic) NSString *ID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *address;

@end
