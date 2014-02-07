//
//  NewsViewController.m
//  CineQuest
//
//  Created by Luca Severini on 10/1/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestAppDelegate.h"
#import "NewsViewController.h"
#import "NewsDetailViewController.h"
#import "DDXML.h"
#import "DataProvider.h"

static NSString *const kNewsCellIdentifier = @"NewsCell";


@implementation NewsViewController

@synthesize switchTitle;
@synthesize newsTableView;
@synthesize activityIndicator;
@synthesize news;

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
	tabBarAnimation = YES;
		
	news = [NSMutableArray new];

	newsTableView.tableHeaderView = nil;
	newsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	
	titleFont = [UIFont systemFontOfSize:[UIFont labelFontSize]];

	NSDictionary *attribute = [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:16.0f] forKey:NSFontAttributeName];
	[switchTitle setTitleTextAttributes:attribute forState:UIControlStateNormal];
	[switchTitle removeSegmentAtIndex:1 animated:NO];
	
	[self performSelectorOnMainThread:@selector(loadData) withObject:nil waitUntilDone:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear: animated];
	
	if(tabBarAnimation)
	{
		[appDelegate.tabBar.view setHidden:YES];
	}
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear: animated];

	if(tabBarAnimation)
	{
		// Don't show an ugly jerk while the bottom tabbar is drawn
		[UIView transitionWithView:appDelegate.tabBar.view duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve
		animations:^
		{
			[appDelegate.tabBar.view setHidden:NO];
		}
		completion:nil];
		
		tabBarAnimation = NO;
	}
}

#pragma mark -
#pragma mark - Private Methods

- (void) loadData
{
	[news removeAllObjects];
	
	NSData *xmlData = [[appDelegate dataProvider] newsFeed];
	
	NSString* myString = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
	myString = [myString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	myString = [myString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	xmlData = [myString dataUsingEncoding:NSUTF8StringEncoding];
	
	DDXMLDocument *newsXMLDoc = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:nil];
	DDXMLElement *rootElement = [newsXMLDoc rootElement];

	NSInteger nodeCount = [rootElement childCount];
	for (NSInteger nodeIdx = 0; nodeIdx < nodeCount; nodeIdx++)
	{
		DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:nodeIdx];
		NSString *chilName = [child name];
		
		if ([chilName isEqualToString:@"ArrayOfNews"])
		{
			NSInteger subNodeCount = [child childCount];
			for (NSInteger subNodeIdx = 0; subNodeIdx < subNodeCount; subNodeIdx++)
			{
				DDXMLElement *newsNode = (DDXMLElement*)[child childAtIndex:subNodeIdx];
				
				NSString *name = @"";
				NSString *description = @"";
				NSString *eventImageUrl = @"";
				NSString *info = @"";
				NSString *thumbImageUrl = @"";
							
				NSInteger subNode2Count = [newsNode childCount];
				if(subNode2Count != 0)
				{
					for (NSInteger subNodeIdx = 0; subNodeIdx < subNode2Count; subNodeIdx++)
					{
						DDXMLElement *newsSubNode = (DDXMLElement*)[newsNode childAtIndex:subNodeIdx];
						NSString *subNodename = [newsSubNode name];
						
						if ([subNodename isEqualToString:@"Name"])
						{
							name = [newsSubNode stringValue];
						}
						else if ([subNodename isEqualToString:@"ShortDescription"])
						{
							description = [newsSubNode stringValue];
						}
						else if ([subNodename isEqualToString:@"EventImage"])
						{
							eventImageUrl = [newsSubNode stringValue];
						}
						else if ([subNodename isEqualToString:@"InfoLink"])
						{
							info = [newsSubNode stringValue];
						}
						else if ([subNodename isEqualToString:@"ThumbImage"])
						{
							thumbImageUrl = [newsSubNode stringValue];
						}
					}
				
					NSMutableDictionary *newsItem = [NSMutableDictionary new];
					[newsItem setObject:name forKey:@"name"];
					[newsItem setObject:description forKey:@"description"];
					[newsItem setObject:eventImageUrl forKey:@"eventImage"];
					[newsItem setObject:info forKey:@"info"];
					[newsItem setObject:thumbImageUrl forKey:@"thumbImage"];
					
					[news addObject:newsItem];
				}
			}
		}
	}

	[self.newsTableView reloadData];
}

- (IBAction) toFestival:(id)sender
{
	CinequestAppDelegate *delegate = appDelegate;
	delegate.tabBar.selectedIndex = 0;
	delegate.isPresentingModalView = NO;
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark UITableView Data Source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [news count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = [indexPath row];
	NSMutableDictionary *newsData = [news objectAtIndex:row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNewsCellIdentifier];
    if(cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kNewsCellIdentifier];
	}
	else
	{
		[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	
	CGSize imgSize = CGSizeMake(0.0, 0.0);
	NSString *imageUrl = [newsData objectForKey:@"thumbImage"];
	if(imageUrl.length != 0)
	{
		imageUrl = [appDelegate.dataProvider cacheImage:imageUrl];
		if(imageUrl.length != 0)
		{
			UIImage *image = [UIImage imageWithContentsOfFile:[[NSURL URLWithString:imageUrl] path]];
			imgSize = [image size];
			
			UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15.0, 6.0, imgSize.width, imgSize.height)];
			imageView.tag = CELL_IMAGE_TAG;
			imageView.image = image;
			[cell.contentView addSubview:imageView];
		}
	}
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 4.0 + imgSize.height, 305.0, 48.0)];
	titleLabel.tag = CELL_TITLE_LABEL_TAG;
	titleLabel.font = titleFont;
	titleLabel.numberOfLines = 2;
	titleLabel.text = [newsData objectForKey:@"name"];

	CGSize size = [titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
	if(size.width < 285.0)
	{
		[titleLabel setFrame:CGRectMake(15.0, 4.0 + imgSize.height, 305.0, 26.0)];
		titleLabel.numberOfLines = 1;
	}
	
	[cell.contentView addSubview:titleLabel];

	// cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
    return cell;
}

#pragma mark -
#pragma mark UITableView Delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = [indexPath row];
	NSDictionary *newsData = [news objectAtIndex:row];

	NewsDetailViewController *eventDetail = [[NewsDetailViewController alloc] initWithNews:newsData];
	[self.navigationController pushViewController:eventDetail animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSMutableDictionary *newsData = [news objectAtIndex:[indexPath row]];

	CGFloat height = 54.0;
	NSString *text = [newsData objectForKey:@"name"];
	CGSize size = [text sizeWithAttributes:@{ NSFontAttributeName : titleFont }];
	if(size.width < 285.0)
	{
		height = 34.0;
	}

	NSString *imageUrl = [newsData objectForKey:@"thumbImage"];
	if(imageUrl.length != 0)
	{
		imageUrl = [appDelegate.dataProvider cacheImage:imageUrl];
		if(imageUrl.length != 0)
		{
			UIImage *image = [UIImage imageWithContentsOfFile:[[NSURL URLWithString:imageUrl] path]];
			if(imageUrl != nil)
			{
				return height + [image size].height;
			}
		}
	}

	return height;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.01;		// This creates a "invisible" footer
}

@end



