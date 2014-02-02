//
//  ForumsViewController.h
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@class CinequestAppDelegate;

@interface ForumsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
    UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;    
	UIFont *sectionFont;
	NSDataDetector *dateDetector;
}

@property (nonatomic, strong) IBOutlet UITableView *forumsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UISegmentedControl *switchTitle;

@property (nonatomic, strong) NSMutableDictionary *dateToForumsDictionary;
@property (nonatomic, strong) NSMutableArray *sortedKeysInDateToForumsDictionary;
@property (nonatomic, strong) NSMutableArray *sortedIndexesInDateToForumsDictionary;

@end
