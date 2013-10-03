//
//  EventsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CinequestAppDelegate.h"
@interface EventsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>	
{
	
	NSMutableDictionary *data;
	NSMutableArray *days;
	NSMutableArray *index;
	
	NSMutableDictionary *backedUpData;
	NSMutableArray *backedUpDays;
	NSMutableArray *backedUpIndex;
	
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	
	IBOutlet UITableView *_tableView;
	IBOutlet UIActivityIndicatorView *activity;
	IBOutlet UILabel *loadingLabel;
	IBOutlet UIImageView *CQIcon;
	IBOutlet UIImageView *SJSUIcon;
	IBOutlet UILabel *offSeasonLabel;

}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, strong) IBOutlet UILabel *loadingLabel;
@property (nonatomic, strong) IBOutlet UIImageView *CQIcon;
@property (nonatomic, strong) IBOutlet UIImageView *SJSUIcon;
@property (nonatomic, strong) IBOutlet UILabel *offSeasonLabel;
@property (nonatomic, strong) NSMutableArray *index;
@property (nonatomic, strong) NSMutableArray *days;
@property (nonatomic, strong) NSMutableDictionary *data;

- (IBAction)reloadData:(id)sender;

@end
