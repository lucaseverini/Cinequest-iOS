//
//  FilmsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

@class CinequestAppDelegate;

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
	CGFloat listByDateOffset;
	CGFloat listByTitleOffset;
	UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;
}

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, weak) IBOutlet UISegmentedControl *switchTitle;
@property (nonatomic, weak) IBOutlet UITableView *filmsTableView;

- (IBAction) switchTitle:(id)sender;
- (IBAction) reloadData:(id)sender;

@end
