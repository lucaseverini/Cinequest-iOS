//
//  GPlusLoginViewController.h
//  Cinequest
//
//  Created by Luca Severini on 12/15/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@class GPPSignInButton;

@interface GPlusLoginViewController : UIViewController <GPPSignInDelegate>
{
	// UIActionSheet *parentSheet;
	BOOL googlePlusConnected;
}

@property (nonatomic, strong) UIActionSheet *parentSheet;

@property (nonatomic, strong) IBOutlet GPPSignInButton *signInButton;
@property (nonatomic, strong) IBOutlet UIButton *signOutButton;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *emailLabel;

- (id) initWithNibName:(NSString*)nibNameOrNil andActionSheet:(UIActionSheet*)aSheet;

- (IBAction) cancelSignIn:(id)sender;
- (IBAction) signOut:(id)sender;

@end
