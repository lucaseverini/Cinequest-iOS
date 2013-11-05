//
//  Show.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/4/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Show : NSObject {
    NSString *ID;
    NSString *name;
    NSUInteger duration;
    NSString *shortDescription;
    NSString *thumbImageURL;
    NSString *eventImageURL;
    NSString *infoLink;
    NSMutableDictionary *customProperties;
    NSMutableArray *currentShowings;
}

@property (strong, nonatomic) NSString *ID;
@property (strong, nonatomic) NSString *name;
@property NSUInteger duration;
@property (strong, nonatomic) NSString *shortDescription;
@property (strong, nonatomic) NSString *thumbImageURL;
@property (strong, nonatomic) NSString *eventImageURL;
@property (strong, nonatomic) NSString *infoLink;
@property (strong, nonatomic) NSMutableDictionary *customProperties;
@property (strong, nonatomic) NSMutableArray *currentShowings;

@end

