//
//  EventsViewController.h
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@class CinequestAppDelegate;

@interface EventsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>	
{
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
    UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;
}

@property (nonatomic, strong) IBOutlet UITableView *eventsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UISegmentedControl *switchTitle;

@property (nonatomic, strong) NSMutableDictionary *dateToEventsDictionary;
@property (nonatomic, strong) NSMutableArray *sortedKeysInDateToEventsDictionary;
@property (nonatomic, strong) NSMutableArray *sortedIndexesInDateToEventsDictionary;

@end
