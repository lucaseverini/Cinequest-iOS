//
//  LogInViewController.h
//  CineQuest
//
//  Created by harold lee on 11/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MySchedulerViewController.h"


@interface LogInViewController : UIViewController 
<UIActionSheetDelegate>
{
	IBOutlet UITextField *passwordLabel;
	IBOutlet UITextField *usernameLabel;	
	MySchedulerViewController *parentsView;
}
@property (nonatomic,retain) IBOutlet UITextField *passwordLabel;
@property (nonatomic,retain) IBOutlet UITextField *usernameLabel;
@property (nonatomic,retain) MySchedulerViewController *parentsView;

-(IBAction)loginUser:(id)sender;
-(IBAction)signup:(id)sender;
-(IBAction)uploadList:(id)sender;
-(void)setParent:(MySchedulerViewController *)parent;
-(BOOL)checkInputFields;

@end