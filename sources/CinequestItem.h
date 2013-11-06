//
//  CinequestItem.h
//  Cinequest
//
//  Created by Hai Nguyen on 11/5/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CinequestItem : NSObject {
    NSString *ID;
    NSString *name;
    NSString *description;
    NSString *imageURL;
}

@property (strong, nonatomic) NSString *ID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSString *imageURL;


@end
