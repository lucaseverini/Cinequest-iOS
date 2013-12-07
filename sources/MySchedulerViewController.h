//
//  MySchedulerViewController.h
//  CineQuest
//
//  Created by someone on 11/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
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
	NSMutableArray *confirmedList;
	NSMutableArray *movedList;
	NSMutableArray *removedList;
	NSMutableArray *currentList;
	NSArray *masterList;			// contains all the lists (confirmed, moved, removed)
	UIColor *currentColor;			// used to help color code the removed,confirmed,moved state of films (NSXMLPARSER Delegate)
	NSDate *previousEndDate;		// a pointer to a previous date to compare schedule conflicts
	UITableViewCell *previousCell;
    EKEventStore *eventStore;
    EKCalendar *cinequestCalendar;
	UIFont *titleFont;
	UIFont *timeFont;
	UIFont *venueFont;    
}

@property (nonatomic, strong) IBOutlet UITableView *scheduleTableView;
@property (nonatomic, strong) IBOutlet UILabel *offSeasonLabel;

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *retrievedTimeStamp;
@property (nonatomic, strong) NSString *status;

+ (NSString*) incrementCQTime:(NSString*)CQdateTime;

@end
