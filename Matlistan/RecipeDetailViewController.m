//
//  RecipeDetailViewController.m
//  MatListan
//
//  Created by Yan Zhang on 25/03/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "RecipeDetailViewController.h"
#import "RecipesViewController.h"
#import "ItemsViewController.h"
#import "RecipePlanTableViewController.h"
#import "AppDelegate.h"
#import "PlanFoodViewController.h"
#import "HelpDialogManager.h"
#import "SignificantChangesIndicator.h"
#import "AddNewRecipeViewVC.h"

static NSInteger maxRecentlyViewedItems = 5;//limit the recently viewed recipies to 30 so that list do not get bigger and bigger
//static NSString *appLink = @"matlistan://";
static NSString *htmlStyle = @"<font face='Helvetica' size='5'><meta name='viewport' content='width=device-width; initial-scale=1.0; maximum-scale=5.0; user-scalable=YES'/>";

@interface RecipeDetailViewController ()<UITextViewDelegate>
{
    NSArray *cellNames;
    Recipebox *recipe;
    NSString *buttonText;
    NSString *ingredientsHTML;
    NSString *instructionHTML;
    NSString *ingredientsHTMLContent;
    NSString *instructionHTMLContent;
    NSString *combinedHTML;
    NSString *verticalHTML;
    int ingredientLines;
    float webViewHeight;
    int totalLineCharacters;
    NSString *screenRedirection;
    
    NSString *notesHTML;
    NSString *notesHTMLContent;
    
    NSString *tipsHTML;
    NSString *tipsHTMLContent;
    
    
    NSMutableArray *selectablePortions;
    BOOL is_open;
    NSString *selected_string;
    NSNumber *currentListID;
    NSRange rSub;
    NSMutableString *searchstr;
    NSMutableArray *ingredienttext_arr;
    NSString *hyperTxt;
    
    NSMutableAttributedString *attributedString;
    NSLayoutManager *layoutManager;
    NSTextContainer *textContainer;
    NSTextStorage *textStorage;
    NSString *portion_substring,*source_substring;
    NSRange portion_range,source_range;
    
    NSMutableAttributedString *res;
    UIFont *newFont;
    NSAttributedString *attr;
    NSNumber *font_size;
    
    NSTimer *timer;
    int hours, minutes, seconds;
    int secondsLeft;
    UILocalNotification *notification;
    NSMutableArray *hoursArray;
    NSMutableArray *minsArray;
    NSMutableArray *secsArray;
    
    NSTimeInterval interval;
    UILabel *hourLabel,*minsLabel,*secsLabel;
    int hr_x,min_x,sec_x;
    NSString* descString,*TimeNumstr;
    BOOL is_dropDownOpen;
}

@end

@implementation RecipeDetailViewController

@synthesize recipeboxId, barButtonType, activeRecipe,picker_timer;

#pragma mark - set pickerview label value

-(void)setPickerLabel:(int)n
{
    [hourLabel removeFromSuperview];
    [minsLabel removeFromSuperview];
    [secsLabel removeFromSuperview];

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        if(IS_IPHONE)
        {
            hr_x=min_x=63+5;
            sec_x=63+7;

        }
        else{
            if(IS_IPAD_PRO)
            {
                hr_x=min_x=sec_x=162+50;
            }
            else
            {
                hr_x=min_x=sec_x=162;
            }
        }
    }
    else{
        if(IS_IPHONE)
        {
            hr_x=120;
            min_x=120+ n;
            sec_x=120+ (2*n);
        }
        else{
            if([UIScreen mainScreen].bounds.size.width == 1366)
            {
                hr_x=220+50;
                min_x=220 +50;
                sec_x=220 +(2*25);
            }
            else
            {
                hr_x=220;
                min_x=220 +n;
                sec_x=220 +(2*n);
            }
        }
        
    }
    hourLabel = [[UILabel alloc] initWithFrame:CGRectMake(hr_x, picker_timer.frame.size.height / 2 - 15, 75, 30)];
    DLog(@"hourLabel: %f",hourLabel.frame.origin.x);
    minsLabel = [[UILabel alloc] initWithFrame:CGRectMake(min_x + (picker_timer.frame.size.width / 3),picker_timer.frame.size.height / 2 - 15, 75, 30)];
    DLog(@"minlabel: %f",minsLabel.frame.origin.x);
    
    secsLabel = [[UILabel alloc] initWithFrame:CGRectMake(sec_x + ((picker_timer.frame.size.width / 3) * 2), picker_timer.frame.size.height / 2 - 15, 75, 30)];
    DLog(@"seclabel: %f",secsLabel.frame.origin.x);
    
    hourLabel.text = [NSString stringWithFormat:@" %@",NSLocalizedString(@"hour", nil)];
    [picker_timer addSubview:hourLabel];
    minsLabel.text =[NSString stringWithFormat:@" %@",NSLocalizedString(@"min", nil)];
    [picker_timer addSubview:minsLabel];
    secsLabel.text =  [NSString stringWithFormat:@" %@",NSLocalizedString(@"sec", nil)];
    [picker_timer addSubview:secsLabel];
}

-(void)setValueInPickerView
{
    hoursArray = [[NSMutableArray alloc] init];
    minsArray = [[NSMutableArray alloc] init];
    secsArray = [[NSMutableArray alloc] init];
    NSString *strVal = [[NSString alloc] init];
    
    for(int i=0; i<60; i++)
    {
        strVal = [NSString stringWithFormat:@"%d", i];
        
        if (i < 12)
        {
            [hoursArray addObject:strVal];
        }
        
        //create arrays with 0-60 secs/mins
        [minsArray addObject:strVal];
        [secsArray addObject:strVal];
    }
}

//Dimple - 9-10-15
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    is_dropDownOpen=true;
    [self addBarButtons];

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height+20;
    }
    else
    {
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height;
    }
    
    if(IS_IPHONE)
    {
        self.more_tableview.translatesAutoresizingMaskIntoConstraints=YES;
        self.more_tableview.frame=CGRectMake(SCREEN_WIDTH-self.more_tableview.frame.size.width-more_tbl_distance-1, navigationBarHeight, self.more_tableview.frame.size.width, 0);
    }
    
    
    (theAppDelegate).currentRecipeDetailController = self;
    [self timerBtnShoworNot];
    
   
    [SyncManager sharedManager].syncManagerDelegate = self;
    if((theAppDelegate).customImage!=nil)
    {
        self.navigationController.navigationBarHidden=YES;
        self.imageView.hidden=NO;
        self.imageView.image=(theAppDelegate).customImage;
        (theAppDelegate).customImage=nil;
        
    }
    else{
        self.navigationController.navigationBarHidden=NO;
        self.imageView.hidden=YES;
        
    }
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }
}
-(void)reloadTableview
{
    [self.timerWindowTbl reloadData];
    if (is_timerWindow_open || is_timerListOpen) {
        
        is_timerListOpen=false;
        [self openNotificationWindow];
        is_timerWindow_open=false;
    }
    else
    {
        is_timerWindow_open=true;
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    (theAppDelegate).currentRecipeDetailController = self; //since it is weak, each time it will be override by otehr detailcontroller object

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableview) name:@"reloadTableViewData" object:nil];

    self.more_tableview.tag=1;
    if(IS_IPHONE)
    {
        more_tableview_height=72;
        more_tbl_distance=6;
    }
    else
    {
        more_tableview_height=93;
        more_tbl_distance=8;
    }

    is_timerListOpen=true;
    self.timerWindowBtn.translatesAutoresizingMaskIntoConstraints=YES;
    [self.timerWindowBtn setImage:[UIImage imageNamed:@"backimg_white"] forState:UIControlStateNormal];
    self.timerWindowBtn.layer.cornerRadius=2;
    self.timerWindowBtn.layer.masksToBounds=YES;
    
   
    if(IS_IPHONE)
    {
        expand_height=106;
        collaps_height=54;
    }
    else
    {
        expand_height=152;
        collaps_height=77;
    }
    
    UIPinchGestureRecognizer *pinchGestRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    pinchGestRecognizer.delegate = self;
    [_textview addGestureRecognizer:pinchGestRecognizer];
    _textview.userInteractionEnabled=true;
    [_textview setEditable:NO];
    self.automaticallyAdjustsScrollViewInsets=NO;
    

//    //Dimple
    if((theAppDelegate).open_from_notification)
    {
        NSString *str1=[Utility getTimerRecipeId];
        [Utility setTimerRecipeId:nil];
        NSNumber *num1 = @([str1 intValue]);
        recipeboxId=num1;
        (theAppDelegate).open_from_notification=false;
        
        //Remove particular notification from notification bar
        NSData *data= [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"uniqueRecipeId_%@",recipeboxId]];
        if(data!=nil)
        {
            UILocalNotification *localNotif = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            NSLog(@"Remove localnotification  are %@", localNotif);
            [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"uniqueRecipeId_%@",recipeboxId]];
            
        }
    }
    
    
    self.navigationController.navigationBar.tintColor  = [Utility getGreenColor];
    //Dimple
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        textview_y=64;
    }
    else
    {
        if ([UIApplication sharedApplication].isStatusBarHidden) {
            textview_y=self.navigationController.navigationBar.frame.size.height;
        }
        else{
            textview_y=self.navigationController.navigationBar.frame.size.height+20;

        }

    }
    [self setValueInPickerView];
    //

    [self.okBtn setTitle:NSLocalizedString(@"Ok",nil) forState:UIControlStateNormal];
    [self.cancelBtn setTitle:NSLocalizedString(@"Cancel",nil) forState:UIControlStateNormal];
    [self.OkPicker_click setTitle:NSLocalizedString(@"Ok",nil) forState:UIControlStateNormal];
    [self.CancelPicker_click setTitle:NSLocalizedString(@"Cancel",nil) forState:UIControlStateNormal];
    
    
    
    SWRevealViewController *revealController = self.revealViewController;
    revealController=[[SWRevealViewController alloc]init];
    revealController = [self revealViewController];
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    revealController.delegate=self;
    revealController.panGestureRecognizer.enabled = YES;
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    //Dimple 9-10-15
    if([self.screen_name isEqualToString:@"Recent"])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GotoList) name:@"MYLISTREDIRECT" object:nil];
        
        screenRedirection=[[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"%@",recipeboxId]];
        //      DLog(@"screenRedirection:%@",screenRedirection);
        
    }
    
    
    //  DLog(@"bar button %d", barButtonType);
    
    CLSLog(@"recipe detail >> display recipeboxId:%@",recipeboxId);
    
    if ([[DataStore instance].viewedRecipes count] < maxRecentlyViewedItems) {
        if (![[DataStore instance].viewedRecipes containsObject:recipeboxId]) {
            [self addItemToTheRecentlyViewedList:recipeboxId];
        }else{
            NSUInteger indexIn = [[DataStore instance].viewedRecipes indexOfObject:recipeboxId];
            [self sortCurrentArray:indexIn];
        }
    }else{
        if (![[DataStore instance].viewedRecipes containsObject:recipeboxId]) {
            [[DataStore instance].viewedRecipes removeLastObject];
            [self addItemToTheRecentlyViewedList:recipeboxId];
            [self sortCurrentArray:[[DataStore instance].viewedRecipes indexOfObject:recipeboxId]];
        }else{
            [self sortCurrentArray:[[DataStore instance].viewedRecipes indexOfObject:recipeboxId]];
        }
    }
    
    SWRevealViewController *reveal = self.revealViewController;
    
    if((theAppDelegate).detailRecipeFlag)
    {
        reveal.panGestureRecognizer.enabled = NO;
        (theAppDelegate).detailRecipeFlag=false;
        
    }
    else{
        reveal.panGestureRecognizer.enabled = YES;
        (theAppDelegate).detailRecipeFlag=true;
        
    }
    [self setTotalLineCharacters];  //get total characters for counting rows and hence the height of cell
    recipe = [Recipebox getRecipeById:recipeboxId];
    [self loadDatatoWebView];
    
    
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
    
    Item_list *list = [DataStore instance].currentList;
    currentListID= list.item_listID;
    
    [self setListNameAndId:self.activeRecipe.listID];
    
    
    //Dimple
    selectablePortions = [[NSMutableArray alloc] init];
    [self getSelectablePortions];
    self.Picker_View.frame=CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, self.Picker_View.frame.size.height);
    self.Picker.frame=CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, self.Picker.frame.size.height);
    
    //Timer picker
   picker_timer.dataSource = self;
    picker_timer.delegate = self;
   [self.timeView addSubview:picker_timer];
    self.headerBtn.frame=CGRectMake(0, 0, SCREEN_WIDTH, 44);
   self.timeView.frame=CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, self.timeView.frame.size.height);
   picker_timer.frame=CGRectMake(0, self.headerBtn.frame.size.height, SCREEN_WIDTH, picker_timer.frame.size.height);
    //
    
    selected_string=recipe.sel_portions;
    if(selected_string == nil && recipe.portions) {
        selected_string = [NSString stringWithFormat:@"%@", recipe.portions];
    }
    if([selectablePortions indexOfObject:selected_string] != NSNotFound) {
        [self.Picker selectRow:[selectablePortions indexOfObject:selected_string] inComponent:0 animated:YES];
    }
    
    self.timerWindowTbl.tableHeaderView=[[UIView alloc]init];
    is_timerWindow_open=true;
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        CGRect frame=self.bannerView.frame;
        frame.size.height=0;
        frame.origin.x=0;
        frame.origin.y=SCREEN_HEIGHT;
        self.bannerView.frame=frame;
    }
    self.timerWindowTbl = [[UITableView alloc] init];
    int y= SCREEN_HEIGHT-self.bannerView.frame.size.height-collaps_height*_timerOnRecipes.count;
    int h=collaps_height*(int)_timerOnRecipes.count;
    NSLog(@"self.textview.frame.origin.y:%f",self.textview.frame.origin.y);

    if(h>SCREEN_HEIGHT-self.bannerView.frame.size.height-textview_y-10-self.timerWindowBtn.frame.size.height)
    {
        self.timerWindowTbl.frame=CGRectMake(0,textview_y+self.timerWindowBtn.frame.size.height+10, SCREEN_WIDTH,SCREEN_HEIGHT-self.bannerView.frame.size.height-textview_y-10-self.timerWindowBtn.frame.size.height);
        
    }
    else
    {
        self.timerWindowTbl.frame=CGRectMake(0,y, SCREEN_WIDTH,h);
    }
    self.timerWindowBtn.frame=CGRectMake(SCREEN_WIDTH-self.timerWindowBtn.frame.size.width, self.timerWindowTbl.frame.origin.y-self.timerWindowBtn.frame.size.height, self.timerWindowBtn.frame.size.width, self.timerWindowBtn.frame.size.height);

    self.timerWindowTbl.dataSource = self;
    self.timerWindowTbl.delegate = self;
    self.timerWindowTbl.tag=2;
    [self.view addSubview:self.timerWindowTbl];
    self.timerWindowTbl.separatorStyle=NO;
    self.timerWindowTbl.backgroundColor=[UIColor colorWithRed:240.0/255.0 green:243.0/255.0 blue:245.0/255.0 alpha:1.0];
    
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    [self.timerWindowBtn addGestureRecognizer:pan];
    
    (theAppDelegate).globalRecipeId=[NSString stringWithFormat:@"%@",recipeboxId];
    [self sendAnalytics];
}
#pragma mark-assign Html To Label
-(void)assignHtmlToLabel
{
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    {
        attributedString = [[NSMutableAttributedString alloc] initWithData:[combinedHTML dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
    }
    else
    {
        attributedString = [[NSMutableAttributedString alloc] initWithData:[verticalHTML dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
    }
    _textview.attributedText = attributedString;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        font_size=[Utility getPortraitFont];
    }
    else
    {
        font_size=[Utility getLandscapeFont];
    }
    
    if(font_size!=0)
    {
        res = [self.textview.attributedText mutableCopy];
        [res beginEditing];
        __block BOOL found = NO;
        [res enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, res.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (value) {
                UIFont *oldFont = (UIFont *)value;
                CGFloat pointSize = [font_size floatValue];
                
                UIFont *font_1;
                font_1 = [oldFont fontWithSize:pointSize];
                
                [res removeAttribute:NSFontAttributeName range:range];
                [res addAttribute:NSFontAttributeName value:font_1 range:range];
                _textview.attributedText = res;
                [_textview setEditable:NO];
                found = YES;
            }
        }];
        if (!found) {
            // No font was found - do something else?
        }
        
        [res endEditing];
    }
    //[_textview sizeToFit];
}

-(void)loadDatatoWebView
{
    //Convert recipe ingredients to html
    [self makeIngredientsWeb];
    
    //Convert Recipe tips to html
    [self makeTipsWeb];
    
    //Convert Recipe Notes to html
    [self makeNotesWeb];
    
    //Convert instruction to html
    [self makeInstructionsWeb];
    [self makeCombinedHTML];
    [self assignHtmlToLabel];
    
}
-(void)GotoList
{
    //  DLog(@"screenRedirection:%@",screenRedirection);
    if([screenRedirection isEqualToString:@"PlanFoodScreen"])
    {
        RecipesViewController *secondViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PlanList"];
        self.navigationController.navigationBarHidden=NO;
        self.navigationController.viewControllers = @[secondViewController];
    }
    else if([screenRedirection isEqualToString:@"RecipeScreen"]){
        PlanFoodViewController *secondViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Recipes"];
        self.navigationController.navigationBarHidden=NO;
        self.navigationController.viewControllers = @[secondViewController];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self setPickerLabel:0];

    CLS_LOG(@"Showing RecipeDetailViewController");
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self];
    [self.timerWindowTbl reloadData];// hear we refreshing the timer table, weather or not timer objects are present , just refresh it to show timer updates (only works if we set the timerdelage of timer object)

}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    for(RecipeTimer *recipes in _timerOnRecipes)
        recipes.recipeTimerdelegate = nil;
    //(theAppDelegate).currentRecipeDetailController = nil;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPremiumAccountPurchased object:nil];
}

/**
 Remove ads if user has purchased premium
 @ModifiedDate: October 7 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)removeAds
{
    if (self.bannerView)
    {
        [self.bannerView removeConstraints:self.bannerView.constraints];
        [self.bannerView removeFromSuperview];
        CGRect frame=self.bannerView.frame;
        frame.size.height=0;
        frame.origin.x=0;
        frame.origin.y=SCREEN_HEIGHT;
        self.bannerView.frame=frame;
        [Utility updateConstraint:self.view toView:self.textview withConstant:0];
    }
}

#pragma mark - buttons and their events

/* Init the buttons on the navigation bar
 What the Android app looks like:
 The buttons are different according to where the segue is from and the recipe's isPurchased and active status
 Segue from PlanFoodViewController -
 "Recept att handla"  - delete, edit
 "Recept att tillaga" - comment cooked recipe, edit
 segue from RecipesViewController -
 Recept har handlats - comment cooked recipe, edit
 Recept inte har en active recipe - plan, edit
 */
-(void)addBarButtons
{
    popupArr=[[NSMutableArray alloc]init];
    popupArr=[[NSMutableArray alloc]initWithObjects:@{@"menuItem":NSLocalizedString(@"Edit recipe",nil)},@{@"menuItem":NSLocalizedString(@"Only Help", nil)},nil];
    
    UIBarButtonItem *editButton,*helpButton,*optionButton;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(IS_IPHONE)
    {
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            optionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Green_moreImg"] style:UIBarButtonItemStylePlain target:self action:@selector(onClickOptionButton)];
        }
        else
        {
            editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pen"] style:UIBarButtonItemStylePlain target:self action:@selector(onClickEditButton)];
            helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?" style:UIBarButtonItemStylePlain target:self action:@selector(showHelp:)];
        }
    }
    else
    {
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pen"] style:UIBarButtonItemStylePlain target:self action:@selector(onClickEditButton)];
        helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?" style:UIBarButtonItemStylePlain target:self action:@selector(showHelp:)];
    }
    
//    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pen"] style:UIBarButtonItemStylePlain target:self action:@selector(onClickEditButton)];

    UIImage *imageMultiFunction = [UIImage imageNamed:@"calendar"]; //set default image to be for TO_PLAN
    if (barButtonType == TO_BUY) {
        imageMultiFunction = nil;   //no need to delete because there is active recipe, it cannot be deleted anyway
    }
    else if(barButtonType == TO_COMMENT){
        imageMultiFunction = [UIImage imageNamed:@"bocken"];
    }
    else if(barButtonType == NOT_CERTAIN){
        if (activeRecipe != nil) {
            if ([activeRecipe.isPurchased boolValue]) {
                imageMultiFunction = [UIImage imageNamed:@"bocken"];    //already cooked, leave comment
                barButtonType = TO_COMMENT;
            }
            else{
                barButtonType = TO_PLAN;
            }
        }
        else{
            //no active recipe, can plan this recipe
            barButtonType = TO_PLAN;
        }
    }
    
    if (barButtonType == ZERO||[[self.navigationController.viewControllers objectAtIndex:0]isKindOfClass:[self class]]) {
        //segue from left menu - latest viewed recipe, add left button
        UIBarButtonItem *leftButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
        NSArray *leftButtons = @[leftButton];
        self.navigationItem.leftBarButtonItems = leftButtons;
    }
    UIBarButtonItem *multiFunctionButton = [[UIBarButtonItem alloc] initWithImage:imageMultiFunction style:UIBarButtonItemStylePlain target:self action:@selector(onClickMultifunctionButton)];
    NSArray *buttons;
    if(IS_IPHONE)
    {
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            buttons = [[NSArray alloc]initWithObjects:optionButton,multiFunctionButton, nil];
        }
        else
        {
            buttons = [[NSArray alloc]initWithObjects:helpButton,editButton,multiFunctionButton, nil];
        }
    }
    else
    {
        buttons = [[NSArray alloc]initWithObjects:helpButton,editButton,multiFunctionButton, nil];

    }
    self.navigationItem.rightBarButtonItems = buttons;
}
                                   
- (IBAction)showHelp:(id)sender {
    [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self force:YES];
}

-(void)showMenu{
    //[self.frostedViewController presentMenuViewController];
    [self.revealViewController revealToggle:self];
}

-(void)onClickEditButton{
    //  DLog(@"click edit");
    //[self goToWebToChangeRecipe];
    AddNewRecipeViewVC *nav=[[AddNewRecipeViewVC alloc]initWithNibName:@"AddNewRecipeViewVC" bundle:nil];
    nav.editRecipe=recipe;
    nav.screenName=@"Edit";
    
    [self.navigationController pushViewController:nav animated:YES];
    [self collapseMenu];
}

-(void)onClickMultifunctionButton{
    //  DLog(@"click multifunction");
    switch (barButtonType) {
        case TO_BUY:
            break;
        case TO_COMMENT:
            [self performSegueWithIdentifier:@"recipeDetailToCooked" sender:self];
            break;
        case TO_PLAN:
            if([[MatlistanHTTPClient sharedMatlistanHTTPClient] isLoggedIn]) {
                [self performSegueWithIdentifier:@"RecipeDetailToPlan" sender:self];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:NSLocalizedString(@"internet_connection_required",nil)
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            
            break;
        default:
            break;
    }
    
}

-(void)setTotalLineCharacters{
    totalLineCharacters = [Utility getScreenWidth]/10.0;
}

#pragma mark - construct html code for webview

-(void)makeInstructionsWeb{
    if ([Utility isStringEmpty:recipe.instructionsMarkup]) {
        instructionHTML = @"";
        return;
    }
    
    //Dimple
    instructionHTML = [recipe.instructionsMarkup stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    if([instructionHTML rangeOfString:@"<timer"].location !=NSNotFound)
    {
        instructionHTML = [instructionHTML stringByReplacingOccurrencesOfString:@"<timer type" withString:@"<a href='didTap://TimerOpen'><timer type"];
        instructionHTML = [instructionHTML stringByReplacingOccurrencesOfString:@"</timer>" withString:@"</timer></a>"];
        temp_str=instructionHTML;
    }
    
    //   DLog(@"\nInstructions:\n%@",recipe.instructionsMarkup);
    //    instructionHTML = [recipe.instructionsMarkup stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    instructionHTML = [instructionHTML stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    instructionHTML = [instructionHTML stringByReplacingOccurrencesOfString:@"<h>" withString:@"<b>"];
    instructionHTML = [instructionHTML stringByReplacingOccurrencesOfString:@"</h>" withString:@"</b>"];
    instructionHTMLContent = instructionHTML;
    instructionHTML = [NSString stringWithFormat:@"<html><body>%@<h4>%@</h4>%@</body></html>",htmlStyle,NSLocalizedString(@"Instruction", nil),instructionHTML];
    //  DLog(@"\nInstructions:\n%@",instructionHTML);
}

-(void)makeIngredientsWeb{
    if ([Utility isStringEmpty:recipe.ingredientsMarkup]) {
        ingredientsHTML = @"";
        return;
    }
    // DLog(@"%@",recipe);
    ingredientsHTML = [recipe.ingredientsMarkup stringByReplacingOccurrencesOfString:@"\n"
                                                                          withString:@"<br/>"];
    ingredientsHTML = [ingredientsHTML stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    ingredientsHTML = [ingredientsHTML stringByReplacingOccurrencesOfString:@"<h>" withString:@"<b>"];
    ingredientsHTML = [ingredientsHTML stringByReplacingOccurrencesOfString:@"</h>" withString:@"</b>"];
    
    [self replaceLinkForIngredients];
    ingredientsHTMLContent = ingredientsHTML;
    ingredientsHTML = [NSString stringWithFormat:@"<html><body>%@<h4>%@</h4>%@</body></html>",htmlStyle,NSLocalizedString(@"Ingredients", nil),ingredientsHTML];
    //    DLog(@"%@,lines %d",ingredientsHTML,ingredientLines);
}


-(void)makeNotesWeb
{
    if([self.screen_name isEqualToString:@"PlanFoodScreen"])
    {
        if ([Utility isStringEmpty:activeRecipe.notes]) {
            notesHTML = @"";
            return;
        }
        //  DLog(@"\nYourNotes:\n%@",activeRecipe.notes);
        notesHTML = [activeRecipe.notes stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
        
    }
    else
    {
        if ([Utility isStringEmpty:recipe.notes]) {
            notesHTML = @"";
            return;
        }
        //   DLog(@"\nYourNotes:\n%@",recipe.notes);
        notesHTML = [recipe.notes stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
        
    }
    notesHTML = [notesHTML stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    notesHTML = [notesHTML stringByReplacingOccurrencesOfString:@"<h>" withString:@"<b>"];
    notesHTML = [notesHTML stringByReplacingOccurrencesOfString:@"</h>" withString:@"</b>"];
    notesHTMLContent = notesHTML;
    notesHTML = [NSString stringWithFormat:@"<html><body>%@<h4>%@</h4>%@</body></html>",htmlStyle,NSLocalizedString(@"Notes", nil),notesHTML];
    // DLog(@"\nYourNotes:\n%@",notesHTML);
}

-(void)makeTipsWeb
{
    if ([Utility isStringEmpty:recipe.advice]) {
        tipsHTML = @"";
        return;
    }
    //   DLog(@"\nTips:\n%@",recipe.advice);
    tipsHTML = [recipe.advice stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    tipsHTML = [tipsHTML stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    tipsHTML = [tipsHTML stringByReplacingOccurrencesOfString:@"<h>" withString:@"<b>"];
    tipsHTML = [tipsHTML stringByReplacingOccurrencesOfString:@"</h>" withString:@"</b>"];
    tipsHTMLContent = tipsHTML;
    tipsHTML = [NSString stringWithFormat:@"<html><body>%@<h4>%@</h4>%@</body></html>",htmlStyle,NSLocalizedString(@"Tips", nil),tipsHTML];
    // DLog(@"\nYourNotes:\n%@",tipsHTML);
}


-(void)makeCombinedHTML{
    NSString *descriptionHTML = [self getDescriptionHTML];
    NSString *divInstruction = @"";
    NSString *sectionInstruction = @"";
    if (![Utility isStringEmpty:instructionHTMLContent]) {
        //dimple
        if ([instructionHTMLContent rangeOfString:@"<timer"].location != NSNotFound)
        {
            instructionHTML = [instructionHTMLContent stringByReplacingOccurrencesOfString:@"<timer type" withString:@"<a href='didTap://TimerOpen'><timer type"];
            instructionHTML = [instructionHTMLContent stringByReplacingOccurrencesOfString:@"</timer>" withString:@"</timer></a>"];
        }
        divInstruction = [NSString stringWithFormat:@"<div id=\"instruction\"><h4>%@</h4>%@</div>",NSLocalizedString(@"Instruction", nil),instructionHTMLContent];
        sectionInstruction = [NSString stringWithFormat:@"<section><h4>%@</h4>%@</section>",NSLocalizedString(@"Instruction", nil),instructionHTMLContent];
    }
    
    NSString *divNotes = @"";
    NSString *sectionNotes = @"";
    if (![Utility isStringEmpty:notesHTMLContent]) {
        divNotes = [NSString stringWithFormat:@"<div id=\"Notes\"><h4>%@</h4>%@</div>",NSLocalizedString(@"Notes", nil),notesHTMLContent];
        sectionNotes = [NSString stringWithFormat:@"<section><h4>%@</h4>%@</section>",NSLocalizedString(@"Notes", nil),notesHTMLContent];
    }
    
    NSString *divTips = @"";
    NSString *sectionTips = @"";
    if (![Utility isStringEmpty:tipsHTMLContent]) {
        divTips = [NSString stringWithFormat:@"<div id=\"Tips\"><h4>%@</h4>%@</div>",NSLocalizedString(@"Tips", nil),tipsHTMLContent];
        sectionTips = [NSString stringWithFormat:@"<section><h4>%@</h4>%@</section>",NSLocalizedString(@"Tips", nil),tipsHTMLContent];
    }
    
    if (!ingredientsHTMLContent)
    {
        // if there is no ingredientsHTMLContent then we should exclude ingredient div tag from html
        combinedHTML = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><style>a:link {color: #5DBB55;}h2{font-size:18px;}b{font-weight:700;font-size:15px;}td{padding:5px;font-size:18px;}#ingredient{line-height:28px;background-color:#fff;height:300px;width:280px;float:left;padding:0px;}#instruction{line-height:28px;width:280px;float:right;padding:2px;}</style></head><body>%@%@%@%@%@</body></html>",htmlStyle,descriptionHTML,divInstruction,divTips,divNotes];
        
        
        verticalHTML = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><style>a:link {color: #5DBB55;}h2{font-size:18px;}</style></head><body>%@%@%@%@%@</body></html>",htmlStyle,descriptionHTML,sectionInstruction,sectionTips,sectionNotes];
    }
    else{
        
        int width,width2;
        if(IS_IPHONE)
        {
            if(iphone4)
            {
                width=240;
                width2=240;
            }
            else
            {
                width=280;
                width2=280;
            }
        }
        else
        {
            width=500;
            width2=500;
        }
        combinedHTML = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><style>a:link {color: #5DBB55;}h2{font-size:18px;}b{font-weight:700;font-size:15px;}td{padding:5px;font-size:18px;}#ingredient{line-height:28px;background-color:#fff;height:300px;width:%dpx;padding-left:0px;}#instruction{line-height:24px;width:%dpx;padding-right:2px;}</style></head><body>%@%@<table><tr><td style=\"vertical-align:top\"><div id=\"ingredient\"><h4>%@</h4>%@</div></td><td style=\"vertical-align:top\"><div id=\"instruction\">%@</div></td></tr></table><br/>%@<br/>%@</body></html>",width,width2,htmlStyle,descriptionHTML,NSLocalizedString(@"Ingredients", nil),ingredientsHTMLContent,divInstruction, divTips,divNotes];
        
        verticalHTML = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><style>a:link {color: #5DBB55;}h2{font-size:18px;}</style></head><body>%@%@<br/><section><h4>%@</h4>%@</section><br/>%@<br/>%@<br/>%@</body></html>",htmlStyle,descriptionHTML,NSLocalizedString(@"Ingredients", nil),ingredientsHTMLContent,sectionInstruction,sectionTips,sectionNotes];
        
    }
    
    // DLog(@"-----combinedHTML----\n%@",combinedHTML);
    verticalHTML = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><style>a:link {color: #5DBB55;}h2{font-size:18px;}</style></head><body>%@%@<section><br/>%@<br/>%@<br/>%@<br/>%@</body></html>",htmlStyle,descriptionHTML, ingredientsHTMLContent == nil ? @"" : [NSString stringWithFormat:@"<h4>%@</h4>%@</section>", NSLocalizedString(@"Ingredients", nil),ingredientsHTMLContent], sectionInstruction,sectionTips,sectionNotes];
    //    DLog(@"-----verticalHTML----\n%@",verticalHTML);
}

/*Make description for the recipe
 * if source or tags are empty, they are not shown
 */
-(NSString*)getDescriptionHTML{
    
    NSString *html = @"<section><table border=\"0\" width=\"100%\">";
    NSString *title = [NSString stringWithFormat: @"<tr><td><h2>%@</h2></td></tr>", recipe.title];
    NSString *imageUrl = [Utility getCorrectURLFromJson: recipe.imageUrl];
    int widthOfScreen = (int)[Utility getScreenWidth]/1.5;
    NSString *imageLink = @"";
    
    // if there is no image Url then we should exclude this img tag from html
    if (imageUrl.length>0) {
        imageLink = [NSString stringWithFormat:@"<tr><td><img src=\"%@\" width=\"%d\"></img></td></tr>",imageUrl,widthOfScreen];
    }
    
    NSString *description = @"";
    if(recipe.descriptionText==nil)
    {
        description = @"<tr><td></td></tr>";
    }
    else
    {
        description = [NSString stringWithFormat: @"<tr><td>%@</td></tr>", recipe.descriptionText];
    }
    NSString *source = @"";
    NSString *sourceText = @"";
    NSString *tagsText = @"";
    
    if ([Utility isStringEmpty:recipe.source_text]) {
        if (![Utility isStringEmpty:recipe.source_url]) {
            source = recipe.source_url;
        }
    }
    else{
        source = recipe.source_text;
    }
    if (![Utility isStringEmpty:source]) {
        NSLog(@"source text %@ %@", source, recipe.source_url);
        if(recipe.source_url == nil)
        {
             sourceText = [NSString stringWithFormat: @"<tr><td>%@: %@</a></td></tr>",NSLocalizedString(@"Source", nil), source];
        }
        else
        {
            sourceText = [NSString stringWithFormat: @"<tr><td>%@:<a href=\"%@\"> %@</a></td></tr>",NSLocalizedString(@"Source", nil),recipe.source_url, source];
        }
        
    }
    NSString *portionType=recipe.portionType;
    NSString *portionStr = [recipe.portions intValue] > 1 ? NSLocalizedString(@"portions", nil) : NSLocalizedString(@"portion", nil);
    
    NSString *cookTimeString = [self getCookTimeString];
    
    NSString *portionTime=@"";
    
     NSString *portionsFromRecipe;
     if(recipe.sel_portions != nil && ![recipe.sel_portions isEqualToString:@"0"]) {
         portionsFromRecipe = recipe.sel_portions;
     }
     else if(recipe.portions != nil && [recipe.portions intValue] != 0){
         portionsFromRecipe = [NSString stringWithFormat:@"%@", recipe.portions];
     }
    if(portionsFromRecipe){
        if(![recipe.instructionsMarkup hasPrefix:@"-"]){
            if(portionType!=nil)
            {
                portionTime = [NSString stringWithFormat:@"<tr><td><a href=\"didtap://button1\">%@ %@</a>\t%@</td></tr>", portionsFromRecipe,portionType, cookTimeString];
            }
            else
            {
                portionTime = [NSString stringWithFormat:@"<tr><td><a href=\"didtap://button1\">%@ %@</a>\t%@</td></tr>", portionsFromRecipe,portionStr, cookTimeString];
            }
        }
        else
        {
            portionTime = [NSString stringWithFormat:@"<tr><td>%@ %@\t%@</td></tr>", portionsFromRecipe,portionStr, cookTimeString];
            
        }
    }
    if (recipe.relatedTags.count > 0) {
        int i= 0;
        for (Recipebox_tag *tag in recipe.relatedTags) {
            i++;
            NSString *htmlSubString = [NSString stringWithFormat:@"<a href=\"%@?*%@*#TagFragment\">%@</a>,",[NSString stringWithFormat:@"%@://", [Utility getAppUrlScheme]],tag.text,tag.text];
            if (i == recipe.relatedTags.count) {
                htmlSubString = [htmlSubString substringToIndex:[htmlSubString length]-1];
            }
            tagsText = [NSString stringWithFormat:@"%@ %@",tagsText,htmlSubString];
        }
        tagsText = [NSString stringWithFormat:@"<tr><td>%@:%@</td></tr>",NSLocalizedString(@"Tags", nil),tagsText];
    }
    
    
    html = [NSString stringWithFormat:@"%@%@%@%@%@%@%@</table></section>",html,title,imageLink,description,sourceText,portionTime,tagsText];
    
    return html;
}

-(NSString*)getCookTimeString{
    NSString *timeString = [Recipebox getCookTimeStringFromRecipe:recipe];
    
    if ([Utility isStringEmpty:timeString]) {
        return @"";
    }
    else{
        timeString =  [NSString stringWithFormat:@"∙\t%@", timeString];
        return timeString;
    }
}

-(void)replaceLinkForIngredients{
    ingredientLines = 0;
    NSRange isRange = [ingredientsHTML rangeOfString:@"<ki>" options:NSCaseInsensitiveSearch];
    ingredienttext_arr=[[NSMutableArray alloc]init];
    while (isRange.location != NSNotFound ) {
        //replace <ki to <a href="matlistan://?xx"> xx </a>
        //        DLog(@" %@",ingredientsHTML);
        NSRange r1 = [ingredientsHTML rangeOfString:@"<ki>"];
        NSRange r2 = [ingredientsHTML rangeOfString:@"</ki>"];
        rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
        NSString *ingredient = [ingredientsHTML substringWithRange:rSub];
        [ingredienttext_arr addObject:ingredient];
        NSString *oldSubString = [NSString stringWithFormat:@"<ki>%@</ki>",ingredient];
        
        NSString *htmlSubString = [NSString stringWithFormat:@"<a href=\"%@?%@**#IngredientFragment\">%@</a>",[NSString stringWithFormat:@"%@://", [Utility getAppUrlScheme]],ingredient,ingredient];
        
        ingredientsHTML = [ingredientsHTML stringByReplacingOccurrencesOfString:oldSubString withString:htmlSubString];
        isRange = [ingredientsHTML rangeOfString:@"<ki>" options:NSCaseInsensitiveSearch];
        ingredientLines++;
    }
}

#pragma mark - UITextView Delegate methods
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    if(_timerOnRecipes.count>0)
    {
        [UIView transitionWithView:self.timerWindowTbl
                          duration:0.3f
                           options:UIViewAnimationOptionCurveEaseOut
                        animations:^(void)
         {
             is_timerWindow_open=YES;
             [self closeNotificationWindow];
         }completion:^(BOOL finished) {
             
         }];
    }
    
    NSString *absoluteUrl = [URL absoluteString];

    if ([absoluteUrl isEqualToString:@"didtap://TimerOpen"])
    {
        if(self.expandedIndexPath!=nil)
        {
            self.expandedIndexPath=nil;
            [self.timerWindowTbl reloadData];
        }

        
        hyperTxt=[textView.text substringWithRange:characterRange];
        NSArray* foo1 = [temp_str componentsSeparatedByString:[NSString stringWithFormat:@"%@</timer>",hyperTxt]];
        
        const NSRange range =  [foo1[0]  rangeOfString:[[[[foo1[0] componentsSeparatedByString:@"description=\""]objectAtIndex:1] componentsSeparatedByString:@"\">"]objectAtIndex:0] options:NSBackwardsSearch];
        
        NSString *str=[foo1[0] substringWithRange:range];
        
        NSString *temp_desc_and_value=@"";
        NSString *myString = foo1[0];
        NSMutableString *reversedString = [NSMutableString string];
        NSInteger charIndex = [myString length];
        while (myString && charIndex > 0) {
            charIndex--;
            NSRange subStrRange = NSMakeRange(charIndex, 1);
            [reversedString appendString:[myString substringWithRange:subStrRange]];
        }
        str = reversedString;
        
        //Get description
        NSArray *desc_temp_arr=[str componentsSeparatedByString:@"\"=noitpircsed"];//description=noitpircsed
        temp_desc_and_value=desc_temp_arr[0];
        
        NSMutableString *reversedString1 = [NSMutableString string];
        NSInteger charIndex1 = [temp_desc_and_value length];
        while (temp_desc_and_value && charIndex1 > 0) {
            charIndex1--;
            NSRange subStrRange1 = NSMakeRange(charIndex1, 1);
            [reversedString1 appendString:[temp_desc_and_value substringWithRange:subStrRange1]];
        }
        NSString *str1 = reversedString1;
        if([str1 rangeOfString:@"\">"].location!=NSNotFound)
        {
            NSArray *temp_arr=[str1 componentsSeparatedByString:@"\">"];
            descString=temp_arr[0];
            self.tempRecipeDesc = descString;
        }
        
        //Get value
        NSArray *value_temp_arr=[str componentsSeparatedByString:@"\"=eulav"];//value=eulav
        temp_desc_and_value=value_temp_arr[0];
        
        NSMutableString *value_reverse_str = [NSMutableString string];
        NSInteger charIndex2 = [temp_desc_and_value length];
        while (temp_desc_and_value && charIndex2 > 0) {
            charIndex2--;
            NSRange subStrRange2 = NSMakeRange(charIndex2, 1);
            [value_reverse_str appendString:[temp_desc_and_value substringWithRange:subStrRange2]];
        }
        NSString *rev_value = value_reverse_str;
        if([rev_value rangeOfString:@"\""].location!=NSNotFound)
        {
            NSArray *temp_arr=[rev_value componentsSeparatedByString:@"\""];
            TimeNumstr=temp_arr[0];
        }
        else
        {
            TimeNumstr=0;
        }
        if ([hyperTxt rangeOfString:@"min"].location != NSNotFound)
        {
            minutes=0;
            minutes=[TimeNumstr intValue];
            [self.picker_timer selectRow:[TimeNumstr intValue] inComponent:1 animated:NO];
        }
        if ([hyperTxt rangeOfString:@"hour"].location != NSNotFound)
        {
            hours=0;
            hours=[TimeNumstr intValue];
            [self.picker_timer selectRow:[TimeNumstr intValue] inComponent:0 animated:NO];
        }
        if ([hyperTxt rangeOfString:@"sec"].location != NSNotFound){
            seconds=0;
            seconds=[TimeNumstr intValue];
            [self.picker_timer selectRow:[TimeNumstr intValue] inComponent:2 animated:NO];
        }
    }
    
    UINavigationController *navigationController = (UINavigationController *)self.revealViewController.frontViewController;
    
    if ([absoluteUrl isEqualToString:@"didtap://button1"]) {
        [self Open_Picker];
        return NO;
    }
    //Dimple
    if ([absoluteUrl isEqualToString:@"didtap://TimerOpen"])
    {
        [self showTimerPopup];
        return NO;
    }
    //
    DLog(@"url scheme %@",[Utility getAppUrlScheme]);
    
    if([absoluteUrl hasPrefix:[NSString stringWithFormat:@"%@://", [[Utility getAppUrlScheme] lowercaseString]]])
    {
        NSString *query = [[URL query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        query = [query stringByReplacingOccurrencesOfString:@"*" withString:@""];
        
        if(([[URL fragment] isEqualToString:@"TagFragment"]))
        {
            //     DLog(@"ViewControllers = %@",self.navigationController.viewControllers);
            
            if(self.navigationController.viewControllers.count > 1) {
                NSInteger index = [self.navigationController.viewControllers indexOfObject:self.navigationController.topViewController]-1;
                
                while(index!=-1){
                    UIViewController* aVC = [self.navigationController.viewControllers objectAtIndex:index];
                    if([aVC isKindOfClass:[RecipesViewController class]]) {
                        
                        [(RecipesViewController*)aVC setTagSearchText:query];
                        [self.navigationController popToViewController:aVC animated:YES];
                        return NO;
                    }
                    index--;
                }
            }
            
            RecipesViewController *aRecipesViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Recipes"];
            [aRecipesViewController setTagSearchText:query];
            navigationController.viewControllers = @[aRecipesViewController];
            [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
            
            //                DLog(@"ViewControllers = %@",self.navigationController.viewControllers);
            
        }
        else if(([[URL fragment] isEqualToString:@"IngredientFragment"]))
        {
            [DataStore instance].ingredientByURL = query;
            ItemsViewController *homeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ItemsView"];
            [homeViewController setIngredientSearchText:query];
            navigationController.viewControllers = @[homeViewController];
            [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
            
        }
        
        
        return NO;
    }
    
    
    return YES;
}

#pragma mark -  UI stuff
-(void)onClickSourceButton{
    
    NSURL *url = [NSURL URLWithString:recipe.source_url];
    [[UIApplication sharedApplication] openURL:url];
}


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self collapseMenu];

    is_timerWindow_open=YES;
    [self closeNotificationWindow];
       if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        attributedString = [[NSMutableAttributedString alloc] initWithData:[combinedHTML dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
        
        _textview.attributedText = attributedString;
        font_size=[Utility getLandscapeFont];

    }
   else
    {
        attributedString = [[NSMutableAttributedString alloc] initWithData:[verticalHTML dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
        _textview.attributedText = attributedString;
        font_size=[Utility getPortraitFont];
    }
   
    if(font_size!=0)
    {
        res = [self.textview.attributedText mutableCopy];
        [res beginEditing];
        __block BOOL found = NO;
        [res enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, res.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (value) {
                UIFont *oldFont = (UIFont *)value;
                CGFloat pointSize = [font_size floatValue];
                
                UIFont *font_1;
                font_1 = [oldFont fontWithSize:pointSize];
                
                [res removeAttribute:NSFontAttributeName range:range];
                [res addAttribute:NSFontAttributeName value:font_1 range:range];
                _textview.attributedText = res;
                [_textview setEditable:NO];
                found = YES;
            }
        }];
        if (!found) {
            // No font was found - do something else?
        }
        [res endEditing];
    }
    [self close_picker];
}
/**
 Make the webview suit the size of tableview cell
 */
- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    aWebView.scrollView.scrollEnabled = YES;    // Property available in iOS 5.0 and later
    //  DLog(@"webView contentSize: %@", NSStringFromCGSize(aWebView.scrollView.contentSize));
}

- (IBAction)onClickActionButton:(id)sender {
    //    DLog(@"Click action button");
    [self goToWebToChangeRecipe];
}

-(void)goToWebToChangeRecipe{
    //http://www.matlistan.se/Account/LogOn?ticket=<ticket>&returnUrl=/RecipeBox/Edit/<recipeId>
    NSString *link = [NSString stringWithFormat:@"http://www.matlistan.se/Account/LogOn?ticket=%@&returnUrl=/RecipeBox/Edit/%@",
                      [MatlistanHTTPClient sharedMatlistanHTTPClient].ticket,recipe.recipeboxID];
    
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:link]];
    //  DLog(@"Click change");
}

#pragma mark - Actionsheet

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
                {
                    DLog(@"Click change");
                    break;
                }
                case 1:
                {
                    DLog(@"Click del");
                    break;
                }
                case 2:
                {
                    DLog(@"Click help");
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqual:@"recipeToList"]) {
        //ShoppingListsTableViewController *destinationViewController = [segue destinationViewController];
        [DataStore instance].ingredientByURL = buttonText;
    }
    else if([segue.identifier isEqual:@"RecipeDetailToPlan"]){
        RecipePlanTableViewController *recipePlanTableVC = (RecipePlanTableViewController *)[segue destinationViewController];
        recipePlanTableVC.activeRecipe = self.activeRecipe;
        [DataStore instance].currentRecipeID = [recipe.recipeboxID longValue];
    }
    else if([segue.identifier isEqual:@"recipeDetailToCooked"]){
        AfterCookViewController *destinationController = [segue destinationViewController];
        destinationController.screen_identifier=screenRedirection;
        destinationController.recipe = recipe;
    }
}

-(void)segueToList:(id)sender{
    UIButton *button = (UIButton*)sender;
    buttonText = button.titleLabel.text;
    [self performSegueWithIdentifier:@"recipeToList" sender:self];
}

#pragma mark - memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -viewedRecipes Manepulation
-(void)addItemToTheRecentlyViewedList:(NSNumber *)recipeBoxIdIn{
    CLSLog(@"***** recipe detail screen >> addItemToTheRecentlyViewedList >>>> Recipebox id :%@",recipeBoxIdIn);
    
    if(recipeBoxIdIn!=nil)
    {
        if([self.screen_name isEqualToString:@"RecipeScreen"] || [self.screen_name isEqualToString:@"PlanFoodScreen"])
        {
            [[NSUserDefaults standardUserDefaults]setObject:self.screen_name forKey:[NSString stringWithFormat:@"%@",recipeboxId]];
            [[NSUserDefaults standardUserDefaults]synchronize];
        }
       
        [[DataStore instance].viewedRecipes insertObject:recipeBoxIdIn atIndex:0];
        [Utility saveInDefaultsWithObject:[DataStore instance].viewedRecipes andKey:@"viewedRecipes"];
    }
}
-(void)sortCurrentArray:(NSUInteger)nsuIntegerIn{
    for (int a = (int)nsuIntegerIn; a >= 0; a--) {
        if (a > 0) {
            [[DataStore instance].viewedRecipes exchangeObjectAtIndex:a withObjectAtIndex:a-1];
        }
    }
}
//#pragma mark- GADbannerViewDelegate
//- (void)adViewDidReceiveAd:(GADbannerView *)view{
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationDuration:0.5f];
//    [view setAlpha:1];
//    [UIView commitAnimations];
//}
//
//- (void)adView:(GADbannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error{
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationDuration:0.5];
//    [view setAlpha:0];
//    [UIView commitAnimations];
//}


-(UIViewController *)getViewControllerAccordingToClass:(Class)class
{
    for(UIViewController *aVC in self.navigationController.viewControllers){
        if([aVC isKindOfClass:class]) {
            return aVC;
        }
    }
    
    return nil;
}

#pragma mark-Calculate portion
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

-(void)Open_Picker
{
    //Open
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // is_open=true;
                         selected_string=@"";
                         self.textview.userInteractionEnabled=false;
                         self.Picker_View.frame=CGRectMake(0, SCREEN_HEIGHT-self.Picker_View.frame.size.height-self.bannerView.frame.size.height, SCREEN_WIDTH, self.Picker_View.frame.size.height);
                     }completion:^(BOOL finished) {
                         
                     }];
    
}
-(void)close_picker
{
    //Cancel
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.textview.userInteractionEnabled=true;
                         self.Picker_View.frame=CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, self.Picker_View.frame.size.height);
                     }completion:^(BOOL finished) {
                         
                     }];
}


#pragma mark - picker view

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    if(pickerView.tag==1)
    {
        return 1;
    }
    
    return 3;
    
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(pickerView.tag==1)
    {
        return selectablePortions.count;
    }
    if(pickerView.tag==2)
    {
        if (component==0)
        {
            return [hoursArray count];
        }
        else if (component==1)
        {
            return [minsArray count];
        }
        else
        {
            return [secsArray count];
        }
    }
    return 0;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(pickerView.tag==1)
    {
        selected_string = [selectablePortions objectAtIndex:row];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
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
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 37)];
        label.textAlignment = NSTextAlignmentCenter;
        
        switch (component)
        {
            case 0:
                hours= [[hoursArray objectAtIndex:row]intValue];
                return [hoursArray objectAtIndex:row];
                break;
            case 1:
                minutes=  [[minsArray objectAtIndex:row]intValue];
                return [minsArray objectAtIndex:row];
                
                break;
            case 2:
                label.textAlignment = NSTextAlignmentLeft;
                
                seconds=  [[secsArray objectAtIndex:row]intValue];
                return [secsArray objectAtIndex:row];
                
                break;
        }
        return nil;
        
    }
     return nil;
}
//- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
//    return pickerView.frame.size.width;
//}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *columnView;
    if(pickerView.tag==1)
    {
        columnView = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, self.view.frame.size.width/*/3 - 35*/, 30)];
        columnView.textAlignment = NSTextAlignmentCenter;
        
        NSString *value = [selectablePortions objectAtIndex:row];
        NSString *original = [NSString stringWithFormat:@"%@", recipe.portions];
        
        if([original isEqualToString:value]) {
            columnView.text = [NSString stringWithFormat:@"%@ (%@)", value, NSLocalizedString(@"original", nil)];
        }
        else {
            columnView.text = value;
        }
        return  columnView;
    }
    else
    {
        columnView = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, self.view.frame.size.width/3 - 35, 30)];
        columnView.text = [NSString stringWithFormat:@"%lu", (long) row];
        columnView.textAlignment = NSTextAlignmentCenter;
    }
    
    return columnView;
}


#pragma mark- Cancel & Done Click
-(IBAction)CancelPicker_click:(id)sender
{
    [self close_picker];
}
-(IBAction)DonePicker_click:(id)sender
{
    
    if(![selected_string isEqualToString:recipe.sel_portions]){
        [self sendIngredientsUpdates];
    }
    [self close_picker];
    
}

-(void)didUpdateItems
{
    if([SignificantChangesIndicator sharedIndicator].recipeChanged)
    {
        //ingredients = [[Ingredient getIngredientsOfRecipeID:recipe.recipeboxID] sortedArrayUsingDescriptors:[self getIngredientsSortOrder]];
        recipe = [Recipebox getRecipeById:recipeboxId];
        [self loadDatatoWebView];
        [SVProgressHUD dismiss];
        [[SignificantChangesIndicator sharedIndicator] resetData];
        //[self setFavoriteStoreName];
    }
    
}

#pragma mark-server Communication
-(void)sendIngredientsUpdates
{
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
    [Recipebox changePortionsWith:selected_string forRecipe:recipe];
    [[SyncManager sharedManager] forceSync];
}
#pragma mark- helper methods

- (NSArray*)getIngredientsSortOrder
{
    NSArray *sort = @[[NSSortDescriptor sortDescriptorWithKey:@"sortableText" ascending:YES]];
    return sort;
}

- (void)setListNameAndId:(NSNumber *)listIdIn
{
    Item_list *belongedList = [Item_list getListById:listIdIn];
    currentListID = belongedList.item_listID;
    if(belongedList == nil) {
        Item_list *list = [DataStore instance].currentList;
        if (list == nil || [list.item_listID intValue] == 0 )
        {
            currentListID = [Item_list getDefaultListId];
        }
        else
        {
            currentListID = list.item_listID;
        }
    }
}
//DImple

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(self.expandedIndexPath!=nil)
    {
        self.expandedIndexPath=nil;
        [self.timerWindowTbl reloadData];
    }

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if(IS_IPHONE)
    {
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            navigationBarHeight=self.navigationController.navigationBar.frame.size.height+20;
        }
        self.more_tableview.frame=CGRectMake(SCREEN_WIDTH-self.more_tableview.frame.size.width-6, navigationBarHeight, self.more_tableview.frame.size.width, 0);
        
    }
    
    [self addBarButtons];
    if(is_timerListOpen)
    {
        [self openNotificationWindow];
        is_timerWindow_open=false;
    }
    else
    {
        is_timerWindow_open=YES;
        [self closeNotificationWindow];
    }
    [self setPickerLabel:0];
}

//Dimple
#pragma mark- Timerview ok  Button click event
-(IBAction)okBtn:(id)sender
{
    BOOL recipePresent = NO;
    [self calculateTimeFromPicker];
    NSTimeInterval duration = interval;
    
    
    
    
    __block BOOL is_match=false;
    __block NSString *countTimer,*recipeDesc;
    __block RecipeTimer *tempTimer = nil;
    
    
    if([_timerOnRecipes count] == 0)
    {
        _selectedRecipe.recipeName=recipe.title;
        _selectedRecipe.recipeDesc=descString;
        _selectedRecipe.interval    = seconds + (minutes*60) + (hours*3600);
        _selectedRecipe.secondsLeft =_selectedRecipe.interval;
        _selectedRecipe.recipeTimerId = 0;
        [_timerOnRecipes addObject:_selectedRecipe];
        _selectedRecipe.recipeTimerdelegate = self;
        _selectedRecipe.recipeListDelegate = (id)theAppDelegate;
        [_selectedRecipe startTimer];
    }
    else
    {
        // for(RecipeTimer *aRecipeTimer in _timerOnRecipes)
        // {
        //    if(![aRecipeTimer.recipeDesc isEqualToString:descString])
        //{
        //      recipePresent = NO;
        //  }
        //   else{
        //      recipePresent = YES;
        
        //  }
        //  }
        
        [_timerOnRecipes enumerateObjectsUsingBlock:^(RecipeTimer  *obj, NSUInteger idx, BOOL *stop) {
            if([obj.recipeDesc isEqualToString:_tempRecipeDesc])
            {
                is_match=true;
                countTimer=obj.countTimer;
                recipeDesc=obj.recipeDesc;
                tempTimer = obj;
                *stop=YES;
            }
        }];
        
        if(!is_match)
        {
            tempTimer = [[RecipeTimer alloc]initWithRecipieId:_selectedRecipe.recipeboxId recipeName:_selectedRecipe.recipeName withRecipeDesc:descString];
            tempTimer.secondsLeft    = seconds + (minutes*60) + (hours*3600);
            [_timerOnRecipes enumerateObjectsUsingBlock:^(RecipeTimer *obj, NSUInteger idx, BOOL *stop) {
                obj.recipeTimerId = idx + 1;
            }];
            tempTimer.recipeTimerId = 0;
            [_timerOnRecipes insertObject:tempTimer atIndex:0];
            tempTimer.recipeTimerdelegate = self;
            tempTimer.recipeListDelegate =(id) theAppDelegate;
            [tempTimer startTimer];
        }
        else
        {
            _selectedRecipe.recipeName=recipe.title;
            _selectedRecipe.recipeDesc=descString;
            _selectedRecipe.interval    = seconds + (minutes*60) + (hours*3600);
            _selectedRecipe.secondsLeft =_selectedRecipe.interval;
            
            _selectedRecipe.tempSecondsLeft = _selectedRecipe.secondsLeft;
            [_selectedRecipe stopTimer];
            NSLog(@"recipe present in list of update timer table just update the new time");
            _selectedRecipe.interval    = seconds + (minutes*60) + (hours*3600);
            _selectedRecipe.interval = duration;
            _selectedRecipe.recipeTimerdelegate = self;
            [_selectedRecipe startTimer];
        }
    }
    
    
    [self hideTimerPopup];
    [self timerBtnShoworNot];
    
    [UIView transitionWithView:self.timerWindowTbl
                      duration:0.3f
                       options:UIViewAnimationOptionCurveEaseIn
                    animations:^(void)
     {
         [self openNotificationWindow];
         is_timerWindow_open=false;
         
         
     }completion:^(BOOL finished) {
         
     }];
    [self.timerWindowTbl reloadData];
}
- (void)dealloc
{
    self.selectedRecipe = nil;
    self.timerOnRecipes = nil;
    self.selectedRecipe.recipeListDelegate = nil;
}
#pragma mark- Timer
-(void)calculateTimeFromPicker
{
    NSString *hoursStr = [NSString stringWithFormat:@"%@",[hoursArray objectAtIndex:[self.picker_timer selectedRowInComponent:0]]];
    NSString *minsStr = [NSString stringWithFormat:@"%@",[minsArray objectAtIndex:[self.picker_timer selectedRowInComponent:1]]];
    NSString *secsStr = [NSString stringWithFormat:@"%@",[secsArray objectAtIndex:[self.picker_timer selectedRowInComponent:2]]];
    
    hours = [hoursStr intValue];
    minutes = [minsStr intValue];
    seconds = [secsStr intValue];
    
    interval = seconds + (minutes*60) + (hours*3600);
    secondsLeft=interval;
}


-(IBAction)cancelBtn:(id)sender
{
    [self hideTimerPopup];
}
#pragma mark- show timer popup
-(void)showTimerPopup
{
    // NSString *tempDesc=_tempRecipe.recipeDesc;
    __block BOOL is_match=false;
    __block NSString *countTimer,*recipeDesc;
    __block RecipeTimer *tempTimer = nil;
    [_timerOnRecipes enumerateObjectsUsingBlock:^(RecipeTimer  *obj, NSUInteger idx, BOOL *stop) {
        if([obj.recipeDesc isEqualToString:_tempRecipeDesc])
        {
            is_match=true;
            countTimer=obj.countTimer;
            recipeDesc=obj.recipeDesc;
            tempTimer = obj;
            *stop=YES;
        }
    }];
    
    if(is_match)
    {
        if(tempTimer)
            self.selectedRecipeTimer = tempTimer;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil)
                                                        message: [NSString stringWithFormat:@"%@\n'%@\' %@ %@.",NSLocalizedString(@"Cancel timer?",nil),recipeDesc,NSLocalizedString(@"is done in",nil),countTimer]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Ok",nil),nil];
        [alert show];
    }
    else
    {
        [self showTimerPicker];
    }

    /*if(![_timerOnRecipes containsObject:_selectedRecipe])
    {
        [self showTimerPicker];
    }
    else
    {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil)
                                                        message: [NSString stringWithFormat:@"%@\n'%@\' %@ %@.",NSLocalizedString(@"Cancel timer?",nil),_selectedRecipe.recipeDesc,NSLocalizedString(@"is done in",nil),_selectedRecipe.countTimer]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Ok",nil),nil];
        [alert show];
        
    }*/
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Set buttonIndex == 1 to handel "Ok"/"Yes" button response
      if (buttonIndex == 1)
    {
        if(self.selectedRecipeTimer)
        {
            [self.selectedRecipeTimer stopTimer];
            [[WatchConnectivityController sharedInstance] stopTimerForRecipeID: self.selectedRecipeTimer.recipeboxId];
            [self removeRecipe:self.selectedRecipeTimer];
        }
        else
        {
            [_selectedRecipe stopTimer];
            [[WatchConnectivityController sharedInstance] stopTimerForRecipeID: _selectedRecipe.recipeboxId];
            [self removeRecipe:_selectedRecipe];
        }
        [self.timerWindowTbl reloadData];
    }
    else
    {
        
    }
    is_timerListOpen=false;
    is_timerWindow_open=true;

}

-(void)showTimerPicker
{
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // is_open=true;
                         self.textview.userInteractionEnabled=false;
                        self.timeView.frame=CGRectMake(0, SCREEN_HEIGHT-self.timeView.frame.size.height-self.bannerView.frame.size.height, SCREEN_WIDTH, self.timeView.frame.size.height);
                         
                     }completion:^(BOOL finished) {
                         

                     }];
}

-(void)hideTimerPopup
{
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.textview.userInteractionEnabled=true;
                         self.timeView.frame=CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, self.timeView.frame.size.height);
                     }completion:^(BOOL finished) {
                         NSArray* getTimenumber = [hyperTxt componentsSeparatedByString:@" "];
                         NSString *TimeNumstr=getTimenumber[0];
                         minutes=0;//dimple
                         hours=0;
                         seconds=0;

                         if ([hyperTxt rangeOfString:@"min"].location != NSNotFound)
                         {
                            minutes=[TimeNumstr intValue];
                             [self.picker_timer selectRow:[TimeNumstr intValue] inComponent:1 animated:YES];
                             [self.picker_timer selectRow:0 inComponent:0 animated:YES];
                             [self.picker_timer selectRow:0 inComponent:2 animated:YES];

                         }
                         if ([hyperTxt rangeOfString:@"hour"].location != NSNotFound)
                         {
                             
                             hours=[TimeNumstr intValue];//dimple
                             [self.picker_timer selectRow:[TimeNumstr intValue] inComponent:0 animated:YES];
                             [self.picker_timer selectRow:0 inComponent:1 animated:YES];
                             [self.picker_timer selectRow:0 inComponent:2 animated:YES];
                         }
                         if ([hyperTxt rangeOfString:@"sec"].location != NSNotFound){
                            seconds=[TimeNumstr intValue];//dimple
                             [self.picker_timer selectRow:[TimeNumstr intValue] inComponent:2 animated:YES];
                             [self.picker_timer selectRow:0 inComponent:1 animated:YES];
                             [self.picker_timer selectRow:0 inComponent:0 animated:YES];
                         }

                     }];
}

- (void)pinchGesture:(UIPinchGestureRecognizer *)pinchGestureRecognizer{
    
    CGFloat scale = 0;
    NSMutableAttributedString *string;
    
    switch (pinchGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.old_scale = 1.0;
            self.last_time = [NSDate date];
            break;
            
        case UIGestureRecognizerStateChanged:
            scale = pinchGestureRecognizer.scale - self.old_scale;
            
            if( [self.last_time timeIntervalSinceNow] < 0.5 )  {       //  updating 5 times a second is best I can do - faster than this and we get buffered changes going on for ages!
                self.last_time = [NSDate date];
                string = [self getScaledStringFrom:[self.textview.attributedText mutableCopy] withScale:1.0 + scale];
                if( string )    {
                    self.textview.attributedText = string;
                    self.old_scale = pinchGestureRecognizer.scale;
                }
            }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            break;
            
        default:
            break;
    }
}

- (NSMutableAttributedString*) getScaledStringFrom:(NSMutableAttributedString*)string withScale:(CGFloat)scale
{
    [string beginEditing];
    [string enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, string.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            UIFont *oldFont = (UIFont *)value;
            newFont = [oldFont fontWithSize:oldFont.pointSize * scale];
            int min_font,max_font;
            if(IS_IPHONE)
            {
                min_font=8;
                max_font=55;
            }
            else{
                min_font=14;
                max_font=70;
            }
            NSLog(@"newFont.pointSize:%f",newFont.pointSize);
            if(newFont.pointSize>max_font || newFont.pointSize<min_font)
            {
                newFont=oldFont;
            }
            
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            {
                [Utility setPortraitFont:[NSNumber numberWithFloat:newFont.pointSize]];
            }
            else
            {
                [Utility setLandscapeFont:[NSNumber numberWithFloat:newFont.pointSize]];
            }
            [string removeAttribute:NSFontAttributeName range:range];
            [string addAttribute:NSFontAttributeName value:newFont range:range];
        }
    }];
    [string endEditing];
    return string;
}

#pragma mark- tableview delegate method
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //    return UITableViewAutomaticDimension;
    if(tableView.tag==1)
    {
        if(IS_IPHONE)
        {
            return 35;
        }
        else{
            return 45;
        }
    }
    else
    {
        int row_height;
        if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame) {
            
            return row_height=expand_height;// Expanded height
        }
        else
        {
            return row_height=collaps_height;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView.tag==1)
    {
        return popupArr.count;
    }
    else
    {
        return _timerOnRecipes.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tempCell;
    if(tableView.tag==1)
    {
        static NSString *cellIdentifier = @"cellID";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:
                                 cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:
                    UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        // Configure the cell...
        int font_size1;
        if(IS_IPHONE)
        {
            font_size1=14.0;
            self.more_tableview.layer.borderWidth=0.5;
        }
        else{
            font_size1=20.0;
            
            self.more_tableview.layer.borderWidth=1;
        }
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:font_size1]];
        self.more_tableview.layer.borderColor=[UIColor lightGrayColor].CGColor;
        cell.backgroundColor=[UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0];
        self.more_tableview.scrollEnabled=NO;
        cell.selectionStyle=NO;
        self.more_tableview.separatorStyle=NO;
        
        NSDictionary *dic=popupArr[indexPath.row];
        cell.textLabel.text=[dic objectForKey:@"menuItem"];
        tempCell=cell;
    }
    else
    {
        CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"timer_cell"];
        if(cell == nil)
        {
            cell=[[CustomCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"timer_cell"];
            NSArray *menuarray=[[NSBundle mainBundle]loadNibNamed:@"CustomCell" owner:self options:nil];
            cell=[menuarray objectAtIndex:0];
        }
        RecipeTimer *timerRecipe = [_timerOnRecipes objectAtIndex:indexPath.row];
        timerRecipe.recipeTimerdelegate = self;
        
       cell.recipeTitleLabel.text =[NSString stringWithFormat:@"%@",timerRecipe.recipeDesc];
        cell.recipeTimerLabel.text =[NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Done in", nil),(timerRecipe.countTimer) ? :@""];
        cell.recipeTitleLabel.tag=1;
        cell.recipeTimerLabel.tag=2;
        
        cell.cellDelegate = self;
        cell.selectionStyle=NO;
        cell.backgroundColor=[UIColor colorWithRed:240.0/255.0 green:243.0/255.0 blue:245.0/255.0 alpha:1.0];
        cell.recipeTimerLabel.backgroundColor=[UIColor clearColor];
        cell.recipeTitleLabel.backgroundColor=[UIColor clearColor];
        
        cell.showRecipeButton.tag = indexPath.row;
        [cell.showRecipeButton addTarget:self action:@selector(showRecipe:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.stopTimerButton.tag = indexPath.row;
        [cell.stopTimerButton addTarget:self action:@selector(stopTimerForRecipe:) forControlEvents:UIControlEventTouchUpInside];

        cell.addMinuteButton.tag = indexPath.row;
        [cell.addMinuteButton addTarget:self action:@selector(addMinuteInRecipeTimer:) forControlEvents:UIControlEventTouchUpInside];

        [cell.showRecipeButton setTitle:NSLocalizedString(@"Show recipe", nil) forState:UIControlStateNormal];
        [cell.stopTimerButton setTitle:NSLocalizedString(@"Stop timer", nil) forState:UIControlStateNormal];
        [cell.addMinuteButton setTitle:NSLocalizedString(@"Add minute", nil) forState:UIControlStateNormal];
        NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
        
        if(![language isEqualToString:@"en"])
        {
            if(IS_IPHONE)
            {
                [cell.showRecipeButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -18, -26, 0)];
                [cell.stopTimerButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -18, -26, 0)];
                [cell.addMinuteButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -37, -26, 0)];

            
                [cell.showRecipeButton setImageEdgeInsets:UIEdgeInsetsMake(-14, 2, 0, -75)];
                [cell.stopTimerButton setImageEdgeInsets:UIEdgeInsetsMake(-13, -1, 0, -84)];
                [cell.addMinuteButton setImageEdgeInsets:UIEdgeInsetsMake(-14, -24, 0, -39)];
            }
            else
            {
                [cell.showRecipeButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -40, -47, 0)];
                [cell.stopTimerButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -34, -45, 0)];
                [cell.addMinuteButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -58, -47, 0)];
                
                [cell.showRecipeButton setImageEdgeInsets:UIEdgeInsetsMake(-16, 6, 0, -84)];
                [cell.stopTimerButton setImageEdgeInsets:UIEdgeInsetsMake(-18, 12, 0, -84)];
                [cell.addMinuteButton setImageEdgeInsets:UIEdgeInsetsMake(-19, -70, 0, -84)];
                
            }
        }
        tempCell=cell;
    }

    return tempCell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag==1)
    {
        if(indexPath.row==0)// Edit recipe
        {
            [self onClickEditButton];
        }
        else if (indexPath.row==1)//Help
        {
            [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self force:YES];
        }
    }
    else
    {
        [self expandCell:indexPath];
    }
    [self collapseMenu];

}

-(NSInteger)totalTimerForReciper{
    return self.timerOnRecipes.count;
}

- (void)timerChangedInRecipe:(RecipeTimer *)recipetimer
{
    NSInteger index = recipetimer.recipeTimerId;//recipe.recipeboxId;
    NSIndexPath *rowPath = [NSIndexPath indexPathForRow:index inSection:0];
//  [self.timerWindowTbl reloadRowsAtIndexPaths:@[rowPath] withRowAnimation:UITableViewRowAnimationNone];
    
    UITableViewCell *cell = [self.timerWindowTbl cellForRowAtIndexPath:rowPath];
    UILabel *labelRecipeDesc = (UILabel*) [cell viewWithTag: 1];
    labelRecipeDesc.text=recipetimer.recipeDesc;

    UILabel *labelRecipeTimerCounter = (UILabel*) [cell viewWithTag: 2];
    labelRecipeTimerCounter.text=[NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Done in", nil),(recipetimer.countTimer) ? :@""];

}

- (void)refreshTimerInRecie:(RecipeTimer *)recipe
{
    [self.timerWindowTbl reloadData];
}

#pragma mark-  stop timer
-(void)stopTimerForRecipe:(UIButton*)sender
{
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.timerWindowTbl];
    expandableIndexPath = [self.timerWindowTbl indexPathForRowAtPoint:buttonPosition];
    CustomCell *timerCell = (CustomCell*)[self.timerWindowTbl cellForRowAtIndexPath:expandableIndexPath];
    
    NSIndexPath *path = [self.timerWindowTbl indexPathForCell:timerCell];
    RecipeTimer *aRecipe = [self.timerOnRecipes objectAtIndex:path.row];
    
    [aRecipe stopTimer];

    [[WatchConnectivityController sharedInstance] stopTimerForRecipeID: aRecipe.recipeboxId];

    [self removeRecipe:aRecipe];
    [self.timerOnRecipes removeObject:aRecipe];
    self.expandedIndexPath=nil;
    
    [self.timerWindowTbl deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
    //    [self.timerWindowTbl reloadData];

    if (_timerOnRecipes.count<1) {
        [[WatchConnectivityController sharedInstance] hideTimerOptionInWatch];
    }

    [UIView transitionWithView:self.timerWindowTbl
                      duration:0.3f
                       options:UIViewAnimationOptionCurveEaseIn
                    animations:^(void)
     {
         
         int y,h;
         if(self.expandedIndexPath!=nil)
         {
             y= SCREEN_HEIGHT-self.bannerView.frame.size.height-expand_height*_timerOnRecipes.count;
             h=(expand_height)*(int)_timerOnRecipes.count;
         }
         else
         {
             y= SCREEN_HEIGHT-self.bannerView.frame.size.height-collaps_height*_timerOnRecipes.count;
             h=collaps_height*(int)_timerOnRecipes.count;
         }
         if(h>SCREEN_HEIGHT-self.bannerView.frame.size.height-self.textview.frame.origin.y-10-self.timerWindowBtn.frame.size.height)
         {
             self.timerWindowTbl.frame=CGRectMake(0,self.textview.frame.origin.y+self.timerWindowBtn.frame.size.height+10, SCREEN_WIDTH,SCREEN_HEIGHT-self.bannerView.frame.size.height-self.textview.frame.origin.y-10-self.timerWindowBtn.frame.size.height);
             
         }
         else
         {
             self.timerWindowTbl.frame=CGRectMake(0,y, SCREEN_WIDTH,h);
         }
         self.timerWindowBtn.frame=CGRectMake(SCREEN_WIDTH-self.timerWindowBtn.frame.size.width, self.timerWindowTbl.frame.origin.y-self.timerWindowBtn.frame.size.height, self.timerWindowBtn.frame.size.width, self.timerWindowBtn.frame.size.height);
     }completion:^(BOOL finished) {
         
     }];
    [UIView commitAnimations];
}

#pragma mark- Show recipe
-(void)showRecipe:(UIButton*)sender
{
    [UIView transitionWithView:self.timerWindowTbl
                      duration:0.3f
                       options:UIViewAnimationOptionCurveEaseIn
                    animations:^(void)
     {
         if(_timerOnRecipes.count==1)
         {
             self.timerWindowTbl.frame=CGRectMake(0, SCREEN_HEIGHT-self.bannerView.frame.size.height-collaps_height*_timerOnRecipes.count, SCREEN_WIDTH,collaps_height*_timerOnRecipes.count);
         }
         
     }completion:^(BOOL finished) {
         
     }];
    [UIView commitAnimations];
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.timerWindowTbl];
    expandableIndexPath = [self.timerWindowTbl indexPathForRowAtPoint:buttonPosition];
    CustomCell *timerCell = (CustomCell*)[self.timerWindowTbl cellForRowAtIndexPath:expandableIndexPath];
    
    NSIndexPath *path = [self.timerWindowTbl indexPathForCell:timerCell];
    RecipeTimer *aRecipe = [self.timerOnRecipes objectAtIndex:path.row];
    
    NSLog(@"Show rcipe");
    r_id = [NSNumber numberWithInteger:aRecipe.recipeboxId];
    recipe = [Recipebox getRecipeById:r_id];
    self.selectedRecipe = aRecipe;
    (theAppDelegate).globalRecipeId=[NSString stringWithFormat:@"%ld",aRecipe.recipeboxId];
    [self loadDatatoWebView];
    self.expandedIndexPath=nil;
    [self.timerWindowTbl reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    [UIView transitionWithView:self.timerWindowTbl
                      duration:0.3f
                       options:UIViewAnimationOptionCurveEaseOut
                    animations:^(void)
     {
         is_timerWindow_open=YES;
         [self closeNotificationWindow];
     }completion:^(BOOL finished) {
         
     }];
    
}
#pragma mark- remove recipe when timer is finished
- (void)removeTimerFinishedRecipe:(RecipeTimer *)inRecipe
{
    if(recipe == nil) return;
    NSInteger index = [self.timerOnRecipes indexOfObject:inRecipe];
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    [self removeRecipe:inRecipe];
    //[self.timerOnRecipes removeObject:inRecipe];
    [self.timerWindowTbl deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];

}


- (void)removeRecipe:(RecipeTimer *)recipes
{
    for(RecipeTimer *recipes in _timerOnRecipes)
    {
        recipes.tempSecondsLeft = recipes.secondsLeft;
        [recipes stopTimer];
    }
    [_timerOnRecipes removeObject:recipes];
    
    [self timerBtnShoworNot];

    if (_timerOnRecipes.count<1) {
        [[WatchConnectivityController sharedInstance] hideTimerOptionInWatch];
    }
    
    [_timerOnRecipes enumerateObjectsUsingBlock:^(RecipeTimer  *obj, NSUInteger idx, BOOL *stop) {
        obj.recipeTimerId = idx;
        obj.secondsLeft = obj.tempSecondsLeft;
        [obj startTimer];
    }];
    
}
#pragma mark- Add minute in current timer
-(void)addMinuteInRecipeTimer:(UIButton*)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.timerWindowTbl];
    expandableIndexPath = [self.timerWindowTbl indexPathForRowAtPoint:buttonPosition];
    CustomCell *timerCell = (CustomCell*)[self.timerWindowTbl cellForRowAtIndexPath:expandableIndexPath];
    
    NSIndexPath *path = [self.timerWindowTbl indexPathForCell:timerCell];
    [self.timerWindowTbl reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    RecipeTimer *aRecipe = [self.timerOnRecipes objectAtIndex:path.row];
    aRecipe.tempSecondsLeft = aRecipe.secondsLeft;
    aRecipe.secondsLeft = aRecipe.tempSecondsLeft + 60 ; //update(Add one minute in current timer)
    [[WatchConnectivityController sharedInstance] updateTimerForRecipeID:aRecipe];
}
#pragma mark-notification window open close animation
-(void)openNotificationWindow
{
    [self.timerWindowBtn setImage:[UIImage imageNamed:@"backimg_white"] forState:UIControlStateNormal];
    is_timerListOpen=true;
    NSLog(@"open ...");
    
    
    int y,h;
    if(self.expandedIndexPath!=nil)
    {
        y= SCREEN_HEIGHT-self.bannerView.frame.size.height-(collaps_height*_timerOnRecipes.count)-collaps_height;
        h=(collaps_height)*(int)_timerOnRecipes.count+collaps_height;
        
    }
    else
    {
        NSLog(@"self.bannerView.frame.size.height:%f",self.bannerView.frame.size.height);
        y= SCREEN_HEIGHT-self.bannerView.frame.size.height-collaps_height*_timerOnRecipes.count;
        h=collaps_height*(int)_timerOnRecipes.count;
    }
    if(h>SCREEN_HEIGHT-self.bannerView.frame.size.height-self.textview.frame.origin.y-10-self.timerWindowBtn.frame.size.height)
    {
        self.timerWindowTbl.frame=CGRectMake(0,self.textview.frame.origin.y+self.timerWindowBtn.frame.size.height+10, SCREEN_WIDTH,SCREEN_HEIGHT-self.bannerView.frame.size.height-self.textview.frame.origin.y-10-self.timerWindowBtn.frame.size.height);
        
    }
    else
    {
        self.timerWindowTbl.frame=CGRectMake(0,y, SCREEN_WIDTH,h);
    }
    self.timerWindowBtn.frame=CGRectMake(SCREEN_WIDTH-self.timerWindowBtn.frame.size.width, self.timerWindowTbl.frame.origin.y-self.timerWindowBtn.frame.size.height, self.timerWindowBtn.frame.size.width, self.timerWindowBtn.frame.size.height);
}
-(void)closeNotificationWindow
{
    [self.timerWindowBtn setImage:[UIImage imageNamed:@"up_backimg_white"] forState:UIControlStateNormal];
    
    self.timerWindowTbl.translatesAutoresizingMaskIntoConstraints=YES;
    self.timerWindowTbl.frame=CGRectMake(0,SCREEN_HEIGHT-self.bannerView.frame.size.height, SCREEN_WIDTH,0);
    is_timerWindow_open=true;
    
    self.timerWindowBtn.frame=CGRectMake(SCREEN_WIDTH-self.timerWindowBtn.frame.size.width, self.timerWindowTbl.frame.origin.y-self.timerWindowBtn.frame.size.height, self.timerWindowBtn.frame.size.width, self.timerWindowBtn.frame.size.height);
}
-(IBAction)onclick_timerWindow:(id)sender
{
    if(self.expandedIndexPath!=nil)
    {
        self.expandedIndexPath=nil;
        [self.timerWindowTbl reloadData];
    }
    if (is_timerWindow_open) {
        [UIView transitionWithView:self.timerWindowTbl
                          duration:0.3f
                           options:UIViewAnimationOptionCurveEaseIn
                        animations:^(void)
         {
             is_timerListOpen=false;
             [self openNotificationWindow];
             is_timerWindow_open=false;
             
         }completion:^(BOOL finished) {
             
         }];
    }else{
        [UIView transitionWithView:self.timerWindowTbl
                          duration:0.3f
                           options:UIViewAnimationOptionCurveEaseOut
                        animations:^(void)
         {
             is_timerListOpen=false;
             is_timerWindow_open=YES;
             [self closeNotificationWindow];
          }completion:^(BOOL finished) {
             
         }];
    }
}
#pragma mark- timer btn show or not
-(void)timerBtnShoworNot
{
    if(_timerOnRecipes.count>0 && _timerOnRecipes!=nil)
    {
        
        is_timerWindow_open=false;
        self.timerWindowTbl.hidden=NO;
        self.timerWindowBtn.hidden=NO;
        is_timerWindow_open=false;
    }
    else
    {
        is_timerWindow_open=true;
        self.timerWindowTbl.hidden=YES;
        self.timerWindowBtn.hidden=YES;
    }
    
    
}
#pragma mark- gesture
- (void)handlePan:(UIPanGestureRecognizer*)recognizer
{
    
    CGPoint velocity = [recognizer velocityInView:self.view];
    BOOL isVerticalGesture = fabs(velocity.y) > fabs(velocity.x);
    
    // when drag STATE changed
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        // when scroll is verticle
        if(isVerticalGesture)
        {
            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options: UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 if(velocity.y > 0)
                                 {
                                     // down
                                     if (!is_timerWindow_open) {
                                         is_timerListOpen=false;
                                         is_timerWindow_open=YES;
                                         [self closeNotificationWindow];
                                      }
                                 }
                                 else{
                                     // top
                                     if (is_timerWindow_open) {
                                         
                                         is_timerListOpen=false;
                                         [self openNotificationWindow];
                                         is_timerWindow_open=false;
                                     }
                                 }
                            }
                             completion:^(BOOL finished){
                             }];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded){
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
        
        if(isVerticalGesture)
        {
            if (velocity.y > 0)
            {
                //Down
                if (!is_timerWindow_open) {
                    is_timerListOpen=false;
                    is_timerWindow_open=YES;
                    [self closeNotificationWindow];
                  }
             }
            else
            {
                // top
                if (is_timerWindow_open) {
                    
                    is_timerListOpen=false;
                    [self openNotificationWindow];
                    is_timerWindow_open=false;
                }
            }
         }
    }completion:^(BOOL finished) {
                             
        }];
    }
}

- (void)expandCell:(NSIndexPath *)indexPath
{
    
   // self.expandedIndexPath=indexPath;
    [self.timerWindowTbl beginUpdates];
    
    if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame)
    {
        self.expandedIndexPath = nil;
        [self.timerWindowTbl endUpdates];
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:4.0
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{

                            if(_timerOnRecipes.count==1)
                             {
                                int y,h;
                                 y= SCREEN_HEIGHT-self.bannerView.frame.size.height-collaps_height*_timerOnRecipes.count;
                                 h=collaps_height*(int)_timerOnRecipes.count;
                                 self.timerWindowTbl.frame=CGRectMake(0, y, SCREEN_WIDTH,h);
                                 self.timerWindowBtn.frame=CGRectMake(SCREEN_WIDTH-self.timerWindowBtn.frame.size.width, self.timerWindowTbl.frame.origin.y-self.timerWindowBtn.frame.size.height, self.timerWindowBtn.frame.size.width, self.timerWindowBtn.frame.size.height);
                             }
                             else
                             {
                                 int y,h;
                                 if(self.expandedIndexPath!=nil)
                                 {
                                     y= SCREEN_HEIGHT-self.bannerView.frame.size.height-collaps_height*_timerOnRecipes.count;
                                     h=(collaps_height)*(int)_timerOnRecipes.count;
                                 }
                                 else
                                 {
                                     y= SCREEN_HEIGHT-self.bannerView.frame.size.height-collaps_height*_timerOnRecipes.count;
                                     h=collaps_height*(int)_timerOnRecipes.count;
                                 }
                                 
                                 if(h>SCREEN_HEIGHT-self.bannerView.frame.size.height-self.textview.frame.origin.y-10-self.timerWindowBtn.frame.size.height)
                                 {
                                     self.timerWindowTbl.frame=CGRectMake(0,self.textview.frame.origin.y+self.timerWindowBtn.frame.size.height+10, SCREEN_WIDTH,SCREEN_HEIGHT-self.bannerView.frame.size.height-self.textview.frame.origin.y-10-self.timerWindowBtn.frame.size.height);
                                 }
                                 else
                                 {
                                     self.timerWindowTbl.frame=CGRectMake(0,y, SCREEN_WIDTH,h);
                                 }
                                 self.timerWindowBtn.frame=CGRectMake(SCREEN_WIDTH-self.timerWindowBtn.frame.size.width, self.timerWindowTbl.frame.origin.y-self.timerWindowBtn.frame.size.height, self.timerWindowBtn.frame.size.width, self.timerWindowBtn.frame.size.height);

                             }
                         }completion:^(BOOL finished) {
                             
                         }];
        [UIView commitAnimations];

       }
    else
    {
        self.expandedIndexPath = indexPath;
        [self.timerWindowTbl endUpdates];

        [UIView animateWithDuration:0.7
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:4.0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             if(_timerOnRecipes.count==1)
                             {
                                 self.timerWindowTbl.frame=CGRectMake(0, SCREEN_HEIGHT-self.bannerView.frame.size.height-expand_height*_timerOnRecipes.count, SCREEN_WIDTH,expand_height*_timerOnRecipes.count);
                                 self.timerWindowBtn.frame=CGRectMake(SCREEN_WIDTH-self.timerWindowBtn.frame.size.width, self.timerWindowTbl.frame.origin.y-self.timerWindowBtn.frame.size.height, self.timerWindowBtn.frame.size.width, self.timerWindowBtn.frame.size.height);
                             }
                             

                             if([indexPath row]==((NSIndexPath*)[[self.timerWindowTbl indexPathsForVisibleRows]lastObject]).row)
                             {
                                 [self.timerWindowTbl scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.expandedIndexPath.row inSection:self.expandedIndexPath.section] atScrollPosition:UITableViewScrollPositionBottom animated:NO];

                             }
                             
                         }
                         completion:^(BOOL finished){
                             
                         }];
        [UIView commitAnimations];
    }
}
#pragma mark- opetion menu
-(void)onClickOptionButton{
    if(is_dropDownOpen)
    {
        [self expandMenu];
    }
    else
    {
        [self collapseMenu];
    }
}
-(void)expandMenu
{
    is_dropDownOpen=false;
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect frame = self.more_tableview.frame;
                         frame.size.height = more_tableview_height;
                         self.more_tableview.frame = frame;
                     }
                     completion:^(BOOL finished){
                         NSLog(@"Done!");
                     }];
    
}
-(void)collapseMenu
{
    is_dropDownOpen=true;
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect frame = self.more_tableview.frame;
                         frame.size.height = 0;
                         self.more_tableview.frame = frame;
                     }
                     completion:^(BOOL finished){
                     }];
    
    
}
#pragma mark- Scrollview delegate Method
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    DLog(@"scrollViewWillBeginDragging called ");
    //Dimple-30-11-2015
    [self collapseMenu];
}

-(void) sendAnalytics {
    MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    NSString *url = [NSString stringWithFormat:@"Recipes/%@/Views", recipe.recipeboxID];
    [client POST:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        DLog(@"Recipe statistics saved");
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        DLog(@"Recipe statistics failed");
    }];
}

@end

