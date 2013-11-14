//
//  ForumsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CinequestAppDelegate.h"

@interface ForumsViewController : UIViewController <UIAccelerometerDelegate> {
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	
	NSMutableArray *days;
	NSMutableArray *index;
	NSMutableDictionary *data;
	
	NSMutableDictionary *backedUpData;
	NSMutableArray *backedUpDays;
	NSMutableArray *backedUpIndex;
	
	IBOutlet UITableView *_tableView;
	IBOutlet UIActivityIndicatorView *activity;
	IBOutlet UILabel *loadingLabel;
	IBOutlet UIImageView *SJSUIcon;
	IBOutlet UIImageView *CQIcon;
	IBOutlet UILabel *offSeasonLabel;
	
}

@property (nonatomic, strong) NSMutableArray *days;
@property (nonatomic, strong) NSMutableArray *index;
@property (nonatomic, strong) NSMutableDictionary *data;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, strong) IBOutlet UILabel *loadingLabel;
@property (nonatomic, strong) IBOutlet UILabel *offSeasonLabel;
@property (nonatomic, strong) IBOutlet UIImageView *SJSUIcon;
@property (nonatomic, strong) IBOutlet UIImageView *CQIcon;
- (IBAction)reloadData:(id)sender;

@end
