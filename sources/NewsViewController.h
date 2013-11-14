//
//  NewsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate>
{
	//Stores a list of name
	NSMutableArray *sections;
	
	//Stores value: name of section
	//		 object: array of rows
	NSMutableDictionary *data;
}
@property (nonatomic, weak) IBOutlet UITableView *newsTableView;
@property (nonatomic, weak) IBOutlet UILabel *loadingLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
		   

@end
