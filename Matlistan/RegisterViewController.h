//
//  RegisterViewController.h
//  MatListan
//
//  Created by Yan Zhang on 04/12/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextField+Extended.h"
#import "MatlistanHTTPClient.h"

@class AppDelegate;
@interface RegisterViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *password2Field;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak,nonatomic) AppDelegate *appDelegate;

- (IBAction)emailDidBegin:(id)sender;
- (IBAction)passwordDidBegin:(id)sender;
- (IBAction)password2DidBegin:(id)sender;
- (IBAction)registerClicked:(id)sender;
- (IBAction)backButtonPressed:(id)sender;

@end
