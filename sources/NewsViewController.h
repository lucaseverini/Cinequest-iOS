//
//  NewsViewController.h
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@interface NewsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate>
{
	BOOL tabBarAnimation;
}

@property (nonatomic, strong) IBOutlet UITableView *newsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) NSMutableArray *news;

@end
