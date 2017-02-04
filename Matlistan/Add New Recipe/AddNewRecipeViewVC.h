//
//  AddNewRecipeViewVC.h
//  Matlistan
//
//  Created by Leocan on 2/16/16.
//  Copyright (c) 2016 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LPlaceholderTextView.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "Recipebox.h"
#import "Recipebox+Extra.h"
#import "Recipebox_tag.h"
#import <UIImageView+AFNetworking.h>
#import "SyncManager.h"

@interface AddNewRecipeViewVC : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,UITextFieldDelegate,UITextViewDelegate,GADBannerViewDelegate, SyncManagerDelegate>
{
    BOOL is_next_prevClick;
    int distance;
    CGRect previousRect,keyboardFrame;
    int screen_width,screen_height;
    BOOL is_iphone6,flag;
    int temp_tag,max_height;
    NSNumber *recipe_id;
    NSValue* keyboardFrameBegin;
}
@property(strong,nonatomic)IBOutlet NSString *descString;

@property(strong,nonatomic)IBOutlet UIScrollView *scroll_view;
@property(strong,nonatomic)IBOutlet UIToolbar *tbKeyboard;

@property(weak,nonatomic)IBOutlet UITextField *titleTxt;//1
@property(weak,nonatomic)IBOutlet UITextField *sourceTxt;//3
@property(weak,nonatomic)IBOutlet UITextField *tagsTxt;//4
@property(weak,nonatomic)IBOutlet UITextField *yieldTxt;//5
@property(weak,nonatomic)IBOutlet UITextField *portionsTxt;//6
@property(weak,nonatomic)IBOutlet UITextField *cookingtimeTxt;//7

@property(weak,nonatomic)IBOutlet LPlaceholderTextView *descTxt;//2
@property(weak,nonatomic)IBOutlet LPlaceholderTextView *ingredientsTxt;//8
@property(weak,nonatomic)IBOutlet LPlaceholderTextView *instructionTxt;//9
@property(weak,nonatomic)IBOutlet LPlaceholderTextView *adviceTxt;//10
@property(weak,nonatomic)IBOutlet LPlaceholderTextView *yourNotesTxt;//11

@property(weak,nonatomic)IBOutlet UILabel *recipeLbl;

//LABEL line
@property(weak,nonatomic)IBOutlet UILabel *lbl_titleTxt;//1
@property(weak,nonatomic)IBOutlet UILabel *lbl_descTxt;//2
@property(weak,nonatomic)IBOutlet UILabel *lbl_sourceTxt;//3
@property(weak,nonatomic)IBOutlet UILabel *lbl_tagsTxt;//4
@property(weak,nonatomic)IBOutlet UILabel *lbl_yieldTxt;//5
@property(weak,nonatomic)IBOutlet UILabel *lbl_portionsTxt;//6
@property(weak,nonatomic)IBOutlet UILabel *lbl_cookingtimeTxt;//7
@property(weak,nonatomic)IBOutlet UILabel *lbl_ingredientsTxt;//8
@property(weak,nonatomic)IBOutlet UILabel *lbl_instructionTxt;//9
@property(weak,nonatomic)IBOutlet UILabel *lbl_adviceTxt;//10
@property(weak,nonatomic)IBOutlet UILabel *lbl_yourNotesTxt;//11
//

@property(strong,nonatomic) IBOutlet UIImageView *recipeImg;
@property (nonatomic, retain) IBOutlet UISwitch *user_recipe_switch;
- (void) switchToggled:(id)sender;

@property(strong,nonatomic) IBOutlet UIView *headerView;
@property(strong,nonatomic) Recipebox *editRecipe;
@property(weak,nonatomic)IBOutlet NSString *screenName;


- (IBAction)backBtn:(id)sender;
-(IBAction)saveRecipe:(id)sender;
-(IBAction)choosePhoto:(id)sender;



@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;


@end
