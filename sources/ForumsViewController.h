//
//  ForumsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

@class CinequestAppDelegate;

@interface ForumsViewController : UIViewController <UIAccelerometerDelegate>
{
	CinequestAppDelegate *delegate;
	NSMutableArray *mySchedule;
	NSMutableDictionary *backedUpData;
	NSMutableArray *backedUpDays;
	NSMutableArray *backedUpIndex;
    UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;    
}

@property (nonatomic, strong) IBOutlet UITableView *forumsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) NSMutableArray *days;
@property (nonatomic, strong) NSMutableArray *index;
@property (nonatomic, strong) NSMutableDictionary *data;

- (IBAction) reloadData:(id)sender;

@end
