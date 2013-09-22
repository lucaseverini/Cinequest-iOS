//
//  MySchedulerViewController.h
//  CineQuest
//
//  Created by someone on 11/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CinequestAppDelegate.h"

@interface MySchedulerViewController : UIViewController 
<UITableViewDelegate, UITableViewDataSource, NSXMLParserDelegate>
{
@public
	IBOutlet UITableView *_tableView;	
	IBOutlet UIImageView *CQIcon;
	IBOutlet UIImageView *SJSUIcon;
	IBOutlet UILabel *offSeasonLabel;
	NSString *username, *password, *retrievedTimeStamp, *status, *xmlStatus;
	
	//BOOL xmlSuccess;	
	
	
@private
	NSMutableArray *index;
	NSMutableArray *titleForSection;
	NSMutableArray *mySchedule;
	NSMutableDictionary *displayData;
	
	CinequestAppDelegate* delegate;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIImageView *CQIcon;
@property (nonatomic, retain) IBOutlet UIImageView *SJSUIcon;
@property (nonatomic, retain) IBOutlet UILabel *offSeasonLabel;
@property (nonatomic, retain) NSString *username, *password, *retrievedTimeStamp, *status, *xmlStatus;
//@property (readwrite) BOOL xmlSuccess;


- (IBAction)processLogin;
- (IBAction)saveFilms;
+(NSString *)incrementCQTime:(NSString *)CQdateTime;
- (IBAction)logIn:(id)sender;


@end
