//
//  LogInViewController.m
//  CineQuest
//
//  Created by harold lee on 11/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LogInViewController.h"
#import "CinequestAppDelegate.h"

@implementation LogInViewController
@synthesize passwordLabel,usernameLabel,parentsView;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	passwordLabel.text = parentsView.password;
	usernameLabel.text = parentsView.username;	
}

- (void)setParent:(MySchedulerViewController *)parent {
	self.parentsView = parent;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];	
	// Release any cached data, images, etc that aren't in use.
}

// Button trigger to launch a browser for cinequest.org registration.
- (IBAction)signup:(id)sender {
	
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"Leaving Application" 
							  message:@"In order to register, you must leave this application." 
							  delegate:self 
							  cancelButtonTitle:nil  
							  otherButtonTitles:@"Nevermind", @"Register", nil];
	
	[alertView show];
	
	//[[app openURL:[NSURL URLWithString:@"http://mobile.cinequest.org/isch_reg.php"]];
}

// Button trigger to retrieve the list of films saved on the CQ server
- (IBAction)loginUser:(id)sender {	
	// assume uesr will login, the XMLparser delegate will set to NO if errors
	parentsView.xmlStatus = @"good";
	
	if ([self checkInputFields]) {
		parentsView.password = passwordLabel.text;
		parentsView.username = usernameLabel.text;
		[parentsView processLogin];
		[parentsView.tableView reloadData];	
		
		
		if ( [parentsView.xmlStatus isEqualToString:@"good"] ) {
			
			// pop the current view after logging in sucessfully
			[parentsView.navigationController popViewControllerAnimated:YES];
		}
		
	}
	
	if ( [parentsView.xmlStatus isEqualToString:@"badLogin"] ) {
		// this is when there is an Authentication error		
		[passwordLabel resignFirstResponder];
		
		
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"Bad Username / Password" 
								  message:@"Your supplied username/password is invalid" 
								  delegate:self 
								  cancelButtonTitle:nil  
								  otherButtonTitles:@"Try Again", @"Register", nil];
		
		[alertView show];
		
		/*
		
		UIActionSheet *prompt = [[UIActionSheet alloc] initWithTitle:@"Your supplied username/password is invalid" delegate:self 
												   cancelButtonTitle:@"Try Again" 
											  destructiveButtonTitle:@"Register" 
												   otherButtonTitles:nil];
		[prompt showInView:self.view];
		[prompt release];
		 
		 */
	}		
}

// Button trigger to upload the current schedule and update online
-(IBAction)uploadList:(id)sender {
	
	// Get mySchedule array
	CinequestAppDelegate *delegate = appDelegate;
	NSMutableArray *mySchedule = delegate.mySchedule;
	
	if ( [mySchedule count] > 0 ) {
		
		// assume uesr will login, the XMLparser delegate will set to NO if errors
		parentsView.xmlStatus = @"good";
		
		if ([self checkInputFields]) {
			parentsView.password = passwordLabel.text;
			parentsView.username = usernameLabel.text;
			[parentsView saveFilms];
			
			if ( [parentsView.xmlStatus isEqualToString:@"good"] ) {			
				// pop the current view after logging in sucessfully
				[parentsView.navigationController popViewControllerAnimated:YES];
			}
			
		}
		
		if ( [parentsView.xmlStatus isEqualToString:@"badLogin"] ) {
			// this is when there is an Authentication error		
			[passwordLabel resignFirstResponder];
			
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:@"Bad Username / Password" 
									  message:@"Your supplied username/password is invalid" 
									  delegate:self 
									  cancelButtonTitle:nil  
									  otherButtonTitles:@"Try Again", @"Register", nil];
			
			[alertView show];
		}
		else if ( [parentsView.xmlStatus isEqualToString:@"overwriteSchedule"] ) {
			// should call method to upload schedule again, the new timestamp should be loaded
			[self uploadList:nil];
		}
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"No Films to add" 
							  message:@"You currently don't have any films to add" 
							  delegate:nil 
							  cancelButtonTitle:@"Okay" 
							  otherButtonTitles:nil];
		[alert show];
	}
	
}

// checks to see if the credentials are typed in.
-(BOOL)checkInputFields {	
	if ( passwordLabel.text == nil || usernameLabel.text == nil ) {		
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Missing Credentials" 
							  message:@"Please fill in your username and/or password" 
							  delegate:nil 
							  cancelButtonTitle:@"Okay" 
							  otherButtonTitles:nil];
		[alert show];
		return NO;
	}
	return YES;
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark UIActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (!buttonIndex == [actionSheet cancelButtonIndex]) {
		
		// loads registration page into safari
		[app openURL:[NSURL URLWithString:@"http://mobile.cinequest.org/isch_reg.php"]];
	}
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
		// loads registration page into safari
		[app openURL:[NSURL URLWithString:@"http://mobile.cinequest.org/isch_reg.php"]];
    }
    
    if (buttonIndex == 0)
    {
		// do nothing let the user re-type
    }
}

@end


