//
//  MatlistanHTTPClient.m
//  MatListan
//
//  Created by Yan Zhang on 28/08/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "MatlistanHTTPClient.h"
#import "JSONResponseSerializerWithData.h"
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "AppDelegate.h"
#import "SyncManager.h"
#import "Mixpanel.h"
#import "DataStore.h"

#import "Environment.h"

@interface MatlistanHTTPClient()

@end

@implementation MatlistanHTTPClient

+(MatlistanHTTPClient *)sharedMatlistanHTTPClient{
    static MatlistanHTTPClient *_sharedClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[self alloc]initWithBaseURL:[NSURL URLWithString:[Utility getMatlistanServerURLString]]];
        _sharedClient.responseSerializer = [JSONResponseSerializerWithData serializer];
        _sharedClient.googleLoginTriedAgain = NO;
    });
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    return self;
}


- (void)loginWithUserName:(NSString *)userName andPassword:(NSString *)password
{
    //self.userName = userName;
    //self.password = password;
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"email"] = userName;
    parameters[@"password"] = password;
    //parameters[@"simulateResponseCode"] = @"501";
    
    DLog(@"login Credentials = %@",parameters);
    
    void (^successBlock)(NSURLSessionDataTask *task, id responseObject) =
    ^(NSURLSessionDataTask *task, id responseObject) {
        DLog(@"Try to log in");
        
        [Utility saveInDefaultsWithBool:NO andKey:@"AnonymousUser"];
        [Utility saveInDefaultsWithInt:LoginTypeEmail andKey:@"LoginType"];
        
        [Utility saveInDefaultsWithObject:userName andKey:@"userName"];
        [Utility saveInDefaultsWithObject:password andKey:@"password"];
        [Utility setCurrentLoginType:LoginTypeEmail];
        
        self.isLoggedIn = YES;
        
        NSDictionary *dict = (NSDictionary*)responseObject;
        
        self.ticket = dict[@"ticket"];
        self.accountId = dict[@"accountId"];
        DLog(@"Get cookie from server %@",self.ticket);
        
        [self getMe];
        [self acknowledgeSubscriptionToServer];
        
        [self didLogin:responseObject];

    };
    void (^failureBlock)(NSURLSessionDataTask *task, NSError *error) =
    ^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to log in");
        NSData *errData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
        NSString *str = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
        DLog(@"des = %@",str);
        self.isLoggedIn = NO;
        
        NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
        long statusCode = (long)r.statusCode;
        
        [self didFailWithCode:statusCode andError: error];
    };
    
    if ([Utility getCurrentLoginType] == LoginTypeAnonymous) {
        parameters[@"create"] = [NSNumber numberWithBool:NO];
        [self PATCH:@"Accounts" parameters:parameters success:successBlock failure: failureBlock];
    }
    else {
        [self POST:@"Sessions" parameters:parameters success:successBlock failure: failureBlock];
    }
}

-(void)retryLogin{
    if ([Utility getCurrentLoginType] == LoginTypeEmail) {
        [self loginWithUserName:[Utility getObjectFromDefaults:@"userName"] andPassword:[Utility getObjectFromDefaults:@"password"]];
    }else if ([Utility getCurrentLoginType] == LoginTypeAnonymous){
        [self loginAsAnonymousWithUserName:[Utility getObjectFromDefaults:@"userName"] andPassword:[Utility getObjectFromDefaults:@"password"]];
    }else if ([Utility getCurrentLoginType] == LoginTypeFacebook){
        [self loginWithFacebook];
    } else if ([Utility getCurrentLoginType] == LoginTypeGoogle) {
        if (self.googleTokenSaved) {
            [self loginWithGoogleIdToken:_googleTokenSaved[@"gIdToken"] andAccessToken:_googleTokenSaved[@"gAccessToken"]];
        }
    }
}

//anonymous login
-(void)registerAsAnonymous{
    
    [self POST:@"Accounts" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject){
        
        NSDictionary *resDic = (NSDictionary *)responseObject;
        DLog(@"Anonymous register successful = %@",responseObject);
        if ([resDic[@"success"] boolValue]) {
            
            self.ticket = resDic[@"ticket"];
            self.accountId = resDic[@"accountId"];
            self.anonymousUserId = resDic[@"anonymousUid"];
            self.anonymousPassword = resDic[@"password"];
            self.isLoggedIn = YES;
            
            [Utility setCurrentLoginType:LoginTypeAnonymous];
            [Utility saveInDefaultsWithObject:self.anonymousUserId andKey:@"userName"];
            [Utility saveInDefaultsWithObject:self.anonymousPassword andKey:@"password"];
            
            [self didLogin:responseObject];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        DLog(@"Anonymous register failed");
        self.isLoggedIn = NO;
        NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
        long statusCode = (long)r.statusCode;
        
        [self didFailWithCode:statusCode andError: error];
    }];
}

-(void)loginAsAnonymousWithUserName:(NSString *)anonymousId andPassword:(NSString *)anonymousPassword{
    self.anonymousUserId = anonymousId;
    self.anonymousPassword = anonymousPassword;
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"anonymousUid"] = anonymousId;
    parameters[@"password"] = anonymousPassword;
    
    [self POST:@"Sessions" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject){
        
        NSDictionary *dict = (NSDictionary*)responseObject;
        DLog(@"Successful Anonymous login");
        
        if ([[responseObject objectForKey:@"success"]boolValue]) {
            self.isLoggedIn = YES;
            [Utility setCurrentLoginType:LoginTypeAnonymous];
            self.ticket = dict[@"ticket"];
            self.accountId = dict[@"accountId"];
            DLog(@"Got cookie from server Anonymous login %@",self.ticket);
            [self didLogin:responseObject];
        }
        
        [self getMe];
        [self acknowledgeSubscriptionToServer];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        DLog(@"Failed Anonymous login");
        self.isLoggedIn = NO;
        NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
        long statusCode = (long)r.statusCode;
        
        [self didFailWithCode:statusCode andError: error];
    }];
}

-(void)loginWithFacebook{
    NSDate *expDate = [[FBSDKAccessToken currentAccessToken] expirationDate];
    NSDate *todayDate = [NSDate date];
    NSLog(@"%@", [FBSDKAccessToken currentAccessToken].expirationDate);
    if(_facebookLoginTriedAgain || [Utility daysBetweenDate:todayDate andDate:expDate] <= 1) {
        DLog(@"refreshing Facebook token");
        [FBSDKAccessToken refreshCurrentAccessToken:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            DLog(@"result refreshCurrentAccessToken = %@",(NSDictionary *) result);
            if (error) {
                DLog(@"failed refreshCurrentAccessToken");
                if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                {
                    [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"action":@"refreshCurrentAccessToken"}];
                }
                _facebookLoginTriedAgain = NO;
                [self didFailWithCode:0 andError: error];
            }
            else {
                 NSLog(@"%@", [FBSDKAccessToken currentAccessToken].expirationDate);
                [Utility saveInDefaultsWithObject:[FBSDKAccessToken currentAccessToken].tokenString andKey:@"FacebookTokenRetrieved"];
                _facebookLoginTriedAgain = NO;
                [self loginWithFacebook];
            }
            
        }];
    }
    else {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"fbAccessToken"] = [FBSDKAccessToken currentAccessToken].tokenString;
        
        [self POST:@"Sessions" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject){
            NSDictionary *dict = (NSDictionary*)responseObject;
            DLog(@"Successful Facebook login");
            _facebookLoginTriedAgain = NO;
            if ([[responseObject objectForKey:@"success"]boolValue]) {
                self.isLoggedIn = YES;
                [Utility setCurrentLoginType:LoginTypeFacebook];
                self.ticket = dict[@"ticket"];
                self.accountId = dict[@"accountId"];
                DLog(@"Got cookie from server facebook login %@",self.ticket);
                [self didLogin:responseObject];
                
                [self getMe];
                [self acknowledgeSubscriptionToServer];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error){
            if(_facebookLoginTriedAgain) {
                DLog(@"Failed Facebook login");
                _facebookLoginTriedAgain = NO;
                self.isLoggedIn = NO;
                NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
                long statusCode = (long)r.statusCode;
                
                [self didFailWithCode:statusCode andError: error];
            }
            else {
                _facebookLoginTriedAgain = YES;
                [self loginWithFacebook];
            }
        }];
    }
}

- (void) loginWithGoogleIdToken:(NSString *)idToken andAccessToken: (NSString *) accessToken {
    
    NSDate *expDate = [Utility getObjectFromDefaults:@"GoogleAccessTokenExpirationDate"];
    NSDate *todayDate = [NSDate date];
    if ([todayDate compare: expDate] == NSOrderedDescending) {
        [GIDSignIn sharedInstance].delegate = self;
        [[GIDSignIn sharedInstance] setServerClientID:[Environment sharedInstance].googleServerClientId];
        [[GIDSignIn sharedInstance] setClientID:[Environment sharedInstance].googleClientId];
        [[GIDSignIn sharedInstance] signInSilently];
    }
    else {
        NSDictionary *parameters = @{@"gIdToken": idToken, @"gAccessToken": accessToken};
        self.googleTokenSaved = parameters;
        
        [self POST:@"Sessions" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject){
            NSDictionary *dict = (NSDictionary*)responseObject;
            DLog(@"Successful Google login");
            
            if ([[responseObject objectForKey:@"success"]boolValue]) {
                self.isLoggedIn = YES;
                [Utility setCurrentLoginType:LoginTypeGoogle];
                self.ticket = dict[@"ticket"];
                self.accountId = dict[@"accountId"];
                DLog(@"Got cookie from server facebook login %@",self.ticket);
                [self didLogin:responseObject];
                
                [self getMe];
                [self acknowledgeSubscriptionToServer];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error){
            if(!_googleLoginTriedAgain) {
                [GIDSignIn sharedInstance].delegate = self;
                [[GIDSignIn sharedInstance] setServerClientID:[Environment sharedInstance].googleServerClientId];
                [[GIDSignIn sharedInstance] setClientID:[Environment sharedInstance].googleClientId];
                [[GIDSignIn sharedInstance] signInSilently];
                _googleLoginTriedAgain = YES;
            }
            else {
                _googleLoginTriedAgain = NO;
                DLog(@"Failed Google login");
                NSData *errData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
                NSString *str = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
                DLog(@"des = %@",str);
                self.isLoggedIn = NO;
                NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
                long statusCode = (long)r.statusCode;
                
                [self didFailWithCode:statusCode andError: error];
            }
        }];
    }

}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    DLog(@"Google login didCompleteWithResult");
    if (user.authentication.idToken && user.authentication.accessToken)
    {
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
            [Utility setCurrentLoginType:LoginTypeGoogle];
            [Utility saveInDefaultsWithObject:user.authentication.idToken andKey:@"GoogleIdTokenRetrieved"];
            [Utility saveInDefaultsWithObject:user.authentication.accessToken andKey:@"GoogleAccessTokenRetrieved"];
            [Utility saveInDefaultsWithObject:user.authentication.accessTokenExpirationDate andKey:@"GoogleAccessTokenExpirationDate"];
            [self loginWithGoogleIdToken: user.authentication.idToken andAccessToken: user.authentication.accessToken];
    }
    else
    {
        if (error) {
            [self didFailWithCode:0 andError: error];
        }
    }
}


- (void) didLogin:(id)cookie {
    [[Crashlytics sharedInstance] setUserIdentifier:self.accountId];
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] identify:self.accountId];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kInternetReachable object:nil];
    [Utility saveInDefaultsWithObject:[NSDate new] andKey:@"LastLoggedInDateKey"];
    [self scheduleLoginIn:3500]; //should reconnect every hour
    [[SyncManager sharedManager] startSync];
    //Save in NSUserDefaults
    self.isLoggedIn = YES;
    [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
    if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didLogin:)]) {
        [self.delegate matlistanHTTPClient:self didLogin:cookie];
    }
}

- (void) didFailWithCode: (long) code andError:(NSError *)error {
    /*
    NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
    long statusCode = (long)r.statusCode;
    if(statusCode >=400 && statusCode < 500){
     */
    DLog(@"client login failed = %@",error.localizedDescription);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kInternetNotReachable object:nil];
    if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didFailWithError:andCode:)]) {
        [self.delegate matlistanHTTPClient:self didFailWithError:error andCode:code];
    }
    else if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didFailWithError:)]) {
        [self.delegate matlistanHTTPClient:self didFailWithError:error];
    }
    
    //IOS-8 Fixes : Bil Cooper
    if ([Utility getDefaultBoolAtKey:@"authorized"]) {
        
        NSData *errorData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
        NSDictionary *errorDic = [Utility getErrorDictionary:errorData];
        DLog(@"Failed login = %@",errorDic);
        
        if (errorDic && ![[errorDic objectForKey:@"success"] boolValue]) {
            
            if (error)
            {
                if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                {
                    [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"Screen":@"Login", @"action":@"Login"}];
                }
            }
            
            LoginType someType = [Utility getCurrentLoginType];
            
            //Dimple - 16-10-2015 fixed bug #304
            if (someType == LoginTypeEmail && code >=400 && code < 500)
            {
                NSArray *options = [NSArray arrayWithObjects:NSLocalizedString(@"Retry",nil),NSLocalizedString(@"Change login",nil),NSLocalizedString(@"Continue without synchronization",nil),nil];
                [self showLoginFailedSheetWithOptions:options];
            }
            else if ((someType == LoginTypeFacebook  || someType == LoginTypeAnonymous  || someType == LoginTypeGoogle) && (code >=400 && code < 500))
            {
                NSArray *optionsAnonymous = [NSArray arrayWithObjects:NSLocalizedString(@"Retry",nil),NSLocalizedString(@"Change login",nil),NSLocalizedString(@"Continue without synchronization",nil), nil];
                [self showLoginFailedSheetWithOptions:optionsAnonymous];
            }
            else {
                [self scheduleLoginIn:10];
            }
        }
        else {
            [self scheduleLoginIn:10];
        }
    }
}


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
    
    [failedLoginSheet showInView:[[[UIApplication sharedApplication] delegate] window]];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (popup.tag == 3002) {
        NSString *title = [popup buttonTitleAtIndex:buttonIndex];
        DLog(@"select index = %ld option = %@",(long)buttonIndex,title);
        
        if ([title isEqualToString:NSLocalizedString(@"Retry", nil)]) {
            [self retrySelectedByUser];
        }else if ([title isEqualToString:NSLocalizedString(@"Continue without synchronization", nil)]){
            //IOS-8 Fixes: Bil Cooper
            DLog(@"Continue without Sync selected");
            _isLoggedIn = NO;
            //_autoRetryLogin = YES;
            [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
            //[self scheduleLoginIn:10];
        }else if ([title isEqualToString:NSLocalizedString(@"Enter new password", nil)]) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New Password", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Login", nil), nil];
            alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
            alert.tag = 3003;
            [alert show];
            
        }else if ([title isEqualToString:NSLocalizedString(@"Change login", nil)]){
            [popup dismissWithClickedButtonIndex:0 animated:YES];
            //Bil Cooper
            DLog(@"enter credentials selected");
            [theAppDelegate switchToLoginViewController];
        }
    }
}

- (void) scheduleLoginIn: (NSTimeInterval) seconds {
    [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(retryLogin) userInfo:nil repeats:NO];
}

-(void)retrySelectedByUser{
    if ([Utility getCurrentLoginType] == LoginTypeEmail) {
        NSString *userName = [Utility getObjectFromDefaults:@"userName"];
        NSString *password = [Utility getObjectFromDefaults:@"password"];
        [self loginWithUserName:userName andPassword:password];
    }else if ([Utility getCurrentLoginType] == LoginTypeFacebook){
            [self loginWithFacebook];
    }else if ([Utility getCurrentLoginType] == LoginTypeAnonymous){
        NSString *userName = [Utility getObjectFromDefaults:@"userName"];
        NSString *password = [Utility getObjectFromDefaults:@"password"];
        [self loginAsAnonymousWithUserName:userName andPassword:password];
    }
    else if ([Utility getCurrentLoginType] == LoginTypeGoogle){
        NSString *gidToken = [Utility getObjectFromDefaults:@"GoogleIdTokenRetrieved"];
        NSString *gauthToken = [Utility getObjectFromDefaults:@"GoogleAccessTokenRetrieved"];
        if(gidToken && gauthToken) {
            [self loginWithGoogleIdToken:gidToken andAccessToken:gauthToken];
        }
    }
}

#pragma mark AlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if (alertView.tag == 3003) {
        if ([title isEqualToString:NSLocalizedString(@"Login", nil)]) {
            NSString *userName = [Utility getObjectFromDefaults:@"userName"];
            NSString *password = [alertView textFieldAtIndex:0].text;
            [[alertView textFieldAtIndex:0] resignFirstResponder];
            [Utility saveInDefaultsWithObject:password andKey:@"password"];
            [self loginWithUserName:userName andPassword:password];
        }
    }
    else if (alertView.tag == 2004) {
        _isLoggedIn = NO;
        [Utility saveInDefaultsWithBool:YES andKey:@"authorized"];
        [self scheduleLoginIn:10];
    }
}


-(void)loginWithPostSession{
    NSString *savedUserName = [Utility getObjectFromDefaults:@"userName"];
    NSString *savedPassword = [Utility getObjectFromDefaults:@"password"];
    
    LoginType loginType = [Utility getCurrentLoginType];
    
    if (loginType == LoginTypeFacebook) {
        [self loginWithFacebook];
    }else if (loginType == LoginTypeEmail){
        [self loginWithUserName:savedUserName andPassword:savedPassword];
    }else if (loginType == LoginTypeAnonymous){
        [self loginAsAnonymousWithUserName:savedUserName andPassword:savedPassword];
    }
    else if (loginType == LoginTypeGoogle){
        NSString *gidToken = [Utility getObjectFromDefaults:@"GoogleIdTokenRetrieved"];
        NSString *gauthToken = [Utility getObjectFromDefaults:@"GoogleAccessTokenRetrieved"];
        if(gidToken && gauthToken) {
            [self loginWithGoogleIdToken:gidToken andAccessToken:gauthToken];
        }
    }
    
}

/**
 API call to reset password
 @ModifiedDate: September 1 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)resetPasswordWithEmail:(NSString*)email
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"email"] = email;
    
    DLog(@"reset password parameters : %@", parameters);
    
    [self POST:@"/Accounts/ForgotPassword" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        DLog(@"Try to reset password");
        if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didResetPasswordSuccessful:)]) {
            
            self.isLoggedIn = NO;
            
            [self.delegate matlistanHTTPClient:self didResetPasswordSuccessful:responseObject];
            
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didResetFailWithError:)]) {
            DLog(@"Fail to reset password");
            NSData *errData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
            NSString *str = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
            DLog(@"des = %@",str);
            self.isLoggedIn = NO;
            [self.delegate matlistanHTTPClient:self didResetFailWithError:error];
        }
    }];
}

/**
 API to get linked accounts
 @ModifiedDate: September 3 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)getLinkedAccounts
{
    [self GET:@"/Me/UserLinks" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
     {
         DLog(@"getting linked accounts");
         if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didRequestSuccessful:withType:)])
         {
             [self.delegate matlistanHTTPClient:self didRequestSuccessful:responseObject withType:RequestGetLinkedAccounts];
             
         }
     } failure:^(NSURLSessionDataTask *task, NSError *error)
     {
         if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didFailWithError:)])
         {
             DLog(@"Fail to get linked accounts");
             [self.delegate matlistanHTTPClient:self didFailWithError:error];
         }
     }];
}

/**
 API to link account to current
 @ModifiedDate: September 3 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)linkAccount:(NSString *)email withFbId:(NSString *)fbId
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"email"] = email;
    parameters[@"fbId"] = fbId;
    if([Utility getObjectFromDefaults:@"GoogleIdTokenRetrieved"]) {
        parameters[@"googleId"] = [Utility getObjectFromDefaults:@"GoogleIdTokenRetrieved"];
    }
    
    DLog(@"link account parameters : %@", parameters);
    
    [self POST:@"/Me/UserLinks" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject)
     {
         DLog(@"getting linked accounts");
         if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didRequestSuccessful:withType:)])
         {
             [self.delegate matlistanHTTPClient:self didRequestSuccessful:responseObject withType:RequestLinkNewAccount];
             
         }
     } failure:^(NSURLSessionDataTask *task, NSError *error)
     {
         if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didFailWithError:)])
         {
             DLog(@"Fail to link account");
             [self.delegate matlistanHTTPClient:self didFailWithError:error];
         }
     }];
}

/**
 API to delete linked account
 @ModifiedDate: September 3 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)deleteAccount:(int)accountId
{
    [self DELETE:[NSString stringWithFormat:@"/Me/UserLinks/%d", accountId] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
     {
         DLog(@"getting linked accounts");
         if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didRequestSuccessful:withType:)])
         {
             [self.delegate matlistanHTTPClient:self didRequestSuccessful:responseObject withType:RequestDeleteLinkedAccount];
             
         }
     } failure:^(NSURLSessionDataTask *task, NSError *error)
     {
         if ([self.delegate respondsToSelector:@selector(matlistanHTTPClient:didFailWithError:)])
         {
             DLog(@"Fail to link account");
             [self.delegate matlistanHTTPClient:self didFailWithError:error];
         }
     }];
}

- (void)showNoInternetAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"No internet",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil, nil];
    alert.delegate = self;
    alert.tag = 2004;
    [alert show];
}

/**
 API to get current user profile to check
 @ModifiedDate: October 7, 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)getMe
{
    [[MatlistanHTTPClient sharedMatlistanHTTPClient] GET:@"/Me" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
     {
         DLog(@"getting user");
         NSDictionary *resDic = (NSDictionary *)responseObject;
         BOOL hasPremium = [[resDic valueForKey:@"hasPremium"] boolValue];
         if (hasPremium)
         {
             [Utility saveInDefaultsWithBool:hasPremium andKey:@"hasPremium"];
             [[NSNotificationCenter defaultCenter] postNotificationName:kPremiumAccountPurchased object:nil userInfo:nil];
         }
         else
         {
             [Utility saveInDefaultsWithBool:false andKey:@"hasPremium"];
         }
         
     } failure:^(NSURLSessionDataTask *task, NSError *error)
     {
         
     }];
}

/**
 API to send in-app subscription data
 @ModifiedDate: October 13, 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)acknowledgeSubscriptionToServer
{
    //This request shouldn't be sent to server every time. Artem.
/*
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    NSData *receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if (receipt)
    {
        parameters[@"receipt"] = [receipt base64EncodedStringWithOptions:0];
        MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
        [client POST:@"/Purchases/ios" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject)
         {
             DLog(@"Validating purchase receipt");
             
         } failure:^(NSURLSessionDataTask *task, NSError *error) {
             DLog(@"Fail to verify receipt");
             NSData *errData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
             NSString *str = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
             DLog(@"des = %@",str);
         }];
    }
*/
}

-(NSString*) accountId {
    if(_accountId) {
        return _accountId;
    }
    else {
        return @"Anonymous";
    }
}

@end
