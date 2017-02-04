//
//  RecipePlanTableViewController.m
//  MatListan
//
//  Created by Yan Zhang on 24/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "RecipePlanTableViewController.h"
#import "UISwitch+Property.h"
#import "UIButton+Property.h"
#import "Item_list+Extra.h"
#import "MatlistanHTTPClient.h"
#import "SignificantChangesIndicator.h"

#import "AppDelegate.h"
//#import "MBProgressHUD.h"
#define myscreenwidth (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

@interface RecipePlanTableViewController ()
{
    NSArray *cellNames;
    NSArray *cellHeights;
    NSArray *lists;
    NSString *currentListName;
    NSNumber *currentListID;
    Recipebox *recipe;
    //NSString *portions;
    NSArray *ingredients;
    //  UITextField *textFieldOccasion; //TO DO: confirm - is it the description for the recipe?
    NSInteger selectedListIndex;
    //    UILabel *labelSelectedList;
    UIButton *btn;
    BOOL isActiveRecipe;
    NSMutableDictionary *ingredientsNames;
    NSMutableDictionary *dictOfSelectedIngredients;
    
    NSMutableArray *selectablePortions;
    
    NSString *Is_IngredientExits;
    int expand_height,collaps_height;
    
    IBOutlet UIView *picker_main_view;
    IBOutlet UIPickerView *picker;
    BOOL isClosedListPicker;
    // UIImageView *dropdown_img;
    
    
    IBOutlet UIView *picker_view_prtioner;
    IBOutlet UIPickerView *picker_portioner;
    BOOL isClosedPortioner;
    
    NSMutableArray *ingrdient_flagarr;
    NSIndexPath *button_IndexPath;
    
    //View for disabling touch
    IBOutlet UIView *hiddenView;
    IBOutlet UIView *hiddenView_upper;
    IBOutlet UIView *hiddenView_bottom;
    
    
    UINavigationBar *headerView;
    
    NSString *previous_label_portion;
    float my_screenwidth;
    
    
    BOOL temp;
    CGSize keyboardSize;
    int portionsStepNumber;
    NSString *portionType;
    BOOL activeRecipeSaved;
   
}
@property(strong,nonatomic)IBOutlet LPlaceholderTextView *textcomment;
//@property(strong,nonatomic)IBOutlet UIScrollView *scroll;

@end

@implementation RecipePlanTableViewController
@synthesize activeRecipe;

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [SyncManager sharedManager].syncManagerDelegate = self;
}

-(BOOL)shouldAutorotate{
    return YES;
}

-(void)loadHeaderControl:(UITableView *)tableview
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    if(IS_IPHONE)
    {
        if(ingredients.count>0)
        {
            self.tableheaderView=[[UIView alloc]initWithFrame:CGRectMake(tableview.frame.origin.x, tableview.frame.origin.y, tableview.frame.size.width, 107)];
            
        }
        else
        {
            self.tableheaderView=[[UIView alloc]initWithFrame:CGRectMake(tableview.frame.origin.x, tableview.frame.origin.y, tableview.frame.size.width, 45)];
            
        }
        
//        if(portionsStepNumber == -1) {
//            self.labelSelectedList=[[UILabel alloc]initWithFrame:CGRectMake(15, 34, 266, 22)];
//            self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(285, 40, 20, 12)];
//            self.shoppingListSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 31, 310, 30)];
//        }
//        else {
//            self.portion_label=[[UILabel alloc]initWithFrame:CGRectMake(15,18, 84, 22)];
//            self.label_portion=[[UILabel alloc]initWithFrame:CGRectMake(65, 18, 206, 22)];
//            self.dropdown_img_portioner=[[UIImageView alloc]initWithFrame:CGRectMake(285, 24, 20, 12)];
//            self.portionerSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 15, 310, 28)];
//            
//            self.labelSelectedList=[[UILabel alloc]initWithFrame:CGRectMake(15, 51, 266, 22)];
//            self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(285, 60, 20, 12)];
//            self.shoppingListSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 47, 310, 30)];
//        }
       
        if(portionsStepNumber == -1) {
            self.labelSelectedList=[[UILabel alloc]initWithFrame:CGRectMake(15, 34, 266, 22)];
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            {
                self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-20*2, 40, 20, 12)];
                self.shoppingListSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 31, SCREEN_WIDTH, 30)];
            }
            else
            {
                self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(285, 40, 20, 12)];
                self.shoppingListSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 31, SCREEN_WIDTH, 30)];
            }
        }
        else {
            self.portion_label=[[UILabel alloc]initWithFrame:CGRectMake(15,18, 84, 22)];
            self.label_portion=[[UILabel alloc]initWithFrame:CGRectMake(65, 18, 206, 22)];
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            {
                self.dropdown_img_portioner=[[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-20*2, 24, 20, 12)];
                self.portionerSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 15, SCREEN_WIDTH, 30)];
                
                self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-20*2, 60, 20, 12)];
                self.shoppingListSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 47,SCREEN_WIDTH, 30)];
            }
            else
            {
                self.dropdown_img_portioner=[[UIImageView alloc]initWithFrame:CGRectMake(285, 24, 20, 12)];
                self.portionerSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 15, 310, 28)];
                self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(285, 60, 20, 12)];
                self.shoppingListSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 47, 310, 30)];
            }
            self.labelSelectedList=[[UILabel alloc]initWithFrame:CGRectMake(15, 51, 266, 22)];
        }

        
        
        
        self.title_label_ingredient=[[UILabel alloc]initWithFrame:CGRectMake(15, 79, 150, 30)];
        
    }
    else
    {
        if(ingredients.count>0)
        {
            self.tableheaderView=[[UIView alloc]initWithFrame:CGRectMake(tableview.frame.origin.x, tableview.frame.origin.y, tableview.frame.size.width, 107)];
            
        }
        else
        {
            self.tableheaderView=[[UIView alloc]initWithFrame:CGRectMake(tableview.frame.origin.x, tableview.frame.origin.y, tableview.frame.size.width, 45)];
            
        }
        
        if(portionsStepNumber == -1) {
            self.labelSelectedList=[[UILabel alloc]initWithFrame:CGRectMake(15, 34, 698, 22)];
            self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-20*2, 40, 20, 12)];
            self.shoppingListSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 31, SCREEN_WIDTH, 40)];
        }
        else
        {
            self.portion_label=[[UILabel alloc]initWithFrame:CGRectMake(15, 18, 84, 22)];
            self.label_portion=[[UILabel alloc]initWithFrame:CGRectMake(65, 18, 626, 22)];
            self.portionerSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 10, SCREEN_WIDTH, 37)];
            
            self.labelSelectedList=[[UILabel alloc]initWithFrame:CGRectMake(15, 54, 698, 22)];
           
            self.shoppingListSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 49,SCREEN_WIDTH, 40)];
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            {
                self.dropdown_img_portioner=[[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-20*2, 24, 20, 12)];
                self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-20*2, 60, 20, 12)];
            }
            else
            {
                self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(726, 60, 20, 12)];
                self.dropdown_img_portioner=[[UIImageView alloc]initWithFrame:CGRectMake(726, 24, 20, 12)];
            }
        }
        
        self.title_label_ingredient=[[UILabel alloc]initWithFrame:CGRectMake(15, 82, 150, 30)];
        
    }
    
    
    if(portionsStepNumber != -1) {
        [self.tableheaderView addSubview:self.portion_label];
        [self.tableheaderView addSubview:self.label_portion];
        [self.tableheaderView addSubview:self.dropdown_img_portioner];
        [self.tableheaderView addSubview:self.portionerSectionBtn];
    }
    if(ingredients.count>0)
    {
        [self.tableheaderView addSubview:self.labelSelectedList];
        [self.tableheaderView addSubview:self.dropdown_img];
        [self.tableheaderView addSubview:self.shoppingListSectionBtn];
    }
    
    [self.tableheaderView addSubview:self.title_label_ingredient];
    
    
    
    self.title_label_ingredient.text= [NSString stringWithFormat:@"%@ :",NSLocalizedString(@"Ingredients", nil)];
    self.portion_label.text=NSLocalizedString(@"Yield", nil);
    
    [self.portionerSectionBtn addTarget:self action:@selector(portionerSectionBtn:) forControlEvents: UIControlEventTouchUpInside];
    [self.shoppingListSectionBtn addTarget:self action:@selector(shoppingListSectionBtn:) forControlEvents: UIControlEventTouchUpInside];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        picker_portioner.frame=CGRectMake(picker_portioner.frame.origin.x, picker_portioner.frame.origin.y, SCREEN_WIDTH-picker_portioner.frame.origin.x*2, 0);
        picker_view_prtioner.frame=CGRectMake(picker_view_prtioner.frame.origin.x, picker_view_prtioner.frame.origin.y, SCREEN_WIDTH-picker_view_prtioner.frame.origin.x*2,0);

        long test = self.labelSelectedList.frame.origin.y + self.labelSelectedList.frame.size.height;
        
        picker_main_view.frame=CGRectMake(picker_main_view.frame.origin.x, test + 70, SCREEN_WIDTH-picker_main_view.frame.origin.x*2,0);
        picker.frame=CGRectMake(picker.frame.origin.x, test + 70,SCREEN_WIDTH-picker.frame.origin.x*2,216);
    }
    else
    {
        picker_portioner.frame=CGRectMake(picker_portioner.frame.origin.x, picker_portioner.frame.origin.y, picker_portioner.frame.size.width, 0);
        picker_view_prtioner.frame=CGRectMake(picker_view_prtioner.frame.origin.x, picker_view_prtioner.frame.origin.y, picker_view_prtioner.frame.size.width,0);
        
        long test = self.labelSelectedList.frame.origin.y + self.labelSelectedList.frame.size.height;
        
        picker_main_view.frame=CGRectMake(picker_main_view.frame.origin.x, test + 70, picker_main_view.frame.size.width,0);
        picker.frame=CGRectMake(picker.frame.origin.x, test + 70, picker.frame.size.width,216);

    }
    
    
    
    [self.view addSubview:self.tableheaderView];
    picker_view_prtioner.translatesAutoresizingMaskIntoConstraints=YES;
    picker_main_view.translatesAutoresizingMaskIntoConstraints=YES;
    if(ingredients.count>0)
    {
        self.title_label_ingredient.hidden=NO;
    }
    else{
        self.title_label_ingredient.hidden=YES;
        
    }//    return self.tableheaderView;
}
-(UIView*)loadFooterControl:(UITableView *)tableview
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    if(IS_IPHONE)
    {
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            self.tablefooterView=[[UIView alloc]initWithFrame:CGRectMake(tableview.frame.origin.x, tableview.frame.origin.y, tableview.frame.size.width, 165)];
            self.title_textFieldOccasion=[[UILabel alloc]initWithFrame:CGRectMake(15, 9, SCREEN_WIDTH-15*2, 22)];
            
            self.textFieldOccasion=[[UITextField alloc]initWithFrame:CGRectMake(15, 35, SCREEN_WIDTH-15*2, 30)];
            self.title_textcomment=[[UILabel alloc]initWithFrame:CGRectMake(15, 76, SCREEN_WIDTH-15*2, 22)];
            self.textcomment=[[LPlaceholderTextView alloc]initWithFrame:CGRectMake(15, 103, SCREEN_WIDTH-15*2, 45)];
        }
        else
        {
            self.tablefooterView=[[UIView alloc]initWithFrame:CGRectMake(tableview.frame.origin.x, tableview.frame.origin.y, tableview.frame.size.width, 165)];
            self.title_textFieldOccasion=[[UILabel alloc]initWithFrame:CGRectMake(15, 9, 290, 22)];
            
            self.textFieldOccasion=[[UITextField alloc]initWithFrame:CGRectMake(15, 35, 290, 30)];
            self.title_textcomment=[[UILabel alloc]initWithFrame:CGRectMake(15, 76, 290, 22)];
            self.textcomment=[[LPlaceholderTextView alloc]initWithFrame:CGRectMake(15, 103, 290, 45)];

        }
        self.textFieldOccasion.font=[UIFont fontWithName:@"Helvetica" size:15.0f];
        self.textcomment.font=[UIFont fontWithName:@"Helvetica" size:15.0f];
    }
    else
    {
        self.tablefooterView=[[UIView alloc]initWithFrame:CGRectMake(tableview.frame.origin.x, tableview.frame.origin.y, tableview.frame.size.width, 176)];
        self.title_textFieldOccasion=[[UILabel alloc]initWithFrame:CGRectMake(15, 13, 111, 22)];
        
        
        self.title_textcomment=[[UILabel alloc]initWithFrame:CGRectMake(15, 86, SCREEN_WIDTH-15*2, 22)];
        
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {

            self.textFieldOccasion=[[UITextField alloc]initWithFrame:CGRectMake(15, 43,  SCREEN_WIDTH-15*2, 30)];

            self.textcomment=[[LPlaceholderTextView alloc]initWithFrame:CGRectMake(15, 117,SCREEN_WIDTH-15*2, 50)];
        }
        else
        {
            self.textFieldOccasion=[[UITextField alloc]initWithFrame:CGRectMake(15, 43,  738, 30)];
            
            self.textcomment=[[LPlaceholderTextView alloc]initWithFrame:CGRectMake(15, 117, 738, 50)];

        }
        self.textFieldOccasion.font=[UIFont fontWithName:@"Helvetica" size:17.0f];
        self.textcomment.font=[UIFont fontWithName:@"Helvetica" size:17.0f];
    
    }
    
    self.textFieldOccasion.delegate=self;
    [self.textFieldOccasion setBorderStyle:UITextBorderStyleRoundedRect];

    [self.tablefooterView addSubview:self.title_textFieldOccasion];
    [self.tablefooterView addSubview:self.textFieldOccasion];
    [self.tablefooterView addSubview:self.title_textcomment];
    [self.tablefooterView addSubview:self.textcomment];
    //self.textcomment.font=[UIFont fontWithName:font_name size:textcomment_font_size];
    self.textcomment.layer.borderWidth = 0.7f;
    self.textcomment.layer.cornerRadius=5.0f;
    self.textcomment.layer.masksToBounds=YES;
    self.textcomment.layer.borderColor = [UIColor colorWithRed:199.0/255.0 green:199.0/255.0 blue:205.0/255.0 alpha:0.7].CGColor;
    _textcomment.delegate=self;


    self.title_textFieldOccasion.text=[NSString stringWithFormat:@"%@ :",NSLocalizedString(@"occasion", nil)];
    self.title_textFieldOccasion.text=[NSString stringWithFormat:@"%@ :",NSLocalizedString(@"occasion", nil)];
    self.textFieldOccasion.placeholder=NSLocalizedString(@"Weekday,date or event", nil);
    self.title_textcomment.text=[NSString stringWithFormat:@"%@ :",NSLocalizedString(@"Comment", nil)];

    _textcomment.placeholderText=[NSString stringWithFormat:@"%@",NSLocalizedString(@"Comment", nil)];
    _textcomment.placeholderColor=[UIColor lightGrayColor];
    [_textcomment setUserInteractionEnabled:YES];

//    [self.view addSubview:self.tablefooterView];
    
    
    return self.tablefooterView;
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    activeRecipeSaved = NO;
    // ingredients=[[NSMutableArray alloc]init];
    // [ingredients addObject: NSLocalizedString(@"Ingredients",nil)];
    
    // [self loadHeaderControl:self.tableView];
    
    //    [self loadFooterControl];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    temp=NO;
    _textcomment.delegate = self;
    
    if(IS_OS_8_OR_LATER)
    {
        my_screenwidth=SCREEN_WIDTH;
    }
    else
    {
        my_screenwidth=myscreenwidth;
    }
    
    
    dictOfSelectedIngredients = [NSMutableDictionary new];
    
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    
    DataStore *dataStore = [DataStore instance];
    
    recipe = [Recipebox getRecipeById:[NSNumber numberWithLong:dataStore.currentRecipeID]];
     portionType=recipe.portionType;
    // Custom navigationbar
   
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
                [self addTitleBar:64 width:SCREEN_WIDTH];
        }
        else
        {
            if(IS_IPHONE)
            {
                [self addTitleBar:36 width:SCREEN_WIDTH];
            }
            else
            {
                [self addTitleBar:64 width:SCREEN_WIDTH];
            }
        }
   
    cellNames=@[@"cellIngredients"];
    //    cellHeights = @[@0.9];
    //    portions = 100;
    
    lists = [Item_list getAllLists];
    
    //[self setCurrentList];
    [self setListNameAndId:self.activeRecipe.listID];
    
    ingredients = [Ingredient getIngredientsOfRecipeID:recipe.recipeboxID];
    ingredients = [ingredients sortedArrayUsingDescriptors:[self getIngredientsSortOrder]];
    
    [self initSwitches];
    
    btn=[[UIButton alloc]init];
    
    selectablePortions = [[NSMutableArray alloc] init];
    [self getSelectablePortions];

    NSString *portionsFromRecipe;
    if(recipe.sel_portions != nil && ![recipe.sel_portions isEqualToString:@"0"]) {
        portionsFromRecipe = recipe.sel_portions;
    }
    else if(recipe.portions != nil && [recipe.portions intValue] != 0){
        portionsFromRecipe = [NSString stringWithFormat:@"%@", recipe.portions];
    }
    else {
        portionsFromRecipe = nil;
    }
    
    portionsStepNumber = portionsFromRecipe ? (int)[selectablePortions indexOfObject:portionsFromRecipe] : -1;
    
    if(portionsFromRecipe) {
        selected_string = portionsFromRecipe;
    }
    else {
        selected_string = [NSString stringWithFormat:@"%@", recipe.portions];
    }
    
    [self loadHeaderControl:self.tableView];
    
    DLog(@"*************portionsStepNumber:%d",portionsStepNumber);
    isActiveRecipe = [Active_recipe isActiveRecipe:recipe.recipeboxID];
    
    //for getting data first time in check box:
    ingrdient_flagarr=[[NSMutableArray alloc]initWithCapacity:[ingredients count]];
    for(int i=0;i<[ingredients count];i++)
    {
        [ingrdient_flagarr addObject:[NSNumber numberWithInt:0]];
    }
    
    
    
    //self.portion_label.font=[UIFont fontWithName:font_name size:Label_portion_font_size];
    //self.label_portion.font=[UIFont fontWithName:font_name size:Label_portion_font_size];
    
    //Dimple-2-10-2015
    //self.label_portion.text = [NSString stringWithFormat:@" : %@ %@", portions,portionType];
    if(portionsStepNumber >= 0) {
        self.label_portion.text = [NSString stringWithFormat:@" : %@ %@", [selectablePortions objectAtIndex:portionsStepNumber],portionType];
        previous_label_portion=self.label_portion.text;
        [picker_portioner selectRow:portionsStepNumber inComponent:0 animated:YES];
    }
    
    
    //self.labelSelectedList.font=[UIFont fontWithName:font_name size:Label_labelselectedlist_font_size];
    self.labelSelectedList.text = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Shopping List", nil), currentListName];
    
    
    // self.title_label_ingredient.font=[UIFont fontWithName:font_name size:title_label_ingredient_font_size];
    
    
    // self.textFieldOccasion.font=[UIFont fontWithName:font_name size:textfieldoccasion_font_size];
    self.textFieldOccasion.delegate = self;
    
    
    
    
    
    [self closepickerportioner];
    picker_view_prtioner.hidden=YES;
    
    [self closedPicker];
    picker_main_view.hidden=YES;
    
    hiddenView.hidden=YES;
    
    //Raj 15-1-2015
    for (int i=0; i<[lists count]; i++)
    {
        if([[[lists objectAtIndex:i]name]isEqualToString:currentListName])
        {
            return [picker selectRow:i inComponent:0 animated:YES];
        }
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- helper methods

- (NSArray*)getIngredientsSortOrder
{
    NSArray *sort = @[[NSSortDescriptor sortDescriptorWithKey:@"sortableText" ascending:YES]];
    return sort;
}

- (void)setCurrentList
{
    Item_list *list = [DataStore instance].currentList;
    if (list == nil || [list.item_listID intValue] == 0 )
    {
        currentListID = [Item_list getDefaultListId];
        currentListName = [Item_list getDefaultListName];
    }
    else
    {
        currentListID = list.item_listID;
        currentListName = list.name;
    }
}

- (void)setListNameAndId:(NSNumber *)listIdIn
{
    Item_list *belongedList = [Item_list getListById:listIdIn];
    currentListID = belongedList.item_listID;
    currentListName = belongedList.name;
    if(belongedList == nil) {
        Item_list *list = [DataStore instance].currentList;
        if (list == nil || [list.item_listID intValue] == 0 )
        {
            currentListID = [Item_list getDefaultListId];
            currentListName = [Item_list getDefaultListName];
        }
        else
        {
            currentListID = list.item_listID;
            currentListName = list.name;
        }
        
    }
}

- (void)initSwitches
{
    ingredientsNames = [[NSMutableDictionary alloc]init];
    for(Ingredient *ingredient in ingredients)
    {
        [ingredientsNames setObject:ingredient forKey:ingredient.sortableText];
    }
}


#pragma mark-Fixed headerview
- (void)addTitleBar:(int)height width:(int)width
{
    [headerView removeFromSuperview];

    DLog(@" height: %d width :%d",height,width);
    //Creating the plain Navigation Bar
    headerView = [[UINavigationBar alloc] init];
    const CGFloat mainHeaderHeight = height;
    [headerView setFrame:CGRectMake(0, 0, width, mainHeaderHeight)];
    //The UINavigationItem is neede as a "box" that holds the Buttons or other elements
    UINavigationItem *buttonCarrier = [[UINavigationItem alloc]initWithTitle:[NSString stringWithFormat:@"Planera : %@", recipe.title]];
    
    UIBarButtonItem *cancelbutton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onClickCancel:)];
    buttonCarrier.leftBarButtonItem = cancelbutton;
    
    
    
    UIBarButtonItem *okbutton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Ok", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onClickOK:)];
    buttonCarrier.rightBarButtonItem = okbutton;
    
    //The NavigationBar accepts those "Carrier" (UINavigationItem) inside an Array
    NSArray *barItemArray = [[NSArray alloc]initWithObjects:buttonCarrier,nil];
    
    // Attaching the Array to the NavigationBar
    [headerView setItems:barItemArray];
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor blackColor],
                                               NSForegroundColorAttributeName,
                                               [UIFont fontWithName:font_name size:header_font_size],
                                               NSFontAttributeName,
                                               nil];
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    
    [self.view addSubview:headerView];
    
}

/**
 Get pre-defined portions on basis of recipe portions
 @retuen: Returns the index of the currently selected portions in the selectablePortions collection
 @ModifiedDate: September 12, 2015
 @Version:1.14
 @Modified by: Yousuf
 */
- (int)getSelectablePortions
{
    int defaultRecipePortions = [recipe.portions intValue];
    NSString *selectedPortions = recipe.sel_portions;
    
    BOOL showOriginal = true;
    
    if (defaultRecipePortions == 1 || defaultRecipePortions == 0)
    {
        [selectablePortions addObject:@"1/10"];
        [selectablePortions addObject:@"1/8"];
        [selectablePortions addObject:@"1/6"];
        [selectablePortions addObject:@"1/5"];
        [selectablePortions addObject:@"1/4"];
        [selectablePortions addObject:@"1/3"];
        [selectablePortions addObject:@"1/2"];
        [selectablePortions addObject:@"2/3"];
        [selectablePortions addObject:@"3/4"];
        [selectablePortions addObject:@"1"];
        [selectablePortions addObject:@"3/2"];
        [selectablePortions addObject:@"2"];
        [selectablePortions addObject:@"3"];
        [selectablePortions addObject:@"4"];
        [selectablePortions addObject:@"5"];
        [selectablePortions addObject:@"6"];
        [selectablePortions addObject:@"8"];
        [selectablePortions addObject:@"10"];
    }
    else
    {
        [selectablePortions addObject:@"1/10"];
        [selectablePortions addObject:@"1/8"];
        [selectablePortions addObject:@"1/6"];
        [selectablePortions addObject:@"1/5"];
        [selectablePortions addObject:@"1/4"];
        [selectablePortions addObject:@"1/3"];
        [selectablePortions addObject:@"1/2"];
        [selectablePortions addObject:@"2/3"];
        [selectablePortions addObject:@"3/4"];
        [selectablePortions addObject:@"1"];
        [selectablePortions addObject:@"3/2"];
        [selectablePortions addObject:@"2"];
        [selectablePortions addObject:@"3"];
        [selectablePortions addObject:@"4"];
        [selectablePortions addObject:@"5"];
        [selectablePortions addObject:@"6"];
        [selectablePortions addObject:@"8"];
        [selectablePortions addObject:@"10"];
        [selectablePortions addObject:@"12"];
        
        
        for(int i = 10 ; i > 1 ; --i)
        {
            if (defaultRecipePortions % i == 0 && defaultRecipePortions / i > 12)
                [selectablePortions addObject:[NSString stringWithFormat:@"%d", (defaultRecipePortions / i)]];
        }
        
        if (defaultRecipePortions * 2 % 3 == 0 && defaultRecipePortions * 2 / 3 > 12)
            [selectablePortions addObject:[NSString stringWithFormat:@"%d", (defaultRecipePortions * 2 / 3)]];
        
        if (defaultRecipePortions * 3 % 4 == 0 && defaultRecipePortions * 3 / 4 > 12)
            [selectablePortions addObject:[NSString stringWithFormat:@"%d", (defaultRecipePortions * 3 / 4)]];
        
        if (defaultRecipePortions > 12)
            [selectablePortions addObject:[NSString stringWithFormat:@"%d", defaultRecipePortions]];
        
        if (defaultRecipePortions * 4 % 3 == 0 && defaultRecipePortions * 4 / 3 > 12)
            [selectablePortions addObject:[NSString stringWithFormat:@"%d", (defaultRecipePortions * 4 / 3)]];
        
        if (defaultRecipePortions * 3 % 2 == 0 && defaultRecipePortions * 3 / 2 > 12)
            [selectablePortions addObject:[NSString stringWithFormat:@"%d", (defaultRecipePortions * 3 / 2)]];
        
        for(int i = 2 ; i <= 10 ; ++i)
        {
            if (defaultRecipePortions * i > 12)
            {
                [selectablePortions addObject:[NSString stringWithFormat:@"%d", (defaultRecipePortions * i)]];
            }
        }
    }
    
    BOOL foundOriginal = false;
    NSString *portionsString = [NSString stringWithFormat:@"%d", defaultRecipePortions];
    for(int i = 0 ; i != selectablePortions.count; ++i)
    {
        if ([[selectablePortions objectAtIndex:i] isEqualToString:portionsString])
        {
            if (showOriginal)
            {
                NSString *object = [NSString stringWithFormat:@"%@", [selectablePortions objectAtIndex:i]];
                [selectablePortions replaceObjectAtIndex:i withObject:object];
            }
            foundOriginal = true;
            
            if (selectedPortions.length == 0)
                return i;
        }
    }
    
    if (!foundOriginal)
    {
        if (showOriginal)
            [selectablePortions addObject:portionsString];
        else
            [selectablePortions addObject:portionsString];
        
        if (selectedPortions.length == 0)
            return (int)selectablePortions.count-1;
    }
    
    for(int i = 0 ; i != selectablePortions.count; ++i)
    {
        if ([[selectablePortions objectAtIndex:i] isEqualToString:portionsString])
            return i;
    }
    
    // The actual portions value was not found, add it
    [selectablePortions addObject:portionsString];
    
    return (int)selectablePortions.count-1;
}

#pragma mark - Table view data source

//Footer
- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(IS_IPHONE)
    {
        return 167;
    }
    else{
        return 178;
    }
    
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [self loadFooterControl:tableView];
    
}


//Header
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    
    return self.tableheaderView.frame.size.height;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.tableheaderView;
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  ingredients.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellNames[indexPath.section] forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    // Configure the cell...
    
    UILabel *ing_label = (UILabel*)[cell viewWithTag:5];
    //ing_label.font=[UIFont fontWithName:font_name size:Label_ingredient_font_size];
    
    UILabel *label = (UILabel*)[cell viewWithTag:1];
    // label.font=[UIFont fontWithName:font_name size:Label_ingredient_font_size];
    UIButton *button=(UIButton *)[cell viewWithTag:13];
    
    UIImage *selectedImage = [UIImage imageNamed:@"tick.png"];
    UIImage *unselectedImage = [UIImage imageNamed:@"tick_empty.png"];
    
    [button setImage:selectedImage forState:UIControlStateSelected];
    [button setImage:unselectedImage forState:UIControlStateNormal];
    
    ing_label.hidden=YES;
        Ingredient *ingredient = ingredients[indexPath.row];
        label.text = ingredient.text;
        Is_IngredientExits=ingredient.text;
        if ([dictOfSelectedIngredients objectForKey:ingredient.sortableText])
        {
            
            button.selected=[[dictOfSelectedIngredients valueForKey:ingredient.sortableText] boolValue];
            //  DLog(@"--------------------------%d------------------------",button.selected);
            
            // [button setImage:[UIImage imageNamed:@"checked"] forState:UIControlStateNormal];
            
        }
        else
        {
            
            button.selected=[ingredient.isProbablyNeeded boolValue];
            //  DLog(@"--------------------------%d------------------------",button.selected);
            
            // [button setImage:[UIImage imageNamed:@"unchecked"] forState:UIControlStateNormal];
            
            
        }
        [ingrdient_flagarr replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithInt:button.selected]];
        //  DLog(@"Row %ld: %@",(long)indexPath.row, ingredient.text);
        button.property=ingredient.sortableText;
        // DLog(@"flag array: %@",ingrdient_flagarr);
    
    [Ingredient updateIngredient:ingredient WithSelectedStatus:[NSNumber numberWithBool:button.selected] ForRecipe:recipe];
    
    [button addTarget:self action:@selector(onBttonclick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 48.0;
}

#pragma mark - UI events

-(void)onBttonclick:(id)sender{
    UIButton *button=(UIButton *)sender;
    NSString *key =(NSString *)button.property;
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    button_IndexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    //  DLog(@"%ld",(long)button_IndexPath.row);
    
    button.selected=!button.selected;
    
    DLog(@"button selected: %@",[NSNumber numberWithBool:button.selected]);
    if(key !=nil)
    {
        if(button.selected)
        {
            //    DLog(@"%@",[NSNumber numberWithBool:button.selected]);
            
            [dictOfSelectedIngredients setObject:@"1" forKey:key];
            [ingrdient_flagarr replaceObjectAtIndex:button_IndexPath.row withObject:[NSNumber numberWithInt:1]];
        }
        else
        {
            //    DLog(@"%@",[NSNumber numberWithBool:button.selected]);
            
            [dictOfSelectedIngredients setObject:@"0" forKey:key];
            [ingrdient_flagarr replaceObjectAtIndex:button_IndexPath.row withObject:[NSNumber numberWithInt:0]];
        }
        
        Ingredient *ingredient = [ingredientsNames objectForKey:key];
        [Ingredient updateIngredient:ingredient WithSelectedStatus:[NSNumber numberWithBool:button.selected] ForRecipe:recipe];
    }
    
}


/**
 Modifications: Make stepper able to select form pre-defined portions
 @ModifiedDate: September 12, 2015
 @Version:1.14
 @Modified by: Yousuf
 */

- (IBAction)onClickCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onClickOK:(id)sender
{
    if(!isClosedPortioner) {
        [self portionerSectionBtn: nil];
    }
    else if(!isClosedListPicker) {
        [self shoppingListSectionBtn: nil];
    }
    else {
    //insert active recipe locally
        if(!recipe.sel_portions) {
            recipe.sel_portions = [NSString stringWithFormat:@"%@", recipe.portions];
        }
        
        NSMutableArray *ingredientList = [[NSMutableArray alloc]init];
        for (Ingredient *ingredient in ingredients) {
            if (ingredient.isSelected != nil && [ingredient.isSelected boolValue] == YES) {
                [ingredientList addObject:[ingredient getJSONforActiveRecipe]];
            }
        }

        [Active_recipe insertActiveRecipeWith:recipe.recipeboxID andPortions:recipe.sel_portions withIngredients:ingredientList forOccasion:self.textFieldOccasion.text andNotes:_textcomment.text inList:currentListID];
        [[SyncManager sharedManager] forceSync];
        if(ingredientList.count == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
            //[self dismissViewControllerAnimated:YES completion:nil];
            activeRecipeSaved = YES;
        }
    }
}

#pragma mark - server communication

-(void)didUpdateItems
{
    DLog(@"Items changed: %@\nRecipe saved: %@", [SignificantChangesIndicator sharedIndicator].itemsChanged ? @"Y" : @"N", activeRecipeSaved ? @"Y" : @"N");
    if([SignificantChangesIndicator sharedIndicator].recipeChanged)
    {
        ingredients = [[Ingredient getIngredientsOfRecipeID:recipe.recipeboxID] sortedArrayUsingDescriptors:[self getIngredientsSortOrder]];
        [self initSwitches];
        [self.tableView reloadData];
        
        [SVProgressHUD dismiss];
        //[self setFavoriteStoreName];
        [[SignificantChangesIndicator sharedIndicator] resetData];
    }
    else if(/*[SignificantChangesIndicator sharedIndicator].itemsChanged && */activeRecipeSaved) {
        activeRecipeSaved = NO;
        [SVProgressHUD dismiss];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[SignificantChangesIndicator sharedIndicator] resetData];
    }
}

/**
 Send the new portions to the server and get the updated quantity for each ingredient
 */
-(void)sendIngredientsUpdates
{
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
    [Recipebox changePortionsWith:selected_string forRecipe:recipe];
    [[SyncManager sharedManager] forceSync];
}

#pragma mark - picker view

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    //Dimple-2-10-2015
    if(pickerView.tag==1)
    {
        return selectablePortions.count;
    }
    else
    {
        return lists.count;
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    //Dimple-2-10-2015
    if(pickerView.tag==1)
    {
        selectedListIndex = row;
        if (selectablePortions !=nil)
        {
            self.label_portion.text = [NSString stringWithFormat:@" : %@ %@",[selectablePortions objectAtIndex:row],portionType];
            selected_string = [selectablePortions objectAtIndex:row];
            DLog(@"label Portion %@",self.label_portion.text);
        }
    }
    else
    {
        selectedListIndex = row;
        Item_list *list = (Item_list*)lists[row];
        if (self.labelSelectedList !=nil)
        {
            currentListName = list.name;
            self.labelSelectedList.text = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Shopping List", nil), currentListName];
            currentListID = list.item_listID;
        }
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    //Dimple-2-10-2015
    if(pickerView.tag==1)
    {
        NSString *value = [selectablePortions objectAtIndex:row];
        NSString *original = [NSString stringWithFormat:@"%@", recipe.portions];
        
        if([original isEqualToString:value]) {
            return [NSString stringWithFormat:@"%@ (%@)", value, NSLocalizedString(@"original", nil)];
        }
        else {
            return value;
        }
    }
    else
    {
        Item_list *list = (Item_list*)lists[row];
        return list.name;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return pickerView.frame.size.width;
}

#pragma mark - show/Hide keyboard
//Dimple-2-10-2015
- (void)keyboardWillShow:(NSNotification *)sender
{
    CGSize kbSize = [[[sender userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSTimeInterval duration = [[[sender userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 0, kbSize.height+3, 0);
        [self.tableView setContentInset:edgeInsets];
        [self.tableView setScrollIndicatorInsets:edgeInsets];
        
        if(IS_IPHONE)
        {
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            {
                if(ingredients.count>0)
                {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ingredients.count-1 inSection:0];
                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                    
                }
                else{
                    if(iphone4)
                    {
                        [self.tableView setContentOffset:CGPointMake(0,70)];
                    }
                    
                }
            }
            else{
                if(ingredients.count>0)
                {
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ingredients.count-1 inSection:0];
                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }
                else{
                    [self.tableView setContentOffset:CGPointMake(0, SCREEN_HEIGHT/2.2)];
                }
                
            }
        }
        else{
            if(ingredients.count>0)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ingredients.count-1 inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
        
    }];
    
    
}

- (void)keyboardWillHide:(NSNotification *)sender
{
    NSTimeInterval duration = [[[sender userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        UIEdgeInsets edgeInsets = UIEdgeInsetsZero;
        [self.tableView setContentInset:edgeInsets];
        [self.tableView setScrollIndicatorInsets:edgeInsets];
    }];
}




#pragma mark-textfield delegate method
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark-textview delegate method
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

-(void)textViewDidBeginEditing:(LPlaceholderTextView *)textView
{
}

#pragma mark- Picker open-close
-(void)openPicker_portioner
{
    
    _shoppingListSectionBtn.hidden=YES;
    
    previous_label_portion=self.label_portion.text;
    self.tableView.scrollEnabled=NO;
    picker_view_prtioner.hidden=NO;
    hiddenView.hidden=NO;
  
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        picker_view_prtioner.frame=CGRectMake(picker_view_prtioner.frame.origin.x, headerView.frame.origin.y+headerView.frame.size.height+12+self.label_portion.frame.size.height+self.label_portion.frame.origin.y, SCREEN_WIDTH-picker_view_prtioner.frame.origin.x*2,180);
    }
    else
    {
        picker_view_prtioner.frame=CGRectMake(picker_view_prtioner.frame.origin.x, headerView.frame.origin.y+headerView.frame.size.height+12+self.label_portion.frame.size.height+self.label_portion.frame.origin.y,picker_view_prtioner.frame.size.width,180);

    }
    picker_portioner.frame=CGRectMake(0,0, picker_view_prtioner.frame.size.width, 216);

    
    self.dropdown_img_portioner.image=[UIImage imageNamed:@"upimg.png"];
    
    isClosedPortioner=false;
    [UIView animateWithDuration:0.2
                          delay:20
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         picker_portioner.hidden=NO;
                         
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
    
    
}

-(void)closepickerportioner
{
    _shoppingListSectionBtn.hidden=NO;
    
    self.dropdown_img_portioner.image=[UIImage imageNamed:@"downimg.png"];
    
    
    picker_view_prtioner.frame=CGRectMake(picker_view_prtioner.frame.origin.x, picker_view_prtioner.frame.origin.y, picker_view_prtioner.frame.size.width,0);
    
    picker_portioner.frame=CGRectMake(0, 0, picker_view_prtioner.frame.size.width, 216);

    [UIView animateWithDuration:0.2
                          delay:20
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // picker_portioner.hidden=NO;
                     }
                     completion:^(BOOL finished){
                         
                         picker_portioner.hidden=YES;
                         isClosedPortioner=true;
                         
                         //Network call
                         DLog(@"previous_label_portion:%@ ||lbl value :%@ ",previous_label_portion,self.label_portion.text);
                         if(self.label_portion.text && ![previous_label_portion isEqualToString:self.label_portion.text])
                         {
                             previous_label_portion = self.label_portion.text;
                             [self sendIngredientsUpdates];
                         }
                         
                     }];
    
    self.tableView.scrollEnabled=YES;
    
    
}

-(void)openPicker
{
    _portionerSectionBtn.hidden=YES;
    self.tableView.scrollEnabled=NO;
    
    picker_main_view.hidden=NO;
    
    hiddenView.hidden=NO;
    hiddenView_upper.hidden=NO;
    hiddenView_bottom.hidden=NO;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        picker_main_view.frame=CGRectMake(picker_main_view.frame.origin.x, headerView.frame.origin.y+headerView.frame.size.height+12+self.labelSelectedList.frame.size.height+self.labelSelectedList.frame.origin.y, SCREEN_WIDTH-picker_main_view.frame.origin.x*2,180);
    }
    else
    {
        picker_main_view.frame=CGRectMake(picker_main_view.frame.origin.x, headerView.frame.origin.y+headerView.frame.size.height+12+self.labelSelectedList.frame.size.height+self.labelSelectedList.frame.origin.y, picker_main_view.frame.size.width,180);

    }
    picker.frame=CGRectMake(0, 0, picker_main_view.frame.size.width, 216);
    
    
    
    self.dropdown_img.image=[UIImage imageNamed:@"upimg.png"];
    
    isClosedListPicker=false;
    [UIView animateWithDuration:0.2
                          delay:20
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         picker.hidden=NO;
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
}
-(void)closedPicker
{
    _portionerSectionBtn.hidden=NO;
    
    self.dropdown_img.image=[UIImage imageNamed:@"downimg.png"];
    
    
    picker_main_view.frame=CGRectMake(picker_main_view.frame.origin.x, picker_main_view.frame.origin.y, picker_main_view.frame.size.width, 0);
    picker.frame=CGRectMake(0,0, picker_main_view.frame.size.width,216);
    
    
    picker.hidden=YES;
    isClosedListPicker=true;
    hiddenView_upper.hidden=YES;
    hiddenView_bottom.hidden=YES;
    
    hiddenView.hidden=YES;
    self.tableView.scrollEnabled=YES;
    
}
#pragma mark-orientation change
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    
    [self closedPicker];
    [self closepickerportioner];
    [headerView removeFromSuperview];
    
    picker_portioner.hidden=YES;
    picker_view_prtioner.hidden=YES;
    picker_main_view.hidden=YES;
    picker.hidden=YES;
    
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self addTitleBar:64 width:SCREEN_WIDTH];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    if(portionsStepNumber == -1) {
        self.labelSelectedList.frame=CGRectMake(15, 34, 266, 22);
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            self.dropdown_img=[[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-20*2, 40, 20, 12)];
            self.shoppingListSectionBtn=[[UIButton alloc]initWithFrame:CGRectMake(15, 31, SCREEN_WIDTH, 30)];
        }
        else
        {
            self.dropdown_img.frame=CGRectMake(285, 40, 20, 12);
            self.shoppingListSectionBtn.frame=CGRectMake(15, 31, SCREEN_WIDTH, 30);
        }
    }
    else {
        self.portion_label=[[UILabel alloc]initWithFrame:CGRectMake(15,18, 84, 22)];
        self.label_portion=[[UILabel alloc]initWithFrame:CGRectMake(65, 18, 206, 22)];
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            self.dropdown_img_portioner.frame=CGRectMake(SCREEN_WIDTH-20*2, 24, 20, 12);
            self.portionerSectionBtn.frame=CGRectMake(15, 15, SCREEN_WIDTH, 30);
            
            self.dropdown_img.frame=CGRectMake(SCREEN_WIDTH-20*2, 60, 20, 12);
            self.shoppingListSectionBtn.frame=CGRectMake(15, 47,SCREEN_WIDTH, 30);
        }
        else
        {
            if(IS_IPHONE)
            {
                self.dropdown_img_portioner.frame=CGRectMake(285, 24, 20, 12);
                self.portionerSectionBtn.frame=CGRectMake(15, 15, 310, 28);
                self.dropdown_img.frame=CGRectMake(285, 60, 20, 12);
                self.shoppingListSectionBtn.frame=CGRectMake(15, 47, 310, 30);
            }
            else
            {
                self.dropdown_img.frame=CGRectMake(726, 60, 20, 12);
                self.dropdown_img_portioner.frame=CGRectMake(726, 24, 20, 12);
                self.portionerSectionBtn.frame=CGRectMake(15, 10, SCREEN_WIDTH, 37);
                self.shoppingListSectionBtn.frame=CGRectMake(15, 49, SCREEN_WIDTH, 40);
            }
        }
        self.labelSelectedList.frame=CGRectMake(15, 51, 266, 22);
    }

    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        picker_portioner.frame=CGRectMake(picker_portioner.frame.origin.x, picker_portioner.frame.origin.y, SCREEN_WIDTH-picker_portioner.frame.origin.x*2, 0);
        picker_view_prtioner.frame=CGRectMake(picker_view_prtioner.frame.origin.x, picker_view_prtioner.frame.origin.y, SCREEN_WIDTH-picker_view_prtioner.frame.origin.x*2,0);
        
        long test = self.labelSelectedList.frame.origin.y + self.labelSelectedList.frame.size.height;
        
        picker_main_view.frame=CGRectMake(picker_main_view.frame.origin.x, test + 70, SCREEN_WIDTH-picker_main_view.frame.origin.x*2,0);
        picker.frame=CGRectMake(picker.frame.origin.x, test + 70,SCREEN_WIDTH-picker.frame.origin.x*2,216);
        
    }
    else
    {
       
            picker_portioner.frame=CGRectMake(picker_portioner.frame.origin.x, picker_portioner.frame.origin.y, self.dropdown_img.frame.size.width+self.dropdown_img.frame.origin.x, 0);
            picker_view_prtioner.frame=CGRectMake(picker_view_prtioner.frame.origin.x, picker_view_prtioner.frame.origin.y,self.dropdown_img.frame.size.width+self.dropdown_img.frame.origin.x,0);
            
            long test = self.labelSelectedList.frame.origin.y + self.labelSelectedList.frame.size.height;
            
            picker_main_view.frame=CGRectMake(picker_main_view.frame.origin.x, test + 70, self.dropdown_img.frame.size.width+self.dropdown_img.frame.origin.x,0);
            picker.frame=CGRectMake(picker.frame.origin.x, test + 70,self.dropdown_img.frame.size.width+self.dropdown_img.frame.origin.x,216);
        
      }
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.textFieldOccasion.frame=CGRectMake(15, 43,  SCREEN_WIDTH-15*2, 30);
        self.textcomment.frame=CGRectMake(15, 117,SCREEN_WIDTH-15*2, 50);
    }
    else
    {
        if(IS_IPHONE)
        {
            self.textFieldOccasion.frame=CGRectMake(15, 35, 290, 30);
            self.textcomment.frame=CGRectMake(15, 103, 290, 45);
        }
        else
        {
            self.textFieldOccasion.frame=CGRectMake(15, 43,  738, 30);
            self.textcomment.frame =CGRectMake(15, 117, 738, 50);
        }
    }
    [self.tableView reloadData];
  
    
    
    _portionerSectionBtn.hidden=NO;
    _shoppingListSectionBtn.hidden=NO;
    
    
    hiddenView.hidden=YES;
    hiddenView_bottom.hidden=YES;
    hiddenView_upper.hidden=YES;
    
    [self closedPicker];
    [self closepickerportioner];
    
    picker_portioner.hidden=YES;
    picker_view_prtioner.hidden=YES;
    picker_main_view.hidden=YES;
    picker.hidden=YES;
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        [self addTitleBar:64 width:SCREEN_WIDTH];
    }
    else
    {
        if(IS_IPHONE)
        {
            if ([UIApplication sharedApplication].isStatusBarHidden) {
                [self addTitleBar:36 width:SCREEN_WIDTH];
            }
            else
            {
                [self addTitleBar:64 width:SCREEN_WIDTH];

            }
        }
        else
        {
            [self addTitleBar:64 width:SCREEN_WIDTH];
        }
    }

   }
#pragma mark- open and close portioner picker
- (IBAction)portionerSectionBtn:(id)sender
{
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if(isClosedPortioner)
                         {
                             [self openPicker_portioner];
                             hiddenView.hidden=NO;
                             
                         }
                         else{
                             
                             [self closepickerportioner];
                             hiddenView.hidden=YES;
                             
                         }
                         
                     }
                     completion:^(BOOL finished){
                         
                     }];
    [UIView commitAnimations];
    
}
#pragma mark- open and close shoppingList picker

- (IBAction)shoppingListSectionBtn:(id)sender
{
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if(isClosedListPicker)
                         {
                             [self openPicker];
                             hiddenView.hidden=YES;
                             hiddenView_upper.hidden=NO;
                             hiddenView_bottom.hidden=NO;
                             
                         }
                         else{
                             
                             [self closedPicker];
                             hiddenView.hidden=YES;
                             hiddenView_upper.hidden=YES;
                             hiddenView_bottom.hidden=YES;
                             
                         }
                         
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
    [UIView commitAnimations];
    
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    picker_main_view.hidden=YES;
    picker_view_prtioner.hidden=YES;
    
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [self addTitleBar:64 width:SCREEN_WIDTH];

    CLS_LOG(@"Showing RecipePlanTableViewController");
}
@end
