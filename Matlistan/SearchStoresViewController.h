//
//  SearchStoresViewController.h
//  MatListan
//
//  Created by Yan Zhang on 17/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchedStore+Extra.h"
#import <CoreLocation/CoreLocation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface SearchStoresViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate, CLLocationManagerDelegate,GADBannerViewDelegate>
- (IBAction)onEditingEnd:(id)sender;
- (IBAction)textFieldValueChanged:(id)sender;

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UITextField *textfieldSearch;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (nonatomic, readwrite) BOOL is_comming_from_items;
- (IBAction)onClickSearch:(id)sender;
@end
