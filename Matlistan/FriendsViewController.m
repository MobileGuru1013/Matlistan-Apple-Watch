//
//  LinkAccountViewController.m
//  Matlistan
//
//  Created by Muhammad Yousuf Saif on 9/2/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "FriendsViewController.h"

//#import "MBProgressHUD.h"
#import "MatlistanHTTPClient.h"
#import "UIImageView+AFNetworking.h"
#import "Mixpanel.h"
#import <Google/SignIn.h>

@interface FriendsViewController ()<UITableViewDelegate, UITableViewDataSource>

@end

@implementation FriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Choose a friend", nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing FriendsViewController");
    self.title = NSLocalizedString(@"Choose a friend", nil);
}

#pragma mark -
#pragma mark - UITableView delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arrFBFriends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * reuseIdentifier = @"FriendsCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    NSString *title = [self.arrFBFriends objectAtIndex:indexPath.row][@"name"];
    UILabel *label = (UILabel *)[cell viewWithTag:102];
    label.text = title;
    
    NSString *url = [self.arrFBFriends objectAtIndex:indexPath.row][@"picture"][@"data"][@"url"];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:101];
    [imageView setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

    
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];

//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"fbId"] = [self.arrFBFriends objectAtIndex:indexPath.row][@"id"];
    if([Utility getObjectFromDefaults:@"GoogleIdTokenRetrieved"]) {
        parameters[@"googleId"] = [Utility getObjectFromDefaults:@"GoogleIdTokenRetrieved"];
    }
    
    [[MatlistanHTTPClient sharedMatlistanHTTPClient] POST:@"/Me/UserLinks" parameters:parameters success:^(NSURLSessionDataTask *task, id response)
     {
//         [MBProgressHUD hideHUDForView:self.view animated:YES];
         [SVProgressHUD dismiss];
         
         DLog(@"%@", response);
         
         NSDictionary *resDic = (NSDictionary *)response;
         
         NSString *accountTitle = [resDic objectForKey:@"email"];
         
         if (accountTitle.length == 0)
         {
             accountTitle = [resDic objectForKey:@"name"];
         }
         
         if (accountTitle.length != 0)
         {
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"linking requested", nil), accountTitle] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
             alertView.tag = 1024;
             [alertView show];
         }
         
     } failure:^(NSURLSessionDataTask *task, NSError *error)
     {
         [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
         
//         [MBProgressHUD hideHUDForView:self.view animated:YES];
         [SVProgressHUD dismiss];
         
         NSData *errData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
         NSString *msg = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
         
         NSError *jsonError;
         NSDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:errData options:NSJSONReadingMutableContainers error:&jsonError];
         
         if (jsonError == nil)
         {
             msg = [responseJson objectForKey:@"message"];
         }
         
         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
         [alertView show];
         if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
         {
             [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": msg ? msg : @"NULL", @"action":@"Link users with Facebook Id"}];
         }
     }];
}

#pragma mark -
#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1024)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark - Memory warning methods
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
