//
//  DVDsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CinequestAppDelegate.h"


@interface DVDsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	
	
	NSMutableArray *order;
	NSMutableDictionary *data;
	
	IBOutlet UITableView *_tableView;
	IBOutlet UIActivityIndicatorView *activity;
	IBOutlet UILabel *loadingLabel;
	
}

@property (nonatomic, retain) NSMutableArray *order;
@property (nonatomic, retain) NSMutableDictionary *data;

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, retain) IBOutlet UILabel *loadingLabel;

@end
