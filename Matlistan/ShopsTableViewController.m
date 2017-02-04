//
//  ShopsTableViewController.m
//  matlistan
//
//  Created by Yan Zhang on 16/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ShopsTableViewController.h"
#import "DataStore.h"
#import "Store+Extra.h"
#import "UIButton+Property.h"
#import "ItemsViewController.h"
#import "ShoppingListsTableViewController.h"
#import "SearchStoresViewController.h"
#import "MatlistanHTTPClient.h"
#import "Mixpanel.h"
#import "SortingSyncManager.h"


#define SECTION_HEADER_HEIGHT 40
#define SECTION_HEADER_IPAD_HEIGHT 60
#define SAVED_STORE 0
#define NEAREST_STORE 1
#define enableLocationService NSLocalizedString(@"Could not fetch your location", nil)
@interface ShopsTableViewController () {
    NSArray *allShops;
}

@end

@implementation ShopsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    [self.searchBar setPlaceholder:NSLocalizedString(@"Search for store (name/address/postal code)", nil)];
    
    if(IS_IPHONE)
    {
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        {
            self.edgesForExtendedLayout = UIRectEdgeNone;
            [self.navigationController.view setBackgroundColor:[UIColor whiteColor]];
        }
    }
//    searchResults = [[NSMutableArray alloc]init];

    
    self.navigationItem.title = NSLocalizedString(@"Select store", nil);
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(onClickSearchButton)];
    
    allShops = [Store getAllStores];
    
    if(allShops.count==0)
    {
        self.userHintLabel.hidden=NO;
        self.tableView.hidden=YES;
        
//        self.userHintLabel.text=NSLocalizedString(@"No_Store_History",nil);
        [self.userHintLabel sizeToFit];
    }
    else
    {
//        self.userHintLabel.text=@"";
        self.userHintLabel.hidden=YES;
       self.tableView.hidden=NO;
    }
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
//    self.tableView.hidden=YES;

}
-(void)setEnableLocalationServiceArr
{
    stores=[[NSMutableArray alloc]init];
    noLocaltionServiceSetArr=@[enableLocationService];
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    [self.tableView reloadData];

}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    (theAppDelegate).isShopsTableviewController=true;
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    [self retrieveLocation:nil];

    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(retrieveLocation:) name:@"retrieveLocation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setEnableLocalationServiceArr) name:@"setEnableLocalationServiceArr" object:nil];

    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }
    
}
-(void)showHintLabel
{
    if((allShops.count==0 && stores.count==0 && noLocaltionServiceSetArr.count==0))
    {
        self.userHintLabel.hidden=NO;
        self.tableView.hidden=YES;
        
        self.userHintLabel.text=NSLocalizedString(@"No_Store_History",nil);
        [self.userHintLabel sizeToFit];
    }
    else
    {
        if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied)
        {
            self.userHintLabel.text=@"";
            self.userHintLabel.hidden=YES;
        }
        else{
            self.userHintLabel.text=NSLocalizedString(@"No_Store_History",nil);
            [self.userHintLabel sizeToFit];
                    }
        self.tableView.hidden=NO;
    }
}
-(void)retrieveLocation:(NSNotification *)aNotification{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [locationManager requestWhenInUseAuthorization];
    }
    [locationManager startUpdatingLocation];
//    if(aNotification.userInfo !=nil)
//    {
//        if([[aNotification.userInfo valueForKey:@"key_retrieveLocation"] isEqualToString:@"1"])
//        {
//            [self searchStoresFromServer:@""];
//        }
//    }
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    latitude = location.coordinate.latitude;
    longitude = location.coordinate.longitude;
    [locationManager stopUpdatingLocation];
    locationManager=nil;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [Utility setLocationPermission:@"1"];
        noLocaltionServiceSetArr=[[NSArray alloc]init];
        [self searchStoresFromServer:@""];
        NSLog(@"Location access accepted");
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [Utility setLocationPermission:@"1"];
        NSLog(@"Location access accepted");
    }
    else if (status == kCLAuthorizationStatusDenied) {
        NSLog(@"Location access denied");
        noLocaltionServiceSetArr=@[enableLocationService];
        self.tableView.delegate=self;
        self.tableView.dataSource=self;
        [self.tableView reloadData];
        [self showHintLabel];
        
        if([CLLocationManager locationServicesEnabled])
        {
            if([[Utility getLocationPermission] isEqualToString:@"0"] || [Utility getLocationPermission]==nil)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                                message:@"To re-enable, please go to Settings and turn on Location Service for this app."
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:NSLocalizedString(@"Ok", nil),nil];
                [Utility setLocationPermission:@"1"];
                alert.tag=11;
                [alert show];
            }
        }

    }
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"didFailWithError: %@", error);
    [locationManager stopUpdatingLocation];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if([CLLocationManager locationServicesEnabled])
    {
        locationManager=nil;
    }
//    if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied)
//    {
//        noLocaltionServiceSetArr=[[NSArray alloc]init];
//          [self searchStoresFromServer:@""];
//    }
//    else
//    {
//        noLocaltionServiceSetArr=@[enableLocationService];
//        self.tableView.delegate=self;
//        self.tableView.dataSource=self;
//        [self.tableView reloadData];
//        [self showHintLabel];
//
//        if([[Utility getLocationPermission] isEqualToString:@"0"] || [Utility getLocationPermission]==nil)
//        {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
//                                                            message:@"To re-enable, please go to Settings and turn on Location Service for this app."
//                                                           delegate:self
//                                                  cancelButtonTitle:nil
//                                                  otherButtonTitles:NSLocalizedString(@"Ok", nil),nil];
//            alert.tag=11;
//            [alert show];
//        }
//    }
    

    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": @"Failed to get user location", @"Screen":@"Search Stores"}];
    }
}
#pragma mark - search stores

-(void)searchStoresFromServer:(NSString*)query{

    if((theAppDelegate).gotoSettingFromSearchShops)
    {
        (theAppDelegate).gotoSettingFromSearchShops=false;
        query=@"";
    }
    [SearchedStore deleteAllItems];
    MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    NSDictionary *parameters = @{@"query": query,
                                 @"lat": [NSNumber numberWithFloat:latitude],
                                 @"long":[NSNumber numberWithFloat:longitude]
                                 };
    
        NSLog(@"Location Services Enabled :%@",parameters);
        
            [client GET:@"StoreSearch" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                
                [SearchedStore insertSearchedStores:responseObject];
                
                stores = [SearchedStore MR_importFromArray:responseObject];
                
                if([self.searchBarController isActive])
                {
                    
                    self.searchBarController.searchResultsTableView.delegate=self;
                    self.searchBarController.searchResultsTableView.dataSource=self;
                    [self.searchBarController.searchResultsTableView reloadData];
                
                    if(stores.count==0)
                    {
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.001);
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        UITableView *temptbl = self.searchBarController.searchResultsTableView;
                        for( UIView *subview in temptbl.subviews ) {
                            if( [subview class] == [UILabel class] ) {
                                UILabel *lbl = (UILabel*)subview; // sv changed to subview.
                                lbl.text =NSLocalizedString(@"No search results found", nil) ;
                            }
                        }
                        });
                    }
                }
                else
                {
                    if(stores.count>0)
                    {
                        noLocaltionServiceSetArr=[[NSArray alloc]init];
                    }
                    else
                    {
                        noLocaltionServiceSetArr=@[enableLocationService];
                    }
                    [self.tableView reloadData];
                    
  
                }
                [self showHintLabel];
                DLog(@"Get stores from server %@",responseObject);
                
            }failure:^(NSURLSessionDataTask *task, NSError *error) {
                DLog(@"Fail to search stores");
                
            }];
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPremiumAccountPurchased object:nil];
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    (theAppDelegate).isShopsTableviewController=false;

    NSLog(@"viewDidDisappear  called ");
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
        
        [Utility updateConstraint:self.view toView:self.tableView withConstant:0];
    }
}

- (IBAction)onClickSearchButton:(id)sender
{
    if([[MatlistanHTTPClient sharedMatlistanHTTPClient] isLoggedIn]) {
        [self performSegueWithIdentifier:@"toSearchStores" sender:self];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"internet_connection_required",nil)
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)onClickAddButton:(id)sender {
    if([[MatlistanHTTPClient sharedMatlistanHTTPClient] isLoggedIn]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"add_store", nil) message:NSLocalizedString(@"add_store_message", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"internet_connection_required",nil)
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag==11)
    {
//        if (buttonIndex == 1)
//        {
            [Utility setLocationPermission:@"1"];
           (theAppDelegate).gotoSettingFromSearchShops=true;
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
//        }
    }
    else
    {
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:NSLocalizedString(@"Ok", nil)]) {
            NSString *shopName = [alertView textFieldAtIndex:0].text;
            if(![shopName isEqualToString:@""]) {
                MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
                NSDictionary *parameters = @{@"name": shopName};
                
                [client POST:@"Stores" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                    Store *selectedStore = [Store createStoreWithResponse:responseObject forContext:[NSManagedObjectContext MR_defaultContext]];
                    //////////
                    [DataStore instance].sortingOrder = STORE;
                    [DataStore instance].sortByStoreID = selectedStore.storeID;
                    [DataStore instance].currentList.sortByStoreId= selectedStore.storeID;
                    
                    [Item_list changeList:[DataStore instance].currentList byNewOrder:STORE andStoreID:selectedStore.storeID];
                    
                    UIApplication *app = [UIApplication sharedApplication];
                    NSString *path = [NSString stringWithFormat:@"%@://?**%@", [Utility getAppUrlScheme],selectedStore.storeID];
                    NSURL *ourURL = [NSURL URLWithString:path];
                    [app openURL:ourURL];
                    
                    
                    for (UIViewController *vc in self.navigationController.viewControllers)
                    {
                        if(self.is_comming_from_items)
                        {
                            if ([vc isKindOfClass:[ItemsViewController class]])
                            {
                                [self.navigationController popToViewController:vc animated:YES];
                                break;
                            }
                        }
                        else
                        {
                            if ([vc isKindOfClass:[ShoppingModeTableViewController class]])
                            {
                                NSMutableDictionary *dict = [NSMutableDictionary new];
                                if(selectedStore.address) [dict setObject:selectedStore.address forKey:@"address"];
                                if(selectedStore.city) [dict setObject:selectedStore.city forKey:@"city"];
                                if(selectedStore.distance) [dict setObject:selectedStore.distance forKey:@"distance"];
                                if(selectedStore.storeID) [dict setObject:selectedStore.storeID forKey:@"id"];
                                if(selectedStore.isFavorite) [dict setObject:selectedStore.isFavorite forKey:@"isFavorite"];
                                if(selectedStore.itemsSortedPercent) [dict setObject:selectedStore.itemsSortedPercent forKey:@"itemsSortedPercent"];
                                if(selectedStore.name) [dict setObject:selectedStore.name forKey:@"name"];
                                if(selectedStore.postalAddress) [dict setObject:selectedStore.postalAddress forKey:@"postalAddress"];
                                if(selectedStore.postalCode) [dict setObject:selectedStore.postalCode forKey:@"postalCode"];
                                if(selectedStore.title) [dict setObject:selectedStore.title forKey:@"title"];
                                (theAppDelegate).storeDict = dict;
                                /*
                                (theAppDelegate).storeDict = @{@"address": selectedStore.address,
                                                               @"city": selectedStore.city,
                                                               @"distance": selectedStore.distance,
                                                               @"id": selectedStore.storeID,
                                                               @"isFavorite": selectedStore.isFavorite,
                                                               @"itemsSortedPercent": selectedStore.itemsSortedPercent,
                                                               @"name": selectedStore.name,
                                                               @"postalAddress": selectedStore.postalAddress,
                                                               @"postalCode": selectedStore.postalCode,
                                                               @"title": selectedStore.title,
                                                               };
                                 */
                                 
                                
                                
                                [self.navigationController popToViewController:vc animated:YES];
                                break;
                            }
                            
                        }
                    }
                    
                    [[SyncManager sharedManager] forceSync];
                    
                }failure:^(NSURLSessionDataTask *task, NSError *error) {
                    DLog(@"Fail to search stores");
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:NSLocalizedString(@"internet_connection_required",nil)
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                }];
            }
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view
-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.searchBarController.active) {
    return 0;
    }
    else{
             if((allShops.count>0 && stores.count>0)  || (allShops.count>0 && noLocaltionServiceSetArr.count>0))
            {
                if(section==0)
                {
                    return 0;
                }
                else
                {
                    if(IS_IPHONE)
                    {
                        return SECTION_HEADER_HEIGHT;
                    }
                    else
                    {
                        return SECTION_HEADER_IPAD_HEIGHT;
                    }
                }
            }
            else
            {
                if(allShops.count>0)
                {
                    if(section==0)
                    {
                        return 0;
                    }
                }
                else if(stores.count>0 || noLocaltionServiceSetArr.count>0)
                {
                    if(section==0)
                    {
                        if(IS_IPHONE)
                        {
                            return SECTION_HEADER_HEIGHT;
                        }
                        else
                        {
                            return SECTION_HEADER_IPAD_HEIGHT;
                        }
                    }
                }
               
            }
            
            return 0;
        }
    }

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.searchBarController.active) {
     return nil;
    }
    else
    {
        int font_size1=17,title_lbl_y=0,header_vw_y=5.0;
        if(IS_IPHONE)
        {
            font_size1=17;
            title_lbl_y=0;
            header_vw_y=5.0;
        }
        else
        {
            font_size1=25;
            title_lbl_y=10;
            header_vw_y=10.0;
        }
    
            sectionNames = @[NSLocalizedString(@"", nil), NSLocalizedString(@"Nearest Stores", nil)];
            
            NSString *sectionTitle = sectionNames[(NSUInteger) section];
            
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40.0f)];
            [view setBackgroundColor:[Utility getGreenColor]];
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, title_lbl_y, tableView.frame.size.width, 40.0f)];
            [titleLabel setTextAlignment:NSTextAlignmentCenter];
            [titleLabel setTextColor:[UIColor whiteColor]];
            titleLabel.font = [UIFont systemFontOfSize:font_size1];
            titleLabel.text = sectionTitle;
            [view addSubview:titleLabel];
    
            if((allShops.count>0 && stores.count>0)  || (allShops.count>0 && noLocaltionServiceSetArr.count>0))
            {
               if (section == 0)
               {
                    return nil;
               }
               else if (section == 1)
               {
                    if (stores.count > 0 || noLocaltionServiceSetArr.count>0) {
                        sectionTitle = sectionNames[(NSUInteger) section];
                        titleLabel.text = sectionTitle;
                        return view;
                    }else {
                        [view setFrame:CGRectMake(0.0f, 0.0f, 0, 0.0f)];
                        return view;
                    }
                }
            }
            else
            {
                if (allShops.count > 0)
                {
                    if (section == 0)
                    {
                        return nil;
                    }
                }
                else if (stores.count > 0 || noLocaltionServiceSetArr.count>0)
                {
                    if (section == 0)
                    {
                        sectionTitle = NSLocalizedString(@"Nearest Stores", nil);
                        titleLabel.text = sectionTitle;
                        return view;
                    }

                }
            }
    }
        return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (self.searchBarController.active) {
        return 1;
    }
    else
    {
         if((allShops!=nil && stores!=nil)  || (allShops!=nil && noLocaltionServiceSetArr!=nil))
        {
             if((allShops.count>0 && stores.count>0)  || (allShops.count>0 && noLocaltionServiceSetArr.count>0))
            {
                return 2;
            }
            else
            {
                return 1;
            }
        }
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (self.searchBarController.active) {
        return stores.count;
    }
    else
    {
         if((allShops.count>0 && stores.count>0))
        {
            if (section == 0)
            {
                return allShops.count;
            }
            else
            {
                return stores.count;
            }
        }
         else if((allShops.count>0 && noLocaltionServiceSetArr.count>0))
         {
             if (section == 0)
             {
                 return allShops.count;
             }
             else
             {
                 return noLocaltionServiceSetArr.count;
             }
         }
        else
        {
                if(allShops.count>0)
                {
                    if (section == 0)
                    {
                        return allShops.count;
                    }
                }
                else if(stores.count>0)
                {
                    if (section == 0)
                    {
                        return stores.count;
                    }
                }
                else if (noLocaltionServiceSetArr.count>0)
                {
                    if (section == 0)
                    {
                        return noLocaltionServiceSetArr.count;
                    }
                }
            }
    }
    return 0;
 }
/*- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    // To "clear" the footer view
    return [UIView new];
}*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
   
    int iPhone_savedStoreHeight,iPhone_nearestStoreHeight,iPad_savedStoreHeight,iPad_nearestStoreHeight;
    iPhone_savedStoreHeight=67;
    iPad_savedStoreHeight=90;
    iPhone_nearestStoreHeight=77;
    iPad_nearestStoreHeight=90;
    if (self.searchBarController.active) {
        if(IS_IPHONE)
        {
            return iPhone_nearestStoreHeight;
        }
        else
        {
            return iPad_nearestStoreHeight;
        }
    }
    else
    {
        if((allShops.count>0 && stores.count>0))
        {
            if (indexPath.section == 0)
            {
                if(IS_IPHONE)
                {
                    return iPhone_savedStoreHeight;
                }
                else
                {
                    return iPad_savedStoreHeight;
                }
            }
            else
            {
                if(IS_IPHONE)
                {
                    return iPhone_nearestStoreHeight;
                }
                else
                {
                    return iPad_nearestStoreHeight;
                }
            }
        }
        else if((allShops.count>0 && noLocaltionServiceSetArr.count>0))
        {
            if (indexPath.section == 0)
            {
                if(IS_IPHONE)
                {
                    return iPhone_savedStoreHeight;
                }
                else
                {
                    return iPad_savedStoreHeight;
                }
            }
            else
            {
                if(IS_IPHONE)
                {
                    return 44;
                }
                else
                {
                    return 50;
                }
            }
        }
        else
        {
            if(allShops.count>0)
            {
                if (indexPath.section == 0)
                {
                    if(IS_IPHONE)
                    {
                        return iPhone_savedStoreHeight;
                    }
                    else
                    {
                        return iPad_savedStoreHeight;
                    }
                }
            }
            else if(stores.count>0)
            {
                if (indexPath.section == 0)
                {
                    if(IS_IPHONE)
                    {
                        return iPhone_nearestStoreHeight;
                    }
                    else
                    {
                        return iPad_nearestStoreHeight;
                    }
                }
            }
            else if(noLocaltionServiceSetArr.count>0)
            {
                if(IS_IPHONE)
                {
                    return 44;
                }
                else
                {
                    return 50;
                }
            }
            return iPhone_nearestStoreHeight;
            
        }
    }

  /*  if (self.searchBarController.active)
    {
   
        if(IS_IPHONE)
        {
            return 77.0f;
        }
        else
        {
             return 90;
        }
    }
    else
    {
        if(IS_IPHONE)
        {
            return 67.0f;
        }
        else
        {
            return 90;
        }
    }*/
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *tempCell=nil;
    // Configure the cell...
    if (self.searchBarController.active) { // Display nearest shops record in search tableview
        
            SearchShopsCustomCell *cell=[tableView dequeueReusableCellWithIdentifier:@"nearestCell"];
            if(cell==nil)
            {
                cell=[[SearchShopsCustomCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nearestCell"];
                NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"SearchShopsCustomCell" owner:self options:nil];
                cell=[nib objectAtIndex:0];
            }
            SearchedStore *store = nil;
            if(stores.count>0)
            {
                store = [stores objectAtIndex:indexPath.row];
                cell.name.text = store.name;
                cell.address.text = store.address;
            }
            if(indexPath.row%2==0)
            {
                cell.backgroundColor=CELL_BG_COLOR;
            }
            else
            {
                cell.backgroundColor=[UIColor whiteColor];
            }
            tempCell=cell;
    }
    else // Display all record in simple tableview
    {
       
            if((allShops.count>0 && stores.count>0))
            {
                if (indexPath.section == 0)
                {
                    // Saved shops
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"savedCell" forIndexPath:indexPath];

                    Store *store = allShops[indexPath.row];
                    UIButton *favButton = (UIButton*)[cell viewWithTag:1];
                    favButton.property = store.storeID;
                    // used UIControlEventTouchUpInside to fix issue # 238 /Yousuf
                    [favButton addTarget:self action:@selector(onClickFavoriteButton:) forControlEvents:UIControlEventTouchUpInside];
                    
                    UIButton *delButton = (UIButton*)[cell viewWithTag:9];
                    delButton.property = store.storeID;
                    [delButton addTarget:self action:@selector(onClickDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
                    
                    [self setFavoriteButtonBackground:favButton withState:[store.isFavorite boolValue]];
                    
                    UILabel *labelStoreName = (UILabel*)[cell viewWithTag:2];
                    labelStoreName.text = store.name;
                    
                    UILabel *labelStoreAddress = (UILabel*)[cell viewWithTag:3];
                    labelStoreAddress.text = store.address;
                    
                    DLog(@"store distance %@",store.distance);
                    tempCell=cell;
                }
                else if (indexPath.section == NEAREST_STORE)
                {
                    if(stores.count>0)
                   {
                        // Nearest shops
                        SearchShopsCustomCell *cell=[tableView dequeueReusableCellWithIdentifier:@"nearestCell"];
                        if(cell==nil)
                        {
                            cell=[[SearchShopsCustomCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nearestCell"];
                            NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"SearchShopsCustomCell" owner:self options:nil];
                            cell=[nib objectAtIndex:0];
                        }
                        SearchedStore *store = nil;
                        store = [stores objectAtIndex:indexPath.row];
                        
                        cell.name.text = store.name;
                        cell.address.text = store.address;
                        tempCell=cell;
                   }
                   


                }
                else
                {
                    
                }
            }
            else  if((allShops.count>0 && noLocaltionServiceSetArr.count>0))
            {
                if (indexPath.section == 0)
                {
                    //Saved shops
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"savedCell" forIndexPath:indexPath];
                    
                    Store *store = allShops[indexPath.row];
                    UIButton *favButton = (UIButton*)[cell viewWithTag:1];
                    favButton.property = store.storeID;
                    // used UIControlEventTouchUpInside to fix issue # 238 /Yousuf
                    [favButton addTarget:self action:@selector(onClickFavoriteButton:) forControlEvents:UIControlEventTouchUpInside];
                    
                    UIButton *delButton = (UIButton*)[cell viewWithTag:9];
                    delButton.property = store.storeID;
                    [delButton addTarget:self action:@selector(onClickDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
                    
                    [self setFavoriteButtonBackground:favButton withState:[store.isFavorite boolValue]];
                    
                    UILabel *labelStoreName = (UILabel*)[cell viewWithTag:2];
                    labelStoreName.text = store.name;
                    
                    UILabel *labelStoreAddress = (UILabel*)[cell viewWithTag:3];
                    labelStoreAddress.text = store.address;
                    
                    DLog(@"store distance %@",store.distance);
                    tempCell=cell;
                }
                else if (indexPath.section == NEAREST_STORE) //no localtion
                {
                    if(noLocaltionServiceSetArr.count>0)
                    {
                        // no location service
                        noLocationServiceCell *cell=[tableView dequeueReusableCellWithIdentifier:@"noLocationService"];
                        if(cell==nil)
                        {
                            cell=[[noLocationServiceCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noLocationService"];
                            NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"noLocationServiceCell" owner:self options:nil];
                            cell=[nib objectAtIndex:0];
                        }
                        
                        cell.reEnableLocation.text=noLocaltionServiceSetArr[indexPath.row];
                        //Draw line below of UILabel text
                        
                        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:cell.reEnableLocation.text];
                        [attString addAttribute:(NSString*)kCTUnderlineStyleAttributeName
                                          value:[NSNumber numberWithInt:kCTUnderlineStyleSingle]
                                          range:(NSRange){0,[attString length]}];
                        cell.reEnableLocation.attributedText = attString;
                        cell.reEnableLocation.textColor = [UIColor blackColor];
                        tempCell=cell;
                        
                    }

                }
            }
        else
        {
            if(allShops.count>0) //Saved shops
            {
                if (indexPath.section == 0)
                {
                    //Saved shops
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"savedCell" forIndexPath:indexPath];
                    
                    Store *store = allShops[indexPath.row];
                    UIButton *favButton = (UIButton*)[cell viewWithTag:1];
                    favButton.property = store.storeID;
                    // used UIControlEventTouchUpInside to fix issue # 238 /Yousuf
                    [favButton addTarget:self action:@selector(onClickFavoriteButton:) forControlEvents:UIControlEventTouchUpInside];
                    
                    UIButton *delButton = (UIButton*)[cell viewWithTag:9];
                    delButton.property = store.storeID;
                    [delButton addTarget:self action:@selector(onClickDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
                    
                    [self setFavoriteButtonBackground:favButton withState:[store.isFavorite boolValue]];
                    
                    UILabel *labelStoreName = (UILabel*)[cell viewWithTag:2];
                    labelStoreName.text = store.name;
                    
                    UILabel *labelStoreAddress = (UILabel*)[cell viewWithTag:3];
                    labelStoreAddress.text = store.address;
                    
                    DLog(@"store distance %@",store.distance);
                    tempCell=cell;
                }
            }
            else if(stores.count>0)
            {
                if (indexPath.section == 0)
                {
                    SearchShopsCustomCell *cell=[tableView dequeueReusableCellWithIdentifier:@"nearestCell"];
                    if(cell==nil)
                    {
                        cell=[[SearchShopsCustomCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nearestCell"];
                        NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"SearchShopsCustomCell" owner:self options:nil];
                        cell=[nib objectAtIndex:0];
                    }
                    SearchedStore *store = nil;
                    store = [stores objectAtIndex:indexPath.row];
                    
                    cell.name.text = store.name;
                    cell.address.text = store.address;
                    tempCell=cell;
                }
            }
            else if(noLocaltionServiceSetArr.count>0)
            {
                if (indexPath.section == 0)
                {
                    if(noLocaltionServiceSetArr.count>0)
                    {
                        // no location service
                        noLocationServiceCell *cell=[tableView dequeueReusableCellWithIdentifier:@"noLocationService"];
                        if(cell==nil)
                        {
                            cell=[[noLocationServiceCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noLocationService"];
                            NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"noLocationServiceCell" owner:self options:nil];
                            cell=[nib objectAtIndex:0];
                        }
                        
                        cell.reEnableLocation.text=noLocaltionServiceSetArr[indexPath.row];
                        //Draw line below of UILabel text
                        
                        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:cell.reEnableLocation.text];
                        [attString addAttribute:(NSString*)kCTUnderlineStyleAttributeName
                                          value:[NSNumber numberWithInt:kCTUnderlineStyleSingle]
                                          range:(NSRange){0,[attString length]}];
                        cell.reEnableLocation.attributedText = attString;
                        cell.reEnableLocation.textColor = [UIColor blackColor];
                        tempCell=cell;
                        
                    }
                }
            }
            
        }
        
        if(allShops.count!=0  && noLocaltionServiceSetArr.count!=0)
        {
            if(indexPath.row> allShops.count)
            {
                tempCell.userInteractionEnabled=NO;
            }
            else{
                tempCell.userInteractionEnabled=YES;
            }
        }
        else
        {
            tempCell.userInteractionEnabled=YES;
        }
       
        if(indexPath.row%2==0)
        {
            tempCell.backgroundColor=CELL_BG_COLOR;
        }
        else
        {
            tempCell.backgroundColor=[UIColor whiteColor];
        }
    }
    return tempCell;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar; // called when cancel button pressed
{
    stores=[[NSArray alloc]init];
    [self showHintLabel];
    if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied)
    {
        [self searchStoresFromServer:@""];
    }
}
-(void)onClickDeleteButton:(id)sender{
    [self.tableView beginUpdates];
    //Fake delete in core data
    
    UIButton *button = (UIButton*)sender;

    NSInteger row = 0;
    for(int i = 0; i<allShops.count; i++) {
        if([((Store*)allShops[i]).storeID longValue] == [((NSNumber*)button.property) longValue]) {
            row = i;
            break;
        }
    }
    [Store fakeDeleteById:(NSNumber*)button.property];
    
   [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    allShops = [Store getAllStores];
    
   if((allShops.count==0 && stores.count>0)  || (allShops.count==0 && noLocaltionServiceSetArr.count>0))
   {
      [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]  withRowAnimation:UITableViewRowAnimationLeft];
   }
    [self showHintLabel];

    [self.tableView endUpdates];
    
    [[SyncManager sharedManager] forceSync];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL is_savedStore=false;
    deletedIndexPth=indexPath;
   Store *savedStore = nil;
    SearchedStore *nearestStored=nil;
    if (self.searchBarController.active) {
        is_savedStore=true;
        [DataStore instance].sortingOrder = STORE;
        nearestStored = stores[indexPath.row];
        
        if ([Store getStoreByID:nearestStored.searchedStoreID] == nil)
        {
            [Store insertSearchedStore:nearestStored];
        }
//        DLog(@"store index %ld, store name %@" , (long)indexPath.row,nearestStored.name);
        [DataStore instance].sortByStoreID = nearestStored.searchedStoreID;
        [DataStore instance].currentList.sortByStoreId= nearestStored.searchedStoreID;

     }
    else
    {
         if((allShops.count>0 && stores.count>0))
        {
            if (indexPath.section == 0)
            {
                is_savedStore=false;
                savedStore = allShops[indexPath.row];
                DLog(@"store index %ld, store name %@" , indexPath.row,savedStore.name);
                
                [DataStore instance].sortingOrder = STORE;
                [DataStore instance].sortByStoreID = savedStore.storeID;
                [DataStore instance].currentList.sortByStoreId= savedStore.storeID;
            }
            else
            {
                is_savedStore=true;
                [DataStore instance].sortingOrder = STORE;
                nearestStored = stores[indexPath.row];
                
                if ([Store getStoreByID:nearestStored.searchedStoreID] == nil)
                {
                    [Store insertSearchedStore:nearestStored];
                }
                DLog(@"store index %ld, store name %@" , indexPath.row,nearestStored.name);
                [DataStore instance].sortByStoreID = nearestStored.searchedStoreID;
                [DataStore instance].currentList.sortByStoreId= nearestStored.searchedStoreID;
            }
        }
        else
        {
            if(allShops.count>0)
            {
                if (indexPath.section == 0)
                {
                    
                    is_savedStore=false;
                    savedStore = allShops[indexPath.row];
                    DLog(@"store index %ld, store name %@" , indexPath.row,savedStore.name);
                    
                    [DataStore instance].sortingOrder = STORE;
                    [DataStore instance].sortByStoreID = savedStore.storeID;
                    [DataStore instance].currentList.sortByStoreId= savedStore.storeID;
                }
            }
            else if(stores.count>0)
            {
                if (indexPath.section == 0)
                {
                    is_savedStore=true;
                    [DataStore instance].sortingOrder = STORE;
                    nearestStored = stores[indexPath.row];
                    
                    if ([Store getStoreByID:nearestStored.searchedStoreID] == nil)
                    {
                        [Store insertSearchedStore:nearestStored];
                    }
                    DLog(@"store index %ld, store name %@" , indexPath.row,nearestStored.name);
                    [DataStore instance].sortByStoreID = nearestStored.searchedStoreID;
                    [DataStore instance].currentList.sortByStoreId= nearestStored.searchedStoreID;
                }
            }
            
        }
    }
    
    
    if(is_savedStore) // nearest store
    {
        
        UIApplication *app = [UIApplication sharedApplication];
        NSString *path = [NSString stringWithFormat:@"%@://?**%@", [Utility getAppUrlScheme],nearestStored.searchedStoreID];
        NSURL *ourURL = [NSURL URLWithString:path];
        [app openURL:ourURL];
        
        for (UIViewController *vc in self.navigationController.viewControllers)
        {
            if(self.is_comming_from_items)
            {
                if ([vc isKindOfClass:[ItemsViewController class]])
                {
                    [Item_list changeList:[DataStore instance].currentList byNewOrder:STORE andStoreID:nearestStored.searchedStoreID];  //update database
                    ((ItemsViewController *)vc).showNoData = YES;
                    [self.navigationController popToViewController:vc animated:YES];
                    break;
                }
            }
            else
            {
                if ([vc isKindOfClass:[ShoppingModeTableViewController class]])
                {
                    (theAppDelegate).storeDict = @{@"address": nearestStored.address,
                                                   @"city": nearestStored.city,
                                                   @"distance": nearestStored.distance,
                                                   @"id": nearestStored.searchedStoreID,
                                                   @"isFavorite": nearestStored.isFavorite,
                                                   @"itemsSortedPercent": nearestStored.itemsSortedPercent,
                                                   @"name": nearestStored.name,
                                                   @"postalAddress": nearestStored.postalAddress,
                                                   @"postalCode": nearestStored.postalCode,
                                                   @"title": nearestStored.title,
                                                   };
                    
                    [self.navigationController popToViewController:vc animated:YES];
                    break;
                }
                
            }
        }
    }
    else  // Saved store
    {
        
        
        UIApplication *app = [UIApplication sharedApplication];
        NSString *path = [NSString stringWithFormat:@"%@://?**%@", [Utility getAppUrlScheme],savedStore.storeID];
        NSURL *ourURL = [NSURL URLWithString:path];
        [app openURL:ourURL];
        
        for (UIViewController *vc in self.navigationController.viewControllers)
        {
            if(self.is_comming_from_items)
            {
                if ([vc isKindOfClass:[ItemsViewController class]])
                {
                    
                    
                    [Item_list changeList:[DataStore instance].currentList byNewOrder:STORE andStoreID:savedStore.storeID];  //update database
                    ((ItemsViewController *)vc).showNoData = YES;
                    [[SortingSyncManager sharedSortingSyncManager] setSortingSyncManagerDelegate:(UIViewController<SortingSyncManagerDelegate> *)vc];
                    [[SyncManager sharedManager] forceSync];
                    [self.navigationController popToViewController:vc animated:YES];
                    break;
                }
            }
            else
            {
                if ([vc isKindOfClass:[ShoppingModeTableViewController class]])
                {
                    NSMutableDictionary *dict = [NSMutableDictionary new];
                    if(savedStore.address) [dict setObject:savedStore.address forKey:@"address"];
                    if(savedStore.city) [dict setObject:savedStore.city forKey:@"city"];
                    if(savedStore.distance) [dict setObject:savedStore.distance forKey:@"distance"];
                    if(savedStore.storeID) [dict setObject:savedStore.storeID forKey:@"id"];
                    if(savedStore.isFavorite) [dict setObject:savedStore.isFavorite forKey:@"isFavorite"];
                    if(savedStore.itemsSortedPercent) [dict setObject:savedStore.itemsSortedPercent forKey:@"itemsSortedPercent"];
                    if(savedStore.name) [dict setObject:savedStore.name forKey:@"name"];
                    if(savedStore.postalAddress) [dict setObject:savedStore.postalAddress forKey:@"postalAddress"];
                    if(savedStore.postalCode) [dict setObject:savedStore.postalCode forKey:@"postalCode"];
                    if(savedStore.title) [dict setObject:savedStore.title forKey:@"title"];
                    (theAppDelegate).storeDict = dict;
                    
                    [[SortingSyncManager sharedSortingSyncManager] setSortingSyncManagerDelegate:(UIViewController<SortingSyncManagerDelegate> *)vc];
                    [[SyncManager sharedManager] forceSync];
                    [self.navigationController popToViewController:vc animated:YES];
                    break;
                }
                
            }
        }
    }
}

#pragma mark - set favorite store

-(void)onClickFavoriteButton:(id)sender{
    UIButton *button = (UIButton*)sender;
    Store *store = [Store getStoreByID:(NSNumber*)button.property];
    BOOL isFavorite = ![store.isFavorite boolValue];
    store.isFavorite = [NSNumber numberWithBool:isFavorite];
    [self setFavoriteButtonBackground:button withState:isFavorite];
    
    DLog(@"%@ set favorite %@",button.property,store.isFavorite);
    //save in core data
    [Store setFavorite:isFavorite forStore:store];
    [[SyncManager sharedManager] forceSync];
}
-(void)setFavoriteButtonBackground:(UIButton*)favButton withState:(BOOL)isFavorite{
    if (isFavorite) {
        [favButton setBackgroundImage:[UIImage imageNamed:@"starFilled"] forState:UIControlStateNormal];
    }
    else{
        [favButton setBackgroundImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
    }
}

#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [self.bannerView setAlpha:1];
    [UIView commitAnimations];
}
- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [self.bannerView setAlpha:0];
    [UIView commitAnimations];
}

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toSearchStores"])
    {
        SearchStoresViewController *controller = (SearchStoresViewController*)segue.destinationViewController;
        controller.is_comming_from_items=self.is_comming_from_items;
    }
}

#pragma mark- search bar
-(BOOL)searchDisplayController:(UISearchController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.001);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    UITableView *temptbl = self.searchBarController.searchResultsTableView;
    for( UIView *subview in temptbl.subviews ) {
        if( [subview class] == [UILabel class] ) {
            UILabel *lbl = (UILabel*)subview; // sv changed to subview.
            lbl.text =[NSString stringWithFormat:@"%@...",NSLocalizedString(@"Searching", nil)];
        }
    }
    });
    
    stores=[[NSArray alloc]init];
    NSString *searchstr=[searchString stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]];
    if(searchstr.length>0)
    {
         [self searchStoresFromServer:searchstr];
         self.searchBarController.searchResultsTableView.separatorColor=[UIColor clearColor];
         self.searchBarController.searchResultsTableView.showsVerticalScrollIndicator=NO;
        return YES;
    }
    return NO;
}

- (void)searchDisplayController:(UISearchController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView setContentInset:UIEdgeInsetsZero];
    [tableView setScrollIndicatorInsets:UIEdgeInsetsZero];
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
    [self showHintLabel];
}
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing ShopsTableViewController");
}

@end
