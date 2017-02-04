//
//  SettingsTableViewController.h
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
//Replaced refrosted - Markus
#import "SWRevealViewController.h"
#import "Active_recipe+Extra.h"
#import "EndpointHash+Extra.h"
#import "Ingredient+Extra.h"
#import "Item+Extra.h"
#import "Item_list+Extra.h"
#import "ItemsCheckedStatus+Extra.h"
#import "Recipebox+Extra.h"
#import "Recipebox_tag+Extra.h"
#import "Store+Extra.h"
#import "Visit+Extra.h"
#import "LoginViewController.h"
#import "FavoriteItem+Extra.h"
#import <GoogleMobileAds/GoogleMobileAds.h>


@interface SettingsTableViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,SWRevealViewControllerDelegate,GADBannerViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;

- (IBAction)showMenu;
@end
