//
//  EventsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

@class CinequestAppDelegate;

@interface EventsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>	
{
	NSMutableDictionary *backedUpData;
	NSMutableArray *backedUpDays;
	NSMutableArray *backedUpIndex;
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
}

@property (nonatomic, strong) IBOutlet UITableView *eventsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, strong) IBOutlet UILabel *loadingLabel;
@property (nonatomic, strong) IBOutlet UILabel *offSeasonLabel;
@property (nonatomic, strong) NSMutableArray *index;
@property (nonatomic, strong) NSMutableArray *days;
@property (nonatomic, strong) NSMutableDictionary *data;

- (IBAction)reloadData:(id)sender;

@end
