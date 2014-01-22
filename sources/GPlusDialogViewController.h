//
//  GPlusDialogViewController.h
//  Cinequest
//
//  Created by Luca Severini on 1/21/14.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@interface GPlusDialogViewController : UIViewController <GPPSignInDelegate>
{
	BOOL signInCompleted;
	id previousDelegate;
}

@property (nonatomic, assign) BOOL signedIn;
@property (nonatomic, strong) NSString *postMessage;
@property (nonatomic, strong) IBOutlet UIButton *signInButton;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *emailLabel;
@property (nonatomic, strong) IBOutlet UIImageView *userImage;

- (IBAction) cancel:(id)sender;
- (IBAction) signIn:(id)sender;
- (IBAction) post:(id)sender;

- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil;

@end
