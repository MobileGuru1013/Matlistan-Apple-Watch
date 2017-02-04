//
//  ItemsSelectionViewVC.h
//  Matlistan
//
//  Created by Leocan on 2/24/16.
//  Copyright (c) 2016 Consumiq AB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "ItemsSelectionCell.h"
#import "DataStore.h"
#import "MatlistanHTTPClient.h"
#import "Item+Extra.h"
#import "ItemListsSorting+Extra.h"
#import "Utility.h"
#import "DOPDropDownMenu.h"
#import "DisplayAllItemListVC.h"
#import "UIViewController+MJPopupViewController.h"
#import "SyncManager.h"

@interface ItemsSelectionViewVC : UIViewController<UITableViewDataSource,UITableViewDelegate,GADBannerViewDelegate,DOPDropDownMenuDataSource, DOPDropDownMenuDelegate,SyncManagerDelegate>
{
    NSMutableArray *selectedRowsArray;
    DataStore *dataStore;
    MatlistanHTTPClient *client;
    NSArray *sectionNames;

    NSMutableArray *colorArr;
    NSMutableArray *toCheckedcolorArr;
    NSMutableArray *toBuycolorArr;
    int colorFlag,colorFlag2,my_screenwidth;
    
    NSMutableArray *UnSortedcolorArr,*SortedcolorArr;
    NSMutableArray *toBuyItems;
    NSString *old_cat,*new_cat;
    NSArray *sortedItems;
    NSArray *unknownItems;   
    NSMutableArray *sortedItemsMUT;    //used for sorting by STORE
    NSMutableArray *unknownItemsMUT;   //used for sorting by STORE

    NSMutableArray *popupArr;
    int x,w,h,floating_X,floating_Y,floating_W,floating_H,navigationBarHeight;
     NSDictionary *menuDic;
    NSInteger matichingItemIndex;
}
@property(strong,nonatomic) NSMutableArray *sortedItemsArr;
@property(strong,nonatomic) NSMutableArray *unlnownItemsArr;

@property(strong,nonatomic) IBOutlet UITableView *table_view;

@property(strong,nonatomic) IBOutlet UILabel *lbl_totalSelectedItems;
@property(strong,nonatomic) IBOutlet UIButton *backBtn;
@property(strong,nonatomic) IBOutlet UIButton *delBtn;
@property(strong,nonatomic) IBOutlet UIButton *moreImgBtn;


@property (strong, nonatomic) IBOutlet GADBannerView *bannerView;
@property (nonatomic, strong) DOPDropDownMenu *moreBtn;

@property(strong,nonatomic) IBOutlet UIView *headerView;
@property(strong,nonatomic) IBOutlet UILabel *navigationLine;

//@property(strong,nonatomic) NSIndexPath *scrollToIndex;

@property(strong,nonatomic) NSNumber *item_id;
@property(strong,nonatomic)  NSString *sectionName;

-(IBAction)onClick_back:(id)sender;
-(IBAction)onClick_delete:(id)sender;


@end
