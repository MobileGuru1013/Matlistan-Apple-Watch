//
//  ReceptViewController.m
//  MatListan
//  This is to show latest recipe
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ReceptViewController.h"

@interface ReceptViewController ()

@end

@implementation ReceptViewController

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
    // Do any additional setup after loading the view.
    
    SWRevealViewController *revealController = self.revealViewController;
    
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }

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
#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [view setAlpha:1];
    [UIView commitAnimations];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [view setAlpha:0];
    [UIView commitAnimations];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing ReceptViewController");
}

@end
