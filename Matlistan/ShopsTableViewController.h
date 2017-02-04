//
//  ShopsTableViewController.h
//  matlistan
//
//  Created by Yan Zhang on 16/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "SearchedStore+Extra.h"
#import <CoreLocation/CoreLocation.h>
#import "SearchShopsCustomCell.h"
#import "noLocationServiceCell.h"
#import <CoreText/CoreText.h>

@interface ShopsTableViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,GADBannerViewDelegate, UISearchBarDelegate,UISearchDisplayDelegate,CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    float latitude,longitude;
//    NSMutableArray *searchResults;
    NSArray *stores,*sectionNames;
    NSIndexPath *deletedIndexPth;
    NSArray *noLocaltionServiceSetArr;
}
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *userHintLabel;
@property (nonatomic, readwrite) BOOL is_comming_from_items;

@property(strong,nonatomic)IBOutlet UISearchDisplayController *searchBarController;


@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

//@property (nonatomic, readwrite) BOOL is_comming_from_items;



@end
