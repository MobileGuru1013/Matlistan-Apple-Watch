//
//  LinkedAccountsViewController.m
//  Matlistan
//
//  Created by Muhammad Yousuf Saif on 9/1/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "LinkedAccountsViewController.h"

//#import "MBProgressHUD.h"

#import "LinkedAccountCellView.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"

#import "FriendsViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "SWRevealViewController.h"

#import "Mixpanel.h"

@interface LinkedAccountsViewController ()<MGSwipeTableCellDelegate, UIAlertViewDelegate>
{
    NSIndexPath *selectedIndex;
}

@property (strong) MatlistanHTTPClient *client;

@end

@implementation LinkedAccountsViewController

@synthesize client;

- (void)viewDidLoad
{
    [super viewDidLoad];
    SWRevealViewController *reveal = self.revealViewController;
    reveal.panGestureRecognizer.enabled = NO;
    self.title = NSLocalizedString(@"Linked Accounts", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = NSLocalizedString(@"Linked Accounts", nil);
    
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];

    
    client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    client.delegate = self;
    [client getLinkedAccounts];
}

#pragma mark -
#pragma mark - UITableView delegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if(IS_IPHONE)
        {
            return 60;
        }
        else
        {
            return 75;
        }
    }
    else
    {
        if(IS_IPHONE)
        {
            return 80;
        }
        else
        {
            return 95;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 2;
    }
    return self.arrLinkedAccounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int font_size1=14,font_size2=17;
    if(IS_IPHONE)
    {
        font_size1=14;
        font_size2=17;
    }
    else
    {
        font_size1=18;
        font_size2=23;
    }
  
    
    if (indexPath.section == 0)
    {
        static NSString * reuseIdentifier = @"OptionsCell";
        LinkedAccountCellView * cell = [self.accountsTable dequeueReusableCellWithIdentifier:reuseIdentifier];
        if (!cell)
        {
            cell = [[LinkedAccountCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        }
        
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [cell.textLabel setFont:[UIFont systemFontOfSize:font_size2]];
        
        if (indexPath.row == 0)
        {
            cell.textLabel.text = NSLocalizedString(@"click to link fb friend", nil);
        }
        else
        {
            cell.textLabel.text = NSLocalizedString(@"click to link email", nil);
        }
        return cell;
    }
    else
    {
        static NSString * reuseIdentifier = @"AccountsCell";
        LinkedAccountCellView * cell = [self.accountsTable dequeueReusableCellWithIdentifier:reuseIdentifier];
        if (!cell) {
            cell = [[LinkedAccountCellView alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
        }
        
        cell.delegate = self;
        cell.indexPath = indexPath;
        
        NSString *title = [self.arrLinkedAccounts objectAtIndex:indexPath.row][@"email"];
        NSString *status = [self.arrLinkedAccounts objectAtIndex:indexPath.row][@"status"];
        
        if (title.length == 0)
        {
            title = [self.arrLinkedAccounts objectAtIndex:indexPath.row][@"name"];
        }
        
        cell.textLabel.text = title;
        [cell.textLabel setFont:[UIFont systemFontOfSize:font_size2]];
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [cell.detailTextLabel setFont:[UIFont systemFontOfSize:font_size1]];
        if ([status isEqualToString:@"Requested"] || [status isEqualToString:NSLocalizedString(@"Requested", nil)])
        {
            cell.detailTextLabel.text = NSLocalizedString(@"link request received", nil);
            cell.rightButtons = @[[MGSwipeButton buttonWithTitle:NSLocalizedString(@"confirm", nil) backgroundColor:[UIColor colorWithRed:93.0/255.0 green:187.0/255.0 blue:83.0/255.0 alpha:1.0]], [MGSwipeButton buttonWithTitle:NSLocalizedString(@"reject", nil) backgroundColor:[UIColor redColor]]];
        }
        else if ([status isEqualToString:@"Initiated"] || [status isEqualToString:NSLocalizedString(@"Initiated", nil)])
        {
            cell.detailTextLabel.text = NSLocalizedString(@"linking initiated", nil);
            cell.rightButtons = @[[MGSwipeButton buttonWithTitle:NSLocalizedString(@"unlink", nil) backgroundColor:[UIColor redColor]]];
        }
        else
        {
            cell.detailTextLabel.text = NSLocalizedString(@"linking confirmed", nil);
            cell.rightButtons = @[[MGSwipeButton buttonWithTitle:NSLocalizedString(@"unlink", nil) backgroundColor:[UIColor redColor]]];
        }
        cell.rightSwipeSettings.transition = MGSwipeTransitionDrag;
        if(indexPath.row%2==0)
        {
            cell.backgroundColor=CELL_BG_COLOR;
        }
        else
        {
            cell.backgroundColor=[UIColor whiteColor];
        }

        return cell;
    }
}


- (void) checkForPermission:(NSString *)permission granted:(void (^)(void))sBlock denied:(void (^)(void))fBlock {
    
    if ([FBSDKAccessToken currentAccessToken]) {
        
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/permissions" parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            
            BOOL hasPermission = NO;
            
            if (!error) {
                
                NSArray *permissions = [result objectForKey:@"data"];
                NSLog(@"%@", permissions);
                for (NSDictionary *dict in permissions) {
                    
                    if ([[dict objectForKey:@"permission"] isEqualToString:permission]) {
                        
                        if ([[dict objectForKey:@"status"] isEqualToString:@"granted"]) {
                            
                            hasPermission = YES;
                        }
                    }
                }
            }
            
            if (hasPermission) {
                
                (sBlock) ? sBlock() : sBlock;
                
            } else {
                
                (fBlock) ? fBlock() : fBlock;
            }
        }];
        
    } else {
        
        (fBlock) ? fBlock() : fBlock;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
        {
//            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];

            if ([FBSDKAccessToken currentAccessToken])
            {
                [self checkForPermission:@"user_friends" granted:^(void){
                    [self showFacebookFriends];
                    
                } denied:^(void){
                    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
                    [loginManager logInWithReadPermissions:@[@"user_friends"] fromViewController:self handler:^(FBSDKLoginManagerLoginResult *result, NSError *error)
                     {
                         if (result.isCancelled || [result.declinedPermissions containsObject:@"user_friends"])
                         {
                             [self showAlertView:@"" withMessage:NSLocalizedString(@"no friends on matlistan", nil)];
                         }
                         else
                         {
                             [self showFacebookFriends];
                         }
                     }];
                }];
            }
            else
            {
                FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
                [login logInWithReadPermissions:@[@"public_profile", @"user_friends"] fromViewController:self handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                    if (error || [result.declinedPermissions containsObject:@"user_friends"])
                    {
                        DLog(@"Process error");
                        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                        {
                            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"View":@"LinkedAccountsViewController"}];
                        }
                        [SVProgressHUD dismiss];
                    }
                    else if (result.isCancelled)
                    {
                        DLog(@"Cancelled");
                        [SVProgressHUD dismiss];
                    }
                    else
                    {
                        [self showFacebookFriends];
                    }
                }];
            }
        }
        else if (indexPath.row == 1)
        {
            [self showAddNewAccountAlert];
        }
    }
}

- (void) showFacebookFriends {
    NSDictionary *params = @{@"fields": @"id, name, picture"};
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/me/friends" parameters:params HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error)
     {
         [SVProgressHUD dismiss];
         // Handle the result
         if (!error)
         {
             if (result)
             {
                 NSArray *friends = [result objectForKey:@"data"];
                 if (friends && friends.count > 0)
                 {
                     [self performSegueWithIdentifier:@"ShowFriendsPicker" sender:friends];
                 }
                 else
                 {
                     [self showAlertView:@"" withMessage:NSLocalizedString(@"no friends on matlistan", nil)];
                 }
             }
             else
             {
                 [self showAlertView:@"" withMessage:NSLocalizedString(@"no friends on matlistan", nil)];
             }
         }
         else
         {
             if (error)
             {
                 if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                 {
                     [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"View":@"LinkedAccountsViewController", @"action":@"Login with Facebook"}];
                 }
             }
         }
     }];
}

#pragma mark -
#pragma mark - Memory warning methods
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - MGSwipeTableCellDelegate methods
- (BOOL) swipeTableCell:(LinkedAccountCellView*)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    selectedIndex = cell.indexPath;
    
    NSString *status = [self.arrLinkedAccounts objectAtIndex:cell.indexPath.row][@"status"];
    
    if ([status isEqualToString:@"Requested"] || [status isEqualToString:NSLocalizedString(@"Requested", nil)])
    {
        if (index == 0)
        {
            [self confirmRequest:selectedIndex.row];
        }
        else if (index == 1)
        {
            [self deleteAccount];
        }
    }
    else if ([status isEqualToString:@"Initiated"] || [status isEqualToString:NSLocalizedString(@"Initiated", nil)])
    {
        [self deleteAccount];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"Unlinking account", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@"OK", nil];
        alert.tag = 1021;
        [alert show];
    }
    return YES;
}

#pragma mark -
#pragma mark - MatlistanHTTPClient delegate methods

- (void)matlistanHTTPClient:(MatlistanHTTPClient *)client didRequestSuccessful:(id)response withType:(RequestType)requestType
{
//    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [SVProgressHUD dismiss];
    
    if (requestType == RequestGetLinkedAccounts)
    {
        NSDictionary *resDic = (NSDictionary *)response;
        
        self.arrLinkedAccounts = [resDic objectForKey:@"list"];
        
        if (self.arrLinkedAccounts == nil || self.arrLinkedAccounts.count == 0)
        {
//            [self showAlertView:NSLocalizedString(@"Error", nil) withMessage:NSLocalizedString(@"no accounts found", nil)];
        }
        [self.accountsTable reloadData];
    }
    else if (requestType == RequestLinkNewAccount)
    {
        DLog(@"%@", response);
        
        NSDictionary *resDic = (NSDictionary *)response;
        
        NSString *accountTitle = [resDic objectForKey:@"email"];
        
        if (accountTitle.length == 0)
        {
            accountTitle = [resDic objectForKey:@"name"];
        }
        
        if (accountTitle.length != 0)
        {
            NSString *msg = @"";
            if ([[NSLocale currentLocale].localeIdentifier isEqualToString:@"sv_US"])
            {
                msg = [NSString stringWithFormat:@"Länkningen har nu initierats. Den träder i kraft när %@\nhar bekräftat länkningen här i appen eller på www.matlistan.se.", accountTitle];
            }
            else
            {
                msg = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"linking requested", nil), accountTitle];
            }
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            alertView.tag = 1024;
            [alertView show];
        }
        
        [self.client getLinkedAccounts];
    }
    else if (requestType == RequestDeleteLinkedAccount)
    {
        [self.client getLinkedAccounts];
    }
    
}

- (void)matlistanHTTPClient:(MatlistanHTTPClient*)client didFailWithError:(NSError*)error
{   
    NSData *errData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
    if (errData) {
        NSString *str = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];

        NSError *jsonError;
        NSDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:errData options:NSJSONReadingMutableContainers error:&jsonError];
        
        if (jsonError == nil)
        {
            str = [responseJson objectForKey:@"message"];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            alertView.tag = 1024;
            [alertView show];

            
        }
        
        //[self showAlertView:NSLocalizedString(@"Error", nil) withMessage:NSLocalizedString(@"No internet",nil)];
        
        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
        {
            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": str ? str : @"NULL", @"Screen":@"LinkedAccountsViewController"}];
        }
    }
    [SVProgressHUD dismiss];
}

#pragma mark -
#pragma mark - Private Methods
- (void)showAlertView:(NSString *)title withMessage:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showAddNewAccountAlert
{
    UIAlertView *linkEmailAlert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"add email to link", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@"OK", nil];
    linkEmailAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    linkEmailAlert.tag = 1022;
    
    UITextField *emailTextField = [linkEmailAlert textFieldAtIndex:0];
    emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    emailTextField.tag = 101;
    
    [linkEmailAlert show];
}

- (void)confirmRequest:(NSInteger)indexRow
{
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];

    
    NSDictionary *dictObject = [self.arrLinkedAccounts objectAtIndex:indexRow];
    
    NSString *email = dictObject[@"email"];
    NSString *fbId = dictObject[@"fbId"];
    NSString *googleId = dictObject[@"googleId"];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (email.length > 0)
    {
        parameters[@"email"] = email;
    }
    else if (fbId.length > 0)
    {
        parameters[@"fbId"] = fbId;
    }
    else if (googleId.length > 0)
    {
        parameters[@"googleId"] = googleId;
    }

    DLog(@"link account parameters : %@", parameters);
    
    [[MatlistanHTTPClient sharedMatlistanHTTPClient] POST:@"/Me/UserLinks" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject)
     {
         DLog(@"getting linked accounts");
         [client getLinkedAccounts];
         
     } failure:^(NSURLSessionDataTask *task, NSError *error)
     {
         DLog(@"Fail to link account");
         [self matlistanHTTPClient:[MatlistanHTTPClient sharedMatlistanHTTPClient] didFailWithError:error];
     }];
}

- (void)deleteAccount
{
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];

    
    NSDictionary *dictObject = [self.arrLinkedAccounts objectAtIndex:selectedIndex.row];
    
    client.delegate = self;
    [client deleteAccount:[[dictObject objectForKey:@"id"] intValue]];
}

- (void)linkNewAccount:(NSString *)email fbId:(NSString *)fbId
{
    
    if(!client.isLoggedIn){
        [self showAlertView:NSLocalizedString(@"Error", nil) withMessage:NSLocalizedString(@"No internet",nil)];
        return;
    }
    client.delegate = self;
    
    if (email.length != 0 || fbId.length != 0)
    {
//        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];

        [client linkAccount:email withFbId:fbId];
    }
    else
    {
        [self showAlertView:@"" withMessage:NSLocalizedString(@"enter valid info", nil)];
    }
}

#pragma mark -
#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1021)
    {
        if (buttonIndex == 1)
        {
            [self deleteAccount];
        }
    }
    else if (alertView.tag == 1022)
    {
        if (buttonIndex == 1)
        {
            NSString *email = [[alertView textFieldAtIndex:0] text];
            
            if (email.length == 0)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"enter valid info", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                alertView.tag = 1023;
                [alertView show];
            }
            else
            {
                [self linkNewAccount:email fbId:@""];
            }
        }
    }
    else if (alertView.tag == 1023)
    {
        [self showAddNewAccountAlert];
    }
}

#pragma mark -
#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowFriendsPicker"])
    {
        FriendsViewController *controller = (FriendsViewController *)segue.destinationViewController;
        controller.arrFBFriends = (NSArray *)sender;
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing LinkedAccountsViewController");
}

@end
