//
//  ForumsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
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

@property (nonatomic, retain) NSMutableArray *days;
@property (nonatomic, retain) NSMutableArray *index;
@property (nonatomic, retain) NSMutableDictionary *data;

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, retain) IBOutlet UILabel *loadingLabel;
@property (nonatomic, retain) IBOutlet UILabel *offSeasonLabel;
@property (nonatomic, retain) IBOutlet UIImageView *SJSUIcon;
@property (nonatomic, retain) IBOutlet UIImageView *CQIcon;
- (IBAction)reloadData:(id)sender;

@end
