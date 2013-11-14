//
//  NewsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DataProvider.h"

@interface NewsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate>
{
	IBOutlet UITableView *_tableView;
	IBOutlet UIActivityIndicatorView *activityIndicator;
	IBOutlet UILabel *loadingLabel;
	//Stores a list of name
	NSMutableArray *sections;
	
	//Stores value: name of section
	//		 object: array of rows
	NSMutableDictionary *data;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *loadingLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
		   
@end
