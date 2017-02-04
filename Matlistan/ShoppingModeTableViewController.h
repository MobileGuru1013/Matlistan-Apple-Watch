//
//  ShoppingModeTableViewController.h
//  MatListan
//
//  Created by Yan Zhang on 10/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Visit+Extra.h"
#import "MatlistanHTTPClient.h"
#import "ShoppingTableViewCell.h"
#import "SyncManager.h"
#import "SortingSyncManager.h"
#import "DOPDropDownMenu.h"
#import "SearchedStore.h"
#import "VCFloatingActionButton.h"
#import "HelpDialogManager.h"
#import "CustomPickerView.h"

@interface ShoppingModeTableViewController : UIViewController<CLLocationManagerDelegate,UIActionSheetDelegate,ShoppingTableViewCellProtocol,SyncManagerDelegate, SortingSyncManagerDelegate, UITabBarDelegate, UITableViewDataSource, CLLocationManagerDelegate,DOPDropDownMenuDataSource, DOPDropDownMenuDelegate, floatMenuDelegate, HelpDialogManagerDelegate, CustomPickerViewDelegate>
{
    NSMutableArray *colorArr;
    NSMutableArray *toCheckedcolorArr;
    NSMutableArray *toBuycolorArr;
    int colorFlag,colorFlag2;
    NSString *old_cat,*new_cat;
    
    NSMutableArray *UnSortedcolorArr,*SortedcolorArr;
    BOOL is_autoSortAlert;
    
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *custView;
@property (strong, nonatomic) VCFloatingActionButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (nonatomic, strong) DOPDropDownMenu *menu;
@property (nonatomic, strong) NSString *selectd_store_id;
@property (nonatomic, strong) NSString *selectd_store_name;
@property (nonatomic, strong) SearchedStore *selectdStoreObj;
- (IBAction)onClickClose:(id)sender;
- (IBAction)onClickRefresh:(id)sender;

@property (nonatomic, strong) DOPDropDownMenu *moreBtn;
@end
