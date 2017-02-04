//
//  SearchStoresViewController.m
//  MatListan
//
//  Created by Yan Zhang on 17/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "SearchStoresViewController.h"
#import "Store+Extra.h"
#import "MatlistanHTTPClient.h"
#import "ItemsViewController.h"
#import "Mixpanel.h"

#define SEARCH_STORES_ROW_HEIGHT 77.0

@interface SearchStoresViewController (){

    NSMutableArray *searchResults;
    NSArray *stores;
    CLLocationManager *locationManager;
    float latitude;
    float longitude;
}
@end

@implementation SearchStoresViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    searchResults = [[NSMutableArray alloc]init];
    
    //the last cell won't be cut off and the top cell is not too far from the textfield
    //UIEdgeInsets insets = UIEdgeInsetsMake( 5.0 - ROW_HEIGHT , 0, self.navigationController.navigationBar.frame.size.height*2, 0);
    //UIEdgeInsets insets = UIEdgeInsetsMake( 5.0 - ROW_HEIGHT , 0, /*self.navigationController.navigationBar.frame.size.height*6.2*/ 0, 0);
    //self.tableview.contentInset = insets; //something like margin for content;
    //self.tableview.scrollIndicatorInsets = insets; // and for scroll indicator (scroll bar)
    self.textfieldSearch.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
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
    [self retrieveLocation];
    //latitude = locationManager.location.coordinate.latitude;
    //longitude = locationManager.location.coordinate.longitude;
    
    //[self searchStoresFromServer:@""];
    
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
        [self.bannerView removeConstraints:self.bannerView.constraints];
        [self.bannerView removeFromSuperview];
        
        [Utility updateConstraint:self.view toView:self.tableview withConstant:0];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return stores.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableview dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    SearchedStore *store = nil;
    
    store = [stores objectAtIndex:indexPath.row];
    
    
    UILabel *labelName = (UILabel*)[cell viewWithTag:1];
    labelName.text = store.name;
    UILabel *labelAddress = (UILabel*)[cell viewWithTag:2];
    labelAddress.text = store.address;
    
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(IS_IPHONE)
    {
        return SEARCH_STORES_ROW_HEIGHT;
    }
    else
    {
        return 90;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchedStore *selectedStore = nil;
    
    [DataStore instance].sortingOrder = STORE;
    
    selectedStore = stores[indexPath.row];
    
    if ([Store getStoreByID:selectedStore.searchedStoreID] == nil)
    {
        [Store insertSearchedStore:selectedStore];
    }
    
    DLog(@"store index %ld, store name %@" , indexPath.row,selectedStore.name);
    
    [DataStore instance].sortByStoreID = selectedStore.searchedStoreID;
    [DataStore instance].currentList.sortByStoreId= selectedStore.searchedStoreID;
    
  
    
    UIApplication *app = [UIApplication sharedApplication];
    NSString *path = [NSString stringWithFormat:@"%@://?**%@", [Utility getAppUrlScheme],selectedStore.searchedStoreID];
    NSURL *ourURL = [NSURL URLWithString:path];
    [app openURL:ourURL];
    
    for (UIViewController *vc in self.navigationController.viewControllers)
    {
        if(self.is_comming_from_items)
        {
            if ([vc isKindOfClass:[ItemsViewController class]])
            {
                 [Item_list changeList:[DataStore instance].currentList byNewOrder:STORE andStoreID:selectedStore.searchedStoreID];  //update database
                
                [self.navigationController popToViewController:vc animated:YES];
                break;
            }
        }
        else
        {
            if ([vc isKindOfClass:[ShoppingModeTableViewController class]])
            {
                (theAppDelegate).storeDict = @{@"address": selectedStore.address,
                                               @"city": selectedStore.city,
                                               @"distance": selectedStore.distance,
                                               @"id": selectedStore.searchedStoreID,
                                               @"isFavorite": selectedStore.isFavorite,
                                               @"itemsSortedPercent": selectedStore.itemsSortedPercent,
                                               @"name": selectedStore.name,
                                               @"postalAddress": selectedStore.postalAddress,
                                               @"postalCode": selectedStore.postalCode,
                                               @"title": selectedStore.title,
                                               };
                
                [self.navigationController popToViewController:vc animated:YES];
                break;
            }
            
        }
    }
    
}

#pragma mark - search stores

-(void)searchStoresFromServer:(NSString*)query{
    [SearchedStore deleteAllItems];
    MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    NSDictionary *parameters = @{@"query": query,
                                 @"lat": [NSNumber numberWithFloat:latitude],
                                 @"long":[NSNumber numberWithFloat:longitude]
                                 };
    
    [client GET:@"StoreSearch" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [SearchedStore insertSearchedStores:responseObject];
        stores = [SearchedStore MR_importFromArray:responseObject];

        [self.tableview reloadData];
        DLog(@"Get stores from server %@",responseObject);
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to search stores");
    }];
}

-(void)retrieveLocation{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [locationManager requestWhenInUseAuthorization];
    }
    [locationManager startUpdatingLocation];
}

- (IBAction)onClickSearch:(id)sender {
    [self search];
}

- (IBAction)onEditingEnd:(id)sender {
    [self search];
}

- (IBAction)textFieldValueChanged:(id)sender {
    if (![Utility isStringEmpty:self.textfieldSearch.text]) {
        [self searchStoresFromServer:self.textfieldSearch.text];
    }
}

-(void)search{
    if (![Utility isStringEmpty:self.textfieldSearch.text]) {
        [self.textfieldSearch resignFirstResponder];
        [self searchStoresFromServer:self.textfieldSearch.text];
    }
}

#pragma mark - HideKeyboard

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textFieldShouldClear:(UITextField *)textField{
    [self searchStoresFromServer:@""];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [self.textfieldSearch resignFirstResponder];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    latitude = location.coordinate.latitude;
    longitude = location.coordinate.longitude;
    [self searchStoresFromServer:@""];
    [locationManager stopUpdatingLocation];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
    [locationManager stopUpdatingLocation];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self searchStoresFromServer:@""];
    
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": @"Failed to get user location", @"Screen":@"Search Stores"}];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
    self.tableview.contentInset = contentInsets;
    self.tableview.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.tableview.contentInset = UIEdgeInsetsZero;
    self.tableview.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    CLS_LOG(@"Showing SearchStoresViewController");
}

@end
