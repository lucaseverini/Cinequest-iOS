//
//  NewsViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

@interface NewsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate>
{
	BOOL tabBarAnimation;
}

@property (nonatomic, strong) IBOutlet UISegmentedControl *switchTitle;
@property (nonatomic, strong) IBOutlet UITableView *newsTableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) NSMutableArray *news;

@end
