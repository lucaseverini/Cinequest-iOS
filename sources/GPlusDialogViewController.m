//
//  GPlusDialogViewController.m
//  Cinequest
//
//  Created by Luca Severini on 1/21/14.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestAppDelegate.h"
#import "GPlusDialogViewController.h"
#import "GPlusDialogView.h"


static NSString *const kPlaceholderAvatarImageName = @"PlaceholderAvatar.png";

@implementation GPlusDialogViewController

@synthesize signedIn;
@synthesize postMessage;
@synthesize signInButton;
@synthesize cancelButton;
@synthesize statusLabel;
@synthesize emailLabel;
@synthesize nameLabel;
@synthesize userImage;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil)
	{
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

	self.title = @"Google+";
	
	self.navigationController.navigationBar.translucent = YES;
	// self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
	// self.navigationController.navigationBar.opaque = YES;
	// self.navigationController.navigationBar.alpha = 0.1;

	self.view.opaque = NO;
	self.view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	previousDelegate = [GPPSignIn sharedInstance].delegate;
	[GPPSignIn sharedInstance].delegate = self;

	signInCompleted = NO;

	BOOL result = [[GPPSignIn sharedInstance] trySilentAuthentication];
	NSLog(@"Google+ trySilentAuthentication: %d", result);
	if(result)
	{
		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		while(!signInCompleted)
		{
			[runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
		}
	}

	signedIn = ([GPPSignIn sharedInstance].authentication != nil);
	if(signedIn)
	{
		NSLog(@"Google+ Authenticated");
	}
	else
	{
		NSLog(@"Google+ Not authenticated");
	}
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	
	[GPPSignIn sharedInstance].delegate = previousDelegate;
}

- (void) dismissDialog
{
	GPlusDialogView *dialogView = (GPlusDialogView*)[self.navigationController.view.superview superview];
	if(dialogView != nil)
	{
		[dialogView close];
	}
	else
	{
		[self.navigationController.view.superview removeFromSuperview];
	}
}

- (void) finishedWithAuth:(GTMOAuth2Authentication*)auth error:(NSError*)error
{
	if(error != nil)
	{
		NSLog(@"Google+ status: Authentication error: %@", error);

		signedIn = NO;

		[signInButton setTitle:@"Sign In" forState:UIControlStateNormal];
		[signInButton addTarget:self action:@selector(signIn:) forControlEvents:UIControlEventTouchUpInside];

		[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
		[cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
	}
	else
	{
		NSLog(@"Google+ status: Authenticated: email:%@ ID:%@", [GPPSignIn sharedInstance].userEmail, [GPPSignIn sharedInstance].userID);
		
		signedIn = YES;

		[signInButton setTitle:@"Sign Out" forState:UIControlStateNormal];
		[signInButton addTarget:self action:@selector(signOut:) forControlEvents:UIControlEventTouchUpInside];

		[cancelButton setTitle:@"Post" forState:UIControlStateNormal];
		[cancelButton addTarget:self action:@selector(post:) forControlEvents:UIControlEventTouchUpInside];
	}

	if (auth != nil)
	{
		GTLPlusPerson *user = [GPPSignIn sharedInstance].googlePlusUser;
		nameLabel.text = [NSString stringWithFormat:@"%@ %@", user.name.givenName, user.name.familyName];
		emailLabel.text = [GPPSignIn sharedInstance].userEmail;
		statusLabel.text = @"Status: Authenticated";

		dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(backgroundQueue,
		^{
			NSData *avatarData = nil;
			NSString *imageURLString = user.image.url;
			if (imageURLString)
			{
				NSURL *imageURL = [NSURL URLWithString:imageURLString];
				avatarData = [NSData dataWithContentsOfURL:imageURL];
			}
			
			if (avatarData)
			{
				// Update UI from the main thread when available
				dispatch_async(dispatch_get_main_queue(),
				^{
					userImage.image = [UIImage imageWithData:avatarData];
				});
			}
		});
	}
	else
	{
		nameLabel.text = @"";
		emailLabel.text = @"";
		statusLabel.text = @"Status: Not Authenticated";
		userImage.image = [UIImage imageNamed:kPlaceholderAvatarImageName];
	}
	
	signInCompleted = YES;
}

- (void) didDisconnectWithError:(NSError*)error
{
	if(error != nil)
	{
		NSLog(@"Google+ status: Failed to disconnect: %@", error);
	}
	else
	{
		NSLog(@"Google+ status: Disconnected");

		signedIn = NO;
		
		[signInButton setTitle:@"Sign In" forState:UIControlStateNormal];
		[signInButton addTarget:self action:@selector(signIn:) forControlEvents:UIControlEventTouchUpInside];

		[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
		[cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];

		nameLabel.text = @"";
		emailLabel.text = @"";
		statusLabel.text = @"Status: Not Authenticated";
		userImage.image = [UIImage imageNamed:kPlaceholderAvatarImageName];
	}
	
	signInCompleted = YES;
}

- (IBAction) signIn:(id)sender
{
	NSLog(@"signIn");

	// [GPPSignIn sharedInstance].actions = [NSArray arrayWithObjects:@"http://schemas.google.com/ListenActivity", nil];

	// NSLog(@"%@", [GPPSignIn sharedInstance].scopes);
	// NSLog(@"%@", [GPPSignIn sharedInstance].actions);
	
	signInCompleted = NO;
	
	[[GPPSignIn sharedInstance] authenticate];

	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	while(!signInCompleted)
	{
		[runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
	}
}

- (IBAction) cancel:(id)sender
{
	NSLog(@"cancel");
	
	[self dismissDialog];
}

- (IBAction) signOut:(id)sender
{
	NSLog(@"signOut");
	
	[[GPPSignIn sharedInstance] disconnect];
}

- (IBAction) post:(id)sender
{
	NSLog(@"post");

	id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
	[shareBuilder setPrefillText:postMessage];
	[shareBuilder open];
}

@end




