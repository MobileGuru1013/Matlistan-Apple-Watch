//
//  ChangeTextViewController.h
//  MatListan
//
//  Created by Yan Zhang on 30/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item+Extra.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ChangeTextViewController : UIViewController<UITextFieldDelegate,UIPickerViewDelegate, UIPickerViewDataSource,GADBannerViewDelegate>

@property (nonatomic,retain)Item *item;

@property (nonatomic,retain)NSNumber *itemId;
@property (nonatomic,retain)NSManagedObjectID *itemObjectId;

@property (weak, nonatomic) IBOutlet UITextField *textFieldItem;

@property (weak, nonatomic) IBOutlet UILabel *labelAfterShopping;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segbutton;



@property (weak, nonatomic) IBOutlet UIPickerView *picker;

@property (weak, nonatomic) IBOutlet UILabel *labelMatchItem;

@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;

@property (weak, nonatomic) IBOutlet UILabel *edititemLabel;

- (IBAction)onClickSave:(id)sender;
- (IBAction)onClickCancel:(id)sender;


@property (weak, nonatomic) IBOutlet UIView *picker_main_view;
@property (weak, nonatomic) IBOutlet UIImageView *pickerImage;
@property (weak, nonatomic) IBOutlet UIButton *openPickerBtn;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;
@property (weak, nonatomic) IBOutlet UIView *navigationHeader;
@property (weak, nonatomic) IBOutlet UILabel *headerLbl;


@property (weak, nonatomic) IBOutlet UILabel *listlbl;
@property (weak, nonatomic) IBOutlet UIPickerView *list_picker;
@property (weak, nonatomic) IBOutlet UIView *picker_view_list;
@property (weak, nonatomic) IBOutlet UIImageView *pickerImage_list;
@property (weak, nonatomic) IBOutlet UIButton *openPickerBtn_list;

- (IBAction)openPickerBtn:(id)sender;
-(IBAction)delete_click:(id)sender;
- (IBAction)openPickerBtn_list:(id)sender;

@end
