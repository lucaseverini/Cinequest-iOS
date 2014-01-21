//
//  GPlusLoginViewController.h
//  Cinequest
//
//  Created by Luca Severini on 12/15/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@interface GPlusLoginViewController : UIViewController
{
	// UIActionSheet *parentSheet;
}

@property (nonatomic, strong) UIActionSheet *parentSheet;

@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UIButton *signInButton;

- (id) initWithNibName:(NSString*)nibNameOrNil andActionSheet:(UIActionSheet*)aSheet;

- (IBAction) cancelSignIn:(id)sender;

@end
