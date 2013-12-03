//
//  FilmsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
// 

@class CinequestAppDelegate;
@class Schedule;
@class Festival;

@interface FilmsViewController : UIViewController < UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate>
{
	NSMutableArray *mySchedule;
	NSInteger switcher;
	CinequestAppDelegate *delegate;
	CGFloat listByDateOffset;
	CGFloat listByTitleOffset;
	UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;
    EKCalendar *cinequestCalendar;
    EKEventStore *eventStore;
	NSMutableArray *curSchedules;
	NSMutableArray *curFilms;
}

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, weak) IBOutlet UISegmentedControl *switchTitle;
@property (nonatomic, weak) IBOutlet UITableView *filmsTableView;
@property (nonatomic, weak) IBOutlet UISearchBar *filmSearchBar;

- (IBAction) switchTitle:(id)sender;
- (IBAction) calendarButtonTapped:(id)sender event:(id)touchEvent;

@end
