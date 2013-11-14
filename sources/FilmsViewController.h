//
//  FilmsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CinequestAppDelegate.h"

@interface FilmsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAccelerometerDelegate>
{
@public
	IBOutlet UIImageView *SJSUIcon;
	IBOutlet UIImageView *CQIcon;
	IBOutlet UILabel *offSeasonLabel;
@private	
	NSMutableDictionary *data;
	NSMutableArray *days;
	NSMutableArray *index;
	
	NSMutableDictionary *backedUpData;
	NSMutableArray *backedUpDays;
	NSMutableArray *backedUpIndex;
	
	NSMutableDictionary *TitlesWithSort;
	NSMutableArray *sorts;
	
	NSMutableArray *mySchedule;
	
	int switcher;
	int refineOrBack;

	CinequestAppDelegate *delegate;
	
}
@property (nonatomic, strong) IBOutlet UILabel *offSeasonLabel;
@property (nonatomic, strong) IBOutlet UIImageView *SJSUIcon;
@property (nonatomic, strong) IBOutlet UIImageView *CQIcon;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, weak) IBOutlet UILabel *loadingLabel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *switchTitle;
@property (nonatomic, weak) IBOutlet UITableView *filmsTableView;


- (IBAction)switchTitle:(id)sender;
- (IBAction)reloadData:(id)sender;

@end
