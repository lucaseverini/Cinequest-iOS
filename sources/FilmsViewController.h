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
}

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, weak) IBOutlet UISegmentedControl *switchTitle;
@property (nonatomic, weak) IBOutlet UITableView *filmsTableView;
@property (nonatomic, weak) IBOutlet UISearchBar *filmSearchBar;

@property (nonatomic, strong) NSMutableDictionary *dateToFilmsDictionary;
@property (nonatomic, strong) NSMutableArray *sortedKeysInDateToFilmsDictionary;			// Sections
@property (nonatomic, strong) NSMutableArray *sortedIndexesInDateToFilmsDictionary;			// Films
@property (nonatomic, strong) NSMutableDictionary *alphabetToFilmsDictionary;				// Films
@property (nonatomic, strong) NSMutableArray *sortedKeysInAlphabetToFilmsDictionary;		// Sections

- (IBAction) switchTitle:(id)sender;
- (IBAction) calendarButtonTapped:(id)sender event:(id)touchEvent;

@end
