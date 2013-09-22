//
//  DVD.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DVD : NSObject 
{
	NSUInteger ID;
	
	NSString *title;
	NSString *sort;
}

@property (readwrite) NSUInteger ID;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *sort;

@end
