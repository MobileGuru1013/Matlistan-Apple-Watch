//
//  ItemsViewController.h
//  MatListan
//
//  Created by Yan Zhang on 20/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SWRevealViewController.h"
#import "MatlistanHTTPClient.h"
#import "SyncManager.h"
#import "SWTableViewCell.h"
#import "DataStore.h"
#import "Communicator.h"
#import "ShoppingModeTableViewController.h"
#import "SortingViewController.h"

#import "Item+Extra.h"
#import "Item_list+Extra.h"

#import "ChangeTextViewController.h"
#import "Store+Extra.h"
#import "ALToastView.h"
#import "UIButton+Property.h"
#import "SortTableViewController.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "ItemCustomCell.h"
#import "CustomPickerView.h"
#import "SortingSyncManager.h"
#import <Google/SignIn.h>
#import "DOPDropDownMenu.h"
#import "VCFloatingActionButton.h"
#import "BarcodeScannerVC.h"
#import "VoiceMatchingVC.h"
#import "VoiceDetectionVC.h"
#import "ItemsSelectionViewVC.h"
#import "DisplayAllItemListVC.h"
#import "UIViewController+MJPopupViewController.h"
#import "RecipeDetailViewController.h"

#define SECTION_HEADER_HEIGHT 40.0
#define ITEMS_VIEW_ROW_HEIGHT 44.0
#define ITEMS_VIEW_IPAD_ROW_HEIGHT 70.0
#define SECTION_HEADER_IPAD_HEIGHT 60

@interface ItemsViewController : UIViewController<UITextFieldDelegate, MatlistanHTTPClientDelegate, SyncManagerDelegate,  UITableViewDataSource,UITableViewDelegate,PossibleMatchesCellDelegate, UIActionSheetDelegate, GADBannerViewDelegate, CustomPickerViewDelegate, SortingSyncManagerDelegate,SWRevealViewControllerDelegate,DOPDropDownMenuDataSource, DOPDropDownMenuDelegate,floatMenuDelegate,MJSecondPopupDelegate,MJMatchingPopupDelegate,UIGestureRecognizerDelegate>
{
    NSString *item_titleLbl;
    CGRect textview_fram_width;
    BOOL stop_animation,call_from_rotate;
    // ItemCustomCell *cell;
    BOOL is_mannual_sort;
    BOOL categoryFlag;
    NSTimer *timer;
    BOOL edit_from_barcode;
    
    VoiceMatchingVC *nav1;
    VoiceDetectionVC *nav;
    
    NSString *undoItemName;
    BOOL is_undoBtnClick;
    UIPopoverController *popup;
    BOOL is_displayUndoToast,LittleDataInfo;
    
}
@property (nonatomic,copy)NSString *ingredientSearchText;// this property is used for the tags

@property (weak, nonatomic) IBOutlet UITextField *textfieldForNewItem;
@property (weak, nonatomic) IBOutlet UIButton *buttonAdd;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddTans;
@property (weak, nonatomic) IBOutlet UIImageView *testImage;
@property (weak, nonatomic) IBOutlet UIButton *buttonFav;
@property (weak, nonatomic) IBOutlet UIButton *buttonVoice;
@property (weak, nonatomic) IBOutlet UIButton *buttonBarcode;

//Raj 26-9-15
@property (weak, nonatomic) IBOutlet UIView *txtView;
@property (nonatomic, strong) IBOutlet UIButton *textBtn;
@property (strong, nonatomic) VCFloatingActionButton *addButton;

- (IBAction)onClickButtonAdd:(id)sender;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;

@property (nonatomic, strong) CustomPickerView *customPickerView;
@property(strong,nonatomic) IBOutlet UIView* custom_toastView;
@property(strong,nonatomic) IBOutlet UILabel* toastLbl;
@property(strong,nonatomic) IBOutlet UILabel* toastLine;
@property(strong,nonatomic) IBOutlet UIButton* toastBtn;
@property(strong,nonatomic) UIButton *toastReadMoreBtn;

@property BOOL showNoData;

- (IBAction)onTextFieldNewItemEditChanged:(id)sender;
- (IBAction)onEditingNewItemDidEnd:(id)sender;
- (IBAction)onTextFieldTouchDown:(id)sender;

//Raj 26-9-15
- (IBAction)TextBtnClick:(id)sender;
- (void)loadRecordsFromCoreData;

//-(IBAction)deleteBtn:(id)sender;
//-(IBAction)editBtn:(id)sender;
@property (strong, nonatomic) NSIndexPath *expandedIndexPath;

//Dimple-26-11-2015
@property (nonatomic, strong) DOPDropDownMenu *menu;



- (IBAction)BarcodeScannerBtn:(id)sender;
- (IBAction)shareButton:(id)sender;


@end
