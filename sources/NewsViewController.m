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

@interface NewsViewController (Private)

- (void)loadNewsFromDB;

@end


@implementation NewsViewController

@synthesize newsTableView;
@synthesize activityIndicator;

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"News";
	
	data = [NSMutableDictionary new];
	sections = [NSMutableArray new];

	tabBarAnimation = YES;

	self.newsTableView.tableHeaderView = nil;
	self.newsTableView.tableFooterView = nil;
	
	// Initialize
	[data removeAllObjects];
	[sections removeAllObjects];
	
	[self performSelectorOnMainThread:@selector(startParsingXML) withObject:nil waitUntilDone:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear: animated];
	
	activityIndicator.hidden = YES;
	
	if(tabBarAnimation)
	{
		[appDelegate.tabBarController.view setHidden:YES];
	}
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear: animated];

	if(tabBarAnimation)
	{
		// Don't show an ugly jerk while the bottom tabbar is drawed
		[UIView transitionWithView:appDelegate.tabBarController.view duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve
		animations:^
		{
			[appDelegate.tabBarController.view setHidden:NO];
		}
		completion:nil];
		
		tabBarAnimation = NO;
	}
}

- (void) startParsingXML
{
	NSData *xmlData = [[appDelegate dataProvider] news];
	
	NSString* myString = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
	myString = [myString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	myString = [myString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	xmlData = [myString dataUsingEncoding:NSUTF8StringEncoding];
	
	DDXMLDocument *newsXMLDoc = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:nil];
	DDXMLElement *rootElement = [newsXMLDoc rootElement];
	NSString *preSection = @"empty";
	NSMutableArray *temp = [NSMutableArray new];
	if([rootElement childCount] == 2)
	{
		NSInteger nodeCount = [rootElement childCount];
		for (NSInteger nodeIdx = 0; nodeIdx < nodeCount; nodeIdx++)
		{
			DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:nodeIdx];
			
			NSDictionary *attributes = [child attributesAsDictionary];
			NSString *section = [attributes objectForKey:@"name"];
			
			NSInteger subNodeCount = [child childCount];
			for (NSInteger subNodeIdx = 0; subNodeIdx < subNodeCount; subNodeIdx++)
			{
				DDXMLElement *item = (DDXMLElement*)[child childAtIndex:subNodeIdx];
				
				NSString *title = @"";
				NSString *link = @"";
							
				NSInteger subNode2Count = [item childCount];
				for (NSInteger subNodeIdx = 0; subNodeIdx < subNode2Count; subNodeIdx++)
				{
					DDXMLElement *node = (DDXMLElement*)[item childAtIndex:subNodeIdx];
					
					if ([[node name] isEqualToString:@"title"])
					{
						title = [node stringValue];
					}
					else if ([[node name] isEqualToString:@"link"])
					{
						NSDictionary *nodeAttributes = [node attributesAsDictionary];
						link = [nodeAttributes objectForKey:@"id"];
					}
				}
			
				NSMutableDictionary *info = [NSMutableDictionary new];
				[info setObject:title forKey:@"title"];
				[info setObject:link forKey:@"link"];
				
				if (![preSection isEqualToString:section])
				{
					[data setObject:temp forKey:preSection];
					
					preSection = [section copy];
					
					[sections addObject:section];
					
					temp = [NSMutableArray new];
					[temp addObject:info];
				}
				else
				{
					[temp addObject:info];
				}
			}
		}
	}
	else
	{
		NSLog(@"Error parsing XML");
		
		return;
	}

	[data setObject:temp forKey:preSection];

	[self.newsTableView reloadData];
}

- (IBAction) toFestival:(id)sender
{
	CinequestAppDelegate *delegate = appDelegate;
	delegate.tabBarController.selectedIndex = 0;
	delegate.isPresentingModalView = NO;
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark UITableView Data Source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSString *sectionString = [sections objectAtIndex:section];
	NSMutableArray *rows = [data objectForKey:sectionString];
	return [rows count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
	
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Set up the cell...
	NSString *sectionString = [sections objectAtIndex:section];
	
	NSMutableArray *rows = [data objectForKey:sectionString];
	NSMutableDictionary *rowData = [rows objectAtIndex:row];
									 
	cell.textLabel.text = [rowData objectForKey:@"title"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	return [sections objectAtIndex:section];
}

#pragma mark -
#pragma mark UITableView Delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *sectionString = [sections objectAtIndex:section];
	
	NSMutableArray *rows = [data objectForKey:sectionString];
	NSMutableDictionary *rowData = [rows objectAtIndex:row];

	NSString *eventId = [rowData objectForKey:@"link"];
	EventDetailViewController *eventDetail = [[EventDetailViewController alloc] initWithTitle:[rowData objectForKey:@"title"]
																						andDataObject:nil
																						andId:eventId];
	[self.navigationController pushViewController:eventDetail animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
