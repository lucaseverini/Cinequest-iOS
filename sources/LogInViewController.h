//
//  LogInViewController.h
//  CineQuest
//
//  Created by harold lee on 11/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MySchedulerViewController.h"


@interface LogInViewController : UIViewController 
<UIActionSheetDelegate>
{
	IBOutlet UITextField *passwordLabel;
	IBOutlet UITextField *usernameLabel;	
	MySchedulerViewController *parentsView;
}
@property (nonatomic,strong) IBOutlet UITextField *passwordLabel;
@property (nonatomic,strong) IBOutlet UITextField *usernameLabel;
@property (nonatomic,strong) MySchedulerViewController *parentsView;

-(IBAction)loginUser:(id)sender;
-(IBAction)signup:(id)sender;
-(IBAction)uploadList:(id)sender;
-(void)setParent:(MySchedulerViewController *)parent;
-(BOOL)checkInputFields;

@end