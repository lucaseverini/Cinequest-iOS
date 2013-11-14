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
	NSString *username, *password, *retrievedTimeStamp, *status, *xmlStatus;
	//BOOL xmlSuccess;	
	
@private
	NSMutableArray *index;
	NSMutableArray *titleForSection;
	NSMutableArray *mySchedule;
	NSMutableDictionary *displayData;
	
	CinequestAppDelegate* delegate;
}

@property (nonatomic, weak) IBOutlet UITableView *scheduleTableView;
@property (nonatomic, weak) IBOutlet UIImageView *CQIcon;
@property (nonatomic, weak) IBOutlet UIImageView *SJSUIcon;
@property (nonatomic, weak) IBOutlet UILabel *offSeasonLabel;
@property (nonatomic, strong) NSString *username, *password, *retrievedTimeStamp, *status, *xmlStatus;
//@property (readwrite) BOOL xmlSuccess;


- (IBAction)processLogin;
- (IBAction)saveFilms;
+(NSString *)incrementCQTime:(NSString *)CQdateTime;
- (IBAction)logIn:(id)sender;


@end
