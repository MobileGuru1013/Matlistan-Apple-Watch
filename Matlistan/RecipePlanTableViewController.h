//
//  RecipePlanTableViewController.h
//  MatListan
//
//  Created by Yan Zhang on 24/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Recipebox+Extra.h"
#import "DataStore.h"
#import "Item_list+Extra.h"
#import "Ingredient+Extra.h"
#import "Active_recipe+Extra.h"
#import "LPlaceholderTextView.h"
#import "SyncManager.h"
//cellPortion, cellListName,cellList, cellTitle, cellIngredients, cellOccasion, cellComment, cellButtons
typedef enum CELL_SECTION
{
    SECTION_INGREDIENTS,
   
} CELL_SECTION;

@interface RecipePlanTableViewController : UIViewController<UITextFieldDelegate,UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate,UITableViewDataSource,UITextViewDelegate,UIScrollViewDelegate,SyncManagerDelegate>
{
    CGFloat animatedDistance;
    NSString *selected_string;
}
@property (strong) UINavigationBar* navigationBar;
@property (nonatomic,retain)Active_recipe *activeRecipe;

@property (strong, nonatomic) NSIndexPath *expandedIndexPath;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
//@property(strong,nonatomic)IBOutlet LPlaceholderTextView *textcomment;
@property(strong,nonatomic)IBOutlet UIView *footer;
- (IBAction)onClickCancel:(id)sender;
- (IBAction)onClickOK:(id)sender;



//Dimple- 27-11-2015
- (IBAction)portionerSectionBtn:(id)sender;
- (IBAction)shoppingListSectionBtn:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *bottomView;


@property (strong, nonatomic) IBOutlet UILabel *portion_label;
@property (strong, nonatomic) IBOutlet UILabel *label_portion;
@property (strong, nonatomic) IBOutlet UIImageView *dropdown_img_portioner;
@property (strong, nonatomic) IBOutlet UIImageView *dropdown_img;
@property (strong, nonatomic) IBOutlet UILabel *labelSelectedList;
@property (strong, nonatomic) IBOutlet UILabel *title_label_ingredient;
@property (strong, nonatomic) IBOutlet UITextField *textFieldOccasion; //TO DO: confirm - is it the description for the recipe?

@property (strong, nonatomic) IBOutlet UILabel *title_textFieldOccasion;
@property (strong, nonatomic) IBOutlet UILabel *title_textcomment;


@property (strong, nonatomic) IBOutlet UIView *tableheaderView;
@property (strong, nonatomic) IBOutlet UIView *tablefooterView;

@property (strong, nonatomic) IBOutlet UIButton *portionerSectionBtn;
@property (strong, nonatomic) IBOutlet UIButton *shoppingListSectionBtn;


@end
