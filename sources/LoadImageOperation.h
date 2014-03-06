//
//  LoadImageOperation.h
//  CineQuest
//
//  Created by Luca Severini on 3/5/14.
//  Copyright (c) 2014 San Jose State University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoadImageOperation : NSOperation
{
	NSURL *imageUrl;
}

@property (atomic, strong) NSData *imageData;

- (id) initWithImageUrl:(NSURL*)url;

@end
