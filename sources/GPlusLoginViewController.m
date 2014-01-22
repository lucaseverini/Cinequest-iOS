//
//  GPlusLoginViewController.m
//  Cinequest
//
//  Created by Luca Severini on 12/15/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import <GooglePlus/GooglePlus.h>
#import "GPlusLoginViewController.h"


@implementation GPlusLoginViewController

@synthesize parentSheet;
@synthesize cancelButton;
@synthesize signInButton;
@synthesize signOutButton;
@synthesize statusLabel;
@synthesize nameLabel;
@synthesize emailLabel;

- (id) initWithNibName:(NSString*)nibNameOrNil andActionSheet:(UIActionSheet*)aSheet
{
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    if (self != nil)
	{
		parentSheet = aSheet;
    }
	
    return self;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

	[cancelButton addTarget:self action:@selector(cancelSignIn:) forControlEvents:UIControlEventTouchUpInside];
	[signOutButton addTarget:self action:@selector(signOut:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[GPPSignIn sharedInstance].delegate = self;
	
	[self checkStatus];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void) checkStatus
{
	GTMOAuth2Authentication *auth = [[GPPSignIn sharedInstance] authentication];
	if (auth != nil)
	{
		GTLPlusPerson *user = [GPPSignIn sharedInstance].googlePlusUser;
		nameLabel.text = [NSString stringWithFormat:@"%@ %@", user.name.givenName, user.name.familyName];
		emailLabel.text = [GPPSignIn sharedInstance].userEmail;
		statusLabel.text = @"Status: Authenticated";
	}
	else
	{
		nameLabel.text = @"";
		emailLabel.text = @"";
		statusLabel.text = @"Status: Not Authenticated";
	}
}

- (IBAction) cancelSignIn:(id)sender
{
	[parentSheet dismissWithClickedButtonIndex:0 animated:YES];	
	// [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) signOut:(id)sender
{
	// [[GPPSignIn sharedInstance] disconnect];
	[[GPPSignIn sharedInstance] signOut];
	
	[parentSheet dismissWithClickedButtonIndex:0 animated:YES];
	// [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) finishedWithAuth:(GTMOAuth2Authentication*)auth error:(NSError *)error
{
	if (error != nil)
	{
		NSLog(@"Google+ Authentication error: %@", error);
	}
	else
	{
		NSLog(@"Google+ Authentication OK");
	}

	[self checkStatus];
}

- (void) didDisconnectWithError:(NSError*)error
{
	if (error != nil)
	{
		NSLog(@"Google+ Failed to disconnect: %@", error);
	}
	else
	{
		NSLog(@"Google+ Disconnected");
	}

	[self checkStatus];
}

@end

