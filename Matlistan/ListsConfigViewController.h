//
//  ListsConfigViewController.h
//  MatListan
//
//  Created by Yan Zhang on 21/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"
#import "UIButton+Property.h"
#import "ListItemCell.h"
#import "SyncManager.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ListsConfigViewController : UIViewController<UITextFieldDelegate,SWTableViewCellDelegate,SyncManagerDelegate,GADBannerViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textfieldNewListName;
@property (weak, nonatomic) IBOutlet UIButton *buttonAdd;

//Raj 26-9-15
@property (weak, nonatomic) IBOutlet UIView *txtView;
@property (nonatomic, strong) IBOutlet UIButton *textBtn;
- (IBAction)TextBtnClick:(id)sender;

- (IBAction)onClickAdd:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;

@end
