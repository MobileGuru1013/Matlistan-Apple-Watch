//
//  LoginViewController.m
//  MatListan
//
//  Created by Yan Zhang on 11/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "LoginViewController.h"
#import "MatlistanHTTPClient.h"
#import "RootViewController.h"
#import "ALToastView.h"
#import "SyncManager.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "AppDelegate.h"
#import "ItemsViewController.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "Mixpanel.h"

//#import "MBProgressHUD.h"

@interface LoginViewController ()

@property(strong) MatlistanHTTPClient *client;
@end

//@implementation UINavigationController (Orientation)
//-(NSUInteger)supportedInterfaceOrientations
//{
//        return [self.topViewController supportedInterfaceOrientations];
//    }
//    
//    -(BOOL)shouldAutorotate
//    {
//        return YES;
//    }
//@end

@implementation LoginViewController {
    NSArray *cellNames;
    UIButton *buttonLogin;
    UIButton *buttonRegister;

    __weak IBOutlet FBSDKLoginButton *loginButton;
    __weak IBOutlet UIControl *googleLoginButton;
    IBOutlet UILabel *googleLoginLabel;
    
    FBSDKAccessToken *myAccessToken;
    LoginType appLoginType;

    UIAlertView *forgetPasswordAlert;
    int fortag;
    CGRect keyboardFrame;
    NSValue* keyboardFrameBegin;

}
@synthesize client;

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    fortag=0;
    [Utility saveInDefaultsWithBool:YES andKey:@"firstDataLoad"];
    cellNames = @[@"logoCell", @"compCell"];

    //client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    //client.delegate = self;
    //self.appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
//    UIImage *logo = [UIImage imageNamed:@"icon.png"];
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self imageWithImage:logo scaledToSize:CGSizeMake(40, 40)]];
//    UIBarButtonItem *imageButton = [[UIBarButtonItem alloc] initWithCustomView:imageView];
//
//    self.navigationItem.leftBarButtonItem = imageButton;
    
    client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    client.delegate = self;
    self.appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [tap setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tap];

    self.automaticallyAdjustsScrollViewInsets=NO;
//    loginButton = [[FBSDKLoginButton alloc] init];
//    loginButton.frame = CGRectMake(self.logInButton.frame.origin.x, self.logInButton.frame.origin.y+self.logInButton.frame.size.height+10, self.logInButton.frame.size.width, self.logInButton.frame.size.height);
    // [self.view addSubview:loginButton];
    
    [loginButton setBackgroundColor:[UIColor clearColor]];
    loginButton.delegate = self;
    loginButton.readPermissions = @[@"public_profile"];
    
    DLog(@"FBSDK version = %@",FBSDK_VERSION_STRING);
    
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Login: view opened"];
    }
    
    
    //Google login
    [GIDSignIn sharedInstance].delegate = self;
    [GIDSignIn sharedInstance].uiDelegate = self;
    [[GIDSignIn sharedInstance] setScopes:@[@"email", @"profile"]];

    [googleLoginButton addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [googleLoginButton addTarget:self action:@selector(touchCancel:) forControlEvents:UIControlEventTouchUpInside];
    [googleLoginButton addTarget:self action:@selector(touchCancel:) forControlEvents:UIControlEventTouchUpOutside];
    /*
    googleLoginButton.layer.shadowOffset = CGSizeMake(5, 5);
    googleLoginButton.layer.shadowOpacity = 1;
    googleLoginButton.layer.shadowRadius = 1.0;
    */
    
    //[googleLoginButton setStyle: kGIDSignInButtonStyleIconOnly];
    //[googleLoginButton setColorScheme:kGIDSignInButtonColorSchemeDark];
    //[[GIDSignIn sharedInstance] signInSilently];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myNotificationMethod:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

}
#pragma mark -Keyboard Frame
- (void)myNotificationMethod:(NSNotification*)notification
{
    self.scrollview.scrollEnabled=YES;
    NSDictionary* keyboardInfo = [notification userInfo];
    keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    keyboardFrame=[keyboardFrameBegin CGRectValue];
    CGFloat height = CGRectGetMaxY(self.forgetPasswordButton.frame);
    self.scrollview.contentSize = CGSizeMake(SCREEN_WIDTH, height+[keyboardFrameBegin CGRectValue].size.height+30);

}

- (void) touchCancel: (id)sender {
    [googleLoginButton setBackgroundColor:[UIColor whiteColor]];
}

- (void) touchDown: (id)sender {
    [googleLoginButton setBackgroundColor:[UIColor grayColor]];
}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    DLog(@"Google login didCompleteWithResult");
    if (user.authentication.idToken && user.authentication.accessToken)
    {
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
        if ([Utility getCurrentLoginType] == LoginTypeAnonymous)
        {
            NSDictionary *parameters = @{@"gIdToken": user.authentication.idToken, @"gAccessToken": user.authentication.accessToken};
            [client PATCH:@"Accounts" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                NSDictionary *dict = (NSDictionary*)responseObject;
                client.ticket = dict[@"ticket"];
                client.accountId = dict[@"accountId"];
                [[Crashlytics sharedInstance] setUserIdentifier:client.accountId];
                DLog(@"Successful Google PATCH response = %@",dict);
                //DLog(@"Get cookie from server %@",client.ticket);
                [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
                [Utility setCurrentLoginType:LoginTypeGoogle];
                [Utility saveInDefaultsWithObject:user.authentication.idToken andKey:@"GoogleIdTokenRetrieved"];
                [Utility saveInDefaultsWithObject:user.authentication.accessToken andKey:@"GoogleAccessTokenRetrieved"];
                [Utility saveInDefaultsWithObject:user.authentication.accessTokenExpirationDate andKey:@"GoogleAccessTokenExpirationDate"];
                if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                {
                    [[Mixpanel sharedInstance] identify:client.accountId];
                }
                [self matlistanHTTPClient:client didLogin:nil];
                //[SVProgressHUD dismiss];
                
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
                [Utility setCurrentLoginType:LoginTypeAnonymous];
                [[GIDSignIn sharedInstance] signOut];//PATCH failed but user is logged in as Google. So log him out.
                [SVProgressHUD dismiss];
                NSData *errorData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
                DLog(@"Failed Google PATCH response = %@",[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]);
                if (errorData == nil)
                {
                    //no internet
                    [self showErrorInputAlert:NSLocalizedString(@"FailedConnection", nil)];
                }
                else
                {
                    NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
                    NSString *errorDetail = [serializedData objectForKey:@"errorString"];
                    if ( ![Utility isStringEmpty:errorDetail])
                    {
                        [self showErrorInputAlert:errorDetail];
                    }
                }
            }];
        }
        else
        {
            [Utility setCurrentLoginType:LoginTypeGoogle];
            [Utility saveInDefaultsWithObject:user.authentication.idToken andKey:@"GoogleIdTokenRetrieved"];
            [Utility saveInDefaultsWithObject:user.authentication.accessToken andKey:@"GoogleAccessTokenRetrieved"];
            [Utility saveInDefaultsWithObject:user.authentication.accessTokenExpirationDate andKey:@"GoogleAccessTokenExpirationDate"];
            client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
            client.delegate = self;
            //[SVProgressHUD dismiss];
            [client loginWithGoogleIdToken: user.authentication.idToken andAccessToken: user.authentication.accessToken];
        }
    }
    else
    {
        if (error && error.code != -5 && error.code != -1) {
            [self showErrorInputAlert:error.localizedDescription];
        }
        else if (error.code == -1) {
            [self showErrorInputAlert:NSLocalizedString(@"No internet",nil)];
        }
    }
}

- (void)dismissKeyboard
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        if(IS_IPHONE)
        {
        }
        else
        {
            self.scrollview.scrollEnabled=NO;
        }
        
    }
    fortag=0;
    [_emailField resignFirstResponder];
    [_passwordField resignFirstResponder];
//    [self.scrollview setContentOffset:CGPointMake(0, 0) animated:YES];
    self.scrollview.contentSize = CGSizeMake(SCREEN_WIDTH,CGRectGetMaxY(self.forgetPasswordButton.frame)+30);
    [self.scrollview setContentOffset:CGPointMake(0, 0) animated:YES];

}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

/* This method is used toupdate login form elements with localise name
 */
- (void)setFormElementLableName
{
    _emailField.placeholder = NSLocalizedString(@"Email", nil);
    _emailField.returnKeyType = UIReturnKeyNext;
    _passwordField.placeholder = NSLocalizedString(@"Password", nil);
    [_noAccountLabel setText:NSLocalizedString(@"No account?", nil)];
    self.navigationItem.title = NSLocalizedString(@"Matlistan", nil);
    [_logInButton setTitle:NSLocalizedString(@"Log in", nil) forState:UIControlStateNormal];
    [_registerButton setTitle:NSLocalizedString(@"Register", nil) forState:UIControlStateNormal];
    [self.registerLaterButton setTitle:NSLocalizedString(@"Register later", nil) forState:UIControlStateNormal];
    [googleLoginLabel setText:NSLocalizedString(@"Log in", nil)];
    
    [ self.forgetPasswordButton setTitle:NSLocalizedString(@"Forgot password", nil) forState:UIControlStateNormal];
     self.continueLbl.text=NSLocalizedString(@"Or Continue with", nil);
    
    _logInButton.layer.cornerRadius=3;
    loginButton.layer.cornerRadius=3;
    googleLoginButton.layer.cornerRadius=3;
    self.registerLaterButton.layer.cornerRadius=3;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DLog(@"login viewWillAppear");
    
    [self setFormElementLableName];
    
    if ([Utility getDefaultIntAtKey:@"LoginType"] == LoginTypeEmail)
    {
        
        NSString *savedUserName = [Utility getObjectFromDefaults:@"userName"];
        NSString *savedPassword = [Utility getObjectFromDefaults:@"password"];
        _emailField.text = savedUserName;
        _passwordField.text = savedPassword;
        
    }
    else
    {
        _emailField.text = @"";
        _passwordField.text = @"";
    }
    
    //For iPhone 4
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];


}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //For iphone 4
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];


}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setScrollEnableOrNot];
    CLS_LOG(@"Showing LoginViewController");
    self.scrollview.contentSize = CGSizeMake(SCREEN_WIDTH,CGRectGetMaxY(self.forgetPasswordButton.frame)+30);

}

// For keyboard on iPhone 4
#pragma mark KeyboardShowHide
- (void)keyboardWillShow:(NSNotification *)aNotification
{
    /*
    NSDictionary *info = [aNotification userInfo];

    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height <= 480.0f) {
        // Animate the current view out of the way
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUp:YES kbHeight:kbSize.height];
        }
        else if (self.view.frame.origin.y < 0) {
            [self setViewMovedUp:NO kbHeight:kbSize.height];
        }
    }
     */
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    /*
    NSDictionary *info = [aNotification userInfo];

    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height <= 480.0f) {
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUp:YES kbHeight:kbSize.height];
        }
        else if (self.view.frame.origin.y < 0) {
            [self setViewMovedUp:NO kbHeight:kbSize.height];
        }
    }
*/
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyNext)
    {
        [_passwordField becomeFirstResponder];
    }
    else
    {
        [textField resignFirstResponder];
        self.scrollview.contentSize = CGSizeMake(SCREEN_WIDTH,CGRectGetMaxY(self.forgetPasswordButton.frame)+30);
        [self.scrollview setContentOffset:CGPointMake(0, 0) animated:YES];
        fortag=0;
        if (_passwordField.text.length > 0 && _emailField.text.length > 0) {
            
            [self login];
        }
    }
    return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [_emailField resignFirstResponder];
    [_passwordField resignFirstResponder];
}

//method to move the view up/down whenever the keyboard is shown/dismissed
- (void)setViewMovedUp:(BOOL)movedUp kbHeight:(float)height
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view

    CGRect rect = self.view.frame;
    if (movedUp) {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= (height/5);
        rect.size.height += (height/5);
    }
    else {
        // revert back to the normal state.
        rect.origin.y += (height/5);
        rect.size.height -= (height/5);
    }
    self.view.frame = rect;

    [UIView commitAnimations];
}

- (IBAction)emailDidBeginEditing:(id)sender
{
    fortag=1;
    [self setContentOffsetWhenEmailTxtBecomeFirstResponder];
}

- (IBAction)passwordDidBeginEditing:(id)sender
{
    fortag=2;
    [self setContentOffsetWhenPasswordTxtBecomeFirstResponder];
}

#pragma mark matlistanHTTPClient
- (void)matlistanHTTPClient:(MatlistanHTTPClient *)client didLogin:(id)cookie {

    [self.appDelegate switchRootViewController];//switching rootviewcontrooler in AppDelegate
}

- (void)matlistanHTTPClient:(MatlistanHTTPClient *)client didFailWithError:(NSError *)error andCode:(long)code
{
    DLog(@"client login failed = %@",error.localizedDescription);
    NSString *errorMessage;
    NSString *info = [error.userInfo objectForKey:@"NSLocalizedDescription"];
    if (code >= 400 && code < 500)
    {
        errorMessage = [NSString stringWithFormat:@"%@ -\r %@", NSLocalizedString(@"Fail to log in", nil), NSLocalizedString(@"Wrong email or password", nil)];
        [Utility setTempEmailID:_emailField.text];
        [self showFailToLoginAlert:errorMessage];
        
        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
        {
            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": errorMessage? errorMessage : @"NULL", @"Screen":@"Login"}];
        }
    }
    else
    {
        errorMessage = [NSString stringWithFormat:@"%@ -\r %@", NSLocalizedString(@"Fail to log in", nil), info];
        [self showErrorInputAlert:errorMessage];
        
        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
        {
            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": errorMessage? errorMessage : @"NULL", @"Screen":@"Login"}];
        }
    }
    
    //[_activityIndicator stopAnimating];
   // _activityIndicator.hidden = YES;
   // [_regLatActIndicator stopAnimating];
   // _regLatActIndicator.hidden = YES;
   // [_fbIndicator stopAnimating];
  //  _fbIndicator.hidden = YES;
    
     [SVProgressHUD dismiss];
    
    /*
    NSData *errorData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
    if (errorData == nil) {
        [self showNoInternetAlert];
    }else {
        
        NSDictionary *errorDic = [Utility getErrorDictionary:errorData];
        DLog(@"Failed login = %@",errorDic);
        
        if (![[errorDic objectForKey:@"success"] boolValue]) {
            
            LoginType someType = [Utility getCurrentLoginType];
            
            if (someType == LoginTypeEmail) {
                NSArray *options = [NSArray arrayWithObjects:NSLocalizedString(@"Retry",nil),NSLocalizedString(@"Continue without synchronization",nil),NSLocalizedString(@"Enter new password",nil), NSLocalizedString(@"Cancel", nil) ,nil];
                [self showLoginFailedSheetWithOptions:options];
            }else if (someType == LoginTypeFacebook  || someType == LoginTypeAnonymous){
                NSArray *optionsAnonymous = [NSArray arrayWithObjects:NSLocalizedString(@"Retry",nil),NSLocalizedString(@"Continue without synchronization",nil),NSLocalizedString(@"Enter credentials",nil), nil];
                [self showLoginFailedSheetWithOptions:optionsAnonymous];
            }
        }else{
            NSString *errStr = [errorDic objectForKey:@"errorString"];
            [self showErrorInputAlert:errStr];
        }
    }
     */
}


- (void)showToastMessage:(NSString *)message {
    [ALToastView toastInView:self.view withText:message];
}

- (void)showErrorInputAlert:(NSString *)msg {
    
    //Dimple-26-10-2015
    if(IS_OS_8_OR_LATER)
    {
        [self OkAlertController:nil message:msg];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:Nil, nil];
        [alert show];
    }
}

- (void)showFailToLoginAlert:(NSString *)msg
{
    //Dimple-24-10-2015
    if(IS_OS_8_OR_LATER)
    {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:msg message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       
                                   }];
        UIAlertAction *TryAgainAction = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"Try again", nil)
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action)
                                         {
                                             // let user correct credentials and try again
                                             [_passwordField becomeFirstResponder];
                                         }];
        UIAlertAction *forgotPassword = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"I forgot the password", nil)
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action)
                                         {
                                             // I forgot the password
                                             [self btnForgetPasswordPressed:nil];
                                             
                                         }];
        UIAlertAction *createAnAccount = [UIAlertAction
                                          actionWithTitle:NSLocalizedString(@"I would like to create an account", nil)
                                          style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action)
                                          {
                                              // Create account
                                              [self btnRegisterPressed:nil];
                                              
                                          }];
        UIAlertAction *loginWithFb = [UIAlertAction
                                      actionWithTitle:NSLocalizedString(@"LoginWithFacebook", nil)
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction *action)
                                      {
                                          //Login With Facebook
                                          [self loginwithfacebook];
                                      }];
        //Raj- 9-2-16
        UIAlertAction *loginWithGmail = [UIAlertAction
                                      actionWithTitle:NSLocalizedString(@"Login with Google", nil)
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction *action)
                                      {
                                          [[GIDSignIn sharedInstance] signIn];
                                      }];

        [alertController addAction:TryAgainAction];
        [alertController addAction:forgotPassword];
        [alertController addAction:createAnAccount];
        [alertController addAction:loginWithFb];
        [alertController addAction:loginWithGmail];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:NSLocalizedString(@"Try again", nil), NSLocalizedString(@"I forgot the password", nil), NSLocalizedString(@"I would like to create an account", nil), NSLocalizedString(@"LoginWithFacebook", nil),NSLocalizedString(@"Login with Google", nil), nil];
        alert.tag = 1921;
        [alert show];
        
    }
}

//#pragma mark Orientation
//-(BOOL)shouldAutorotate
//{
//    [super shouldAutorotate];
//    return NO;
//}
//-(NSUInteger) supportedInterfaceOrientations {
//    [super supportedInterfaceOrientations];
//    // Return a bitmask of supported orientations. If you need more,
//    // use bitwise or (see the commented return).
//    return UIInterfaceOrientationMaskPortrait;
//    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
//}
//
//- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
//    [super preferredInterfaceOrientationForPresentation];
//    // Return the orientation you'd prefer - this is what it launches to. The
//    // user can still rotate. You don't have to implement this method, in which
//    // case it launches in the current orientation
//    return UIInterfaceOrientationPortrait;
//}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark LoginRegister
- (void)login
{
    [self dismissKeyboard];
    
    NSString *userName = _emailField.text;
    NSString *password = _passwordField.text;

    /**
     Added empty string check for username
     @ModifiedDate: September 1 , 2015
     @Version:1.14
     @Author: Yousuf
     */
    if (userName.length == 0)
    {
        //Dimple 26-10-2015
        if(IS_OS_8_OR_LATER)
        {
            [self OkAlertController:@"" message:NSLocalizedString(@"EmailError", nil)];
        }
        else
        {
            kCustomAlertWithParamAndTarget(nil, NSLocalizedString(@"EmailError", nil), nil);
        }
        
        return;
    }
    
    if (password.length == 0)
    {
        //Dimple 26-10-2015
        if(IS_OS_8_OR_LATER)
        {
            [self OkAlertController:@"" message:NSLocalizedString(@"PasswordEmptyError", nil)];
        }
        else
        {
            kCustomAlertWithParamAndTarget(nil, NSLocalizedString(@"PasswordEmptyError", nil), nil);
        }
        [_passwordField resignFirstResponder];
        //[_activityIndicator stopAnimating];
        //_activityIndicator.hidden = YES;
       
        return;
    }
    
    if (userName != nil && password != nil)
    {
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
        [client loginWithUserName:userName andPassword:password];
    }
    else {
       // [_activityIndicator stopAnimating];
        //_activityIndicator.hidden = YES;
        [SVProgressHUD dismiss];
    }
}

- (IBAction)loginPressed:(id)sender
{
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Login: Login with Email clicked"];
    }
    
    //_activityIndicator.hidden = NO;
   // [_activityIndicator startAnimating];
    
    [self login];
}

#pragma mark Anonymous Login
- (IBAction)registerLaterPressed:(id)sender
{
    [Utility setTempEmailID:nil];
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Login: Register later clicked"];
    }
    
    [self dismissKeyboard];
    
    LoginType loginType = (LoginType)[Utility getDefaultIntAtKey:@"LoginType"];

    if (loginType == LoginTypeAnonymous)
    {
        [self performSegueWithIdentifier:@"loginToRoot" sender:self];
        [[SyncManager sharedManager] startSync];
        [MatlistanHTTPClient sharedMatlistanHTTPClient].isLoggedIn = YES;
        [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
    }
    else
    {
        
        client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
        client.delegate = self;
        
        //[Utility saveInDefaultsWithObject:@"" andKey:@"userName"];
        //[Utility saveInDefaultsWithObject:@"" andKey:@"password"];
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
        [client registerAsAnonymous];
    }
}

- (IBAction)btnRegisterPressed:(id)sender
{
    [self dismissKeyboard];
    [self performSegueWithIdentifier:@"loginToRegister" sender:self];
}

#pragma mark FacebookButtonDelegate
- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error
{
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];

    DLog(@"Facebook login didCompleteWithResult");
    if (result.token)
    {
        if ([Utility getCurrentLoginType] == LoginTypeAnonymous)
        {
            NSDictionary *parameters;
            parameters = @{@"fbAccessToken": result.token.tokenString};
            [client PATCH:@"Accounts" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
               // _fbIndicator.hidden = NO;
              //  [_fbIndicator startAnimating];
                
                

                //[SVProgressHUD dismiss];
                NSDictionary *dict = (NSDictionary*)responseObject;
                client.ticket = dict[@"ticket"];
                client.accountId = dict[@"accountId"];
                [[Crashlytics sharedInstance] setUserIdentifier:client.accountId];
                DLog(@"Successful Facebook PATCH response = %@",dict);
                //DLog(@"Get cookie from server %@",client.ticket);
                [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
                [Utility setCurrentLoginType:LoginTypeFacebook];
                myAccessToken = result.token;
                [Utility saveInDefaultsWithObject:result.token.tokenString andKey:@"FacebookTokenRetrieved"];
                
                if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                {
                    [[Mixpanel sharedInstance] identify:client.accountId];
                }
                
                //[self matlistanHTTPClient:client didLogin:nil];
                [client didLogin:nil];
                  [SVProgressHUD dismiss];
                
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
                [Utility setCurrentLoginType:LoginTypeAnonymous];
                [self logoutFacebook];//PATCH failed but user is logged in as Facebook. So log him out.
                //_fbIndicator.hidden = YES;
                //[_fbIndicator stopAnimating];
                
                 //[SVProgressHUD dismiss];
                
                NSData *errorData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
                DLog(@"Failed Facebook PATCH response = %@",[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]);
                if (errorData == nil)
                {
                    //no internet
                    [self showErrorInputAlert:NSLocalizedString(@"FailedConnection", nil)];
                    
                    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                    {
                        [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": NSLocalizedString(@"FailedConnection", nil), @"Screen":@"Login", @"action":@"Login with Facebook"}];
                    }
                }
                else
                {
                    NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
                    NSString *errorDetail = [serializedData objectForKey:@"errorString"];
                    if ( ![Utility isStringEmpty:errorDetail])
                    {
                        [self showErrorInputAlert:errorDetail];
                        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                        {
                            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": errorDetail? errorDetail : @"NULL", @"Screen":@"Login", @"action":@"Login with Facebook"}];
                        }
                    }
                }
                 [SVProgressHUD dismiss];
            }];
        }
        else
        {
            [Utility setCurrentLoginType:LoginTypeFacebook];
            myAccessToken = result.token;
            [Utility saveInDefaultsWithObject:result.token.tokenString andKey:@"FacebookTokenRetrieved"];
            client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
            client.delegate = self;
           // _fbIndicator.hidden = NO;
          //  [_fbIndicator startAnimating];
            
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
            [client loginWithFacebook];
            
        }
    }
    else
    {
        if (result.isCancelled)
            DLog(@"user canceled facebook login");
        if (error)
            [self showErrorInputAlert:error.localizedDescription];
        [SVProgressHUD dismiss];
    }
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
    DLog(@"Facebook login loginButtonDidLogOut");
}

-(void)logoutFacebook
{
    FBSDKLoginManager *manager = [[FBSDKLoginManager alloc] init];
    [manager logOut];
}

/*
#pragma mark - Actionsheet
-(void)showLoginFailedSheetWithOptions:(NSArray *)optionsArray{
    UIActionSheet *failedLoginSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Login Failed", nil)
                                                                  delegate:self
                                                         cancelButtonTitle:nil
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:nil, nil];
    failedLoginSheet.tag = 3002;
    
    for (NSString *str in optionsArray) {
        [failedLoginSheet addButtonWithTitle:str];
    }
    
    [failedLoginSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (popup.tag == 3002) {
        NSString *title = [popup buttonTitleAtIndex:buttonIndex];
        DLog(@"select index = %ld option = %@",(long)buttonIndex,title);
        
        if ([title isEqualToString:NSLocalizedString(@"Retry", nil)]) {
            [self retrySelectedByUser];
        }else if ([title isEqualToString:NSLocalizedString(@"Continue without synchronization", nil)]){
            
            DLog(@"Continue without Sync selected");
            client.isLoggedIn = NO;
            [Utility saveInDefaultsWithBool:YES andKey:@"ContinueWithoutSyncSelected"];
            [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
            [self.appDelegate switchRootViewController];
            
        }else if ([title isEqualToString:NSLocalizedString(@"Enter new password", nil)]) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New Password", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Login", nil), nil];
            alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
            alert.tag = 3003;
            [alert show];
            
        }else if ([title isEqualToString:NSLocalizedString(@"Enter credentials", nil)]){
            self.emailField.text = @"";
            self.passwordField.text = @"";
            [popup dismissWithClickedButtonIndex:0 animated:YES];
        }else if ([title isEqualToString:NSLocalizedString(@"Cancel", nil)]){
            [self performSelectorOnMainThread:@selector(stopActivityIndicator) withObject:nil waitUntilDone:YES];
            return;
        }
    }
}
 */
-(void)stopActivityIndicator{
   
}
#pragma mark AlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView.tag == 3003)
    {
        if ([title isEqualToString:NSLocalizedString(@"Login", nil)])
        {
            NSString *password = [alertView textFieldAtIndex:0].text;
            [[alertView textFieldAtIndex:0] resignFirstResponder];
            
            NSString *userName = [Utility getObjectFromDefaults:@"userName"];
            [Utility saveInDefaultsWithObject:password andKey:@"password"];
            
            
            [client loginWithUserName:userName andPassword:password];
        }
    }
    else if (alertView.tag == 100)
    {
        if ([title isEqualToString:@"OK"])
        {
            NSString *email = [[alertView textFieldAtIndex:0] text];
            if ([Utility validEmail:email])
            {
//                [MBProgressHUD showHUDAddedTo:self.view animated:true];
                [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];

                [client resetPasswordWithEmail:email];
            }
            else
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"EmailError", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                alertView.tag = 1121;
                [alertView show];
            }
        }
        else if ([title isEqualToString:NSLocalizedString(@"Cancel", nil)])
        {
            if (forgetPasswordAlert != nil)
            {
                [[forgetPasswordAlert textFieldAtIndex:0] setText:@""];
            }
        }
    }
    else if (alertView.tag == 1121)
    {
        [self btnForgetPasswordPressed:nil];
    }
    else if (alertView.tag == 2003)
    {
        
    }
    else if (alertView.tag == 1921)
    {
        if (buttonIndex == 1)
        {
            // let user correct credentials and try again
            [_passwordField becomeFirstResponder];
        }
        else if (buttonIndex == 2)
        {
            // I forgot the password
            [self btnForgetPasswordPressed:nil];
        }
        else if (buttonIndex == 3)
        {
            // Create account
            [self btnRegisterPressed:nil];
        }
        else if (buttonIndex == 4)
        {
            //Dimple 24-10-2015
            //Login With Facebook
            [self loginwithfacebook];
        }
        else if(buttonIndex == 5)
        {
            //Raj- 9-2-16
            //Login with Google
            [[GIDSignIn sharedInstance] signIn];
        }
    }
}

#pragma mark -
#pragma mark - Forget Password

/**
 Forget Password button action, api calls and delegate methods
 @ModifiedDate: September 1 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (IBAction)btnForgetPasswordPressed:(id)sender
{
    [self showForgetPasswordAlert:NSLocalizedString(@"forgot password dialog title", nil) andMessage:NSLocalizedString(@"forgot password dialog message", nil)];
}

- (void)showForgetPasswordAlert:(NSString *)title andMessage:(NSString *)message
{
    if(IS_OS_8_OR_LATER)
    {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:title
                                                                            message:message
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.delegate = self;
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            if([Utility getTempEmailID]!=nil)
            {
                textField.text=[Utility getTempEmailID];
            }
        }];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSString *email = ((UITextField *)[controller.textFields objectAtIndex:0]).text;
                                       //                                           DLog(@"email:%@",email);
                                       if ([Utility validEmail:email])
                                       {
                                           [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
                                           [client resetPasswordWithEmail:email];
                                       }
                                       else
                                       {
                                           //Dimple-26-10-2015
                                           UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"EmailError", nil) preferredStyle:UIAlertControllerStyleAlert];
                                           
                                           UIAlertAction *okAction = [UIAlertAction
                                                                      actionWithTitle:@"OK"
                                                                      style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action)
                                                                      {
                                                                          [self btnForgetPasswordPressed:nil];
                                                                      }];
                                           [alertController addAction:okAction];
                                           [self presentViewController:alertController animated:YES completion:nil];
                                       }
                                   }];
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction *action)
                                 {
                                 }];
        
        [controller addAction:cancel];
        [controller addAction:okAction];
        [self presentViewController:controller animated:YES completion:nil];
        
    }
    else{
        if (forgetPasswordAlert == nil)
        {
            forgetPasswordAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@"OK", nil];
            forgetPasswordAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
            forgetPasswordAlert.tag = 100;
            
            UITextField *emailTextField = [forgetPasswordAlert textFieldAtIndex:0];
            DLog(@"email textfield value :%@",emailTextField);
            if([Utility getTempEmailID]!=nil)
            {
                emailTextField.text=[Utility getTempEmailID];
            }
            emailTextField.delegate = self;
            emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
            emailTextField.tag = 101;
        }
        
        [forgetPasswordAlert show];
    }
}

- (void)matlistanHTTPClient:(MatlistanHTTPClient*)client didResetPasswordSuccessful:(id)response
{
//    [MBProgressHUD hideHUDForView:self.view animated:true];
    [SVProgressHUD dismiss];
    
    if (forgetPasswordAlert != nil)
    {
        [[forgetPasswordAlert textFieldAtIndex:0] setText:@""];
    }
    
    //Dimple-26-10-2015
    if(IS_OS_8_OR_LATER)
    {
        [self OkAlertController:@"" message:NSLocalizedString(@"password reset successful", nil)];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"password reset successful", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void)matlistanHTTPClient:(MatlistanHTTPClient*)client didResetFailWithError:(NSError*)error
{
//    [MBProgressHUD hideHUDForView:self.view animated:true];
    [SVProgressHUD dismiss];
    
    //Dimple-26-10-2015
    if(IS_OS_8_OR_LATER)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"ResetPasswordFailure", nil) preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK",nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self btnForgetPasswordPressed:nil];
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"ResetPasswordFailure", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alertView.tag = 1121;
        [alertView show];
    }
}

- (void)showNoInternetAlert
{
    //Dimple 26-10-2015
    if(IS_OS_8_OR_LATER)
    {
        [self OkAlertController:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"No internet",nil)];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"No internet",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil, nil];
        alert.delegate = self;
        alert.tag = 2003;
        [alert show];
    }
}

//Dimple 26-10-2015
#pragma mark- OkAlertController
-(void)OkAlertController:(NSString *)title message:(NSString*)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK",nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   
                               }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

//Dimple-24-10-2015
#pragma mark-this function call via alertview
-(void)loginwithfacebook
{
    // login with facebook
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logInWithReadPermissions:@[@"public_profile"] fromViewController:self handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        DLog(@"Facebook login didCompleteWithResult");
        if (result.token)
        {
            if ([Utility getCurrentLoginType] == LoginTypeAnonymous)
            {
                NSDictionary *parameters;
                parameters = @{@"fbAccessToken": result.token.tokenString};
                [client PATCH:@"Accounts" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                    [SVProgressHUD dismiss];
                    NSDictionary *dict = (NSDictionary*)responseObject;
                    client.ticket = dict[@"ticket"];
                    client.accountId = dict[@"accountId"];
                    [[Crashlytics sharedInstance] setUserIdentifier:client.accountId];
                    DLog(@"Successful Facebook PATCH response = %@",dict);
                    //DLog(@"Get cookie from server %@",client.ticket);
                    [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
                    [Utility setCurrentLoginType:LoginTypeFacebook];
                    myAccessToken = result.token;
                    [Utility saveInDefaultsWithObject:result.token.tokenString andKey:@"FacebookTokenRetrieved"];
                    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                    {
                        [[Mixpanel sharedInstance] identify:client.accountId];
                    }
                    //[self matlistanHTTPClient:client didLogin:nil];
                    [client didLogin:nil];
                    
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
                    [Utility setCurrentLoginType:LoginTypeAnonymous];
                    [self logoutFacebook];//PATCH failed but user is logged in as Facebook. So log him out.
                    [SVProgressHUD dismiss];
                    NSData *errorData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
                    DLog(@"Failed Facebook PATCH response = %@",[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]);
                    if (errorData == nil)
                    {
                        //no internet
                        [self showErrorInputAlert:NSLocalizedString(@"FailedConnection", nil)];
                    }
                    else
                    {
                        NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
                        NSString *errorDetail = [serializedData objectForKey:@"errorString"];
                        if ( ![Utility isStringEmpty:errorDetail])
                        {
                            [self showErrorInputAlert:errorDetail];
                        }
                    }
                }];
            }
            else
            {
                [Utility setCurrentLoginType:LoginTypeFacebook];
                myAccessToken = result.token;
                [Utility saveInDefaultsWithObject:result.token.tokenString andKey:@"FacebookTokenRetrieved"];
                client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
                client.delegate = self;
                [SVProgressHUD dismiss];
                [client loginWithFacebook];
            }
        }
        else
        {
            if (result.isCancelled)
                DLog(@"user canceled facebook login");
            if (error)
                [self showErrorInputAlert:error.localizedDescription];
        }
    }];
}
- (IBAction)googleLogin:(id)sender {
    [googleLoginButton setBackgroundColor:[UIColor whiteColor]];
    [[GIDSignIn sharedInstance] signIn];
}

#pragma mark- rotation delegate method
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(fortag==0)
    {
        [self.scrollview setContentOffset:CGPointMake(0, 0) animated:NO];
    }
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(fortag==1)
    {
        [self setContentOffsetWhenEmailTxtBecomeFirstResponder];
    }
    else if (fortag==2)
    {
        [self setContentOffsetWhenPasswordTxtBecomeFirstResponder];
    }
    else
    {
        self.scrollview.contentSize = CGSizeMake(SCREEN_WIDTH,CGRectGetMaxY(self.forgetPasswordButton.frame)+30);
    }
    [self setScrollEnableOrNot];
}

#pragma mark - set scroll enable or disable
-(void)setScrollEnableOrNot
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        if(IS_IPHONE)
        {
            if(iphone4)
            {
                self.scrollview.scrollEnabled=YES;
            }
            else
            {
                self.scrollview.scrollEnabled=NO;
            }
        }
        else
        {
            self.scrollview.scrollEnabled=NO;
        }
    }
    else//landscape
    {
        if(IS_IPHONE)
        {
            self.scrollview.scrollEnabled=YES;
        }
        else
        {
            if(IS_IPAD_PRO)
            {
                self.scrollview.scrollEnabled = NO;
            }
            else
            {
                self.scrollview.scrollEnabled = YES;
            }
        }
    }
    
}

#pragma mark- set content offset when textfield become first responder
-(void)setContentOffsetWhenEmailTxtBecomeFirstResponder
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
    }
    else
    {
        int set_y=30;
        if(IS_IPHONE)
        {
            if(iphone4)
            {
                set_y=45;
            }
            else if (iphone5)
            {
                set_y=45;
            }
            else
            {
                set_y=45;
            }
            [self.scrollview setContentOffset:CGPointMake(0,self.emailField.frame.origin.y+set_y) animated:YES];
        }
        else
        {
            if(IS_IPAD_PRO)
            {
            }
            else
            {
                [self.scrollview setContentOffset:CGPointMake(0,self.emailField.frame.origin.y+45) animated:YES];
            }
        }
    }

}

-(void)setContentOffsetWhenPasswordTxtBecomeFirstResponder
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
    }
    else
    {
        int set_y=30;
        if(IS_IPHONE)
        {
            if(iphone4)
            {
                set_y=45;
            }
            else if (iphone5)
            {
                set_y=45;
            }
            else if (iphone6 || iphone6Plus)
            {
                set_y=0;
            }
            else
            {
                set_y=45;
            }
            [self.scrollview setContentOffset:CGPointMake(0,self.passwordField.frame.origin.y+set_y) animated:YES];
        }
        else
        {
            if(IS_IPAD_PRO)
            {
            }
            else
            {
                [self.scrollview setContentOffset:CGPointMake(0,self.emailField.frame.origin.y+45) animated:YES];
            }
        }
        
    }
}
@end
