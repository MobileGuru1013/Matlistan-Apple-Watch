//
//  LeftMenuTableViewController.h
//  MatListan
//
//  Created by Yan Zhang on 03/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"
#import "Recipebox+Extra.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface LeftMenuTableViewController : UIViewController<GADBannerViewDelegate,UITableViewDataSource,UITableViewDelegate>
{
    UIView *bgView;
    SWRevealViewController *revealController;
     UINavigationController *navigationController1;
}
@property(strong,nonatomic)IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *timerOnRecipes;
@property (nonatomic, strong) NSMutableArray *recipeArr;
@end
