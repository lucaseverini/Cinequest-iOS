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

@property (nonatomic, strong) NSMutableArray *order;
@property (nonatomic, strong) NSMutableDictionary *data;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, strong) IBOutlet UILabel *loadingLabel;

@end
