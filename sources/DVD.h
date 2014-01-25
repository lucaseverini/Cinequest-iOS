//
//  DVD.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DVD : NSObject 
{
	NSUInteger ID;
	
	NSString *title;
	NSString *sort;
}

@property (readwrite) NSUInteger ID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *sort;

@end
