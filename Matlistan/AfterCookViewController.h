//
//  AfterCookViewController.h
//  MatListan
//
//  Created by Yan Zhang on 23/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Recipebox+Extra.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface AfterCookViewController : UIViewController<UITextFieldDelegate,GADBannerViewDelegate>
{
    NSInteger tag;
    float movementduration;
}
@property (nonatomic,retain) Recipebox *recipe;
@property (nonatomic, retain) NSNumber *activeRecipeId;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart1;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart2;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart3;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart4;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart5;
@property (weak, nonatomic) IBOutlet UITextField *textfieldTime;
@property (weak, nonatomic) IBOutlet UISwitch *switchChangeMore;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton *buttonSave;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property(strong,nonatomic) NSString *screen_identifier;
@property(strong,nonatomic)IBOutlet UIToolbar *tbKeyboard;

- (IBAction)onClickButtonSave:(id)sender;
- (IBAction)onClickButtonCancel:(id)sender;
- (IBAction)onClickStar1:(id)sender;
- (IBAction)onClickStar5:(id)sender;

- (IBAction)onClickStar2:(id)sender;
- (IBAction)onClickStar3:(id)sender;
- (IBAction)onClickStar4:(id)sender;
@end
