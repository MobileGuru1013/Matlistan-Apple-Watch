//
//  RecipeDetailViewController.h
//  MatListan
//
//  Created by Yan Zhang on 25/03/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Active_recipe+Extra.h"
#import "MatlistanHTTPClient.h"
#import "AfterCookViewController.h"
//Replaced refrosted - Markus
#import "SWRevealViewController.h"
#import "RecipeData.h"
#import "DataStore.h"
#import "RecipeOverviewTableViewCell.h"
#import "Recipebox+Extra.h"
#import "Active_recipe+Extra.h"
#import "Recipebox_tag+Extra.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "SyncManager.h"
#import "CustomCell.h"
#import "RecipeTimer.h"

typedef enum BAR_BUTTON_TYPE
{
    ZERO,
    TO_BUY,
    TO_COMMENT,
    TO_PLAN,
    TO_DELETE,
    NOT_CERTAIN
} BAR_BUTTON_TYPE;

@interface RecipeDetailViewController : UIViewController<UIWebViewDelegate,GADBannerViewDelegate,SWRevealViewControllerDelegate,UIGestureRecognizerDelegate,UIPickerViewDataSource,UIPickerViewDelegate,UITextViewDelegate, SyncManagerDelegate,CellDelegate,RecipeDelegate,UITableViewDelegate,UITableViewDataSource>
{
    BOOL is_timerWindow_open;
    NSNumber *r_id;
    BOOL is_timerListOpen;
    int expand_height,collaps_height;
    NSIndexPath *expandableIndexPath;
    int textview_y,more_tableview_height,navigationBarHeight,more_tbl_distance;
    NSMutableArray *popupArr;
    NSString *temp_str;
}
@property (nonatomic,retain)Active_recipe *activeRecipe;
@property (nonatomic,retain)NSNumber *recipeboxId;
@property (nonatomic)int barButtonType;
@property (nonatomic)BOOL segueFromLeftMenu;
@property CGFloat old_scale;
@property NSDate *last_time;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
//Dimple 9-10-15
@property (weak, nonatomic) NSString *screen_name;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;



@property (weak, nonatomic) IBOutlet UITextView *textview;

//Dimple 9-10-15
@property(strong,nonatomic)IBOutlet UIView *Picker_View;
@property(strong,nonatomic)IBOutlet UIPickerView *Picker;
@property(strong,nonatomic)IBOutlet UIView *buttonbar;
@property(strong,nonatomic) IBOutlet UIButton *okBtn;
@property(strong,nonatomic) IBOutlet UIButton *cancelBtn;
@property(strong,nonatomic) IBOutlet UIButton *CancelPicker_click;
@property(strong,nonatomic) IBOutlet UIButton *OkPicker_click;

//Dimple



@property(retain, nonatomic) IBOutlet UIPickerView *picker_timer;
@property (weak, nonatomic) IBOutlet UILabel  *hrlbl;
@property (weak, nonatomic) IBOutlet UILabel  *minlbl;
@property (weak, nonatomic) IBOutlet UILabel  *seclbl;
@property (strong, nonatomic) IBOutlet UIView *timeView;
@property (strong, nonatomic) IBOutlet UIButton *headerBtn;
@property (nonatomic, strong) IBOutlet UITableView *more_tableview;



-(IBAction)CancelPicker_click:(id)sender;
-(IBAction)DonePicker_click:(id)sender;

- (void)removeTimerFinishedRecipe:(RecipeTimer *)inRecipe;

@property (strong, nonatomic) NSIndexPath *expandedIndexPath;

@property (strong, nonatomic) IBOutlet UIButton *timerWindowBtn;
@property (strong, nonatomic) IBOutlet UITableView *timerWindowTbl;
-(IBAction)onclick_timerWindow:(id)sender;
@property(strong,nonatomic) NSString *tempRecipeDesc;
@property (nonatomic, weak) RecipeTimer *selectedRecipeTimer;

@property (nonatomic, strong) RecipeTimer *selectedRecipe;
@property (nonatomic, strong) RecipeTimer *tempRecipe;

@property (weak, nonatomic) NSMutableArray *timerOnRecipes;

@end

@protocol RecipesDelegate <NSObject>
- (void)removeRecipe:(RecipeTimer *)inRecipe;
@end

