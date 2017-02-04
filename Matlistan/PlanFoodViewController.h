//
//  PlanFoodViewController.h
//  MatListan
//
//  Created by Yan Zhang on 23/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
//Replaced refrosted - Markus
#import "SWRevealViewController.h"
#import "SWTableViewCell.h"
#import "ActiveRecipeSWCell.h"
#import "AfterCookViewController.h"
#import "SyncManager.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "AddNewRecipeViewVC.h"

@interface PlanFoodViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UIActionSheetDelegate, SyncManagerDelegate,GADBannerViewDelegate,SWRevealViewControllerDelegate>
{
    NSMutableArray *activeRecipes;
    NSString *timeStr;
    int selected_index;
    Recipebox *edit_recipe;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet UIImageView *testImage;
@property (strong, nonatomic) NSIndexPath *expandedIndexPath;
/*Developer : Dimple
 Date : 3-10-15
 Description : UI Improvment*/

-(IBAction)showMenu;
-(IBAction)cookedBtn:(id)sender;
-(IBAction)boughtBtn:(id)sender;
-(IBAction)deleteBtn:(id)sender;
-(IBAction)editBtn:(id)sender;
-(IBAction)expandViewBtn:(id)sender;

@property (nonatomic, strong) NSMutableArray *recipeArr;
@property (nonatomic, strong) NSMutableArray *timerOnRecipes;

@end
