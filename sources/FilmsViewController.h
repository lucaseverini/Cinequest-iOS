//
//  FilmsViewController.h
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
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
	BOOL statusBarHidden;
	NSDataDetector *dateDetector;
	BOOL searchActive;
}

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UISegmentedControl *switchTitle;
@property (nonatomic, strong) IBOutlet UITableView *filmsTableView;
@property (nonatomic, strong) IBOutlet UISearchBar *filmSearchBar;

@property (nonatomic, strong) NSMutableDictionary *dateToFilmsDictionary;
@property (nonatomic, strong) NSMutableArray *sortedKeysInDateToFilmsDictionary;			// Sections
@property (nonatomic, strong) NSMutableArray *sortedIndexesInDateToFilmsDictionary;			// Films
@property (nonatomic, strong) NSMutableDictionary *alphabetToFilmsDictionary;				// Films
@property (nonatomic, strong) NSMutableArray *sortedKeysInAlphabetToFilmsDictionary;		// Sections

- (IBAction) switchTitle:(id)sender;
- (IBAction) calendarButtonTapped:(id)sender event:(id)touchEvent;

@end
