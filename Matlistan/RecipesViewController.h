//
//  RecipesViewController.h
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

//Replaced refrosted - Markus
#import "SWRevealViewController.h"
#import "DataStore.h"
#import "Communicator.h"
//#import "RecipeCellView.h"
#import "RecipeData.h"
#import "RecipeListSWCell.h"
#import "SWTableViewCell.h"
#import "SyncManager.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "AddNewRecipeViewVC.h"
#import "RecipeTimer.h"

#define ACTIONSHEET_SWIPE 1
#define ACTIONSHEET_SORT 2
@interface RecipesViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UISearchDisplayDelegate,UIActionSheetDelegate,SyncManagerDelegate,GADBannerViewDelegate,SWRevealViewControllerDelegate,RecipeListDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet UIImageView *testImage;
@property (nonatomic,copy)NSString *tagSearchText;// this property is used for the tags

//Dimple
@property (strong, nonatomic) IBOutlet UIView *picker_main_view;
@property(strong,nonatomic) IBOutlet UIPickerView *picker;
@property(strong,nonatomic) IBOutlet UIView *clearView;
@property (strong, nonatomic) NSIndexPath *expandedIndexPath;

/*Developer : Dimple
 Date : 30-9-15
 Description : UI Improvment*/

-(IBAction)showMenu;
//-(IBAction)planBtn:(id)sender;
//-(IBAction)deleteBtn:(id)sender;
//-(IBAction)editBtn:(id)sender;
-(IBAction)expandViewBtn:(id)sender;

@property (nonatomic, strong) IBOutlet UITableView *more_tableview;

@property (nonatomic, strong) NSMutableArray *timerOnRecipes;
@property (nonatomic, strong) NSMutableArray *recipeArr;
@property NSIndexPath *selected_index;
@end
