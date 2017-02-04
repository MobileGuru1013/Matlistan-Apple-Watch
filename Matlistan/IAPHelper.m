//
//  IAPHelper.m
//  In App Rage
//

// 1
#import "IAPHelper.h"
#import <StoreKit/StoreKit.h>
#import "Mixpanel.h"

NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";

// 2
@interface IAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

// 3
@implementation IAPHelper {
    /* an instance variable to store the SKProductsRequest you will issue to retrieve a list of products, while it is active.
    You keep a reference to the request so 
     a) you can know if you have one active already,
     b) you’ll be guaranteed that it’s in memory while it’s active.
     */
    SKProductsRequest * _productsRequest;
    /*
     keep track of the completion handler for the outstanding products request, the list of product identifiers passed in, and the list of product identifers that have been previously purchased.
     */
    RequestProductsCompletionHandler _completionHandler;
    
    NSSet * _productIdentifiers;    //the list of product identifiers
    NSMutableSet * _purchasedProductIdentifiers;    // the list of product identifers that have been previously purchased
}
/*
 an initializer that takes a list of product identifiers
 */
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
                DLog(@"Previously purchased: %@", productIdentifier);
            } else {
                DLog(@"Not purchased: %@", productIdentifier);
            }
        }
        
        // Add self as transaction observer. Apple will tell you when somebody purchased something
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
    }
    return self;
    
}
/*
 *retrieve information about the products from iTunes Connect
 */

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {
    
    
    // This first squirrels a copy of the completion handler block inside the instance variable so it can notify the caller when the product request asynchronously completes.
    _completionHandler = [completionHandler copy];
    
    //It creates a new instance of SKProductsRequest, which is the Apple-written class that contains the code to pull the info from iTunes Connect. It’s very easy to use – you just give it a delegate (that conforms to the SKProductsRequestDelegate protocol) and then call start to get things running.
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    
    //IAPHelper will receive a callback when the products list completes (productsRequest:didReceiveResponse) or fails (request:didFailWithErorr).
    _productsRequest.delegate = self;
    [_productsRequest start];
    
}
// determine if a product has been purchased
- (BOOL)productPurchased:(NSString *)productIdentifier {
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

//start buying a product
- (void)buyProduct:(SKProduct *)product {
    
    DLog(@"Buying %@...", product.productIdentifier);
    
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    DLog(@"Loaded list of products...");
    _productsRequest = nil;
    
    NSArray * skProducts = response.products;
    for (SKProduct * skProduct in skProducts) {
        DLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    
    _completionHandler(YES, skProducts);
    _completionHandler = nil;
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    DLog(@"Failed to load list of products.");
    _productsRequest = nil;
    
    _completionHandler(NO, nil);
    _completionHandler = nil;
    
    if (error)
    {
        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
        {
            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription, @"action":[NSString stringWithFormat:@"%s", __FUNCTION__]}];
        }
    }
    
}

#pragma mark SKPaymentTransactionOBserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
                break;
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    DLog(@"completeTransaction...");
    
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

//if the user has the same app on multiple devices (or deletes it and reinstalls it) and wants to get access to their prior purchases
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    DLog(@"restoreTransaction...");
    
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    DLog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        DLog(@"Transaction error: %@", transaction.error.localizedDescription);
        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
        {
            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": transaction.error.localizedDescription, @"action":[NSString stringWithFormat:@"%s", __FUNCTION__]}];
        }
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

/*
 When a product is purchased, this method adds the product identifier to the list of purchaed product identifiers, marks it as purchased in NSUserDefaults, and sends a notification so others can be aware of the purchase.
 */
- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedNotification object:productIdentifier userInfo:nil];
    
}

- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end