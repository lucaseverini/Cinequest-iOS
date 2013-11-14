//
//  FilmsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CinequestAppDelegate.h"

@interface FilmsViewController : UIViewController < UITableViewDelegate, UITableViewDataSource >
{
	NSMutableDictionary *data;
	NSMutableArray *days;
	NSMutableArray *index;
	NSMutableDictionary *backedUpData;
	NSMutableArray *backedUpDays;
	NSMutableArray *backedUpIndex;
	NSMutableDictionary *titlesWithSort;
	NSMutableArray *sorts;
	NSMutableArray *mySchedule;
	NSInteger switcher;
	CinequestAppDelegate *delegate;
}

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, strong) IBOutlet UILabel *loadingLabel;
@property (nonatomic, strong) IBOutlet UISegmentedControl *switchTitle;
@property (nonatomic, strong) IBOutlet UITableView *table;

- (IBAction)switchTitle:(id)sender;
- (IBAction)reloadData:(id)sender;

@end
