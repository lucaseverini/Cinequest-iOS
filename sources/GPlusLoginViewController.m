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

- (id) initWithNibName:(NSString*)nibNameOrNil andActionSheet:(UIActionSheet*)aSheet
{
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    if (self != nil)
	{
		parentSheet = aSheet;
		
		// [GPPSignInButton class];
    }
	
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	[cancelButton addTarget:self action:@selector(cancelSignIn:) forControlEvents:UIControlEventTouchUpInside];
}


- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction) cancelSignIn:(id)sender
{
	NSLog(@"cancelSignIn: %@", sender);
	
	[parentSheet dismissWithClickedButtonIndex:0 animated:YES];
}

@end
