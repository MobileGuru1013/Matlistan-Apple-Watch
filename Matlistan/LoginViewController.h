//
//  LoginViewController.h
//  MatListan
//
//  Created by Yan Zhang on 11/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MatlistanHTTPClient.h"
#import <FBSDKLoginKit/FBSDKLoginButton.h>
#import <Google/SignIn.h>


@class AppDelegate;
@interface LoginViewController : UIViewController<UITextFieldDelegate, MatlistanHTTPClientDelegate,FBSDKLoginButtonDelegate,UIActionSheetDelegate, GIDSignInUIDelegate, GIDSignInDelegate>


@property (nonatomic)BOOL isSwitchingUser;
//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *registerLaterButton;
//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *regLatActIndicator;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UILabel *noAccountLabel;
//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *fbIndicator;
@property (weak, nonatomic) IBOutlet UIButton *forgetPasswordButton;
@property (weak, nonatomic) IBOutlet UILabel *continueLbl;

@property (weak,nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollview;

- (IBAction)loginPressed:(id)sender;
- (IBAction)emailDidBeginEditing:(id)sender;
- (IBAction)passwordDidBeginEditing:(id)sender;
- (IBAction)registerLaterPressed:(id)sender;
- (IBAction)btnForgetPasswordPressed:(id)sender;
- (IBAction)googleLogin:(id)sender;

@end
