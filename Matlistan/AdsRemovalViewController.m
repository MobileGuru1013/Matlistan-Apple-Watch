//
//  AdsRemovalViewController.m
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "AdsRemovalViewController.h"
#import <StoreKit/StoreKit.h>
#import "MatlistanHTTPClient.h"
#import "MatlistanIAPHelper.h"
#import "AppDelegate.h"

#define PRODUCT_IDENTIFIER          @"com.consumiq.matlistan.premium_subscription.yearly"

@interface AdsRemovalViewController () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    GADBannerView *bannerView;
    
    NSArray *productIDs;
    
    SKProduct *productToBuy;
    
    BOOL transactionInProgress;
}
@end

@implementation AdsRemovalViewController

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
    revealController=[[SWRevealViewController alloc]init];
    revealController = [self revealViewController];
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    revealController.delegate=self;
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    self.title = NSLocalizedString(@"Remove Ads", nil);
    
    // IOS-10: get rid of ads /Yousuf 12-10-2015
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        bannerView = [[GADBannerView alloc] initWithAdSize:GADAdSizeFromCGSize(CGSizeMake(self.view.frame.size.width, 50))];
        bannerView.frame = CGRectMake(0, self.view.frame.size.height - 50, bannerView.frame.size.width, bannerView.frame.size.height);
        [self.view addSubview:bannerView];
        [self.view bringSubviewToFront:bannerView];
        
        bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        bannerView.delegate = self;
        bannerView.rootViewController = self;
        [bannerView loadRequest:[GADRequest request]];
    }
    
    productIDs = [[NSMutableArray alloc] initWithObjects:PRODUCT_IDENTIFIER, nil];
    
    transactionInProgress = NO;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    self.lblTitle.text = NSLocalizedString(@"remove ads title", nil);
    self.lblDescription.text = NSLocalizedString(@"remove ads description", nil);
    [self.btnBuySubcription setTitle:NSLocalizedString(@"account_upgrade_button", nil) forState:UIControlStateNormal];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPremiumAccountPurchased object:nil];
}

/**
 Remove ads if user has purchased premium
 @ModifiedDate: October 12 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)removeAds
{
    if (bannerView)
    {
        [bannerView removeFromSuperview];
    }
}

- (void)dealloc
{
    DLog(@"dealloc called");
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view{
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [bannerView setAlpha:1];
    [UIView commitAnimations];
    
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [bannerView setAlpha:0];
    [UIView commitAnimations];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    bannerView.frame = CGRectMake(0, self.view.frame.size.height-50, self.view.frame.size.width, 50);
}

- (IBAction)btnBuySubscription_Pressed:(UIButton *)sender
{
//    if([[Utility getAppUrlScheme] isEqualToString:@"matlistan"]) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
//                                                        message:NSLocalizedString(@"ads_removal_unavailable",nil)
//                                                       delegate:self
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//        return;
//    }
    if (!transactionInProgress)
    {
        transactionInProgress = YES;
        
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
        
        [self requestProductInfo];
    }
    else
    {
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
    }
}

#pragma mark -
#pragma mark -

- (void)requestProductInfo
{
    if ([SKPaymentQueue canMakePayments])
    {
        SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[[NSSet alloc] initWithArray:productIDs]];
        productRequest.delegate = self;
        [productRequest start];
    }
    else
    {
        transactionInProgress = NO;
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Erro", nil) message:@"Cannot perform In App Purchases." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    if (response.products.count != 0)
    {
        productToBuy = [response.products objectAtIndex:0];
        
        SKPayment *payment = [SKPayment paymentWithProduct:productToBuy];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        transactionInProgress = YES;
    }
    else
    {
        DLog(@"There are no products");
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                transactionInProgress = YES;
                [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
                break;
            case SKPaymentTransactionStatePurchased:
                [self acknowledgeSubscriptioToServer:transaction];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [[NSNotificationCenter defaultCenter] postNotificationName:kPremiumAccountPurchased object:nil userInfo:nil];
                transactionInProgress = NO;
                break;
            case SKPaymentTransactionStateFailed:
                [SVProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:transaction.error.localizedFailureReason message:transaction.error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
//                [SVProgressHUD dismissWithError:transaction.error.localizedDescription];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                transactionInProgress = NO;
                break;
            default:
                break;
        }
    }
}

/**
 API to send in-app subscription data
 @ModifiedDate: October 13, 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)acknowledgeSubscriptioToServer:(SKPaymentTransaction *)trasaction
{
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    NSData *receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if (!receipt)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Fail to get receipt data.", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        [SVProgressHUD dismiss];
    }
    else
    {
        parameters[@"receipt"] = [receipt base64EncodedStringWithOptions:0];
        
        DLog(@"parameters : %@", parameters);
        MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
        [client POST:@"/Purchases/ios" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject)
        {
            [SVProgressHUD dismiss];
            DLog(@"Validating purchase receipt");
            [client getMe];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Fail to verify receipt");
            NSData *errData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
            NSString *str = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
            DLog(@"des = %@",str);
            
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:str delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            
            [SVProgressHUD dismiss];
        }];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing AdsRemovalViewController");
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}
@end
