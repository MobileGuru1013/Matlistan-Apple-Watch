//
//  HelpViewController.m
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//
#import "HelpViewController.h"
#import "Appirater.h"
#import "Mixpanel.h"
#import "UIViewController+MJPopupViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Dimple-2-12-2015
    [self.buttonQuestion setTitle:NSLocalizedString(@"FAQ", nil) forState: UIControlStateNormal];
    [self.buttonContactUs setTitle:NSLocalizedString(@"Contact Us", nil) forState: UIControlStateNormal];
    [self.buttonRate setTitle:NSLocalizedString(@"Rate this app", nil) forState: UIControlStateNormal];
    [self.btn_Verionhistory setTitle:NSLocalizedString(@"Version history", nil) forState: UIControlStateNormal];

    
    SWRevealViewController *revealController = self.revealViewController;
    revealController=[[SWRevealViewController alloc]init];
    revealController = [self revealViewController];
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    revealController.delegate=self;
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    // Do any additional setup after loading the view.
    self.navigationItem.title = NSLocalizedString(@"Help", nil);
    
    /*Developer : Dimple
     Date : 28-9-15
     Description : Sliding menu swipe gesture management.*/
    
   // SWRevealViewController *revealController = self.revealViewController;
   // [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
    
    [Appirater setCustomAlertTitle:NSLocalizedString(@"Rate App Title", nil)];
    [Appirater setCustomAlertMessage:NSLocalizedString(@"Rate App message", nil)];
    [Appirater setCustomAlertCancelButtonTitle:NSLocalizedString(@"No, Thanks", nil)];
    [Appirater setCustomAlertRateButtonTitle:NSLocalizedString(@"Rate It Now", nil)];
    [Appirater setCustomAlertRateLaterButtonTitle:NSLocalizedString(@"Remind Me Later", nil)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPremiumAccountPurchased object:nil];
}

/**
 Remove ads if user has purchased premium
 @ModifiedDate: October 7 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)removeAds
{
    if (self.bannerView)
    {
        [self.bannerView removeFromSuperview];
    }
}

- (IBAction)showMenu
{
    //[self.frostedViewController presentMenuViewController];
    [self.revealViewController revealToggle:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickQuestion:(id)sender
{
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Help: FAQ clicked"];
    }
    [self surfToURL:@"http://www.matlistan.se/Help/Faq"];
}

- (IBAction)onClickContactUs:(id)sender
{
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Help: Contact us clicked"];
    }
    [self surfToURL:@"mailto:info@matlistan.se"];
}

- (IBAction)onClickFacebook:(id)sender
{
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Help: Facebook clicked"];
    }
    [self surfToURL:@"http://www.facebook.com/matlistan"];
}

- (IBAction)onClickRate:(id)sender
{
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Help: Rate clicked"];
    }
    //TO DO: add rating link after this app has been released
    [Appirater rateApp];
}

- (void)surfToURL:(NSString*)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication]openURL:url];
}

#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [view setAlpha:1];
    [UIView commitAnimations];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [view setAlpha:0];
    [UIView commitAnimations];
}
-(IBAction)onClickVersionHistory:(id)sender
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPopup) name:@"dismissMJPopUp" object: nil];
   Version_VC *Version=[[Version_VC alloc]initWithNibName:@"Version_VC" bundle:nil];
    [self presentPopupViewController:Version animationType:MJPopupViewAnimationFade];
}
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}
-(void)dismissPopup
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing HelpViewController");
}

@end
