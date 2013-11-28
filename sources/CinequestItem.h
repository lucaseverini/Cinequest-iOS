//
//  CinequestItem.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@interface CinequestItem : NSObject

@property (strong, nonatomic) NSString *ID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSString *imageURL;
@property (strong, nonatomic) NSString *infoLink;

@property (strong, nonatomic) NSMutableArray *shortItems;
@property (strong, nonatomic) NSMutableArray *schedules;

@end
