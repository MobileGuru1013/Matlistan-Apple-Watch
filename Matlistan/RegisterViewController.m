//
//  RegisterViewController.m
//  MatListan
//
//  Created by Yan Zhang on 04/12/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "RegisterViewController.h"
#import "AppDelegate.h"
#import "Mixpanel.h"
#import "SyncManager.h"

@interface RegisterViewController (){
    NSArray *cellNames;
    NSArray *placeHolders;
    NSArray *sectionRows;
    NSMutableArray *textFields;
    NSString *email;
    NSString *pwd;
    UIActivityIndicatorView * spinner;
    UIImageView * bgimage;
    UILabel * loadingLabel;
}

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Utility saveInDefaultsWithBool:YES andKey:@"firstDataLoad"];
    [_activityIndicator stopAnimating];
    _activityIndicator.hidden = YES;
    
    _emailField.delegate = self;
    if([Utility getTempEmailID]!=nil)
    {
        _emailField.text=[Utility getTempEmailID];
    }
    _passwordField.delegate = self;
    _password2Field.delegate = self;
    _emailField.placeholder = NSLocalizedString(@"Email", nil);
    _passwordField.placeholder = NSLocalizedString(@"Password", nil);
    _password2Field.placeholder = NSLocalizedString(@"Confirm password", nil);
    _emailField.returnKeyType = UIReturnKeyNext;
    _passwordField.returnKeyType = UIReturnKeyNext;
    _password2Field.returnKeyType = UIReturnKeyDone;
    [_registerButton setTitle:NSLocalizedString(@"Register", nil) forState:UIControlStateNormal];
    
    cellNames = @[@"cellImage",@"cellText",@"cellButton"];
    placeHolders = @[@"Email",NSLocalizedString(@"Password",nil),NSLocalizedString(@"Confirm password",nil)];
    sectionRows = @[@1,@3,@1];
    textFields = [[NSMutableArray alloc] initWithCapacity:3];
    self.tableView.backgroundColor = [UIColor whiteColor];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(dismissKeyboard)];

    [self.view addGestureRecognizer:tap];
    self.appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;//for switching rootViewController
    self.registerButton.layer.cornerRadius=3;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dismissKeyboard {
    [_emailField resignFirstResponder];
    [_passwordField resignFirstResponder];
    [_password2Field resignFirstResponder];
}

#pragma mark- tableview
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = cellNames[indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.backgroundColor = [UIColor clearColor];
    switch (indexPath.section)
    {
        case 0:{
            UIImageView *iv = (UIImageView*)[cell viewWithTag:1];
            iv.image = [UIImage imageNamed:@"logo"];
            iv.contentMode = UIViewContentModeScaleAspectFit;
            break;
        }
        case 1:{
            UITextField *textField = (UITextField*)[cell viewWithTag:1];
            textField.placeholder = placeHolders[indexPath.row];
            textField.delegate = self;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.returnKeyType = indexPath.row <2 ? UIReturnKeyNext: UIReturnKeyDone;
            if (indexPath.row > 0) {
                UITextField *prevTextField   = textFields[indexPath.row -1];
                prevTextField.nextTextField = textField;
                textField.secureTextEntry = YES;
            }
            
            textFields[indexPath.row] = textField;
            
            break;
        }
        case 2:
        {
            UIButton *button = (UIButton*)[cell viewWithTag:1];
            [Utility setGreenButtonBorder:button];
            [button setTitle:NSLocalizedString(@"Register",nil) forState:UIControlStateNormal];
            // used UIControlEventTouchUpInside to fix issue # 238 /Yousuf
            [button addTarget:self action:@selector(onClickRegisterButton) forControlEvents:UIControlEventTouchUpInside];
            CGRect frameRelativeToParent = [button convertRect:button.bounds toView:self.view];
            CGRect tmpFrame = _activityIndicator.frame;
            tmpFrame.origin.y = frameRelativeToParent.origin.y;
            tmpFrame.origin.x = (self.view.frame.size.width - frameRelativeToParent.size.width)/2;
            _activityIndicator.frame = tmpFrame;
            DLog(@"x: %f y: %f", tmpFrame.origin.x, tmpFrame.origin.y);
            break;
        }
        default:
            break;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat height = 44.0;
    if(indexPath.section > 0){
        height = 44.0;
    }
    else{
        height = IS_IPHONE? 70.0:200;
    }
    return height;
    
}

#pragma mark- register
-(void)onClickRegisterButton{
    [self dismissKeyboard];
    _activityIndicator.hidden = NO;
    [_activityIndicator startAnimating];
    //Validate user password
    
    email = self.emailField.text;
    pwd = self.passwordField.text;
    
    if (![pwd isEqualToString:_password2Field.text]) {
        [self showErrorInputAlert:NSLocalizedString(@"PasswordNotMatch", nil)];
        [_activityIndicator stopAnimating];
        _activityIndicator.hidden = YES;
    }
    else if(email.length < 6 || (![Utility containsSubstring:@"@" inString:email])){
        
        [self showErrorInputAlert:NSLocalizedString(@"EmailError", nil)];
        [_activityIndicator stopAnimating];
        _activityIndicator.hidden = YES;
        
    }
    else{
        //send to server registeration info
        [self sendRegistrationToServer];
    }
    
}
-(void)sendRegistrationToServer{
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];

//    [self createWaitOverlay:[NSString stringWithFormat:@"%@ ...", NSLocalizedString(@"Register",nil)]];
    MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    NSDictionary *parameters;
    
    if ([Utility getCurrentLoginType] == LoginTypeAnonymous) {
        
        parameters = @{@"email": email,
                       @"password": pwd,
                       @"create":[NSNumber numberWithBool:YES]
                                     };
        [client PATCH:@"Accounts" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSDictionary *dict = (NSDictionary*)responseObject;
            client.ticket = dict[@"ticket"];
            client.accountId = dict[@"accountId"];
            [[Crashlytics sharedInstance] setUserIdentifier:client.accountId];
            DLog(@"registeration response PATCH = %@",dict);
            //DLog(@"Get cookie from server %@",client.ticket);
            [_activityIndicator stopAnimating];
            _activityIndicator.hidden = YES;
            
            [Utility saveInDefaultsWithObject:email andKey:@"userName"];
            [Utility saveInDefaultsWithObject:pwd andKey:@"password"];
            [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
            [Utility setCurrentLoginType:LoginTypeEmail];
            
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                [[Mixpanel sharedInstance] identify:client.accountId];
            }
            
//            [self removeWaitOverlay];
            [SVProgressHUD dismiss];

            //[self dismissViewControllerAnimated:YES completion:nil];
            [client didLogin:nil];
            [self.appDelegate switchRootViewController];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
//            [self removeWaitOverlay];
            [SVProgressHUD dismiss];

            [_activityIndicator stopAnimating];
            _activityIndicator.hidden = YES;
            [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
            [Utility setCurrentLoginType:LoginTypeAnonymous];//User stays as anonymous user

            NSData *errorData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
            DLog(@"failed Register with error = %@",[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]);
            if (errorData == nil) {
                //no internet
                [self showErrorInputAlert:NSLocalizedString(@"FailedConnection", nil)];
            }
            else {
                NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
                NSString *errorDetail = [serializedData objectForKey:@"errorString"];
                
                if ( ![Utility isStringEmpty:errorDetail]) {
                    [self showErrorInputAlert:errorDetail];
                }
            }
        }];
    }else{
        parameters = @{@"email": email,
                       @"password": pwd,
                                     };
        [client POST:@"Accounts" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSDictionary *dict = (NSDictionary*)responseObject;
            client.ticket = dict[@"ticket"];
            client.accountId = dict[@"accountId"];
            [[Crashlytics sharedInstance] setUserIdentifier:client.accountId];
            DLog(@"registeration response POST = %@",dict);
            //DLog(@"Get cookie from server %@",client.ticket);
            [_activityIndicator stopAnimating];
            _activityIndicator.hidden = YES;
            
            [Utility saveInDefaultsWithObject:email andKey:@"userName"];
            [Utility saveInDefaultsWithObject:pwd andKey:@"password"];
            [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
            [Utility setCurrentLoginType:LoginTypeEmail];
            
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                [[Mixpanel sharedInstance] identify:client.accountId];
            }
            
//            [self removeWaitOverlay];
            [SVProgressHUD dismiss];
            
            //[self dismissViewControllerAnimated:YES completion:nil];
            [client didLogin:nil];
            [self.appDelegate switchRootViewController];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
//            [self removeWaitOverlay];
            [SVProgressHUD dismiss];

            [_activityIndicator stopAnimating];
            _activityIndicator.hidden = YES;
            
            NSString *errorMessage = NSLocalizedString(@"RegisterError",nil);
            NSData *errorData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
            if (errorData == nil) {
                //no internet
                [self showErrorInputAlert:NSLocalizedString(@"FailedConnection", nil)];
            }
            else {
                NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
                NSString *errorDetail = [serializedData objectForKey:@"errorString"];
                
                if ( ![Utility isStringEmpty:errorDetail]) {
                    [self showErrorInputAlert:errorDetail];
                }
                else{
                    [self showErrorInputAlert:errorMessage];
                }
            }
        }];
    }
}


-(void)showErrorInputAlert:(NSString*)msg{
    //Dimple 26-10-2015
    if(IS_OS_8_OR_LATER)
    {
        [self OkAlertController:NSLocalizedString(@"Info",nil) message:msg];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info",nil) message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:Nil, nil];
        [alert show];
    }
}

#pragma HideKeyboard
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _emailField && textField.returnKeyType == UIReturnKeyNext) {
        [_passwordField becomeFirstResponder];
    }else if (textField == _passwordField && textField.returnKeyType == UIReturnKeyNext){
        [_password2Field becomeFirstResponder];
    }else if(textField == _password2Field){
        [_password2Field resignFirstResponder];
        if (_emailField.text.length > 0 && _passwordField.text.length > 0 && _password2Field.text.length > 0) {
            [self onClickRegisterButton];
        }
    }
    return YES;
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}


#pragma mark - showSpinner

//-(void)createWaitOverlay:(NSString*)message
//{
//    // fade the overlay in
//    if (loadingLabel != nil) {
//        return;
//    }
//    if (message.length > 14) {
//        loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 75,self.view.bounds.size.height/2 - 30,210.0, 50.0)];
//    }
//    else{
//        loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 -100,self.view.bounds.size.height/2 - 30,210.0, 20.0)];
//    }
//    loadingLabel.text = message;
//    loadingLabel.numberOfLines = 0;
//    loadingLabel.textColor = [UIColor whiteColor];
//    bgimage = [[UIImageView alloc] initWithFrame:self.view.frame];
//    bgimage.image = [UIImage imageNamed:@"waitOverLay.png"];
//    [self.view addSubview:bgimage];
//    bgimage.alpha = 0;
//    [bgimage addSubview:loadingLabel];
//    loadingLabel.alpha = 0;
//    
//    [UIView beginAnimations: @"Fade In" context:nil];
//    [UIView setAnimationDelay:0];
//    [UIView setAnimationDuration:.5];
//    bgimage.alpha = 1;
//    loadingLabel.alpha = 1;
//    [UIView commitAnimations];
//    
//    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//    spinner.hidden = FALSE;
//    spinner.frame = CGRectMake(self.view.bounds.size.width/2 - 25,self.view.bounds.size.height/2 - 75, 50, 50);
//    [spinner setHidesWhenStopped:YES];
//    [self.view addSubview:spinner];
//    [self.view bringSubviewToFront:spinner];
//    [spinner startAnimating];
//
//}
//
//-(void)removeWaitOverlay {
//    [UIView beginAnimations: @"Fade Out" context:nil];
//    [UIView setAnimationDelay:0];
//    [UIView setAnimationDuration:.5];
//    bgimage.alpha = 0;
//    loadingLabel.alpha = 0;
//    [UIView commitAnimations];
//    [spinner stopAnimating];
//    
//    if (loadingLabel != nil) {
//        [bgimage removeFromSuperview];
//        [loadingLabel removeFromSuperview];
//        [spinner removeFromSuperview];
//        bgimage = nil;
//        loadingLabel = nil;
//        spinner = nil;
//    }
//}

- (IBAction)emailDidBegin:(id)sender {
}

- (IBAction)passwordDidBegin:(id)sender {
}

- (IBAction)password2DidBegin:(id)sender {
}

- (IBAction)registerClicked:(id)sender {
    [self onClickRegisterButton];
}

- (IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Orientation
-(BOOL)shouldAutorotate
{
    [super shouldAutorotate];
    return NO;
}
- (NSUInteger) supportedInterfaceOrientations {
    [super supportedInterfaceOrientations];
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskPortrait;
    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    [super preferredInterfaceOrientationForPresentation];
    // Return the orientation you'd prefer - this is what it launches to. The
    // user can still rotate. You don't have to implement this method, in which
    // case it launches in the current orientation
    return UIInterfaceOrientationPortrait;
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

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing RegisterViewController");
}

@end
