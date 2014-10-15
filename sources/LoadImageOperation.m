//
//  LoadImageOperation.m
//  CineQuest
//
//  Created by Luca Severini on 3/5/14.
//  Copyright (c) 2014 San Jose State University. All rights reserved.
//

#import "LoadImageOperation.h"

@implementation LoadImageOperation

@synthesize imageData;

// Init the image with the url
- (id) initWithImageUrl:(NSURL*)url
{
	self = [super init];
    if(self != nil)
    {
		imageUrl = url;
    }
    
    return self;
}

- (void) main 
{	    
	if([self isCancelled])
	{
		NSLog(@"Loading image %@ canceled", imageUrl);
		return;
	}
	
    NSError *error = nil;
	imageData = [NSData dataWithContentsOfURL:imageUrl options:NSDataReadingMappedIfSafe error:&error];
	if(imageData == nil)
	{
		NSLog(@"Error %@ loading image %@", error.localizedDescription, imageUrl);
	}
}

@end
