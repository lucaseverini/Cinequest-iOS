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
}

@property (nonatomic, weak) IBOutlet UITableView *eventsTableView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, weak) IBOutlet UILabel *loadingLabel;
@property (nonatomic, strong) IBOutlet UIImageView *CQIcon;
@property (nonatomic, strong) IBOutlet UIImageView *SJSUIcon;
@property (nonatomic, strong) IBOutlet UILabel *offSeasonLabel;
@property (nonatomic, strong) NSMutableArray *index;
@property (nonatomic, strong) NSMutableArray *days;
@property (nonatomic, strong) NSMutableDictionary *data;

- (IBAction)reloadData:(id)sender;

@end
