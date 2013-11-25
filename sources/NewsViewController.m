//
//  NewsViewController.m
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NewsViewController.h"
#import "CinequestAppDelegate.h"
#import "EventDetailViewController.h"
#import "DDXML.h"
#import "DataProvider.h"

static NSString *const kNewsCellIdentifier = @"NewsCell";


@implementation NewsViewController

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
	
	self.title = @"News";

	tabBarAnimation = YES;
		
	news = [NSMutableArray new];

	self.newsTableView.tableHeaderView = nil;
	self.newsTableView.tableFooterView = nil;
		
	[self performSelectorOnMainThread:@selector(startParsingXML) withObject:nil waitUntilDone:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear: animated];
	
	activityIndicator.hidden = YES;
	
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

- (void) startParsingXML
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
				NSString *imageUrl = @"";
				NSString *info = @"";
							
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
							imageUrl = [newsSubNode stringValue];
						}
						else if ([subNodename isEqualToString:@"InfoLink"])
						{
							info = [newsSubNode stringValue];
						}
					}
				
					NSMutableDictionary *newsItem = [NSMutableDictionary new];
					[newsItem setObject:name forKey:@"name"];
					[newsItem setObject:description forKey:@"description"];
					[newsItem setObject:imageUrl forKey:@"image"];
					[newsItem setObject:info forKey:@"info"];
					
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNewsCellIdentifier];
    if(cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kNewsCellIdentifier];
    }
    
	NSMutableDictionary *newsData = [news objectAtIndex:row];
									 
	cell.textLabel.text = [newsData objectForKey:@"name"];
	cell.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
	cell.textLabel.numberOfLines = 2;
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

#pragma mark -
#pragma mark UITableView Delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = [indexPath row];
	NSMutableDictionary *newsData = [news objectAtIndex:row];

	EventDetailViewController *eventDetail = [[EventDetailViewController alloc] initWithNews:newsData];
	[self.navigationController pushViewController:eventDetail animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 54.0;
}

@end
