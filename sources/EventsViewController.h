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
	NSMutableDictionary *backedUpData;
	NSMutableArray *backedUpDays;
	NSMutableArray *backedUpIndex;
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
    UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;
}

@property (nonatomic, strong) IBOutlet UITableView *eventsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) NSMutableArray *index;
@property (nonatomic, strong) NSMutableArray *days;
@property (nonatomic, strong) NSMutableDictionary *data;

- (IBAction)reloadData:(id)sender;

@end
