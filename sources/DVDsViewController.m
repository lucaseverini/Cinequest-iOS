//
//  DVDsViewController.m
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DVDsViewController.h"
#import "LoadDataViewController.h"
#import "FilmDetail.h"
#import "DVD.h"
#import "DDXML.h"
#import "NewsViewController.h"

@interface DVDsViewController (Private)

- (void) loadDataFromDatabase;

@end


@implementation DVDsViewController


#pragma mark -
#pragma mark Memory Management
@synthesize order;
@synthesize data;
@synthesize activity;
@synthesize loadingLabel;
@synthesize tableView = _tableView;


#pragma mark -
#pragma mark UIViewController Methods

- (void)viewDidLoad {
    [super viewDidLoad];
	

	data = [[NSMutableDictionary alloc] init];
	order = [[NSMutableArray alloc] init];
		
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"CQ Pick"
																			 style:UIBarButtonItemStylePlain
																			target:self
																			action:@selector(pickOfTheWeek:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"New Release"
																			  style:UIBarButtonItemStylePlain
																			 target:self
																			 action:@selector(newRelease:)];
	
	[activity startAnimating];
	[NSThread detachNewThreadSelector:@selector(startParsingXML) toTarget:self withObject:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
    [_tableView deselectRowAtIndexPath:tableSelection animated:NO];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark Actions

#define PICKOFTHEWEEK @"http://mobile.cinequest.org/mobileCQ.php?type=dvd&iphone&pick"
#define NEWRELEASE @"http://mobile.cinequest.org/mobileCQ.php?type=dvd&iphone&release"

- (void)pickOfTheWeek:(id)sender {
	NSURL *url = [NSURL URLWithString:PICKOFTHEWEEK];
	DVD *temp = [[DVD alloc] init];
	FilmDetail *detail = [[FilmDetail alloc] initWithTitle:@"" andDataObject:temp andURL:url];
	[self.navigationController pushViewController:detail animated:YES];
}
- (void)newRelease:(id)sender {
	NSURL *url = [NSURL URLWithString:NEWRELEASE];
	DVD *temp = [[DVD alloc] init];
	FilmDetail *detail = [[FilmDetail alloc] initWithTitle:@"" andDataObject:temp andURL:url];
	[self.navigationController pushViewController:detail animated:YES];
}

#pragma mark -
#pragma mark Private Methods
- (void)startParsingXML {
	@autoreleasepool {
		NSURL *link = [NSURL URLWithString:DVDs];
		NSData *dvddata = [NSData dataWithContentsOfURL:link];
		
		DDXMLDocument *dvdxmlDoc = [[DDXMLDocument alloc] initWithData:dvddata options:0 error:nil];
		DDXMLNode *rootElement = [dvdxmlDoc rootElement];
		
		int childCount = [rootElement childCount];
		
		NSString *previousLetter = @"empty";
		NSMutableArray *tempArray = [[NSMutableArray alloc] init];
		for (int i = 0; i < childCount; i++) {
			DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
			NSDictionary *attributes = [child attributesAsDictionary];
			
			NSString *ID		= [attributes objectForKey:@"id"];
			NSString *sort		= [attributes objectForKey:@"sort"];
			
			DVD *dvd		= [[DVD alloc] init];
			
			dvd.ID			= [ID intValue];
			
			dvd.title		= [child stringValue];
			dvd.sort		= sort;
			
			NSString *letter = dvd.sort;
			
			if (![previousLetter isEqualToString:letter]) {
				[data setObject:tempArray forKey:previousLetter];
				
				previousLetter = [[NSString alloc] initWithString:letter];
				[order addObject:previousLetter];
				
				
				tempArray = [[NSMutableArray alloc] init];
				[tempArray addObject:dvd];
			} else {
				[tempArray addObject:dvd];
			}
			
			
		}
		[data setObject:tempArray forKey:previousLetter];
		
		[activity stopAnimating];
		loadingLabel.hidden = YES;
		[self.tableView reloadData];
		self.tableView.hidden = NO;

	}
}
#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [order count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSString *letter = [order objectAtIndex:section];
	NSMutableArray *dvds = [data objectForKey:letter];
    return [dvds count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
	
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Set up the cell...
	NSString *letter = [order objectAtIndex:section];
	
	NSMutableArray *dvds = [data objectForKey:letter];
	
	DVD *dvd = [dvds objectAtIndex:row];
	
	cell.textLabel.font = [UIFont systemFontOfSize:16.0f];
	cell.textLabel.text = dvd.title;
	
    return cell;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *letter = [order objectAtIndex:section];
	return letter;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView
{
	return order;
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *date = [order objectAtIndex:section];
	
	NSMutableArray *dvds = [data objectForKey:date];
	
	DVD *dvd = [dvds objectAtIndex:row];
	
	NSString *link = [NSString stringWithFormat:@"%@%d",DETAILFORDVDID,dvd.ID];
	
	FilmDetail *film = [[FilmDetail alloc] initWithTitle:dvd.title
										   andDataObject:dvd
												  andURL:[NSURL URLWithString:link]];
	
	UIApplication *app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = YES;
	
	[self.navigationController pushViewController:film animated:YES];
	
	
	//NSLog(@"%@%d",DETAILFORDVDID, dvd.ID);
	
}


@end

