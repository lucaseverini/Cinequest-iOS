//
//  MySchedulerViewController.h
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@class CinequestAppDelegate;
@class EKEventStore;
@class EKCalendar;

@interface MySchedulerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, EKEventEditViewDelegate>
{
	NSMutableArray *index;
	NSMutableArray *titleForSection;
	NSMutableArray *mySchedule;
	NSMutableDictionary *displayData;
	CinequestAppDelegate* delegate;
    EKEventStore *eventStore;
    EKCalendar *cinequestCalendar;
	UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;
	UIFont *sectionFont;
	BOOL editActivatedFromButton;
}

@property (nonatomic, strong) IBOutlet UITableView *scheduleTableView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *switchTitle;

@end
