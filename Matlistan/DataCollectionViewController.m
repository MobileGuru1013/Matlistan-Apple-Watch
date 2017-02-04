//
//  DataCollectionViewController.m
//  Matlistan
//
//  Created by Yousuf on 10/20/15.
//  Copyright © 2015 Flame Soft. All rights reserved.
//

#import "DataCollectionViewController.h"

#import "AppDelegate.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "Mixpanel.h"

@interface DataCollectionViewController ()
{
    NSArray *arrDataCollectionsTitle;
    NSArray *arrDataCollectionsSummary;
}
@end

@implementation DataCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Data Collection", nil);
    
    arrDataCollectionsTitle = [NSArray arrayWithObjects:NSLocalizedString(@"pref_automatic_bugreports_title", nil), NSLocalizedString(@"pref_ga_enable_title", nil), nil];
    arrDataCollectionsSummary = [NSArray arrayWithObjects:NSLocalizedString(@"pref_automatic_bugreports_summary", nil), NSLocalizedString(@"pref_ga_enable_summary", nil), nil];
}

#pragma mark -
#pragma mark - UITableView delegate methods

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strDescription = [NSString stringWithFormat:@"%@",[arrDataCollectionsSummary objectAtIndex:indexPath.row]];
    
    CGSize sizeForDescriptionLabel = [Utility getSizeForText:strDescription maxWidth:tableView.frame.size.width-20 font:@"helvetica" fontSize:14.0];
    
    return sizeForDescriptionLabel.height+70;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return arrDataCollectionsTitle.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * reuseIdentifier = @"DataCollectionTypeCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

    UILabel *labelTitle = (UILabel*)[cell viewWithTag:1];
    UILabel *labelDetail = (UILabel*)[cell viewWithTag:2];
    
    labelTitle.text = arrDataCollectionsTitle[indexPath.row];
    labelDetail.text = arrDataCollectionsSummary[indexPath.row];
    
    for (NSLayoutConstraint *height in labelDetail.constraints)
    {
        if (height.firstAttribute == NSLayoutAttributeHeight)
        {
            NSString *strDescription = [NSString stringWithFormat:@"%@",[arrDataCollectionsSummary objectAtIndex:indexPath.row]];
            
            CGSize sizeForDescriptionLabel = [Utility getSizeForText:strDescription maxWidth:tableView.frame.size.width-20 font:@"helvetica" fontSize:14.0];
            
            height.constant = sizeForDescriptionLabel.height;
        }
    }
    
    UISwitch *onOff = (UISwitch*)[cell viewWithTag:3];
    if (indexPath.row == 0)
    {
        [onOff addTarget:self action:@selector(onSendReportSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        [onOff setOn:[Utility getDefaultBoolAtKey:@"sendBugReport"]];
    }
    else if (indexPath.row == 1)
    {
        [onOff addTarget:self action:@selector(onAnalyticsSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        [onOff setOn:[Utility getDefaultBoolAtKey:@"sendAnalyticsReport"]];
    }
    [onOff setHidden:NO];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - 
#pragma mark - Click Methods

- (void)onSendReportSwitchPressed:(id)sender
{
    UISwitch *onOff = (UISwitch*)sender;
    [Utility saveInDefaultsWithBool:onOff.isOn andKey:@"sendBugReport"];
    if (onOff.isOn)
    {
        [Crashlytics startWithAPIKey:@"21794aa12eeef1dfbe87cffba19decc2219a1b16"];
         [[Crashlytics sharedInstance] setUserIdentifier:[MatlistanHTTPClient sharedMatlistanHTTPClient].accountId];

    }
    else
    {
        
    }
}

- (void)onAnalyticsSwitchPressed:(id)sender
{
    UISwitch *onOff = (UISwitch*)sender;
    [Utility saveInDefaultsWithBool:onOff.isOn andKey:@"sendAnalyticsReport"];
    
    if (onOff.isOn)
    {
        [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        
        [mixpanel unregisterSuperProperty:@"$ignore"];
        
        if (mixpanel)
        {
            [mixpanel identify:[MatlistanHTTPClient sharedMatlistanHTTPClient].accountId];
        }
    }
    else
    {
        [[Mixpanel sharedInstance] registerSuperProperties:@{@"$ignore":@"Yes"}];
    }
}

#pragma mark -
#pragma mark - Memory warning methods
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing DataCollectionViewController");
}

@end
