//
//  ItemsViewController.m
//  MatListan
//
//  Created by Yan Zhang on 20/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ItemsViewController.h"
#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "SignificantChangesIndicator.h"
#import "SortingSyncManager.h"
#import "ShopsTableViewController.h"
#import "ItemListsSorting+Extra.h"
#import "HelpDialogManager.h"
#import "Version_VC.h"

#import "Mixpanel.h"
#import "FavoriteItem.h"
#import "RecipeDetailViewController.h"

#import "Appirater.h"

#define UNSORTED_SECTION 0
#define SORTED_SECTION 1
#define MAX_ITEM_RELOAD_TIMES 20



//dimple-19-10-2015
#define myscreenwidth (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

@interface ItemsViewController ()
{
    DataStore *dataStore;
    
    BOOL isSuggestionOn;

    NSMutableArray *suggestedItems;
    
    UIActivityIndicatorView * spinner;
    
    UIImageView * bgimage;
    UIImage *imageMenu;
    UILabel * loadingLabel;
    
    NSArray *headerNames; //TODO not used - Markus
    
    NSMutableArray *allItems;      //all the items for section 1
    NSMutableArray *sortedItems;    //used for sorting by STORE
    NSMutableArray *unknownItems;   //used for sorting by STORE
    
    NSNumber *currentListId;        //current list id //TODO use this id instead of Datastore id
    
    NSManagedObjectID *currentListObjectId; //TODO not used - Markus
    
    NSString *cookie; //TODO not used - Markus
    
    NSNumber *selectedItemId;
    
    NSString *selectedItemText; //TODO not used - Markus
    
    NSManagedObjectID *selectedItemObjectId;
    
    NSIndexPath *selectedIndexPath;
    
    //Store *favoriteStore;
    
    NSArray *sectionNames;
    NSArray *sortingNames;
    
    int reloadTimes; //TODO not used - Markus
    
    NSArray *constraintVertical; //TODO not used - Markus
    NSArray *constraintHorizontal; //TODO not used - Markus
    
    BOOL waitOverlayHasBeenShown;
    BOOL hasShownSortingError;
    BOOL changeDeleteMenuShowing;
    
    UIView *loadingView;
    
    NSString *methodOfAddingItem;
    
    Item *selectedItem;
    //UIImage *imageVagn;
    
    //Dimple 7-10-2015
    //    UIView *expanView;
    IBOutlet UIButton *expandViewBtn;
    NSIndexPath *expandableIndexPath;
    int expand_height,collaps_height;
    //dimple-19-10-2015
    float my_screenwidth;
    
    //Dimple-21-10-2015
    BOOL picker_Flag,isDrop,is_store;
    int colorFlag,colorFlag2;
    
    NSString *old_cat,*new_cat;
    NSMutableArray *colorArr;
    NSMutableArray *SortedcolorArr;
    NSMutableArray *UnSortedcolorArr;
    
    
    //Dimple-26-11-2015
    NSMutableArray *Final_Fav_arr;
    Item *LastFavItem;
    //Dimple-30-11-2015
    int navigationBarHeight;
    int x,w,h,floating_X,floating_Y,floating_W,floating_H;
    
    NSMutableArray *matchingItemArray;
    
    
}

@property (weak, nonatomic) IBOutlet UILabel *userHintLabel;

@property(strong) MatlistanHTTPClient *httpClient;
@property(nonatomic, assign)CGFloat oldBottomContentInset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint; // defualt is 2
@end

@implementation ItemsViewController
     
@synthesize httpClient;
@synthesize addButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.showNoData = NO;
    LittleDataInfo=false;
    CLS_LOG(@"Itemviewcontroller view did load called");

    [self.textfieldForNewItem setPlaceholder:NSLocalizedString(@"AddNewItem", nil)];
    is_displayUndoToast=false;
    is_undoBtnClick=false;
    
    
    //raj-20-1-16
    
        SWRevealViewController *revealController = self.revealViewController;
        revealController=[[SWRevealViewController alloc]init];
        revealController = [self revealViewController];
        [self.view addGestureRecognizer:revealController.panGestureRecognizer];
        revealController.delegate=self;
        [revealController panGestureRecognizer];
        [revealController tapGestureRecognizer];
    

    //Dimple
    if((theAppDelegate).open_from_notification)
    {
        NSString *str1=[Utility getTimerRecipeId];
        NSNumber *num1 = @([str1 intValue]);
        Recipebox *r = [Recipebox getRecipeById:num1];
        RecipeTimer *selRecipe = [[RecipeTimer alloc] initWithRecipieId:[r.recipeboxID intValue] recipeName:r.title withRecipeDesc:nil];
        
        UINavigationController *navigationController = (UINavigationController *)self.revealViewController.frontViewController;
        navigationController.navigationBarHidden=YES;
        (theAppDelegate).detailRecipeFlag=false;
        RecipeDetailViewController *recipeController = [self.storyboard instantiateViewControllerWithIdentifier:@"RecipeDetail"];
        recipeController.timerOnRecipes=(theAppDelegate).ActiveTimerArr;
        recipeController.barButtonType = NOT_CERTAIN;
        recipeController.selectedRecipe=selRecipe;
        
        recipeController.timerOnRecipes = (theAppDelegate).ActiveTimerArr; //_timerOnRecipes;
        selRecipe.recipeListDelegate =  (id)theAppDelegate;
        selRecipe.recipeTimerdelegate = recipeController;

        //Dimple
        recipeController.screen_name=@"Recent";
        navigationController.viewControllers = @[recipeController];
        
        //[self.revealViewController setFrontViewController:recipeController animated:YES];
        [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
        
        
    }
    
    // self.imageView.image=(theAppDelegate).customImage;
    isDrop=NO;
    is_store=false;
    
    int n;
    if(IS_IPHONE)
    {
        n=3;
    }
    else
    {
        n=5;
    }
    
    self.view.layer.cornerRadius=n;
    self.view.layer.masksToBounds=YES;
    
    
    //Dimple-26-11-2015*******************
    
    Final_Fav_arr=[[NSMutableArray alloc]init];
    (theAppDelegate).no_fav_item_flag=false;
    my_screenwidth=SCREEN_WIDTH;
    
    self.testImage.hidden=YES;
    UIInterfaceOrientation orientation1 = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation1 == UIInterfaceOrientationPortrait || orientation1 == UIInterfaceOrientationPortraitUpsideDown)
    {
        if([Utility getItemscustomImage]!=nil)
        {
            self.testImage.image=[Utility getItemscustomImage];
            self.testImage.hidden=NO;
        }
    }
    else
    {
        if([Utility getItemscustomLandImage]!=nil)
        {
            self.testImage.image=[Utility getItemscustomLandImage];
            self.testImage.hidden=NO;
        }
    }
    
    //Dimple-7-10-2015
    if(IS_IPHONE)
    {
        expand_height=96;
        collaps_height=48;
    }
    else
    {
        expand_height=143;
        collaps_height=70;
    }
    stop_animation=YES;
    //methodOfAddingItem = @"Manual";
    
    changeDeleteMenuShowing = NO;
    hasShownSortingError = NO;
    isSuggestionOn = NO;
    
    
    self.buttonAdd.hidden=YES;
    self.menu.hidden=NO;
    self.buttonFav.hidden=NO;
     self.menu.hidden=NO;
    
    self.textfieldForNewItem.delegate = self;
    self.txtView.layer.cornerRadius=3;
    [self.textfieldForNewItem sizeToFit];
    self.buttonAdd.layer.cornerRadius=3;
    self.buttonVoice.layer.cornerRadius=3;
    self.buttonFav.layer.cornerRadius=3;
    self.buttonBarcode.layer.cornerRadius=3;
    
    httpClient = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    httpClient.delegate = self;
    
    dataStore = [DataStore instance];
    dataStore.hasListBeenShown = NO;
    if (dataStore.tagByURL.length > 0)
    {
        [self performSegueWithIdentifier:@"itemsToRecipes" sender:self];
    }
    
    allItems = [[NSMutableArray alloc]init];
    sortedItems = [[NSMutableArray alloc]init];
    unknownItems = [[NSMutableArray alloc]init];
    
    sortingNames = @[NSLocalizedString(@"Latest first",nil),
                     NSLocalizedString(@"Alphabetically", nil),
                     NSLocalizedString(@"Own sorting", nil),
                     NSLocalizedString(@"By category", nil),
                     NSLocalizedString(@"Unsorted items", nil),
                     NSLocalizedString(@"Alphabetically", nil)];
    
    //imageVagn = [UIImage imageNamed:@"vagn"];
    imageMenu = [UIImage imageNamed:@"menu"];
    // UIImage *imageLists = [UIImage imageNamed:@"lists"];
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:imageMenu style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
    
    
    //Dimple-16-9-2015
    //CGRect frameimg = CGRectMake(250, 9, 32,32);
    // UIButton *SettingButton = [[UIButton alloc] initWithFrame:frameimg];
    // [SettingButton setBackgroundImage:imageVagn forState:UIControlStateNormal];
    //[SettingButton addTarget:self action:@selector(switchToStore)forControlEvents:UIControlEventTouchUpInside];
    //[SettingButton setShowsTouchWhenHighlighted:YES];
    //UIBarButtonItem *storeButton =[[UIBarButtonItem alloc] initWithCustomView:SettingButton];
    //self.navigationItem.rightBarButtonItem=storeButton;
    
    //     UIBarButtonItem *storeButton = [[UIBarButtonItem alloc] initWithImage:imageVagn style:UIBarButtonItemStylePlain target:self action:@selector(switchToStore)];
    
    self.navigationItem.leftBarButtonItems = @[menuButton];
    //self.navigationItem.rightBarButtonItems = @[storeButton];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSorting:) name:@"SortingChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableWithNewItems:) name:@"FinishInsertingItems" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuIsShown:) name:@"MenuShown" object:nil];
    
    
    
    //Facebook Token renewel if 1 day left in expiry of current token
    /*
    if ([Utility getCurrentLoginType] == LoginTypeFacebook) {
        
        FBSDKAccessToken *recentToken = [FBSDKAccessToken currentAccessToken];
        NSDate *expDate = [recentToken expirationDate];
        NSDate *todayDate = [NSDate date];
        if ([Utility daysBetweenDate:todayDate andDate:expDate] <= 1) {
            DLog(@"refreshing Facebook token");
            [FBSDKAccessToken refreshCurrentAccessToken:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                DLog(@"result refreshCurrentAccessToken = %@",(NSDictionary *) result);
                if (error) {
                    DLog(@"failed refreshCurrentAccessToken");
                    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                    {
                        [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"action":@"refreshCurrentAccessToken"}];
                    }
                }
                
            }];
        }
    } else if([Utility getCurrentLoginType] == LoginTypeGoogle) {
       NSDate *expDate = [Utility getObjectFromDefaults:@"GoogleAccessTokenExpirationDate"];
       NSDate *todayDate = [NSDate date];
       if ([todayDate compare: expDate] == NSOrderedDescending) {
       [GIDSignIn sharedInstance].delegate = [MatlistanHTTPClient sharedMatlistanHTTPClient];
       [[GIDSignIn sharedInstance] signInSilently];
       }
       }
       */
    
    //DLog(@"self.tableView.constraints %@", self.tableView.constraints);
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"lastVersion"] != nil) {
        if(![[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastVersion"]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPopup) name:@"dismissMJPopUp" object: nil];
            Version_VC *Version=[[Version_VC alloc]initWithNibName:@"Version_VC" bundle:nil];
            if(Version.hasContent){
                [self presentPopupViewController:Version animationType:MJPopupViewAnimationFade];
            }
            [Utility saveInDefaultsWithObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] andKey:@"lastVersion"];
        }
    }
    else {
        [Utility saveInDefaultsWithObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] andKey:@"lastVersion"];
    }
}

-(void)dismissPopup
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    //Show rate dialog here
    /*
     The review dialog has not been shown yet: Do nothing, wait for the review dialog as today
     The review dialog has been shown, but less than a month ago: Show the review dialog again when one month has passed since the review dialog was last shown.
     */
     /*
      IOS-82
     The review dialog has been shown, but more than a month ago: Show the review dialog immediately.
     */
    if(![(Appirater *)[Appirater sharedInstance] userHasRatedCurrentVersion]) {
        NSDate *date = [Appirater getLastRatedDate];
        if(date != nil && [Utility monthsBetweenDate:date andDate:[NSDate new]] >= 1){
            [Appirater forceShowPrompt:YES];
        }
    }
}
-(void)dismissList:(NSNotification *)noti
{
    NSDictionary* userInfo = noti.userInfo;
    if([[userInfo objectForKey:@"Option"] isEqualToString:@"Move Items"])
    {
        //methodOfAddingItem = @"Manual";
        Item *SelItem=[userInfo objectForKey:@"SelectItem"];
        
        //[Item fakeDelete:SelItem.objectID];
        Item_list *list=[userInfo objectForKey:@"SelectedList"];
        //[Item insertItemWithText:[userInfo objectForKey:@"SelectedItemText"] andBarcode:@"" andBarcodeType:@"" belongToList:list withSource:methodOfAddingItem];
        
        [SelItem updateItemWithItemListId:list.item_listID];
        
        [[SyncManager sharedManager] forceSync];

    }
    else if([[userInfo objectForKey:@"Option"] isEqualToString:@"Copy Items"])
    {
        methodOfAddingItem = @"Manual";
        Item_list *list=[userInfo objectForKey:@"SelectedList"];
        [Item insertItemWithText:[userInfo objectForKey:@"SelectedItemText"] andBarcode:@"" andBarcodeType:@"" belongToList:list withSource:methodOfAddingItem];
        [[SyncManager sharedManager] forceSync];
        
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"dismissListView" object:nil];
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    [self loadRecordsFromCoreData];

}
#pragma mark - view
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self AddFavouriteButtonWithTable];

    if([self.textfieldForNewItem isFirstResponder])
    {
        self.menu.hidden=YES;
    }
    else{
        self.menu.hidden=NO;
    }
    //Raj 18-1-2016
    SWRevealViewController *reveal = self.revealViewController;
    reveal.panGestureRecognizer.enabled = YES;

    //self.buttonVoice.userInteractionEnabled=YES;
    
    self.userHintLabel.text=@"Please wait...";
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        [self loadRecordsFromCoreData];
        //Dimple-19-10-2015
        if(IS_OS_8_OR_LATER)
        {
            my_screenwidth=SCREEN_WIDTH;
        }
        else
        {
            my_screenwidth=myscreenwidth;
        }
        
        
        [SyncManager sharedManager].syncManagerDelegate = self;
        
        // DLog(@"function name : %s", __FUNCTION__);
        // DLog(@"unknown items count : %d", (int)unknownItems.count);
        
        // register notification for keyboard
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(wakeUp:) name: @"UpdateUINotification" object: nil];
        
        [SortingSyncManager sharedSortingSyncManager].sortingSyncManagerDelegate = self;
        
        [self moveUpTableViewPosition: NO];
        
        if (_ingredientSearchText.length > 0)
        {
            self.textfieldForNewItem.text = _ingredientSearchText;
        }
        else if ([DataStore instance].ingredientByURL && [DataStore instance].ingredientByURL.length > 0)
        {
            self.textfieldForNewItem.text = [DataStore instance].ingredientByURL;
        }
        else
        {
            self.textfieldForNewItem.text = [DataStore instance].iTemNameNotAddedYet;
        }
        
        if (self.textfieldForNewItem.text.length > 0)
        {
             [self TextBoxAnimationStart];
//            [self.textfieldForNewItem becomeFirstResponder];
            [self switchSuggestionTo:YES];
        }
        
        //  DLog(@"Sort by storeID %@, current list %@",[DataStore instance].sortByStoreID,[DataStore instance].currentList.name );
        
        //[self setFavoriteStoreName];
        //[self loadRecordsFromCoreData];
        
        // IOS-10: get rid of ads /Yousuf 7-10-2015
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
        if ([Utility getDefaultBoolAtKey:@"hasPremium"])
        {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_TO_REMOVE_ADS * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                           {
                               [self removeAds];
                               
                           });
        }
        [self AddFloatingButton];
        [self.tableView setContentOffset:CGPointMake(0, 0)];
        
        if(is_displayUndoToast)
        {
            is_displayUndoToast=false;
            [self ShowToastForUndoItem:undoItemName];
        }

        
        // DLog(@"end of function : %s", __FUNCTION__);
        // DLog(@"unknown items count : %d", (int)unknownItems.count);
    });
    
   
}
- (void) wakeUp: (NSNotification*)notification {
    [SyncManager sharedManager].syncManagerDelegate = self;
    [self didUpdateItems];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    CLS_LOG(@"Showing ItemsViewController");
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        // DLog(@"Google Mobile Ads SDK version: %@", [GADRequest sdkVersion]);
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if([SortingSyncManager sharedSortingSyncManager].sortingSyncManagerDelegate == self)
    {
        [SortingSyncManager sharedSortingSyncManager].sortingSyncManagerDelegate = nil;
    }
    
    // remove resister notification for keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPremiumAccountPurchased object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateUINotification" object:nil];
    
    //TODO here we store the list id - Markus
    //[Utility saveInDefaultsWithInt:[[DataStore instance].currentList.item_listID intValue] andKey:@"DEFAULT_LIST_ID"];
    [Utility saveInDefaultsWithInt:(long)currentListId andKey:@"DEFAULT_LIST_ID"];
    
    if (([self.tableView visibleCells].count > 0)&&(_ingredientSearchText.length == 0))
    {
        if (self.textfieldForNewItem.text && self.textfieldForNewItem.text.length > 0)
        {
            [DataStore instance].iTemNameNotAddedYet = self.textfieldForNewItem.text;
        }
    }
    
    if (self.customPickerView)
    {
        [self.customPickerView removeFromSuperview];
    }
    
    // DLog(@"function name : %s", __FUNCTION__);
    //  DLog(@"unknown items count : %d", (int)unknownItems.count);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [DataStore instance].ingredientByURL = @""; //clear the content in the textfield for the future
    _ingredientSearchText = @"";
    
    [self switchSuggestionTo:NO];   //turn off suggestion mode
    
    //DLog(@"function name : %s", __FUNCTION__);
    // DLog(@"unknown items count : %d", (int)unknownItems.count);
}

/**
 Remove ads if user has purchased premium
 @ModifiedDate: October 7 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)removeAds
{
    [self.addButton removeFromSuperview];
    [self AddFloatingButton];

    if (self.bannerView)
    {
        [self.bannerView removeConstraints:self.bannerView.constraints];
        [self.bannerView removeFromSuperview];
        [Utility updateConstraint:self.view toView:self.tableView withConstant:0];
    }
}

#pragma mark - show data on the UI

- (void)updateTableWithNewItems:(NSNotification*)notif
{
    //Ticket # 93 Slide in menu on an item, wait a few sec, sometimes menu disappears #iPhone4
    if(!changeDeleteMenuShowing)
    {
        [self reloadData];
    }
}

- (void)reloadData
{
    [self loadRecordsFromCoreData];
    //    [self removeWaitOverlay]; //TODO - not sure if this is needed - Markus
    [SVProgressHUD dismiss];
    [self.view setNeedsDisplay];
}

/**
 *Load the items from core data
 */
- (void)loadRecordsFromCoreData
{
    //Dimple-26-11-2015
    [self setCurrentList];
    NSString *navigationTitle = dataStore.currentList.name;
    if(navigationTitle.length==0 || navigationTitle==nil)
    {
        navigationTitle=@"";
    }
    // Raj - 26-9-15
    int nav_title_x=70,nav_title_width=180,nav_title_char=15,title_font_size=17;
    if(IS_IPHONE)
    {
        nav_title_x=70;
        nav_title_width=180;
        nav_title_char=15;
        title_font_size=17;
    }
    else
    {
        nav_title_x=10;
        nav_title_width=280;
        nav_title_char=30;
        title_font_size=20;
        
    }
    UIView *navTitle = [[UIView alloc] initWithFrame:CGRectMake(nav_title_x,6,nav_title_width,imageMenu.size.height)];
    UILabel *ListTitle=[[UILabel alloc]initWithFrame:CGRectMake(0,0,nav_title_width,imageMenu.size.height)];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed:@"backimg"];
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    NSMutableAttributedString *myString=nil;
    if(navigationTitle.length<=nav_title_char)
    {
        myString= [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",navigationTitle]];
    }
    else
    {
        myString= [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",[navigationTitle substringWithRange:NSMakeRange(0, nav_title_char)]]];
    }
    [myString appendAttributedString:attachmentString];
    
    ListTitle.attributedText = myString;
    ListTitle.textAlignment=NSTextAlignmentCenter;
    [ListTitle setFont:[UIFont systemFontOfSize:title_font_size]];
    [navTitle addSubview:ListTitle];
    
    UIButton *ShowList =[[UIButton alloc] initWithFrame:CGRectMake(nav_title_x,0,nav_title_width,imageMenu.size.height)];
    ShowList.backgroundColor=[UIColor clearColor];
    //    [ShowList setAttributedTitle:myString forState:UIControlStateNormal];
    [ShowList addTarget:self action:@selector(showLists) forControlEvents:UIControlEventTouchUpInside];
    
    [navTitle addSubview:ShowList];
    
    [navTitle setBackgroundColor:[UIColor clearColor]];
    self.navigationItem.titleView = navTitle;
    
    
    
    if ([self isStoreIDEmpty] && dataStore.sortingOrder == STORE)
    {
        [dataStore setPreviousSortingOrder];
        DLog(@"Empty store ID, use previous sorting order %d", dataStore.sortingOrder);
    }
    
    if ([DataStore instance].sortingOrder == STORE)
    {
        [self getSortedItemsByStoreFromServer];
    }
    else
    {
        sortedItems = [[NSMutableArray alloc] init];
        unknownItems = [[NSMutableArray alloc] init];
        
        DLog(@"sorting order %d",[DataStore instance].sortingOrder);
//        if([DataStore instance].sortingOrder==0 || [DataStore instance].sortingOrder==1)
//        {
//            [Utility SetSortName:nil];
//        }
//        else
//        {
//            [Utility SetSortName:@"By category"];
//        }
        allItems = [NSMutableArray arrayWithArray:[Item getItemsToBuyFromList:[DataStore instance].currentList.item_listID andList:[DataStore instance].currentList andSortInOrder:[DataStore instance].sortingOrder]];

        //Dimple - Color Chnage
        if(allItems!=nil && allItems.count!=0)
        {
            colorFlag=0;
            colorFlag2=0;
            Item *firstItem=allItems[0];
            old_cat=firstItem.placeCategory;
            
            
        }
        
    }
    
    [self reloadtableViewData];
    [self getFavouritFromCoredata];//Dimple 21-12-15
    
}

- (void)setCurrentList
{
    if(dataStore.currentList == nil)
    {
        NSInteger listID = [Utility getDefaultIntAtKey:@"DEFAULT_LIST_ID"];
        if (listID != 0)
        {
            currentListId = [NSNumber numberWithInteger:listID];
            dataStore.currentList = [Item_list getListById:currentListId];
            
            if (dataStore.currentList == nil)
            {
                dataStore.currentList = [Item_list getDefaultList];
                currentListId = dataStore.currentList.item_listID;
            }
        }
        else
        {
            dataStore.currentList = [Item_list getDefaultList];
            currentListId = dataStore.currentList.item_listID;
        }
    }
    else
    {
        currentListId = dataStore.currentList.item_listID;
        if (currentListId == nil)
        {
            dataStore.currentList = [Item_list getDefaultList];
            currentListId = dataStore.currentList.item_listID;
        }
    }
    
    currentListObjectId = dataStore.currentList.objectID;
    DLog(@"%u",(SORT_TYPE)[Item_list getSortType:dataStore.currentList]);
    dataStore.sortingOrder = (SORT_TYPE)[Item_list getSortType:dataStore.currentList];
    
    if ([DataStore instance].sortingOrder == STORE)
    {
        dataStore.sortByStoreID = dataStore.currentList.sortByStoreId;
    }
}

#pragma mark - UI related

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.menu removeFromSuperview];
    [self.addButton removeFromSuperview];
    x=53,w=53,h=48;
    if(IS_IPHONE)
    {
        my_screenwidth=SCREEN_WIDTH;
        
        x=my_screenwidth-53;
        w=53;
        h=48;
    }
    else
    {
        my_screenwidth=SCREEN_WIDTH;
        
        x=my_screenwidth-70;
        w=68;
        h=68;
    }
    
    int floating_distance=0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height+20;
        self.menu = [[DOPDropDownMenu alloc] initWithOrigin:CGPointMake(my_screenwidth-105, 0) andX:x andY:navigationBarHeight andWidth:w andHeight:h];
        if(IS_IPHONE)
        {
            
            floating_W=44;
            floating_H=44;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=30;
            
        }
        else
        {
            floating_W=66;
            floating_H=66;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=45;
        }
        
    }
    else
    {
        if ([UIApplication sharedApplication].isStatusBarHidden)
        {
            navigationBarHeight=self.navigationController.navigationBar.frame.size.height;
        }
        else
        {
            navigationBarHeight=self.navigationController.navigationBar.frame.size.height+20;
        }
        self.menu = [[DOPDropDownMenu alloc] initWithOrigin:CGPointMake(my_screenwidth-105, 0) andX:x andY:navigationBarHeight andWidth:w andHeight:h];
        if(IS_IPHONE)
        {
            floating_W=44;
            floating_H=44;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            
            floating_distance=30;
            
        }
        else
        {
            floating_W=66;
            floating_H=66;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            
            floating_distance=45;
            
        }
    }
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        floating_Y=SCREEN_HEIGHT-floating_distance-floating_H;
    }
    else
    {
        floating_Y=SCREEN_HEIGHT-self.bannerView.frame.size.height-floating_distance-floating_H;
    }

    [self AddFloatingBtn:floating_X Y:floating_Y W:floating_W H:floating_H];
    self.menu.dataSource = self;
    self.menu.screenname=@"items";
    
    self.menu.delegate = self;
    
    [self.view addSubview:self.menu];
    self.menu = self.menu;
    
    if ( UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)) {
        
        NSDictionary *viewsDictionary;
        
        if (self.bannerView)
        {
            viewsDictionary = @{@"tableView" : self.tableView,
                                @"bannerView": self.bannerView,
                                @"textField":self.textfieldForNewItem,
                                @"buttonAdd":self.buttonAdd,
                                @"bannerView":self.bannerView
                                };
        }
        else
        {
            viewsDictionary = @{@"tableView" : self.tableView,
                                @"bannerView":self.view,
                                @"textField":self.textfieldForNewItem,
                                @"buttonAdd":self.buttonAdd,
                                @"bannerView":self.view
                                };
        }
        
        
        NSDictionary *metrics = @{@"paddingTop":@0.0,@"paddingBottom":@0,@"margin":@54.0};  //64.0 is the sum of status bar height and navigation bar height.
        constraintVertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[textField]-paddingTop-[tableView]-paddingBottom-[bannerView]|"
                                                                     options:kNilOptions
                                                                     metrics:metrics
                                                                       views:viewsDictionary];
        
        [self.view updateConstraints];
    }
    [self TakePic];
    
    if([self.textfieldForNewItem isFirstResponder])
    {
        self.menu.hidden=YES;
    }
    else{
        self.menu.hidden=NO;
    }
    
    //re-creating picker view
    /*
    if(self.customPickerView) {
        [UIView animateWithDuration:0.1 animations:^{
            CGRect frame = self.customPickerView.frame;
            frame.size.width = self.view.frame.size.width;
            self.customPickerView.frame = frame;
            
            self.customPickerView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height - 80);
        }completion:^(BOOL finished) {
            //Dimple-21-10-2015
            if ([self.textfieldForNewItem isFirstResponder])
            {
                [self TextBoxAnimationStop];
            }
        }];
    }
     */
}

-(void)moveUpTableViewPosition:(BOOL)shoudMoveUp{
    //  Committed by Ashish date 21Aug2015 - Do not set any hard coded UIEdgeInsets.
    //  I'm managing it by using Keyboard  notifications
    
    if (shoudMoveUp) {
        //the last cell won't be cut off
        //        UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 180.0, 0);    //remove the empty space above table view's first cell
        //        self.tableView.contentInset = insets; //something like margin for content;
        //        self.tableView.scrollIndicatorInsets = insets; // and for scroll indicator (scroll bar)
    }
    else{
        //        UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 0, 0);
        //        self.tableView.contentInset = insets; //something like margin for content;
        //        self.tableView.scrollIndicatorInsets = insets; // and for scroll indicator (scroll bar)
    }
}

- (void)showLists
{
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    if ([self.textfieldForNewItem isFirstResponder])
    {
        [self.textfieldForNewItem resignFirstResponder];
    }
    [self performSegueWithIdentifier:@"ItemsToLists" sender:self];
    dataStore.hasListBeenShown = YES;
}


- (void)updateSection:(NSInteger)section withText:(NSString*)text
{
    [self.tableView headerViewForSection:section].textLabel.text = text;
    [self reloadtableViewData];
}

- (void)changeSorting:(NSNotification *)notif
{
    //resort list
    DLog(@"sorting by %d",[DataStore instance].sortingOrder);
    [self loadRecordsFromCoreData];
}

- (void)showToastMessage:(NSString*)message
{
    if (!hasShownSortingError)
    {
        [ALToastView toastInView:self.view withText:message];
        hasShownSortingError = YES;
    }
}


/**
 * When the menu is shown, the keyboard must disappear
 */
-(void)menuIsShown:(NSNotification *)notif{
    
    [self.textfieldForNewItem resignFirstResponder];
}

-(void)didUpdateItems
{
    DLog(@"get updated items from server");
    if([SignificantChangesIndicator sharedIndicator].itemsChanged)
    {
        if([SignificantChangesIndicator sharedIndicator].currentItemListChanged) {
            [DataStore instance].currentList = nil;
        }
        [self loadRecordsFromCoreData];
        [[SignificantChangesIndicator sharedIndicator] resetData];
        [[WatchConnectivityController sharedInstance] changeShoppingList];
        //[self setFavoriteStoreName];
    }
    else {
        [self getFavouritFromCoredata];
    }
}

-(void)sortingSyncFinished: (BOOL) withError{
    [SVProgressHUD dismiss];
    if(withError) {
        [self showToastMessage:NSLocalizedString(@"SortingRequestFailure", nil)];
        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
        {
            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": @"SortingRequestFailure"}];
        }
    }
    if (dataStore.sortingOrder == STORE) {
        [self getSortedItemsByStoreFromServer];
    }
    else {
        [self reloadtableViewData];
    }
    [self getFavouritFromCoredata];//Dimple 21-12-15
}

//-(void) syncFinished
//{
//
//}

#pragma mark - MatlistanHTTPClientDelegate

-(void)matlistanHTTPClient:(MatlistanHTTPClient *)client didLogin:(id)cookie
{
    //TODO this should be fixed later, right now there is no session created
    //Save in NSUserDefaults
    //[self setFavoriteStoreName];
    [self loadRecordsFromCoreData];
    
    //    [self removeWaitOverlay];
    [SVProgressHUD dismiss];
}

-(void)matlistanHTTPClient:(MatlistanHTTPClient *)client didFailWithError:(NSError *)error{
    if (error)
    {
        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
        {
            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"View":@"ItemsViewController"}];
        }
    }
    
    [SVProgressHUD dismiss];
}

#pragma mark - sort by store
- (BOOL)isStoreIDEmpty
{
    NSString * storeID = [NSString stringWithFormat:@"%@",[DataStore instance].sortByStoreID];
    
    // Added StoreId == 0 check to avoid Sorting with (null) Store issue
    return [Utility isStringEmpty:storeID] || [[DataStore instance].sortByStoreID isEqualToNumber:[NSNumber numberWithInt:0]];
}

- (void)getSortedItemsByStoreFromServer
{
    [DataStore instance].sortByStoreID = [DataStore instance].currentList.sortByStoreId;
    if([DataStore instance].sortByStoreID == nil || [[DataStore instance].sortByStoreID intValue] == 0)
    {
        return;
    }
    
    ItemListsSorting *sorting = [ItemListsSorting getSortingForItemListId:currentListId andShopId:[DataStore instance].sortByStoreID];
    if (sorting != nil)
    {
        allItems = [[NSMutableArray alloc] init];
        
        sortedItems = [self getItemsWithIDs:sorting.sortedItems];
        unknownItems = [self getItemsWithIDs:sorting.unknownItems];
        
        NSMutableArray *arrIds = [[NSMutableArray alloc] init];
        for (Item *item in sortedItems)
        {
            [arrIds addObject:item.itemID];
        }
        for (Item *item in unknownItems)
        {
            [arrIds addObject:item.itemID];
        }
        
        NSArray *arrWithIdZero = [Item getAllItemsInList:currentListId exceptItemIds:arrIds];
        int index = 0;
        for (Item *item in arrWithIdZero)
        {
            if (![unknownItems containsObject:item] && ![item.isChecked boolValue])
            {
                [unknownItems insertObject:item atIndex:index];
                index++;
            }
        }
        if([unknownItems count]>0 && [sortedItems count]>0)
        {
            allItems= [NSMutableArray arrayWithArray:unknownItems];
            [allItems addObjectsFromArray: sortedItems];
        }
        else if ([unknownItems count]==0)
        {
            allItems= [NSMutableArray arrayWithArray:sortedItems];
            
        }
        else if ([sortedItems count]==0)
        {
            allItems= [NSMutableArray arrayWithArray:unknownItems];
            
        }
        // removed unknownItems.count from check to fix issue # 239 /Yousuf
        if (sortedItems.count == 0 && _showNoData)
        {
            hasShownSortingError=NO;//Raj fixed #125(1.1)
            LittleDataInfo=YES;
            NSMutableDictionary *presentedHelpsMap = [NSMutableDictionary dictionaryWithDictionary:[Utility getObjectFromDefaults:@"presentedHelpsMap"]];
            if(presentedHelpsMap && presentedHelpsMap[@"SortingToast"] && [presentedHelpsMap[@"SortingToast"] boolValue]) {
                [self showToast:NSLocalizedString(@"LittleDataInfo", nil)];
            }
            else {
                [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self byName:@"SortingToast" force:YES];
            }
        }
        _showNoData = NO;
        
    }
    else
    {
        [[SortingSyncManager sharedSortingSyncManager] forceSync];
        Store *store = [Store getStoreByID:[DataStore instance].sortByStoreID];
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Sort items for",nil), store.name] maskType:SVProgressHUDMaskTypeClear];
    }
    
    [self reloadtableViewData];
}

-(NSMutableArray*)getItemsWithIDs:(NSArray* )itemIDs
{
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for (NSString* itemID in itemIDs)
    {
        Item *item = [Item getItemInList:currentListId withItemID:[NSNumber numberWithInteger:[itemID integerValue]]];
        if (item != nil && (![item.isChecked boolValue] || [item.isPermanent boolValue])) {
            [array addObject:item];
        }
    }
    return array;
}


#pragma mark - Actionsheet
/*
 *Show the sorting types in action sheet
 * Senast överst, Alfabetiskt, Per kategori, Sortera efter butik ...
 * Senast överst, Alfabetiskt, Per kategori, Egen sortering(this is manual sorting), butik namn, Annan butik
 
 "Latest first"="Latest first";
 "Alphabetically"="Alphabetically";
 "By category"="By category";
 "Own sorting"="Own sorting";
 "Another store"="Another store";
 "Sort by store"="Sort by store";
 */

- (void)showSortingActionSheet:(UIButton *)btn
{
    CLS_LOG(@"showSortingActionSheet method called");

    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Sorting", nil)
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    actionSheet.tag = 1001;
    NSArray *arrayOfButtonTitles;
    
    NSArray *favStoresArray = [Store getFavouriteStoresArray];
    
    BOOL hasStores = [Store getNumberOfFavouriteStores] > 0;
    
    if (hasStores) {
        /*
         if (favoriteStore == nil) {
         [self setFavoriteStoreName];
         }
         */
        if([dataStore.currentList.sortOrder isEqualToString:@"Manual"] || is_mannual_sort==true)
        {
            arrayOfButtonTitles = [[NSArray alloc] initWithObjects: NSLocalizedString(@"Latest first",nil),NSLocalizedString(@"Alphabetically", nil),NSLocalizedString(@"By category",nil),NSLocalizedString(@"Own sorting",nil),NSLocalizedString(@"Another shop", nil),nil];
        }
        else
        {
            arrayOfButtonTitles = [[NSArray alloc] initWithObjects: NSLocalizedString(@"Latest first",nil),NSLocalizedString(@"Alphabetically", nil),NSLocalizedString(@"By category",nil),NSLocalizedString(@"Another shop", nil),nil];
        }
        
        //        for (NSString * title in arrayOfButtonTitles)
        //        {
        //            [actionSheet addButtonWithTitle:title];
        //        }
        for(int i=0;i<arrayOfButtonTitles.count;i++)
        {
            if(i<arrayOfButtonTitles.count-1)
            {
                [actionSheet addButtonWithTitle:[arrayOfButtonTitles objectAtIndex:i]];
            }
        }
        for (Store *store in favStoresArray)
        {
            [actionSheet addButtonWithTitle:store.name];
        }
        NSString *title=[arrayOfButtonTitles lastObject];
        if([title isEqualToString:NSLocalizedString(@"Another shop", nil)])
        {
            [actionSheet addButtonWithTitle:title];
        }
    }
    else
    {
        if([dataStore.currentList.sortOrder isEqualToString:@"Manual"] || is_mannual_sort==true)
        {
            arrayOfButtonTitles = [[NSArray alloc] initWithObjects: NSLocalizedString(@"Latest first",nil),NSLocalizedString(@"Alphabetically", nil),NSLocalizedString(@"By category",nil),NSLocalizedString(@"Own sorting",nil),NSLocalizedString(@"Sort By Store",nil),nil];
        }
        else
        {
            arrayOfButtonTitles = [[NSArray alloc] initWithObjects: NSLocalizedString(@"Latest first", nil), NSLocalizedString(@"Alphabetically",nil), NSLocalizedString(@"By category",nil), NSLocalizedString(@"Sort By Store",nil), nil];
        }
        
        for (NSString * title in arrayOfButtonTitles)
        {
            [actionSheet addButtonWithTitle:title];
        }
    }
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    
    if (IS_IPHONE) {
        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    else{
        [actionSheet showFromRect:CGRectMake(self.tableView.frame.origin.x,self.tableView.frame.origin.y+2 , SCREEN_WIDTH-20, 62) inView:self.view animated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    BOOL hasStores = [Store getNumberOfFavouriteStores] > 0;
    NSString *title = [popup buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:NSLocalizedString(@"Cancel",nil)]) {
        return;
    }
    
    [DataStore instance].previousSortingOrder = [DataStore instance].sortingOrder;
    dataStore.previousSortByStoreID = dataStore.sortByStoreID;
    CLS_LOG(@"actionsheet clickedButtonAtIndex method called  and title of selected index of actionsheet :%@",title);

    if([title isEqualToString: NSLocalizedString(@"Latest first",nil)]){
        
        [Utility SetSortName:nil];
        categoryFlag=false;
        [DataStore instance].sortingOrder = DATE;
        DLog(@"Click Senast överst");
        
    }
    else if ([title isEqualToString:NSLocalizedString(@"Alphabetically", nil)])
    {
        [Utility SetSortName:nil];
        categoryFlag=false;
        
        [DataStore instance].sortingOrder = DEFAULT;
        DLog(@"Click Alfabetiskt");
    }
    else if ([title isEqualToString:NSLocalizedString(@"By category", nil)])
    {
        sortedItems = [[NSMutableArray alloc] init];
        unknownItems = [[NSMutableArray alloc] init];
        
        [Utility SetSortName:@"By category"];
        DLog(@"get sort nae :%@",[Utility getSortName]);
        categoryFlag=true;
        [DataStore instance].sortingOrder = GROUPED;
        DLog(@"Click per kategori");
    }
    else if ([title isEqualToString:NSLocalizedString(@"Own sorting", nil)] || [title isEqualToString:NSLocalizedString(@"Sort By Store",nil)])
    {
        
        [Utility SetSortName:@"By category"];
        categoryFlag=true;
        
        if ([title isEqualToString:NSLocalizedString(@"Own sorting", nil)] || hasStores)
        {
            sortedItems = [[NSMutableArray alloc] init];
            unknownItems = [[NSMutableArray alloc] init];
            [DataStore instance].sortingOrder = MANUAL;
        }
        else
        {
            //[DataStore instance].sortingOrder = STORE;
            [self showStores];
        }
    }
    else if ([title isEqualToString:NSLocalizedString(@"Another shop",nil)])
    {
        [Utility SetSortName:nil];
        categoryFlag=false;
        
        [self showStores];
    }
    else if ([Store checkIfOneOftheFavouriteStoresWithName:title])
    {
        categoryFlag=true;
        [Utility SetSortName:@"By category"];
        is_store=true;
        _showNoData = YES;
        hasShownSortingError = NO;
        
        if (hasStores)
        {
            //favoriteStore = [Store getFavoriteStoreWithName:title];
            
            [DataStore instance].sortingOrder = STORE;
            [DataStore instance].sortByStoreID = [Store getFavoriteStoreWithName:title].storeID;
        }
        else
        {
            [dataStore setPreviousSortingOrder];
        }
    }
    else
    {
        [Utility SetSortName:nil];
        categoryFlag=false;
        
        [dataStore setPreviousSortingOrder];
    }
    
    DLog(@"sort type: %d",[DataStore instance].sortingOrder );
    
    if (((dataStore.sortingOrder != dataStore.previousSortingOrder) || dataStore.previousSortByStoreID != dataStore.sortByStoreID) && title != NSLocalizedString(@"Another shop",nil) && title != NSLocalizedString(@"Sort By Store",nil))
    {
        NSNumber *storeID = dataStore.sortByStoreID;
        DLog(@"storeID: %d",[storeID intValue]);
        [Item_list changeList:[DataStore instance].currentList byNewOrder:dataStore.sortingOrder andStoreID:storeID];
        [self updateSection:UNSORTED_SECTION withText:[self getSortingName]];
        [self loadRecordsFromCoreData];
    }
    
    
    [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, 0) animated:YES];
    [[SyncManager sharedManager] forceSync];
}

/**
 *This is called when click "Annan butik..." or "Sortera efter butik ... "
 */
- (void)switchToLogin
{
    [self performSegueWithIdentifier:@"itemsToLogin" sender:self];
}

- (void)showStores
{
    [self performSegueWithIdentifier:@"ItemsToStores" sender:self];
}

- (void)switchToStore
{
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Go to In Store screen"];
    }
    
    [self performSegueWithIdentifier:@"ItemsToShoppingMode" sender:self];
}

- (void)showMenu
{
    [self.revealViewController revealToggle:self];
    
    /*Developer : Dimple
     Date : 28-9-15
     Description : Sliding menu swipe gesture management.*/
    [self CancelTapped];
    
    //[self.frostedViewController presentMenuViewController];
    //self.textfieldForNewItem.text = @"";
    if ([self.textfieldForNewItem isFirstResponder]) {
        [self.textfieldForNewItem resignFirstResponder];
    }
    
}

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    CLS_LOG(@"prepareForSegue method called  in itemsview controller");

    [self hideToast];
    const float movementDuration = 0.1; // tweak as needed
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    //[self.tableView setContentOffset:CGPointMake(0, 0)]; //offset 2
    [UIView commitAnimations];
    
    if(self.textfieldForNewItem.text.length==0)
    {
        [self TextBoxAnimationStop];
    }
    
    [self.textfieldForNewItem resignFirstResponder];
    [self moveUpTableViewPosition:YES];

    if ([segue.identifier isEqualToString:@"ItemsToShoppingMode"])
    {
        CLS_LOG(@"ItemsToShoppingMode condition called in prepareForSegue method in itemsview controller");

        (theAppDelegate).storeDict=[[NSDictionary alloc] init];
        (theAppDelegate).storeDict=nil;
        
        [Item clearUncheckedItems];
        dataStore.sorteditemsList = allItems;
        dataStore.hasListBeenShown = YES;
    }
    else if([segue.identifier isEqualToString:@"toChangeItem"])
    {
        CLS_LOG(@"toChangeItem condition called in prepareForSegue method in itemsview controller");

        //DLog(@"Item selectedItemId %@",selectedItemId);
        //DLog(@"Item selectedItemObjectId %@",selectedItemObjectId);
        //DLog(@"Item selectedItem %@",selectedItem);
        
        
        ChangeTextViewController *controller = (ChangeTextViewController*)segue.destinationViewController;
        controller.itemId = selectedItemId;
        controller.itemObjectId = selectedItemObjectId;
        controller.item = selectedItem;
        
        
    }
    else if([segue.identifier isEqualToString:@"itemsToSort"])
    {
        CLS_LOG(@"itemsToSort condition called in prepareForSegue method in itemsview controller");

        SortTableViewController *controller = (SortTableViewController*)segue.destinationViewController;
        controller.itemsList = allItems;
        controller.is_sorttype=categoryFlag;
    }
    else if ([segue.identifier isEqualToString:@"ItemsToStores"])
    {
        CLS_LOG(@"ItemsToStores condition called in prepareForSegue method in itemsview controller");

        ShopsTableViewController *controller = (ShopsTableViewController*)segue.destinationViewController;
        controller.is_comming_from_items=YES;
    }
}

#pragma mark - add new item
/**
 Fixed if we have empty list of items and then add item it does not show up until Sync manager is finished syncing
 @ModifiedDate: September 10, 2015
 @Version:1.14
 @Modified by: Yousuf
 */
- (void)addNewItem {
    [self addNewItem:self.textfieldForNewItem.text];
}

-(void)addUndoItem
{
    if(is_undoBtnClick)
    {
        is_undoBtnClick=false;
        NSLog(@"undoItemName %@",undoItemName);
        [self hideToast];
    }

    [self addNewItem:undoItemName];
}
-(void) addNewItem: (NSString*)itemName
{
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    
    
    NSString *newItemName = [itemName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self switchSuggestionTo:NO];   //turn off suggestion mode
    if ([Utility isStringEmpty:newItemName])
    {
        self.textfieldForNewItem.text = @"";
        item_titleLbl=@"";
        return;
    }
    item_titleLbl=newItemName;
    //add new item in core data, sync to server in sync engine later
    Item_list *list = dataStore.currentList;
    
   // DLog(@"Got list from datastore");
    
    Item *item = [Item insertItemWithText:newItemName andBarcode:@"" andBarcodeType:@"" belongToList:list withSource:methodOfAddingItem];
    
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        NSMutableDictionary *properties = [NSMutableDictionary new];
        if(newItemName) properties[@"Text"] = newItemName; else properties[@"Text"] = @"NULL";
        if(list.name) properties[@"list"] = list.name; else properties[@"list"] = @"NULL";
        if(methodOfAddingItem) properties[@"source"] = methodOfAddingItem; else properties[@"source"] = @"NULL";
        [[Mixpanel sharedInstance] track:@"Item Added" properties:properties];
    }
    
    //sync to server in sync engine later
    
    //    [self.textfieldForNewItem resignFirstResponder];
    //    DLog(@"Resigned text field");
    
    if (dataStore.sortingOrder == STORE )
    {
        [unknownItems insertObject:item atIndex:0];
        DLog(@"Insert new item to unknownItems");
    }
    else
    {
        [allItems insertObject:item atIndex:0];
        DLog(@"Insert new item to allItems");
    }
    
    if ([newItemName isEqualToString:[DataStore instance].ingredientByURL ] && [[DataStore instance].ingredientByURL length] > 0)
    {
        [self moveUpTableViewPosition:NO];//only when there is some text in textfield
    }
    else
    {
        [self moveUpTableViewPosition:YES];
    }
    
    self.textfieldForNewItem.text = @"";
    //if item successfully added then iTemNameNotAddedYet must be empty.
    [DataStore instance].iTemNameNotAddedYet = @"";
    
    // reload table view to load data when new item added
    //force sync when new item is added
    [[SyncManager sharedManager] forceSync];
    [self reloadtableViewData];
}

- (IBAction)onClickButtonAdd:(id)sender
{
   // DLog(@"methodOfAddingItem : %@", methodOfAddingItem);
    //Raj - 26-9-15
    //[self TextBoxAnimationStop];
    CLS_LOG(@"onClickButtonAdd called  in itemsview controller");

    [self addNewItem];
}
//Raj - 26-9-15
- (IBAction)TextBtnClick:(id)sender
{
    call_from_rotate=NO;
    [self TextBoxAnimationStart];
    
}
// Raj - 26-9-15
// Animation for add item textbox
-(void)TextBoxAnimationStart
{
    //Dimple 21-10-2015
    self.expandedIndexPath=nil;
    stop_animation=false;
    int textfield_w=80,textfield_x=10,textview_w=64;
    if(IS_IPHONE)
    {
        textfield_w=80+4;
        textview_w=64+5;
        textfield_x=15;
    }
    else
    {
        textfield_w=98+20;
        textview_w=77+26;
        textfield_x=23;
    }
    self.textBtn.hidden=YES;
    if(!call_from_rotate)
    {
        [self.textfieldForNewItem becomeFirstResponder];
    }
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect newFrame1= self.textfieldForNewItem.frame;
                         newFrame1.origin.x= textfield_x;
                         newFrame1.size.width= SCREEN_WIDTH-textfield_w;
                         self.textfieldForNewItem.frame = newFrame1;
                         
                         textview_fram_width = self.txtView.frame;
                         textview_fram_width.size.width = SCREEN_WIDTH-textview_w;
                         self.txtView.frame=textview_fram_width;
                         
                         self.buttonAdd.hidden=NO;
                         self.buttonAddTans.hidden=NO;
                         
                         self.buttonBarcode.hidden=YES;
                         self.buttonFav.hidden=YES;
                         self.menu.hidden=YES;
                         self.buttonVoice.hidden=YES;
                         self.menu.hidden=YES;
                     }
                     completion:^(BOOL finished){
                     }];
    [UIView commitAnimations];
    self.tableView.hidden=YES;
}
-(void)TextBoxAnimationStop
{
    stop_animation=true;
    self.buttonAdd.hidden=YES;
    self.buttonAddTans.hidden=YES;
    self.buttonFav.hidden=NO;
     self.menu.hidden=NO;
    self.buttonVoice.hidden=NO;
    self.buttonBarcode.hidden=NO;
    self.menu.hidden=NO;
    
    int textfield_w=80,textfield_x=10,textview_w=64;
    if(IS_IPHONE)
    {
        textfield_w=186+4;
        textview_w=172+3;
        textfield_x=15;
    }
    else
    {
        textfield_w=230;
        textview_w=211+27;
        textfield_x=23;
    }
    
    
    [self.textfieldForNewItem resignFirstResponder];
    const float movementDuration = 0.3; // tweak as needed
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    //[self.tableView setContentOffset:CGPointMake(0, 0)];
    //dimple-21-10-2015
    if(picker_Flag)
    {
        [self.tableView setContentOffset:CGPointMake(0, 0)];
    }
    
    [UIView commitAnimations];
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect newFrame1= self.textfieldForNewItem.frame;
                         newFrame1.origin.x= textfield_x;
                         newFrame1.size.width= SCREEN_WIDTH-textfield_w;
                         self.textfieldForNewItem.frame = newFrame1;
                         
                         CGRect newFrame = self.txtView.frame;
                         
                         newFrame.size.width = SCREEN_WIDTH-textview_w;
                         self.txtView.frame=newFrame;
                         
                     }
                     completion:^(BOOL finished){
                         self.textBtn.hidden=NO;
                     }];
    [UIView commitAnimations];
    self.tableView.hidden=NO;
    if (dataStore.sortingOrder == STORE )
    {
        if(unknownItems.count>0 || sortedItems.count>0)
        {
            self.tableView.hidden=NO;
        }
        else
        {
            self.tableView.hidden=YES;
            
        }
    }
    else
    {
        if(allItems.count>0)
        {
            self.tableView.hidden=NO;
        }
        else
        {
            self.tableView.hidden=YES;
            
        }
    }
}



- (void)switchSuggestionTo:(BOOL)onOff
{
    isSuggestionOn = onOff;
    [self.tableView setContentOffset:self.tableView.contentOffset animated:NO];
    if (onOff)
    {
        DLog(@"turn on suggestions");
        [self moveUpTableViewPosition:YES];
        [self getSuggestionsFromServer];
    }
    else
    {
        DLog(@"turn off suggestions");
        [self moveUpTableViewPosition:NO];
        [self reloadtableViewData];
    }
    if(self.textfieldForNewItem.text.length ==0)
    {
        self.tableView.hidden=YES;
    }
}

/**
 *Get suggestions for input
 */
- (IBAction)onTextFieldNewItemEditChanged:(id)sender {
    DLog(@"changed %@", self.textfieldForNewItem.text );
    if(self.textfieldForNewItem.text.length <= 1){
        methodOfAddingItem = @"Manual";
    }
    [self switchSuggestionTo:self.textfieldForNewItem.text.length > 0 && httpClient.isLoggedIn];
}

- (IBAction)onEditingNewItemDidEnd:(id)sender {
    
    [self switchSuggestionTo:NO];   //turn off suggestion mode
    
}

- (IBAction)onTextFieldTouchDown:(id)sender {
    [self moveUpTableViewPosition:YES];
    DLog(@"text = %@",NSStringFromUIEdgeInsets(self.tableView.contentInset));
}

- (void)getSuggestionsFromServer
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSDictionary *parameters = @{@"query": self.textfieldForNewItem.text};
    [httpClient GET:@"ItemSearch" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        suggestedItems = [[NSMutableArray alloc]initWithArray: responseObject];
        [self reloadtableViewData];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        DLog(@"Get %@ from server",suggestedItems);
        
        if([self numberOfSectionsInTableView:self.tableView] > 0 && [self tableView:self.tableView numberOfRowsInSection:0] > 0){
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to getStoresFromServer");
        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
        {
            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription, @"View":@"ItemsViewController", @"action":@"Fail to getStoresFromServer"}];
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}
#pragma mark - TableView delegate methods
/**
 Added code to display icon when the isPermanent field of the item is set
 @ModifiedDate: September 11 , 2015
 @Version:1.14
 @Modified by: Yousuf
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:  (NSIndexPath *)indexPath
{
    int font_size1=14,font_size2=17, item_size=36;
    if(IS_IPHONE)
    {
        font_size1=14;
        font_size2=17;
        item_size=36;
    }
    else
    {
        font_size1=20;
        font_size2=25;
        item_size=72;
    }
    ItemCustomCell *cell=[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(cell==nil)
    {
        
        cell=[[ItemCustomCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        
        NSArray *menuarray=[[NSBundle mainBundle]loadNibNamed:@"ItemCustomCell" owner:self options:nil];
        cell=[menuarray objectAtIndex:0];
    }
    
    cell.clipsToBounds=YES;
    
    
    //  ItemCell *√ = (ItemCell*)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    // DLog(@"Index section %ld, sorting %d",(long)indexPath.section,[DataStore instance].sortingOrder);
    
    Item *item = nil;
    
    cell.pinImageTrailingConstraint.constant = 8;
    
    //cell.pinImageTrailingConstraint.constant = 8;
    cell.btnPossibleMatches.layer.cornerRadius=3;
    if (isSuggestionOn)
    {
        cell.btnAddSuggestion.hidden = NO;
        cell.btnAddSuggestion.userInteractionEnabled = YES;
        cell.btnAddSuggestion.tag = indexPath.row;
        [cell.btnAddSuggestion addTarget:self
                                  action:@selector(addSuggestedItem:)
                        forControlEvents:UIControlEventTouchUpInside];

        if (suggestedItems.count > 0 && indexPath.section == 0)
        {
            NSDictionary *dict = [suggestedItems objectAtIndex:indexPath.row];
            cell.titleLabel.text = [dict objectForKey:@"text"];
        }
        else
        {
            cell.titleLabel.text = @"";
        }
        
        cell.delegate = self;
        cell.btnPossibleMatches.hidden = YES;
        cell.pinImage.hidden = true;
        if(indexPath.row%2==0)
        {
            cell.backgroundColor=CELL_BG_COLOR;
        }
        else
        {
            cell.backgroundColor=[UIColor whiteColor];
        }
        return cell;
    }
    else {
        cell.btnAddSuggestion.hidden = YES;
        cell.btnAddSuggestion.userInteractionEnabled = NO;
    }

    //when there is no suggestion on
    NSString *color=@"";
    if([DataStore instance].sortingOrder == STORE)
    {
        if(indexPath.section == UNSORTED_SECTION && unknownItems.count > 0)
        {
            if (unknownItems!= nil && unknownItems.count > 0) {
                item = unknownItems[indexPath.row];
                color=[UnSortedcolorArr objectAtIndex:indexPath.row];
            }
        }
        else
        {
            if (sortedItems != nil && sortedItems.count > 0) {
                item = sortedItems[indexPath.row];
                color=[SortedcolorArr objectAtIndex:indexPath.row];
            }
        }
    }
    else
    {
        item = [allItems objectAtIndex:indexPath.row];
        if([[Utility getSortName] isEqualToString:@"By category"]){
            if(colorArr!=nil && colorArr.count>0)
            {
                color=[colorArr objectAtIndex:indexPath.row];
            }
        }
    }
    
    cell.delegate = self;
    if (item != nil)
    {
        cell.cellItem = item;
        cell.itemId = item.itemID;
        cell.itemObjectId = item.objectID;
        cell.titleLabel.text = [NSString stringWithFormat:@"%@", item.text];
        if(item.text==nil)
        {
            cell.titleLabel.text=item_titleLbl;
        }
        //DLog(@"knownItemText = %@",item.knownItemText);
        if (item.text.length > item_size)
        {
            cell.titleLabel.numberOfLines = 0;
            [cell.titleLabel setFont:[UIFont systemFontOfSize:font_size1]];
            
            //            if (item.text && item.knownItemText && [Utility theString:item.text containSubString:item.knownItemText])
            //            {
            if(cell.titleLabel.text != nil || cell.titleLabel.text.length>0)
            {
                [self adjustTitleLabelForKnowText:cell.titleLabel withItem:item withFountSize:font_size1];
            }
            //            }
        }
        else
        {
            cell.titleLabel.numberOfLines = 1;
            [cell.titleLabel setFont:[UIFont systemFontOfSize:font_size2]];
            if(cell.titleLabel.text != nil || cell.titleLabel.text.length>0)
            {
                [self adjustTitleLabelForKnowText:cell.titleLabel withItem:item withFountSize:font_size2];
            }
        }
        
        // IOS-28: let user select a matching item
        cell.btnPossibleMatches.hidden = YES;
        
        if([DataStore instance].sortingOrder == STORE || [DataStore instance].sortingOrder == GROUPED  || [DataStore instance].sortingOrder == DEFAULT)
        {
            NSArray *arrPossibleMatches = (NSArray *)item.possibleMatches;
            
            if (arrPossibleMatches && arrPossibleMatches.count > 0)
            {
                if ([item.isPossibleMatch isEqualToNumber:[NSNumber numberWithBool:false]])
                {
                    cell.btnPossibleMatches.hidden = NO;
                }
            }
        }
        
        // IOS-11: Display an icon next to an item which is not removed from the item list after being taken in store
        if ([item.isPermanent isEqualToNumber:[NSNumber numberWithBool:true]])
        {
            cell.pinImage.hidden = false;
            
            if (!cell.btnPossibleMatches.hidden)
            {
                if(IS_IPHONE)
                {
                    cell.pinImageTrailingConstraint.constant = cell.btnPossibleMatches.frame.size.width + 16;
                }
                else
                {
                    cell.pinImageTrailingConstraint.constant = cell.btnPossibleMatches.frame.size.width+ 25;
                }
            }
        }
        else
        {
            if(IS_IPHONE)
            {
                cell.pinImageTrailingConstraint.constant = 8;
            }
            else
            {
                cell.pinImageTrailingConstraint.constant = 35;
            }
            cell.pinImage.hidden = true;
        }
    }
    
    NSNumber *is_mannual_num = item.manualSortIndex;
    if([is_mannual_num intValue]>0)
    {
        is_mannual_sort=true;
    }
    
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    
    //cell.editBtn.titleLabel.text=NSLocalizedString(@"Change",nil);
    // cell.deleteBtn.titleLabel.text=NSLocalizedString(@"Delete",nil);
    [cell.editBtn setTitle:NSLocalizedString(@"Change",nil) forState: UIControlStateNormal];
    [cell.deleteBtn setTitle:NSLocalizedString(@"Delete",nil) forState: UIControlStateNormal];
    [cell.copytoBtn setTitle:NSLocalizedString(@"Copy to",nil) forState: UIControlStateNormal];
    [cell.moveBtn setTitle:NSLocalizedString(@"Move",nil) forState: UIControlStateNormal];
    
    if(![language isEqualToString:@"en"])
    {
        if(IS_IPHONE)
        {
            [cell.editBtn setTitleEdgeInsets:UIEdgeInsetsMake(26, -28, 0, 0)];
            [cell.deleteBtn setTitleEdgeInsets:UIEdgeInsetsMake(26, -28, 0, 0)];
            [cell.copytoBtn setTitleEdgeInsets:UIEdgeInsetsMake(26, -24, 0, 0)];
            [cell.moveBtn setTitleEdgeInsets:UIEdgeInsetsMake(26,-21, 0, 0)];
        }
        else
        {
            [cell.editBtn setTitleEdgeInsets:UIEdgeInsetsMake(53, -46, 0, 1)];
            [cell.deleteBtn setTitleEdgeInsets:UIEdgeInsetsMake(51, -62, 0, 1)];
            [cell.copytoBtn setTitleEdgeInsets:UIEdgeInsetsMake(49, -52, 0, 0)];
            [cell.moveBtn setTitleEdgeInsets:UIEdgeInsetsMake(51, -37, 0, 0)];
        }
    }
    
    cell.editBtn.tag = indexPath.row;
    [cell.editBtn addTarget:self action:@selector(editBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.deleteBtn.tag = indexPath.row;
    [cell.deleteBtn addTarget:self action:@selector(deleteBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.copytoBtn.tag = indexPath.row;
    [cell.copytoBtn addTarget:self action:@selector(copyToBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.moveBtn.tag = indexPath.row;
    [cell.moveBtn addTarget:self action:@selector(moveBtn:) forControlEvents:UIControlEventTouchUpInside];

    
    
    cell.editBtn.titleLabel.textColor=[Utility getGreenColor];
    cell.deleteBtn.titleLabel.textColor=[Utility getGreenColor];
    cell.copytoBtn.titleLabel.textColor=[Utility getGreenColor];
    cell.moveBtn.titleLabel.textColor=[Utility getGreenColor];
    
    //Dimple-18-11-2015
    //DLog(@"Utility getsort %@",[Utility getSortName]);
    if([[Utility getSortName] isEqualToString:@"By category"])
    {
        if([color isEqualToString:@"Blue"])
        {
            cell.backgroundColor=lightblueColor;
        }
        else
        {
            cell.backgroundColor=lightgreenColor;
        }
    }
    else{
        if(indexPath.row%2==0)
        {
            cell.backgroundColor=CELL_BG_COLOR;
        }
        else
        {
            cell.backgroundColor=[UIColor whiteColor];
        }
        
    }
    
    //Long press gesture
    UILongPressGestureRecognizer *longPressGesture= [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration = .6; //seconds
    longPressGesture.delegate = self;
    longPressGesture.delaysTouchesBegan = YES;
    cell.titleLabel.userInteractionEnabled = YES;
    [cell.titleLabel addGestureRecognizer:longPressGesture];
    
    return cell;
}

- (void) addSuggestedItem: (UIButton*)sender  {
    if (suggestedItems != nil && suggestedItems.count > sender.tag) {
        NSDictionary *dict = [suggestedItems objectAtIndex:sender.tag];
        methodOfAddingItem = @"Autocomplete";
        [self switchSuggestionTo:NO];
        [self addNewItem:dict[@"text"]];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    if (isSuggestionOn) {
        if (suggestedItems != nil && suggestedItems.count > indexPath.row) {
            NSDictionary *dict = [suggestedItems objectAtIndex:indexPath.row];
            self.textfieldForNewItem.text = [dict objectForKey:@"text"];
            methodOfAddingItem = @"Autocomplete";
            [self switchSuggestionTo:NO];
            self.tableView.hidden=YES;
        }
    }
    else
    {
        if(![self.textfieldForNewItem isFirstResponder])
        {
            [self expandCell:indexPath];
        }
        
    }
    if ([self.textfieldForNewItem isFirstResponder]) {
        //        [self.textfieldForNewItem resignFirstResponder];
        [self moveUpTableViewPosition:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (unknownItems.count > 0 && sortedItems.count > 0)
    {
        return 2;
    }
    return 1;
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(IS_IPHONE)
    {
        
        return SECTION_HEADER_HEIGHT;
    }
    else
    {
        return SECTION_HEADER_IPAD_HEIGHT;
    }
    
    // Commented by Ashish date 13Aug2015 header height to display is maintain by tableView
    //    Top and Buttom Constraints
    //    To Resolve the Bug no 115 from google doc.
    /*
     if (isSuggestionOn) {
     return SECTION_HEADER_HEIGHT;
     return 0;
     }
     else{
     return SECTION_HEADER_HEIGHT;
     }
     */
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row_height;
    if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame) {
        
        return row_height=expand_height;// Expanded height
    }
    else
    {
        return row_height=collaps_height;
    }
    //    if(IS_IPHONE)
    //    {
    //        return ITEMS_VIEW_ROW_HEIGHT;
    //    }
    //    else
    //    {
    //        return ITEMS_VIEW_IPAD_ROW_HEIGHT;
    //    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowSum = 0;
    
    switch (section)
    {
        case 0:
        {
            if (isSuggestionOn)
            {
                rowSum = suggestedItems.count;
            }
            else{
                rowSum = [DataStore instance].sortingOrder == STORE? (unknownItems.count > 0 ? unknownItems.count : sortedItems.count) : allItems.count;
            }
            //DLog(@"sortingOrder %d, section %ld, row sum %ld",[DataStore instance].sortingOrder,(long)section,(long)rowSum);
            break;
        }
        case 1:
        {
            if (isSuggestionOn)
            {
                rowSum = 0;
            }
            else
            {
                rowSum  = [DataStore instance].sortingOrder == STORE? sortedItems.count : 0;
            }
            // DLog(@"sortingOrder %d, section %ld, row sum %ld",[DataStore instance].sortingOrder,(long)section,(long)rowSum);
            break;
        }
        default:
            break;
    }
    
    // DLog(@"rowSum : %lu", (long)rowSum);
    
    return rowSum; // Return the number of rows in the section.
}

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section{
    if (isSuggestionOn)
    {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
        return view;
    }
    
    sectionNames = nil;
    
    if ([DataStore instance].sortingOrder == STORE)
    {
        is_store=true;
        categoryFlag=true;
        [Utility SetSortName:@"By category"];
        //sectionNames = @[NSLocalizedString(@"Unsorted items", nil), NSLocalizedString(@"Sorted items", nil)];
        if (unknownItems.count > 0)
        {
            sectionNames = @[NSLocalizedString(@"Unsorted items", nil), NSLocalizedString(@"Sorting", nil)];
        }
        else
        {
            //sectionNames = @[NSLocalizedString(@"Sorting", nil)];
            if([sortedItems count]>0)
            {
                sectionNames = @[NSLocalizedString(@"Sorting", nil)];
            }
            else{
                sectionNames = @[@"",@""];
                
            }
            
        }
    }
    else
    {
        is_store=false;
        sectionNames = @[[self getSortingName],@""];
    }
    
    NSString *sectionTitle = sectionNames[(NSUInteger) section];
    if ([sectionTitle rangeOfString:NSLocalizedString(@"By category", nil)].location !=NSNotFound || is_store || [sectionTitle rangeOfString:NSLocalizedString(@"Own sorting", nil)].location !=NSNotFound) {
        categoryFlag=true;
        //[Utility SetSortName:@"By category"];
    }
    else{
        categoryFlag=false;
        //[Utility SetSortName:nil];
    }
    
    // Raj - 26-9-15
    
    int sortview1_width=my_screenwidth-57;
    int sortview1_full_width=my_screenwidth-10;
    int sortview2_x=my_screenwidth-50;
    int vw_height=40,vw_width=45,size,store_btn_y;
    int sortview1_x=8;
    
    if(IS_IPHONE)
    {
        vw_height=40;
        vw_width=45;
        sortview1_width=my_screenwidth-68;
        sortview2_x=my_screenwidth-53;
        size=18;
        store_btn_y=0;
        sortview1_x=8;
        
    }
    else
    {
        vw_height=62;
        vw_width=65;
        sortview1_width=my_screenwidth-98;
        sortview2_x=my_screenwidth-78;
        size=26;
        store_btn_y=5;
        sortview1_x=14;
        
    }
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, vw_height)];
    UIView *sort_view1 = [[UIView alloc] initWithFrame:CGRectMake(sortview1_x, 0, sortview1_width, vw_height)];
    
    UIView *sort_view2 = [[UIView alloc] initWithFrame:CGRectMake(sortview2_x, 0, vw_width, vw_height)];
    sort_view2.layer.cornerRadius=3;
    sort_view1.layer.cornerRadius=3;
    
    /* Create custom view to display section header... */
    //Dimple-19-10-2015
    UIButton *buttonMove = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, vw_width, vw_height)];
    [buttonMove setBackgroundColor:[Utility getGreenColor]];
    [buttonMove setTintColor:HIGHLIGHTED_COLOR];
    buttonMove.layer.cornerRadius=3;
    [buttonMove setImage:[UIImage imageNamed:@"sort"] forState:UIControlStateNormal];
    [buttonMove addTarget:self action:@selector(onClickButtonMove:) forControlEvents:UIControlEventTouchDown];
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, sortview1_width, vw_height)];
    [button setBackgroundColor:[Utility getGreenColor]];
    
    [button addTarget:self action:@selector(onClickSection0Header:) forControlEvents:UIControlEventTouchDown];
    //[button.titleLabel setTextAlignment:NSTextAlignmentCenter];
    // [button setTitle:sectionTitle forState:UIControlStateNormal];
    // [button setTitle:sectionTitle forState:UIControlStateSelected];
    // button.titleLabel.font = [UIFont systemFontOfSize:size];
    
    NSDictionary *attrDict = @{
                               NSFontAttributeName : [UIFont systemFontOfSize:size],
                               NSForegroundColorAttributeName : [UIColor whiteColor]
                               };
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed:@"backimg_white"];
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    NSMutableAttributedString *myString=nil;
    myString= [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",sectionTitle] attributes:attrDict];
    
    [myString appendAttributedString:attachmentString];
    [button setAttributedTitle:myString forState:UIControlStateNormal];
    [button setAttributedTitle:myString forState:UIControlStateSelected];
    
    
    button.layer.cornerRadius=3;
    if (sectionTitle.length == 0)
    {
        return view;
    }
    else
    {
        // Dimple - 2015-10-15 fixed bug #302
        [sort_view2 addSubview:buttonMove];
        [sort_view2 setBackgroundColor:[Utility getGreenColor]];
        [view addSubview:sort_view2];
        
        CGRect newFrame1= sort_view1.frame;
        newFrame1.size.width= sortview1_width;
        sort_view1.frame = newFrame1;
        
        newFrame1= button.frame;
        newFrame1.size.width= sortview1_width;
        button.frame = newFrame1;
        
        
        if ((section == 1 && [DataStore instance].sortingOrder == STORE && unknownItems.count > 0) || (section == 0 && [DataStore instance].sortingOrder == STORE && unknownItems.count == 0))
        {
            [button setFrame:CGRectMake(0, store_btn_y, tableView.frame.size.width, SECTION_HEADER_HEIGHT)];
            Store *currentStore = [Store getStoreByID:dataStore.sortByStoreID];
            sectionTitle = [sectionTitle stringByAppendingString:[NSString stringWithFormat:@": %@",currentStore.name]];
            currentStore = nil;
            
            
            NSDictionary *attrDict = @{
                                       NSFontAttributeName : [UIFont systemFontOfSize:size],
                                       NSForegroundColorAttributeName : [UIColor whiteColor]
                                       };
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"backimg_white"];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            NSMutableAttributedString *myString=nil;
            myString= [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",sectionTitle] attributes:attrDict];
            
            [myString appendAttributedString:attachmentString];
            
            [button setAttributedTitle:myString forState:UIControlStateNormal];
            [button setAttributedTitle:myString forState:UIControlStateSelected];
            if(IS_IPHONE)
            {
                [button setTitleEdgeInsets:UIEdgeInsetsMake(0,10,0, 10)];
            }
            else
            {
                [button setTitleEdgeInsets:UIEdgeInsetsMake(10,10,0, 10)];
            }
            
            
            
            if([unknownItems count]==0)
            {
                [sort_view2 addSubview:buttonMove];
                [sort_view2 setBackgroundColor:[Utility getGreenColor]];
                [view addSubview:sort_view2];
                
                CGRect newFrame1= sort_view1.frame;
                newFrame1.size.width= sortview1_width;
                sort_view1.frame = newFrame1;
                
                newFrame1= button.frame;
                newFrame1.size.width= sortview1_width;
                button.frame = newFrame1;
            }
            else
            {
                CGRect newFrame1= sort_view1.frame;
                newFrame1.size.width= sortview1_full_width;
                sort_view1.frame = newFrame1;
                
                newFrame1= button.frame;
                newFrame1.size.width= sortview1_full_width;
                button.frame = newFrame1;
                
            }
            
        }
        [sort_view1 addSubview:button];
        [sort_view1 setBackgroundColor:[Utility getGreenColor]];
        [view addSubview:sort_view1];
        [view setBackgroundColor:[UIColor clearColor]];
    }
    return view;
}

- (void)onClickButtonMove:(id)sender
{
    if ([self.textfieldForNewItem isFirstResponder])
    {
        [self.textfieldForNewItem resignFirstResponder];
    }
    [self performSegueWithIdentifier:@"itemsToSort" sender:self];   //sort the items manually
}

- (void)onClickSection0Header:(id)sender
{
    //[self reloadTheseCells:[self.tableView indexPathsForVisibleRows]];
    
    if ([self.textfieldForNewItem isFirstResponder])
    {
        [self.textfieldForNewItem resignFirstResponder];
    }
    UIButton *button = (UIButton*)sender;
    [self showSortingActionSheet:button]; //show actionsheet for sorting types
    
}

-(NSString*)getSortingName{
    NSString *text = NSLocalizedString(@"Sorting", nil);
    int index = [DataStore instance].sortingOrder;
    text =[NSString stringWithFormat:@"%@ : %@",NSLocalizedString(@"Sorting", nil), sortingNames[index]];
    
    return text;
}

#pragma mark - Swipe function

//- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
//{
//    if (suggestedItems.count > 0 && isSuggestionOn)
//    {
//        return;
//    }
//    else
//    {
//        ItemCell *itemCell = (ItemCell*)cell;
//        selectedItemId = itemCell.itemId;
//        selectedItemObjectId = itemCell.itemObjectId;
//        selectedItemText = itemCell.titleLabel.text;
//        selectedItem = itemCell.cellItem;
//
//        switch (index)
//        {
//            case 0:
//            {
//                // Change button is pressed
//                // show change view
//                [self performSegueWithIdentifier:@"toChangeItem" sender:self];
//                [cell hideUtilityButtonsAnimated:YES];
//                break;
//            }
//            case 1:
//            {
//                // Delete button is pressed
//                selectedIndexPath = [self.tableView indexPathForCell:cell];
//                [self deleteItem];
//                //[self showDeleteChoice:[NSString stringWithFormat:NSLocalizedString(@"Do you want to remove the item?",nil)]];
//                break;
//            }
//            default:
//                break;
//        }
//    }
//}

//- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
//{
//    if (state == kCellStateRight)
//    {
//        NSArray *indxPathsArray = [self.tableView indexPathsForVisibleRows];
//        for (NSIndexPath *indxPath in indxPathsArray)
//        {
//            SWTableViewCell *tmpCell = (SWTableViewCell *)[self.tableView cellForRowAtIndexPath:indxPath];
//            if (tmpCell != cell)
//            {
//                [tmpCell hideUtilityButtonsAnimated:NO];
//                changeDeleteMenuShowing = YES;
//            }
//        }
//        if ([self.textfieldForNewItem isFirstResponder])
//        {
//            [self.textfieldForNewItem resignFirstResponder];
//        }
//    }
//    else if (state == kCellStateCenter || state == kCellStateLeft)
//    {
//        changeDeleteMenuShowing = NO;
//    }
//}

/**
 Added this delegate method in SWTableViewCell to show possible matches for any item
 @ModifiedDate: September 8 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)showPossibleMatches:(NSMutableArray *)arrPossibleMatches withSelectedItem:(id)selectedItem1
{
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    
    if (self.customPickerView == nil)
    {
        [self showPickerView:@"possibleMatches" withArray:arrPossibleMatches withItem:(Item *)selectedItem1];
    }
}

/*
 -(void)showDeleteChoice:(NSString*)msg{
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil) message:msg delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:@"OK", nil];
 [alert show];
 }
 
 - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
 // Set buttonIndex == 1 to handel "Ok"/"Yes" button response
 if (buttonIndex == 1) {
 //Fake delete in core data
 [Item fakeDelete:selectedItemObjectId];
 //Delete in the tableView
 if (selectedIndexPath.section == 0) {
 if ([DataStore instance].sortingOrder == STORE) {
 if (unknownItems!= nil && unknownItems.count > selectedIndexPath.row) {
 [unknownItems removeObjectAtIndex:selectedIndexPath.row];
 }
 
 }
 else{
 if (allItems != nil && allItems.count > selectedIndexPath.row) {
 [allItems removeObjectAtIndex:selectedIndexPath.row];
 }
 }
 }
 else{
 if (sortedItems != nil && sortedItems.count > selectedIndexPath.row) {
 [sortedItems removeObjectAtIndex:selectedIndexPath.row];
 }
 
 }
 
 [self.tableView deleteRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
 [self reloadtableViewData];
 }
 else if(buttonIndex == 0)
 {
 [self reloadtableViewData];    //to make the more/delete buttons disappear
 
 }
 }
 */
/*
 - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
 if (alertView.tag == 2002){
 NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
 if ([title isEqualToString:NSLocalizedString(@"Login", nil)]) {
 
 NSString *savedUserName = [Utility getObjectFromDefaults:@"userName"];
 NSString *savedPassword = [alertView textFieldAtIndex:0].text;
 [Utility saveInDefaultsWithObject:savedPassword andKey:@"password"];
 LoginType loginType = [Utility getCurrentLoginType];
 
 if (loginType == LoginTypeEmail){
 
 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 
 [NSThread sleepForTimeInterval:5]; //wait for 5seconds and then try to log in
 [httpClient loginWithUserName:savedUserName andPassword:savedPassword];
 DLog(@"ItemsViewController - login with New Password");
 });
 }
 }
 }else if (alertView.tag == 2003){
 
 }else if (alertView.tag == 2004){
 
 }
 }
 */

// Dimple - 2015-10-15 fixed bug #298
- (void) deleteItem {
    //Fake delete in core data
    [Item fakeDelete:selectedItemObjectId];
    [self hideToast];
    DLog(@"%@",selectedItemText);
    [self ShowToastForUndoItem:selectedItemText];
    //Delete in the tableView
    if (selectedIndexPath.section == 0) {
        if ([DataStore instance].sortingOrder == STORE)
        {
            if (unknownItems!= nil && unknownItems.count > selectedIndexPath.row) {
                CLS_LOG(@"delete item from unknownItems in store condition");

                [unknownItems removeObjectAtIndex:selectedIndexPath.row];
                
                if(unknownItems.count>0)
                {
                    [self.tableView deleteRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                }
                [self getFavouritFromCoredata];
                [[SyncManager sharedManager] forceSync];
                [self reloadtableViewData];
                
            }
            else
            {
                
                if (sortedItems != nil && sortedItems.count > selectedIndexPath.row) {
                    CLS_LOG(@"delete item from sortedItems in store condition");

                    [sortedItems removeObjectAtIndex:selectedIndexPath.row];
                    
                    if(sortedItems.count>0)
                    {
                        [self.tableView deleteRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                    }
                    [self getFavouritFromCoredata];
                    
                    [[SyncManager sharedManager] forceSync];
                    [self reloadtableViewData];
                }
                
            }
            
            
        }
        else
        {
            if (allItems != nil && allItems.count > selectedIndexPath.row)
            {
                CLS_LOG(@"delete item from allItems");

                [allItems removeObjectAtIndex:selectedIndexPath.row];
                
                if(allItems.count>0)
                {
                    [self.tableView deleteRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                }
                [self getFavouritFromCoredata];
                
                [[SyncManager sharedManager] forceSync];
                [self reloadtableViewData];
                
            }
        }
    }
    else
    {
        CLS_LOG(@"delete item from sortedItems in else section");

        if (sortedItems != nil && sortedItems.count > selectedIndexPath.row) {
            [sortedItems removeObjectAtIndex:selectedIndexPath.row];
            
            if(sortedItems.count>0)
            {
                [self.tableView deleteRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            [self getFavouritFromCoredata];
            
            [[SyncManager sharedManager] forceSync];
            [self reloadtableViewData];
        }
        
    }
    
    //[self.tableView deleteRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    // [[SyncManager sharedManager] forceSync];
    //  [self reloadtableViewData];
}

#pragma mark - rotation
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    //Raj-7-1-2015
    [popup dismissPopoverAnimated:NO];
    
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    
    //Dimple-19-10-2015
    
    if(IS_OS_8_OR_LATER)
    {
        my_screenwidth=SCREEN_WIDTH;
    }
    else
    {
        my_screenwidth=myscreenwidth;
    }
    
    
    //Raj - 2-10-15
    //    CGRect newFrame = self.txtView.frame;
    //    newFrame.size.width = my_screenwidth-10;
    //    self.txtView.frame=newFrame;
    //    self.textBtn.hidden=NO;
    //
    if(!stop_animation)
    {
        call_from_rotate=YES;
        [self TextBoxAnimationStart];
    }
    [self reloadtableViewData];
    if(!stop_animation)
    {
        self.tableView.hidden=YES;
    }
    //this is to redraw the section header so that it suits the width of the tableView
}

#pragma mark - HideKeyboard
- (BOOL)textFieldShouldClear:(UITextField *)textField {
    /*
    [textField resignFirstResponder];
    
    [self switchSuggestionTo:NO];   //turn off suggestion mode
    
    if (([self.textfieldForNewItem.text isEqualToString:[DataStore instance].ingredientByURL ] && [[DataStore instance].ingredientByURL length]>0)||[self.textfieldForNewItem.text isEqualToString:[DataStore instance].iTemNameNotAddedYet]) {
        [self moveUpTableViewPosition:NO];
    } else {
        [self moveUpTableViewPosition:YES];
    }
    */
    
    suggestedItems = [NSMutableArray new];
    [DataStore instance].ingredientByURL = @"";
    [DataStore instance].iTemNameNotAddedYet = @"";
    textField.text = @"";
    [self reloadtableViewData];
    if([textField isFirstResponder])
    {
        self.tableView.hidden=YES;
    }
    /*
    if(textField.text.length==0)
    {
        [self TextBoxAnimationStop];
    }
    */
    return NO;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    suggestedItems = [NSMutableArray new];

    /*
     Developer : Dimple
     Date-Time : 22-9-2015
     Description : input box underneath */
    const float movementDuration = 0.3; // tweak as needed
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    [self.tableView setContentOffset:CGPointMake(0, 0)];
    [UIView commitAnimations];
    
    if(textField.text.length==0)
    {
        [self TextBoxAnimationStop];
    }
    
    [textField resignFirstResponder];
    [self moveUpTableViewPosition:YES];
    
    if (dataStore.sortingOrder == STORE )
    {
        if(unknownItems.count>0 || sortedItems.count>0)
        {
            self.tableView.hidden=NO;
        }
        else
        {
            self.tableView.hidden=YES;

        }
    }
    else
    {
        if(allItems.count>0)
        {
            self.tableView.hidden=NO;
        }
        else
        {
            self.tableView.hidden=YES;

        }
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    textField.textAlignment=NSTextAlignmentLeft;
    //dimple-21-10-2015
    if(picker_Flag)
    {
        [self CancelTapped];
    }
    
    // these lines were causing crash when were clickin on textview
    //for clearing change/delete menu
    //    NSArray *visibleCellIndexes = [self.tableView indexPathsForVisibleRows];
    //    [self reloadTheseCells:visibleCellIndexes];
    
    NSString *textfieldStr=[self.textfieldForNewItem.text stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceCharacterSet]];
    if(textfieldStr.length==0)
    {
        self.tableView.hidden=YES;
    }
    else{
        [self switchSuggestionTo:self.textfieldForNewItem.text.length > 0 && httpClient.isLoggedIn];
        
    }
//    self.tableView.hidden=YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    //[self.textfieldForNewItem resignFirstResponder];
    
    //Raj 15-1-2016
    const float movementDuration = 0.3; // tweak as needed
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    //[self.tableView setContentOffset:CGPointMake(0, 0)]; //Offset 1
    [UIView commitAnimations];
    
    if(self.textfieldForNewItem.text.length==0)
    {
        [self TextBoxAnimationStop];
    }

    [self.textfieldForNewItem resignFirstResponder];
    [self moveUpTableViewPosition:YES];
}

#pragma mark - showSpinner
/*
 -(void)createWaitOverlay:(NSString*)message
 {
 waitOverlayHasBeenShown = YES;
 // fade the overlay in
 if (loadingLabel != nil) {
 return;
 }
 if (message.length > 14) {
 loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 75,self.view.bounds.size.height/2 - 30,210.0, 50.0)];
 }
 else{
 loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 -100,self.view.bounds.size.height/2 - 30,210.0, 20.0)];
 }
 loadingLabel.text = message;
 loadingLabel.numberOfLines = 0;
 loadingLabel.textColor = [UIColor whiteColor];
 bgimage = [[UIImageView alloc] initWithFrame:self.view.frame];
 bgimage.image = [UIImage imageNamed:@"waitOverLay.png"];
 [self.view addSubview:bgimage];
 bgimage.alpha = 0;
 [bgimage addSubview:loadingLabel];
 loadingLabel.alpha = 0;
 
 
 [UIView beginAnimations: @"Fade In" context:nil];
 [UIView setAnimationDelay:0];
 [UIView setAnimationDuration:.5];
 bgimage.alpha = 1;
 loadingLabel.alpha = 1;
 [UIView commitAnimations];
 
 spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
 spinner.hidden = FALSE;
 spinner.frame = CGRectMake(self.view.bounds.size.width/2 - 25,self.view.bounds.size.height/2 - 75, 50, 50);
 [spinner setHidesWhenStopped:YES];
 [self.view addSubview:spinner];
 [self.view bringSubviewToFront:spinner];
 [spinner startAnimating];
 }
 
 -(void)removeWaitOverlay {
 [UIView beginAnimations: @"Fade Out" context:nil];
 [UIView setAnimationDelay:0];
 [UIView setAnimationDuration:.5];
 bgimage.alpha = 0;
 loadingLabel.alpha = 0;
 [UIView commitAnimations];
 [spinner stopAnimating];
 
 if (loadingLabel != nil) {
 [bgimage removeFromSuperview];
 [loadingLabel removeFromSuperview];
 [spinner removeFromSuperview];
 bgimage = nil;
 loadingLabel = nil;
 spinner = nil;
 }
 }
 */


#pragma mark - dealloc
- (void)dealloc {
    // we are no longer interested in these notifications:
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SortingChanged" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FinishInsertingItems" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MenuShown" object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - otherMehods
- (void)reloadTheseCells:(NSArray *)arrayIn
{
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:arrayIn withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)adjustTitleLabelForKnowText:(UILabel *)labelIn withItem:(Item *)itemIn withFountSize:(CGFloat) fontSizeIn
{
    CLS_LOG(@"adjustTitleLabelForKnowText method called in itemsview controller");

    if (itemIn.knownItemText && itemIn.knownItemText.length != 0)
    {
        if ([labelIn respondsToSelector:@selector(setAttributedText:)])
        {
            UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSizeIn];
            UIFont *regularFont = [UIFont systemFontOfSize:fontSizeIn];
            UIColor *foregroundColor = [UIColor blackColor];
            
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName,foregroundColor, NSForegroundColorAttributeName, nil];
            NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, nil];
            
            const NSRange range = [labelIn.text rangeOfString:itemIn.knownItemText];
            
            
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:labelIn.text attributes:attrs];
//            [attributedText setAttributes:subAttrs range:range];
             int n=0;
            NSRange whiteSpaceRange = [itemIn.knownItemText rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
            if (whiteSpaceRange.location == NSNotFound) {
             
                if([labelIn.text.lowercaseString rangeOfString:itemIn.knownItemText.lowercaseString].location!=NSNotFound)
                {
                    NSArray* strArr = [labelIn.text componentsSeparatedByString: @" "];
                    for(int i=0;i<strArr.count;i++)
                    {
                        NSString *matchStr=@"";
                        NSString *newString=@"";
                        
                        n+=[strArr[i] length]+i;
                        matchStr=[strArr objectAtIndex:i];
                        if(i==0)
                        {
                            if(matchStr.length>=itemIn.knownItemText.length)
                            {
                                newString = [matchStr substringToIndex:itemIn.knownItemText.length];
                                if([newString.lowercaseString isEqualToString:itemIn.knownItemText.lowercaseString])
                                {
                                    NSString *string2 =[labelIn.text substringWithRange:NSMakeRange(0, matchStr.length)];
                                    const NSRange range = [labelIn.text.lowercaseString rangeOfString:string2.lowercaseString];
                                    [attributedText setAttributes:subAttrs range:range];
                                    [labelIn setAttributedText:attributedText];
                                    break;
                                }
                            }
                        }
                        else if(i!=strArr.count-1 && i!=0)
                        {
                            if([matchStr.lowercaseString isEqualToString:itemIn.knownItemText.lowercaseString])
                            {
                                const NSRange range= [labelIn.text.lowercaseString rangeOfString:[NSString stringWithFormat:@" %@ ", itemIn.knownItemText.lowercaseString]];
                                [attributedText setAttributes:subAttrs range:range];
                                [labelIn setAttributedText:attributedText];
                                break;
                            }
                        }
                        else if(i==strArr.count-1)
                        {
                            if([matchStr.lowercaseString isEqualToString:itemIn.knownItemText.lowercaseString])
                            {
                                const NSRange range =  [labelIn.text  rangeOfString:itemIn.knownItemText options:NSBackwardsSearch];
                                [attributedText setAttributes:subAttrs range:range];
                                [labelIn setAttributedText:attributedText];
                                break;
                            }

                        }
                    }
                }
            }
            else
            {
                [attributedText setAttributes:subAttrs range:range];
                [labelIn setAttributedText:attributedText];

            }
            
        
            /*NSRange range = [labelIn.text rangeOfString:[NSString stringWithFormat:@" %@ ", itemIn.knownItemText]];
             if (range.location == NSNotFound)
             {
             range = [labelIn.text rangeOfString:[NSString stringWithFormat:@" %@", itemIn.knownItemText]];
             if (range.location != NSNotFound)
             {
             [attributedText setAttributes:subAttrs range:range];
             }
             else
             {
             range = [labelIn.text rangeOfString:[NSString stringWithFormat:@"%@", itemIn.knownItemText]];
             if (range.location != NSNotFound)
             {
             [attributedText setAttributes:subAttrs range:range];
             }
             }
             }
             else
             {
             [attributedText setAttributes:subAttrs range:range];
             }*/
            //             [labelIn setAttributedText:attributedText];

        }
    }
    else
    {
        // Adde code to fix issue # 183, /Yousuf
        if ([labelIn respondsToSelector:@selector(setAttributedText:)])
        {
            UIFont *regularFont = [UIFont systemFontOfSize:fontSizeIn];
            UIColor *foregroundColor = [UIColor blackColor];
            
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName,foregroundColor, NSForegroundColorAttributeName, nil];
            
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:labelIn.text attributes:attrs];
            [labelIn setAttributedText:attributedText];
        }
    }
}

#pragma mark - Private reload methods for the TableView

- (void)reloadtableViewData
{
    
    UnSortedcolorArr=[[NSMutableArray alloc]init];
    SortedcolorArr=[[NSMutableArray alloc]init];
    colorArr=[[NSMutableArray alloc]init];
    
    is_mannual_sort=false;
    
    [self.tableView reloadData];
    self.testImage.hidden=YES;
    self.userHintLabel.text=@"";
    //[self TakePic];
    
    // if visiblecells is nil then there is no row in the table view.
    //         if ([self.tableView visibleCells].count == 0)
    
    if (isSuggestionOn)
    {
        [self.tableView setHidden:NO];
        //[self TakePic];
        [self.userHintLabel setText:@""];
    }
    else
    {
        if (allItems.count == 0 && unknownItems.count == 0 && sortedItems.count == 0)
        {
            [self.tableView setHidden:YES];
            
            NSString *str_msg = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"Your grocery list is empty.", nil), NSLocalizedString(@"Add an item by entering text into the input field above and then press the + button.", nil)];
            [self.userHintLabel setText:str_msg];
        }
        else
        {
            colorFlag=0;
            colorFlag2=0;
            
            // DLog(@"sortedItems.count %lu",(unsigned long)sortedItems.count);
            //  DLog(@"unknownItems %lu",(unsigned long)unknownItems.count);
            if(allItems.count>0 && sortedItems.count==0 && unknownItems.count==0)
            {
                Item *firstItem=allItems[0];
                old_cat=firstItem.placeCategory;
                colorArr=[[NSMutableArray alloc]init];
                for (int i=0; i<allItems.count; i++) {
                    Item *firstItem=allItems[i];
                    new_cat=firstItem.placeCategory;
                    if([old_cat isEqualToString:new_cat] && old_cat!=nil && new_cat!=nil)
                    {
                        if(colorFlag2==0)
                        {
                            colorFlag=0;
                            [colorArr addObject:@"Blue"];
                        }
                        else
                        {
                            colorFlag=1;
                            [colorArr addObject:@"Green"];
                            
                        }
                    }
                    else{
                        old_cat=new_cat;
                        
                        if(colorFlag==0)
                        {
                            [colorArr addObject:@"Green"];
                            colorFlag=1;
                            colorFlag2=1;
                        }
                        else{
                            [colorArr addObject:@"Blue"];
                            colorFlag=0;
                            colorFlag2=0;
                        }
                    }
                    
                }
            }
            if (unknownItems.count>0)
            {
                Item *firstItem=unknownItems[0];
                old_cat=firstItem.placeCategory;
                UnSortedcolorArr=[[NSMutableArray alloc]init];
                for (int i=0; i<unknownItems.count; i++) {
                    Item *firstItem=unknownItems[i];
                    new_cat=firstItem.placeCategory;
                    // DLog(@"old cat1 :%@ || new cat1 :%@",old_cat,new_cat);
                    if([old_cat isEqualToString:new_cat] && old_cat!=nil && new_cat!=nil)
                    {
                        if(colorFlag2==0)
                        {
                            colorFlag=0;
                            [UnSortedcolorArr addObject:@"Blue"];
                        }
                        else
                        {
                            colorFlag=1;
                            [UnSortedcolorArr addObject:@"Green"];
                            
                        }
                    }
                    else{
                        old_cat=new_cat;
                        
                        if(colorFlag==0)
                        {
                            [UnSortedcolorArr addObject:@"Green"];
                            colorFlag=1;
                            colorFlag2=1;
                        }
                        else{
                            [UnSortedcolorArr addObject:@"Blue"];
                            colorFlag=0;
                            colorFlag2=0;
                        }
                    }
                    
                }
            }
            if (sortedItems.count>0)
            {
                Item *firstItem=sortedItems[0];
                old_cat=firstItem.placeCategory;
                SortedcolorArr=[[NSMutableArray alloc]init];
                for (int i=0; i<sortedItems.count; i++) {
                    Item *firstItem=sortedItems[i];
                    new_cat=firstItem.placeCategory;
                    // DLog(@"old cat1 :%@ || new cat1 :%@",old_cat,new_cat);
                    if([old_cat isEqualToString:new_cat] && old_cat!=nil && new_cat!=nil)
                    {
                        if(sortedItems.count>0 && unknownItems.count==0)
                        {
                            if(colorFlag2==0)
                            {
                                colorFlag=0;
                                [SortedcolorArr addObject:@"Blue"];
                            }
                            else
                            {
                                colorFlag=1;
                                [SortedcolorArr addObject:@"Green"];
                                
                            }
                        }
                        else{
                            if(colorFlag2==0)
                            {
                                colorFlag=0;
                                [SortedcolorArr addObject:@"Green"];
                            }
                            else
                            {
                                colorFlag=1;
                                [SortedcolorArr addObject:@"Blue"];
                                
                            }
                            
                        }
                    }
                    else{
                        old_cat=new_cat;
                        if(sortedItems.count>0 && unknownItems.count==0)
                        {
                            if(colorFlag==0)
                            {
                                [SortedcolorArr addObject:@"Green"];
                                colorFlag=1;
                                colorFlag2=1;
                            }
                            else{
                                [SortedcolorArr addObject:@"Blue"];
                                colorFlag=0;
                                colorFlag2=0;
                            }
                        }
                        else{
                            if(colorFlag==0)
                            {
                                [SortedcolorArr addObject:@"Blue"];
                                colorFlag=1;
                                colorFlag2=1;
                            }
                            else{
                                [SortedcolorArr addObject:@"Green"];
                                colorFlag=0;
                                colorFlag2=0;
                            }
                        }
                    }
                    
                }
            }
            
            
            
            [self.tableView setHidden:NO];
            [self TakePic];
            [self.userHintLabel setText:@""];
        }
    }
    
}
-(void)TakePic
{
    CLS_LOG(@"TakePic called  in itemsview controller");

    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
    }
    else
        UIGraphicsBeginImageContext(self.view.bounds.size);
    
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        [Utility setItemscustomImage:UIGraphicsGetImageFromCurrentImageContext()];
        UIGraphicsEndImageContext();
    }
    else
    {
        UIGraphicsBeginImageContext(self.view.bounds.size);
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        [Utility setItemscustomLandImage:UIGraphicsGetImageFromCurrentImageContext()];
        UIGraphicsEndImageContext();
    }
    
    self.testImage.hidden=YES;
}
#pragma mark - Keyboard Registered notifications methods

- (void)keyboardWillShow:(NSNotification *)note
{
    /*
     Developer : Dimple
     Date-Time : 22-9-2015
     Description : input box underneath */
    
    if(IS_IPHONE)
    {
        self.tableView.contentInset=UIEdgeInsetsMake(-40.0f, 0.0f, 20, 0.0);
    }
    else
    {
        self.tableView.contentInset=UIEdgeInsetsMake(-70.0f, 0.0f, 20, 0.0);
    }
    
    
    self.oldBottomContentInset = self.tableView.contentInset.bottom;
    //    self.tableViewTopConstraint.constant -= 40;
    
    CGRect keyboardRect = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0.0f, CGRectGetHeight(keyboardRect), 0.0f);
    
    [UIView animateWithDuration:[[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
        [self.view layoutIfNeeded];
        [self.view setNeedsLayout];
    }];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    /*
     Developer : Dimple
     Date-Time : 22-9-2015
     Description : input box underneath */
    if(IS_IPHONE)
    {
        self.tableView.contentInset=UIEdgeInsetsMake(0, 0.0f, -40, 0.0);
    }
    else
    {
        self.tableView.contentInset=UIEdgeInsetsMake(0, 0.0f, -70, 0.0);
    }
    
    
    ////    self.tableViewTopConstraint.constant += 40;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0.0f, self.oldBottomContentInset, 0.0f);
    
    [UIView animateWithDuration:[[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        self.tableView.contentInset = contentInset;
        self.tableView.scrollIndicatorInsets = contentInset;
        
        [self.view layoutIfNeeded];
        [self.view setNeedsLayout];
    }];
}

- (void)showNoInternetAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"No internet",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil, nil];
    alert.delegate = self;
    alert.tag = 2003;
    [alert show];
}

#pragma mark -
#pragma mark - CustomPickerViewDelegate Methods
/**
 Use this method to show variants
 @ModifiedDate: September 9 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)showPickerView:(NSString *)type withArray:(NSMutableArray *)array withItem:(Item *)item
{
    //Dimple-21-10-2015#325
    picker_Flag=true;
    
    self.customPickerView = [CustomPickerView createViewWithItems:array pickerType:type];
    self.customPickerView.delegate = self;
    self.customPickerView.selectedItem = item;
    /*
    CGRect frame = self.customPickerView.frame;
    //frame.size.height = 260;
    frame.size.width = self.view.frame.size.width;
    
    self.customPickerView.frame = frame;
    */
    self.customPickerView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height + 300);
    
    [self.parentViewController.parentViewController.view addSubview:self.customPickerView];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.customPickerView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height - 80);
    }completion:^(BOOL finished) {
        //Dimple-21-10-2015
        if ([self.textfieldForNewItem isFirstResponder])
        {
            [self TextBoxAnimationStop];
        }
        self.customPickerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *viewsDictionary = @{@"pickerView":self.customPickerView};
        NSArray *constraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[pickerView]-0-|"
                                                                            options:0
                                                                            metrics:nil
                                                                              views:viewsDictionary];
        [self.parentViewController.parentViewController.view addConstraints:constraint_POS_H];
        NSArray *constraint_POS_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[pickerView]-|"
                                                                            options:0
                                                                            metrics:nil
                                                                              views:viewsDictionary];
        [self.parentViewController.parentViewController.view addConstraints:constraint_POS_V];

    }];
}

/**
 This method will be called when user will select any option and presses done
 @ModifiedDate: September 9 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)pickerView:(CustomPickerView *)pickerView withSelectedOption:(NSInteger)optionIndex
{
    NSString *matchingItem = [pickerView.items objectAtIndex:optionIndex];
    if (![matchingItem isEqualToString:@"?"])
    {
        [pickerView.selectedItem updateItemWithMatchingText:matchingItem andIsPossibleMatch:[NSNumber numberWithBool:true]];
        
        [[SyncManager sharedManager] forceSync];
        [self.tableView reloadData];
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        self.customPickerView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height + 200);
    }completion:^(BOOL finished) {
        [self.customPickerView removeFromSuperview];
        self.customPickerView = nil;
    }];
}

/**
 this method will be called when Cancel is tapped from custom picker view
 @ModifiedDate: September 9 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)CancelTapped
{
    //Dimple-21-10-2015
    picker_Flag=false;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.customPickerView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height + 200);
    }completion:^(BOOL finished) {
        [self.customPickerView removeFromSuperview];
        self.customPickerView = nil;
    }];
}


#pragma mark - Expand Cell
- (void)expandCell:(NSIndexPath *)indexPath
{
    // self.expandedIndexPath=indexPath;
    [self.tableView beginUpdates];
    
    if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame)
    {
        self.expandedIndexPath = nil;
        [self.tableView endUpdates];
        
    }
    else
    {
        self.expandedIndexPath = indexPath;
        [self.tableView endUpdates];
        
        [UIView animateWithDuration:0.7
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:4.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             if([indexPath row]==((NSIndexPath*)[[self.tableView indexPathsForVisibleRows]lastObject]).row)
                             {
                                 [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.expandedIndexPath.row inSection:self.expandedIndexPath.section] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                             }
                             
                         }
                         completion:^(BOOL finished){
                             
                         }];
        [UIView commitAnimations];
    }
    
}

#pragma mark - expand cell edit,delete event
-(void)editBtn:(UIButton*)sender
{
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    expandableIndexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    ItemCell *itemCell = (ItemCell*)[self.tableView cellForRowAtIndexPath:expandableIndexPath];
    
//    DLog(@"Item id %@",itemCell.itemId);
//    DLog(@"Item itemObjectId %@",itemCell.itemObjectId);
//    DLog(@"Item titleLabel.text %@",itemCell.titleLabel.text);
//    DLog(@"Item cellItem %@",itemCell.cellItem);
    
    selectedItemId = itemCell.itemId;
    selectedItemObjectId = itemCell.itemObjectId;
    selectedItemText = itemCell.titleLabel.text;
    selectedItem = itemCell.cellItem;
    self.expandedIndexPath=nil;
    
    //Raj-7-1-16
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getUndoItemText:) name:@"UndoItemToast" object:nil];
    
    [self performSegueWithIdentifier:@"toChangeItem" sender:self];
    
    
}
-(void)deleteBtn:(UIButton*)sender
{
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    expandableIndexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    ItemCell *itemCell = (ItemCell*)[self.tableView cellForRowAtIndexPath:expandableIndexPath];
    
    selectedItemId = itemCell.itemId;
    selectedItemObjectId = itemCell.itemObjectId;
    selectedItemText = itemCell.titleLabel.text;
    selectedItem = itemCell.cellItem;
    self.expandedIndexPath=nil;
    
    // Delete button is pressed
    selectedIndexPath = [self.tableView indexPathForCell:itemCell];
    [self deleteItem];
    
}
-(IBAction)copyToBtn:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    expandableIndexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    ItemCell *itemCell = (ItemCell*)[self.tableView cellForRowAtIndexPath:expandableIndexPath];
    [self gotoListView:@"Copy Items" item:itemCell.cellItem];
    self.expandedIndexPath=nil;
    [self.tableView reloadRowsAtIndexPaths:@[expandableIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}
-(IBAction)moveBtn:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    expandableIndexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    ItemCell *itemCell = (ItemCell*)[self.tableView cellForRowAtIndexPath:expandableIndexPath];
    [self gotoListView:@"Move Items" item:itemCell.cellItem];
    self.expandedIndexPath=nil;
    [self.tableView reloadRowsAtIndexPaths:@[expandableIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)updateTableViewBottomConstraint:(CGFloat)constant
{
    for (NSLayoutConstraint *constraint in self.view.constraints)
    {
        if ([self isBottomConstraint:constraint])
        {
            constraint.constant = constant;
        }
    }
}

- (BOOL)isBottomConstraint:(NSLayoutConstraint *)constraint
{
    return  [self firstItemMatchesTopConstraint:constraint] || [self secondItemMatchesTopConstraint:constraint];
}

- (BOOL)firstItemMatchesTopConstraint:(NSLayoutConstraint *)constraint
{
    return constraint.firstItem == self.view && constraint.firstAttribute == NSLayoutAttributeBottom;
}

- (BOOL)secondItemMatchesTopConstraint:(NSLayoutConstraint *)constraint
{
    return constraint.secondItem == self.view && constraint.secondAttribute == NSLayoutAttributeBottom;
}

//Dimple-26-11-2015
#pragma mark- Get favourit Items List
-(void)getFavouritFromCoredata{
    
    NSArray *coreDataFavArr = [FavoriteItem MR_findAllSortedBy:@"sortOrder" ascending:YES];
    Final_Fav_arr=[[NSMutableArray alloc]init];
    
    if(coreDataFavArr.count>0)
    {
        (theAppDelegate).no_fav_item_flag=true;
        for(FavoriteItem *favClass in coreDataFavArr)
        {
            NSString *fav_Text,*fav_matchingItem;
            fav_matchingItem=favClass.matchingItem;
            fav_Text=favClass.text;
            
            if(fav_Text!=nil && (fav_matchingItem==nil || fav_matchingItem.length==0))
            {
                fav_matchingItem=fav_Text;
            }
            
            BOOL itemAdded = NO;
            BOOL includeItemToFavList = YES;
            
            for (Item *item in allItems)
            {
                if(([item.searchedText isEqualToString:fav_matchingItem] || [item.matchingItemText isEqualToString:fav_matchingItem]))
                {
                    if(![item.isPermanent boolValue]) {
                        itemAdded = YES;
                    }
                    else {
                        includeItemToFavList = NO;
                    }
                    break;
                }
                
            }
            
            if(includeItemToFavList) {
                if(itemAdded)
                {
                    NSMutableDictionary *tempDic=[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                  fav_Text, @"fav_matchin_item",
                                                  @"Gray", @"is_color",nil];
                    [Final_Fav_arr addObject:tempDic];
                }
                else{
                    NSMutableDictionary *tempDic=[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                  fav_Text, @"fav_matchin_item",
                                                  @"Black", @"is_color",nil];
                    [Final_Fav_arr addObject:tempDic];
                }
            }
        }
    }
    else{
        (theAppDelegate).no_fav_item_flag=false;
        NSMutableDictionary *tempDic=[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      NSLocalizedString(@"You don't have any favorites yet.", nil), @"fav_matchin_item",
                                      @"Gray", @"is_color",nil];
        [Final_Fav_arr addObject:tempDic];
    }
    [self.menu.tableView reloadData];
}
- (void)addNewItemFromFavourite:(NSString *)newItem
{
    NSString *newItemName = [newItem stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self switchSuggestionTo:NO];   //turn off suggestion mode
    
    //add new item in core data, sync to server in sync engine later
    Item_list *list = dataStore.currentList;
    
    DLog(@"Got list from datastore");
    
    LastFavItem = [Item insertItemWithText:newItemName andBarcode:@"" andBarcodeType:@"" belongToList:list withSource:methodOfAddingItem];
    
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        NSMutableDictionary *properties = [NSMutableDictionary new];
        if(newItemName) properties[@"Text"] = newItemName; else properties[@"Text"] = @"NULL";
        if(list.name) properties[@"list"] = list.name; else properties[@"list"] = @"NULL";
        if(methodOfAddingItem) properties[@"source"] = methodOfAddingItem; else properties[@"source"] = @"NULL";
        [[Mixpanel sharedInstance] track:@"Item Added" properties:properties];
    }
    
    //sync to server in sync engine later
    
    //    [self.textfieldForNewItem resignFirstResponder];
    //    DLog(@"Resigned text field");
    
    if (dataStore.sortingOrder == STORE )
    {
        [unknownItems insertObject:LastFavItem atIndex:0];
        DLog(@"Insert new item to unknownItems");
    }
    else
    {
        [allItems insertObject:LastFavItem atIndex:0];
        DLog(@"Insert new item to allItems");
    }
    
    if ([newItemName isEqualToString:[DataStore instance].ingredientByURL ] && [[DataStore instance].ingredientByURL length] > 0)
    {
        [self moveUpTableViewPosition:NO];//only when there is some text in textfield
    }
    else
    {
        [self moveUpTableViewPosition:YES];
    }
    
    //if item successfully added then iTemNameNotAddedYet must be empty.
    [DataStore instance].iTemNameNotAddedYet = @"";
    
    // reload table view to load data when new item added
    //force sync when new item is added
    [[SyncManager sharedManager] forceSync];
    [self reloadtableViewData];
}
- (void) deleteNewItemFromFavourite {
    //Fake delete in core data
    Item *temp = LastFavItem;
    LastFavItem = nil;
    if(temp) {
        if([allItems containsObject:temp])
        {
            [allItems removeObject:temp];
            [self.tableView reloadData];
        
        }
        [Item fakeDeleteItem:temp];
        [[SyncManager sharedManager] forceSync];
    }
    
}
#pragma mark - Favourite Table Delegate mathod
- (NSInteger)numberOfColumnsInMenu:(DOPDropDownMenu *)menu {
    return 1;
}

- (NSInteger)menu:(DOPDropDownMenu *)menu numberOfRowsInColumn:(NSInteger)column {
    DLog(@"%lu", (unsigned long)Final_Fav_arr.count);
    return Final_Fav_arr.count;
}
- (NSDictionary *)menu:(DOPDropDownMenu *)menu titleForRowAtIndexPath:(DOPIndexPath *)indexPath {
    if(Final_Fav_arr.count>0)
    {
        NSDictionary *fav_dic=[Final_Fav_arr objectAtIndex:indexPath.row];
        return fav_dic;
    }
    return 0;
}
- (void)menu:(DOPDropDownMenu *)menu didSelectRowAtIndexPath:(DOPIndexPath *)indexPath
{
    if(Final_Fav_arr.count>0)
    {
        NSMutableDictionary *fav_dic=[Final_Fav_arr objectAtIndex:indexPath.row];
        NSString *is_color,*fav_matchingItem;
        
        is_color=[fav_dic objectForKey:@"is_color"];
        fav_matchingItem=[fav_dic objectForKey:@"fav_matchin_item"];
        
        if([is_color isEqualToString:@"Black"])
        {
            DLog(@"**********insert called ********* ");
            is_color=@"Gray";
            fav_dic=[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                     fav_matchingItem,@"fav_matchin_item",
                     is_color, @"is_color",nil];
            
            
            [Final_Fav_arr replaceObjectAtIndex:indexPath.row withObject:fav_dic];
            //DLog(@"fav_dic:%@",fav_dic);
            [self addNewItemFromFavourite:fav_matchingItem];
        }
        else if([is_color isEqualToString:@"Gray"] && [LastFavItem.text isEqualToString:fav_matchingItem])
        {
            DLog(@"**********delete called ********* ");
            
            is_color=@"Black";
            fav_dic=[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                     fav_matchingItem,@"fav_matchin_item",
                     is_color, @"is_color",nil];
            // DLog(@"fav_dic:%@",fav_dic);
            [Final_Fav_arr replaceObjectAtIndex:indexPath.row withObject:fav_dic];
            [self deleteNewItemFromFavourite];
        }
        else{
            
        }
        
        [self.menu.tableView reloadData];
    }
    
}
#pragma mark- Scrollview delegate Method
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    DLog(@"scrollViewWillBeginDragging called ");
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
}

-(void)AddFloatingBtn:(CGFloat)x1 Y:(CGFloat)y1 W:(CGFloat)w1 H:(CGFloat)h1
{
    CGRect floatFrame = CGRectMake(x1, y1, w1, h1);
    addButton = [[VCFloatingActionButton alloc]initWithFrame:floatFrame normalImage:[UIImage imageNamed:@"cart_floating_sel"] andPressedImage:[UIImage imageNamed:@"cart_floating_sel"] withScrollview:self.tableView];
    
    addButton.hideWhileScrolling = NO;
    addButton.delegate = self;
    
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    
    [self.view addSubview:addButton];
    
}
-(void)FloatingBtnTap:(id)sender
{
  //  DLog(@"Floating btn clicked");
    //Dimple-30-11-2015
    if(self.menu.show)
    {
        [self.menu backgroundTapped:nil];
    }
    
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Go to In Store screen"];
    }
    [self performSegueWithIdentifier:@"ItemsToShoppingMode" sender:self];
    
}
#pragma mark- Barcode Scanner Button Click event
-(IBAction)BarcodeScannerBtn:(id)sender
{
    [self hideToast];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BardodeSignleItemAdd:) name:@"BAERCODE_ADD_SINGE_ITEM" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editBarcodeItem:) name:@"editBarcodeMultipleItem" object: nil];
    [self checkedCameraPermission];

//    BarcodeScannerVC  *bsNav=[[BarcodeScannerVC alloc]initWithNibName:@"BarcodeScannerVC" bundle:nil];
//    (theAppDelegate).is_scan_start=true;
//    // [self.navigationController pushViewController:bsNav animated:YES];
//    [self presentViewController:bsNav animated:YES completion:nil];
}
-(void)BardodeSignleItemAdd:(NSNotification *)pNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSDictionary* userInfo = pNotification.userInfo;
    
    //DLog(@"User Info %@",userInfo);
    NSString *barcodeItemName = [[userInfo objectForKey:@"ItemText"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self switchSuggestionTo:NO];
    
    if([[userInfo objectForKey:@"flag"] intValue]==0)
    {
        
    
            Item_list *list = dataStore.currentList;
            Item *item = [Item insertItemWithTextBarcode:barcodeItemName andBarcode:[userInfo objectForKey:@"barcodeContent"] andBarcodeType:[userInfo objectForKey:@"barcodeType"] belongToList:list withSource:@"Barcode"];
            
            selectedItemId=item.itemID;
            selectedItemObjectId=item.objectID;
            selectedItem=item;
            
            
           
            if (dataStore.sortingOrder == STORE )
            {
                DLog(@"barcode store %@",item.text);
                [unknownItems insertObject:item atIndex:0];
                DLog(@"Insert new item to unknownItems");
            }
            else
            {
                DLog(@"barcode %@",item.text);
                [allItems insertObject:item atIndex:0];
                DLog(@"Insert new item to allItems");
            }
            
            [self showToast:item.text];
            
            //if item successfully added then iTemNameNotAddedYet must be empty.
            [DataStore instance].iTemNameNotAddedYet = @"";
            
            [self reloadtableViewData];
    }
    else
    {
        Item_list *list = dataStore.currentList;
       // Item *item = [Item insertItemWithTextBarcode:barcodeItemName andBarcode:[userInfo objectForKey:@"barcodeContent"] andBarcodeType:[userInfo objectForKey:@"barcodeType"] belongToList:list withSource:@"Barcode"];
        
        Item *item = [Item insertItemWithText:barcodeItemName andBarcode:[userInfo objectForKey:@"barcodeContent"] andBarcodeType:[userInfo objectForKey:@"barcodeType"] belongToList:list withSource:@"Barcode"];
        
        selectedItemId=item.itemID;
        selectedItemObjectId=item.objectID;
        selectedItem=item;
        
        
        
        if (dataStore.sortingOrder == STORE )
        {
            DLog(@"barcode store %@",item.text);
            [unknownItems insertObject:item atIndex:0];
            DLog(@"Insert new item to unknownItems");
        }
        else
        {
            DLog(@"barcode %@",item.text);
            [allItems insertObject:item atIndex:0];
            DLog(@"Insert new item to allItems");
        }
        
        [self showToast:item.text];
        
        //if item successfully added then iTemNameNotAddedYet must be empty.
        [DataStore instance].iTemNameNotAddedYet = @"";
        [[SyncManager sharedManager] forceSync];
        [self reloadtableViewData];
    }
    
}
-(void)editBarcodeItem:(NSNotification *)pNotification
{
    if(pNotification.userInfo!=nil)
    {
        selectedItemId=[pNotification.userInfo objectForKey:@"ItemId"];
        selectedItemObjectId=[pNotification.userInfo objectForKey:@"ItemObjectId"];
        selectedItem=[pNotification.userInfo objectForKey:@"Item"];
    }
    edit_from_barcode=true;
    [self hideToast];
    [self performSegueWithIdentifier:@"toChangeItem" sender:self];
    
}

-(void)showToast:(NSString *)itemName
{
    //raj-20-1-16
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getUndoItemText:) name:@"UndoItemToast" object:nil];

    timer= [NSTimer scheduledTimerWithTimeInterval:7 target:self selector:@selector(hideToast) userInfo:nil repeats:NO];
    
    [self.custom_toastView removeFromSuperview];
    [self.toastLbl removeFromSuperview];
    [self.toastLine removeFromSuperview];
    [self.toastBtn removeFromSuperview];
    
    
    int n;
    if(IS_IPHONE)
    {
        n=15;
        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(16,SCREEN_HEIGHT-106, SCREEN_WIDTH-32, 33)];
        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(26, SCREEN_HEIGHT-97-3, SCREEN_WIDTH-100, 21)];
        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-65,SCREEN_HEIGHT-97-3, 1, 21)];
        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-50, SCREEN_HEIGHT-97, 18, 18)];
    }
    else{
        n=15;
        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(28,SCREEN_HEIGHT-115,SCREEN_WIDTH-77 , 45)];
        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(46, SCREEN_HEIGHT-110-15,SCREEN_WIDTH-178, 100)];
        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-133,SCREEN_HEIGHT-110, 2, 21)];
        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-118, SCREEN_HEIGHT-110, 70, 18)];
    }

    self.custom_toastView.layer.cornerRadius=5;
    self.custom_toastView.layer.masksToBounds=YES;
    self.custom_toastView.backgroundColor=[UIColor blackColor];
    self.custom_toastView.alpha=0.5;
    
    self.toastLbl.numberOfLines=0;
    self.toastLbl.textColor=[UIColor whiteColor];
    
    self.toastLine.backgroundColor=[UIColor whiteColor];
    [self.toastBtn  setImage:[UIImage imageNamed:@"editToast"] forState:UIControlStateNormal];
    
    [self.view addSubview:self.custom_toastView];
    [self.view addSubview:self.toastLbl];

    if(!LittleDataInfo)
    {
        self.toastLbl.text=[NSString stringWithFormat:@"%@ added",itemName];

        [self.view addSubview:self.toastLine];
        [self.view addSubview:self.toastBtn];

    }
    
    [self.toastBtn addTarget:self
                      action:@selector(editBarcodeItem)
            forControlEvents:UIControlEventTouchUpInside];
    
    
    self.toastLbl.hidden=NO;
    self.custom_toastView.hidden=NO;
    self.toastLine.hidden=NO;
    self.toastBtn.hidden=NO;
    
    
    
    [self.toastLbl sizeToFit];
    int lbl_height=self.toastLbl.frame.size.height;
    if(IS_IPAD)
    {
        CGRect frame=self.toastLbl.frame;
        frame.size.height=lbl_height+25;
        frame.size.width=590;
        self.toastLbl.frame=frame;
    }
    
    
    int lbl_h,lbl_w;
    if(IS_IPHONE)
    {
        self.toastLbl.font=[UIFont fontWithName:@"Helvetica" size:15.0f];
        
        if(lbl_height>30)
        {
            lbl_h=50;
            lbl_w=40;
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y, self.custom_toastView.frame.size.width, lbl_height+n-5);
                      self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y, self.toastLine.frame.size.width, lbl_height);
        }
        else{
            lbl_h=35;
            lbl_w=40;
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y, self.custom_toastView.frame.size.width, lbl_height+n);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y, self.toastLine.frame.size.width, lbl_height+n-10);
        }
    }
    else{
        self.toastLbl.font=[UIFont fontWithName:@"Helvetica" size:22.0f];
        
       // DLog(@"lbl height :%d",lbl_height);
        if(lbl_height>=35)
        {
            lbl_h=65;
            lbl_w=75;
          //  DLog(@"if called");
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y-7, self.custom_toastView.frame.size.width, lbl_height+25);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y, self.toastLine.frame.size.width, lbl_height+5);
            
            
        }
        else{
            lbl_h=40;
            lbl_w=75;
           // DLog(@"else  called");
            // self.toastBtn.frame=CGRectMake(self.toastBtn.frame.origin.x-7, self.toastBtn.frame.origin.y-7,75, 35);
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y-8, self.custom_toastView.frame.size.width, lbl_height+25);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y-5, self.toastLine.frame.size.width, lbl_height+n-5);
            
            
        }
        
        
    }
    if(LittleDataInfo)
    {
        self.toastReadMoreBtn = [UIButton new];
        self.toastReadMoreBtn.titleLabel.font= [UIFont fontWithName:@"Helvetica" size:15.0f];
        [self.toastReadMoreBtn setTitle:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Read_more",nil)] forState: UIControlStateNormal];
        [self.toastReadMoreBtn addTarget:self
                     action:@selector(readMore)
           forControlEvents:UIControlEventTouchUpInside];
        
        self.toastLbl.text=[NSString stringWithFormat:@"%@",itemName];
        int n=35;
       
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        int toast_view_height=80,toast_lbl_height=70;
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            
            if(IS_IPHONE)
            {
                toast_view_height=80;
                toast_lbl_height=70;
            }
            else
            {
                toast_view_height=60;
                toast_lbl_height=60;
                
            }
            if (![Utility getDefaultBoolAtKey:@"hasPremium"])
            {
                if(IS_IPHONE)
                {
                    n=35;
                }
                else
                {
                    n=15;

                }
            }
            else
            {
                if(IS_IPHONE)
                {
                    n=-10;
                }
                else
                {
                    n=-15;
                    
                }
            }
        }
        else
        {
            if(IS_IPHONE)
            {
                toast_view_height=50;
                toast_lbl_height=40;
            }
            else
            {
                toast_view_height=60;
                toast_lbl_height=60;
                
            }
            if (![Utility getDefaultBoolAtKey:@"hasPremium"])
            {
                n=15;
            }
            else
            {
                n=-35;
            }

        }
        self.custom_toastView.frame=CGRectMake(10, self.custom_toastView.frame.origin.y-n -20,SCREEN_WIDTH-20,toast_view_height + 20);
        self.toastLbl.frame=CGRectMake(20, self.toastLbl.frame.origin.y-n -20, SCREEN_WIDTH-35,toast_lbl_height);
        self.toastReadMoreBtn.frame = CGRectMake(20, toast_view_height - 5, SCREEN_WIDTH-35, 20);
        [self.custom_toastView addSubview:self.toastReadMoreBtn];
        self.custom_toastView.layer.zPosition = 1;
        self.toastLbl.layer.zPosition = 1;
        LittleDataInfo=false;
    }
    

    self.toastBtn.frame=CGRectMake(self.toastBtn.frame.origin.x-7, self.toastBtn.frame.origin.y-10, lbl_w, lbl_h);
}

- (void) readMore {
    [self hideToast];
    [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self byName:@"SortingToast" force:YES];
}

#pragma mark - view
-(void)hideToast
{
    is_undoBtnClick=false;
    self.toastLbl.hidden=YES;
    self.custom_toastView.hidden=YES;
    self.toastLine.hidden=YES;
    self.toastBtn.hidden=YES;
    if(timer != nil)
    {
        [timer invalidate];
        timer = nil;
    }
    (theAppDelegate).add_success=false;

    
    
}
-(void)editBarcodeItem
{
    edit_from_barcode=true;
    [self hideToast];
    [self performSegueWithIdentifier:@"toChangeItem" sender:self];
    
}


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.addButton removeFromSuperview];
    [self hideToast];
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}


- (IBAction)shareButton:(id)sender{
    
    NSMutableString * message = [NSMutableString new];
    
    //For facebook
    /*
     UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
     pasteboard.string = message;
     */
    
    if([DataStore instance].sortingOrder == STORE)
    {
        for (Item * item in unknownItems) {
            [message appendString:item.text];
            [message appendString:@"\n"];
        }
        for (Item * item in sortedItems) {
            [message appendString:item.text];
            [message appendString:@"\n"];
        }
    }
    else
    {
        for (Item * item in allItems) {
            [message appendString:item.text];
            [message appendString:@"\n"];
        }
    }
    
    NSArray * shareItems = @[message];
    
//    UIActivityViewController * avc = [[UIActivityViewController alloc] initWithActivityItems:shareItems applicationActivities:nil];
//    
//    [self presentViewController:avc animated:YES completion:nil];
    
    UIActivityViewController * avc = [[UIActivityViewController alloc] initWithActivityItems:shareItems applicationActivities:nil];
    if(IS_IPHONE)
    {
        [self presentViewController:avc animated:YES completion:nil];
    }
    else{
        popup = [[UIPopoverController alloc] initWithContentViewController:avc];
        [popup presentPopoverFromRect:CGRectMake (SCREEN_WIDTH, self.navigationController.navigationBar.frame.size.height+20, 0, 0)inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    
}



- (IBAction)recordSpeechButtonTapped:(UIButton *)sender
{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //self.buttonVoice.userInteractionEnabled=NO;
                if ([Utility getDefaultBoolAtKey:@"hasPremium"])
                {
                    (theAppDelegate).voiceResult=[[NSArray alloc] init];
                    [self openRecorderView];
                }
                else
                {
                    NSString *SpeechCnt=[Utility getSpeechCount:[Utility getUserName:@"userName"]];
                    // NSLog(@"speech count %@",SpeechCnt);
                    if([SpeechCnt intValue]<10)
                    {
                        int SpeechCntVal=[SpeechCnt intValue];
                        SpeechCntVal+=1;
                        [Utility setSpeechCount:[NSString stringWithFormat:@"%d",SpeechCntVal] userKey:[Utility getUserName:@"userName"]];
                        
                        (theAppDelegate).voiceResult=[[NSArray alloc] init];
                        [self openRecorderView];
                    }
                    else
                    {
                        [self showAlertView:@"" withMessage:NSLocalizedString(@"Speech usage description", nil)];
                    }
                }
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"microphone_disabled", nil)
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
                [alert show];
            });
        }
    }];
}
-(void)openRecorderView
{
    //self.buttonVoice.userInteractionEnabled=NO;
    //    [[NSNotificationCenter defaultCenter]removeObserver:@"voiceDetectionViewDismiss"];
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceDetectionViewDismiss:) name:@"voiceDetectionViewDismiss" object: nil];
    
    nav=[[VoiceDetectionVC alloc]initWithNibName:@"VoiceDetectionVC" bundle:nil];
    //NSLog(@"self %@",self);
    nav.delegate = self;
    [self presentPopupViewController:nav animationType:MJPopupViewAnimationFade];
    
    //        nav2=[[DemoPopupViewController alloc]initWithNibName:@"DemoPopupViewController" bundle:nil];
    //        // nav.matchingArr=arr;
    //        [self presentPopupViewController:nav2 animationType:MJPopupViewAnimationFade];
    
    
}
-(void)dismissMatchingView:(NSNotification *)pNotification  // matching item display view dismiss
{
    //self.buttonVoice.userInteractionEnabled=YES;
    [[NSNotificationCenter defaultCenter]removeObserver:@"dismissMatchingView"];
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    NSDictionary *dic=pNotification.userInfo;
    if([[dic objectForKey:@"Source"] isEqualToString:@"Voice"])
    {
        [self addNewItemAfterVoiceRecognice:[dic objectForKey:@"ItemText"] itemSource:[dic objectForKey:@"Source"]];
    }
//    else if([[dic objectForKey:@"Source"] isEqualToString:@"SpeakAgain"])
//    {
//        [self openRecorderView];
//    }
    
    
}
#pragma mark- add new item for voice recognization
-(void)addNewItemAfterVoiceRecognice:(NSString *)itemName itemSource:(NSString *)itemSource
{
   // DLog(@"addNewItemAfterVoiceRecognice called");
    if((theAppDelegate).AddViaVoice)
    {
        (theAppDelegate).AddViaVoice=false;
        [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
        
        NSString *item_name=itemName;
        NSString *item_source=itemSource;
        
        
        NSString *newItemName = [item_name  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self switchSuggestionTo:NO];   //turn off suggestion mode
        
        //add new item in core data, sync to server in sync engine later
        Item_list *list = dataStore.currentList;
        
        //DLog(@"Got list from datastore");
        
        Item *item = [Item insertItemWithText:newItemName andBarcode:@"" andBarcodeType:@"" belongToList:list withSource:item_source];
        selectedItemId=item.itemID;
        selectedItemObjectId=item.objectID;
        selectedItem=item;
        [self showToast:item_name];
        
        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
        {
            NSMutableDictionary *properties = [NSMutableDictionary new];
            if(newItemName) properties[@"Text"] = newItemName; else properties[@"Text"] = @"NULL";
            if(list.name) properties[@"list"] = list.name; else properties[@"list"] = @"NULL";
            if(item_source) properties[@"source"] = item_source; else properties[@"source"] = @"NULL";
            [[Mixpanel sharedInstance] track:@"Item Added" properties:properties];
        }
        
        //sync to server in sync engine later
        
        //    [self.textfieldForNewItem resignFirstResponder];
        //    DLog(@"Resigned text field");
        
        if (dataStore.sortingOrder == STORE )
        {
            [unknownItems insertObject:item atIndex:0];
           // DLog(@"Insert new item to unknownItems");
        }
        else
        {
            [allItems insertObject:item atIndex:0];
           // DLog(@"Insert new item to allItems");
        }
        
        if ([newItemName isEqualToString:[DataStore instance].ingredientByURL ] && [[DataStore instance].ingredientByURL length] > 0)
        {
            [self moveUpTableViewPosition:NO];//only when there is some text in textfield
        }
        else
        {
            [self moveUpTableViewPosition:YES];
        }
        
        self.textfieldForNewItem.text = @"";
        //if item successfully added then iTemNameNotAddedYet must be empty.
        [DataStore instance].iTemNameNotAddedYet = @"";
        
        // reload table view to load data when new item added
        //force sync when new item is added
        [[SyncManager sharedManager] forceSync];
        [self reloadtableViewData];
    }
}
- (void)cancelButtonClicked:(VoiceDetectionVC *)aSecondDetailViewController
{
    
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
   // self.buttonVoice.userInteractionEnabled=YES;
    DLog(@"voice result 1%@",(theAppDelegate).voiceResult);
    if((theAppDelegate).voiceResult != nil && (theAppDelegate).voiceResult.count)
    {
        NSMutableArray *texts = [NSMutableArray new];
        for (NSString *voiceResult in (theAppDelegate).voiceResult) {
            NSDictionary *tempDictionary = [NSDictionary dictionaryWithObject:voiceResult forKey:@"text"];
            [texts addObject:tempDictionary];
        }
        NSDictionary *parameters = [NSDictionary dictionaryWithObject:texts forKey:@"voiceMatches"];
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please wait",nil)] maskType:SVProgressHUDMaskTypeClear];
        [[MatlistanHTTPClient sharedMatlistanHTTPClient] POST:@"ItemSearch" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSArray *response = (NSArray *)responseObject;
            if(response.count==1)
            {
                (theAppDelegate).AddViaVoice=true;
                NSString *itemText = response[0][@"text"];
                ///////Don't ask why it is here...////////
                [self presentPopupViewController:nil animationType:MJPopupViewAnimationFade];
                [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
                ///////////////////////////////////////////
                if(itemText) {
                    [self addNewItemAfterVoiceRecognice:itemText itemSource:@"Voice"];
                }
            }
            else if(response.count>0)
            {
                [[NSNotificationCenter defaultCenter]removeObserver:@"dismissMatchingView"];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissMatchingView:) name:@"dismissMatchingView" object: nil];
                
                NSMutableArray *responseTextsArr = [NSMutableArray new];
                
                for(NSDictionary *itemFromServer in response) {
                    NSString *itemText = itemFromServer[@"text"];
                    if(itemText) {
                        [responseTextsArr addObject:itemText];
                    }

                }
                nav1=[[VoiceMatchingVC alloc]initWithNibName:@"VoiceMatchingVC" bundle:nil];
                nav1.matchingArr=responseTextsArr;
                nav1.delegate=self;
                [self presentPopupViewController:nav1 animationType:MJPopupViewAnimationFade];
            }
            [SVProgressHUD dismiss];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [SVProgressHUD dismiss];
            [ALToastView toastInView:self.view withText:NSLocalizedString(@"server_problem", nil)];
        }];
    }
    if((theAppDelegate).voice_not_found)
    {
        (theAppDelegate).voice_not_found=false;
        [ALToastView toastInView:self.view withText:NSLocalizedString(@"Found no matching items. Please try again.", nil)];
    }
}

- (void)MatchingButtonClicked:(VoiceMatchingVC*)voiceMatchingVC
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    [self openRecorderView];
}

#pragma mark-Show undo item toast
-(void)ShowToastForUndoItem:(NSString *)Itemname
{
    [self hideToast];
    is_undoBtnClick=true;
    
    undoItemName=Itemname;
    
    
    timer= [NSTimer scheduledTimerWithTimeInterval:7 target:self selector:@selector(hideToast) userInfo:nil repeats:NO];
    
    [self.custom_toastView removeFromSuperview];
    [self.toastLbl removeFromSuperview];
    [self.toastLine removeFromSuperview];
    [self.toastBtn removeFromSuperview];
    
    
    int n;
//    if(IS_IPHONE)
//    {
//        n=15;
//        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(16,SCREEN_HEIGHT-106, 288, 33)];
//        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(26, SCREEN_HEIGHT-97-3, 220, 21)];
//        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(255,SCREEN_HEIGHT-97-3, 1, 21)];
//        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(270, SCREEN_HEIGHT-97, 18, 18)];
//    }
//    else{
//        n=15;
//        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(28,SCREEN_HEIGHT-115,691 , 45)];
//        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(46, SCREEN_HEIGHT-110-15,590, 100)];
//        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(635,SCREEN_HEIGHT-110, 2, 21)];
//        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(650, SCREEN_HEIGHT-110, 70, 18)];
//    }
    if(IS_IPHONE)
    {
        n=15;
        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(16,SCREEN_HEIGHT-106, SCREEN_WIDTH-32, 33)];
        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(26, SCREEN_HEIGHT-97-3, SCREEN_WIDTH-100, 21)];
        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-65,SCREEN_HEIGHT-97-3, 1, 21)];
        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-50, SCREEN_HEIGHT-97, 18, 18)];
    }
    else{
        n=15;
        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(28,SCREEN_HEIGHT-115,SCREEN_WIDTH-77 , 45)];
        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(46, SCREEN_HEIGHT-110-15,SCREEN_WIDTH-178, 100)];
        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-133,SCREEN_HEIGHT-110, 2, 21)];
        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-118, SCREEN_HEIGHT-110, 70, 18)];
    }

    self.custom_toastView.layer.cornerRadius=5;
    self.custom_toastView.layer.masksToBounds=YES;
    self.custom_toastView.backgroundColor=[UIColor blackColor];
    self.custom_toastView.alpha=0.5;
    
    self.toastLbl.numberOfLines=2;
    self.toastLbl.textColor=[UIColor whiteColor];
    
    self.toastLine.backgroundColor=[UIColor whiteColor];
    [self.toastBtn  setImage:[UIImage imageNamed:@"UndoImg"] forState:UIControlStateNormal];
    
    
    [self.view addSubview:self.custom_toastView];
    [self.view addSubview:self.toastLbl];
    [self.view addSubview:self.toastLine];
    [self.view addSubview:self.toastBtn];
    
    [self.toastBtn addTarget:self
                      action:@selector(addUndoItem)
            forControlEvents:UIControlEventTouchUpInside];
    
    
    self.toastLbl.hidden=NO;
    self.custom_toastView.hidden=NO;
    self.toastLine.hidden=NO;
    self.toastBtn.hidden=NO;
    
    
    self.toastLbl.text=[NSString stringWithFormat:@"%@ deleted",undoItemName];
    
    [self.toastLbl sizeToFit];
    int lbl_height=self.toastLbl.frame.size.height;
    if(IS_IPAD)
    {
        CGRect frame=self.toastLbl.frame;
        frame.size.height=lbl_height+25;
        frame.size.width=590;
        self.toastLbl.frame=frame;
    }
    
    
    int lbl_h,lbl_w;
    if(IS_IPHONE)
    {
        self.toastLbl.font=[UIFont fontWithName:@"Helvetica" size:15.0f];
        
        if(lbl_height>30)
        {
            lbl_h=50;
            lbl_w=40;
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y, self.custom_toastView.frame.size.width, lbl_height+n-5);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y, self.toastLine.frame.size.width, lbl_height);
        }
        else{
            lbl_h=35;
            lbl_w=40;
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y, self.custom_toastView.frame.size.width, lbl_height+n);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y, self.toastLine.frame.size.width, lbl_height+n-10);
        }
    }
    else{
        self.toastLbl.font=[UIFont fontWithName:@"Helvetica" size:22.0f];
        
        // DLog(@"lbl height :%d",lbl_height);
        if(lbl_height>=35)
        {
            lbl_h=65;
            lbl_w=75;
           // DLog(@"if called");
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y-7, self.custom_toastView.frame.size.width, lbl_height+25);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y, self.toastLine.frame.size.width, lbl_height+5);
            
            
        }
        else{
            lbl_h=40;
            lbl_w=75;
           // DLog(@"else  called");
            // self.toastBtn.frame=CGRectMake(self.toastBtn.frame.origin.x-7, self.toastBtn.frame.origin.y-7,75, 35);
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y-8, self.custom_toastView.frame.size.width, lbl_height+25);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y-5, self.toastLine.frame.size.width, lbl_height+n-5);
            
            
        }
        
        
    }
    self.toastBtn.frame=CGRectMake(self.toastBtn.frame.origin.x-7, self.toastBtn.frame.origin.y-10, lbl_w, lbl_h);
}

#pragma mark- check camera permission
-(void)checkedCameraPermission
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            // Will get here on both iOS 7 & 8 even though camera permissions weren't required
            // until iOS 8. So for iOS 7 permission will always be granted.
            if (granted) {
                // Permission has been granted. Use dispatch_async for any UI updating
                // code because this block may be executed in a thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    //                    [self doStuff];
                   // DLog(@"permission granted");
                    BarcodeScannerVC  *bsNav=[[BarcodeScannerVC alloc]initWithNibName:@"BarcodeScannerVC" bundle:nil];
                    (theAppDelegate).is_scan_start=true;
                    // [self.navigationController pushViewController:bsNav animated:YES];
                    [self presentViewController:bsNav animated:YES completion:nil];
                });
            }
            else
            {
                if(authStatus==AVAuthorizationStatusDenied)
                {
                    // Permission has been denied.
                   // DLog(@"permission denied");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *alertText;
                        
                        BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
                        if (canOpenSettings)
                        {
                            alertText = @"It looks like your privacy settings are preventing us from accessing your camera to do barcode scanning. You can fix this by doing the following:\n\n1. Touch the Go button below to open the Settings app.\n\n2. Touch Privacy.\n\n3. Turn the Camera on.\n\n4. Open this app and try again.";
                            
                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert" message:alertText preferredStyle:UIAlertControllerStyleAlert];
                            
                            
                            UIAlertAction *cancelAction = [UIAlertAction
                                                           actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                           style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action)
                                                           {
                                                               [self.navigationController popViewControllerAnimated:YES];
                                                           }];
                            [alertController addAction:cancelAction];
                            UIAlertAction *GoAction = [UIAlertAction
                                                       actionWithTitle:@"Go"
                                                       style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action)
                                                       {
                                                           BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
                                                           if (canOpenSettings)
                                                               [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                       }];
                            [alertController addAction:GoAction];
                            [self presentViewController:alertController animated:YES completion:nil];
                        }
                    });
                }
            }
        }];
    }
}

#pragma mark - Private Methods
- (void)showAlertView:(NSString *)title withMessage:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Read_more",nil) otherButtonTitles:NSLocalizedString(@"Cancel",nil), nil];
    alertView.tag=1;
    [alertView show];
}
#pragma mark AlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1)
    {
        if (buttonIndex == 0)
        {
            //DLog(@"read more");
            [self performSegueWithIdentifier:@"ItemToAdRemoval" sender:self];
            
            
        }
        if (buttonIndex == 1)
        {
            //DLog(@"cancel");
            
        }

    }
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        self.expandedIndexPath=nil;
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        ItemCell *itemCell = (ItemCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        NSNumber *selected_itemId = itemCell.itemId;
        if (indexPath == nil)
        {
            NSLog(@"couldn't find index path");
        }
        else
        {
            NSString *section_name=@"";
            if([DataStore instance].sortingOrder == STORE)
            {
                if(indexPath.section == UNSORTED_SECTION && unknownItems.count > 0)
                {
                    section_name=@"UNSORTED_SECTION";
                }
                else
                {
                    section_name=@"SORTED_SECTION";
                    
                }
            }
            ItemsSelectionViewVC *ItemSelVC=[[ItemsSelectionViewVC alloc]initWithNibName:@"ItemsSelectionViewVC" bundle:nil];
            ItemSelVC.item_id=selected_itemId;
            ItemSelVC.sectionName=section_name;
            [self.navigationController pushViewController:ItemSelVC animated:NO];
        }
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        //Check the duration and if it is less than what you wanted, invalidate the timer.
    }
}


#pragma mrak- open  list view
-(void)gotoListView:(NSString*)screen_name item:(Item*)item
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissList:) name:@"dismissListView" object: nil];
    
    DisplayAllItemListVC *DisAllVC=[[DisplayAllItemListVC alloc]initWithNibName:@"DisplayAllItemListVC" bundle:nil];
    DisAllVC.selectedItemsArr=@[item];
    DisAllVC.screenName=screen_name;
    DisAllVC.selectedItem=item;
    [self presentPopupViewController:DisAllVC animationType:MJPopupViewAnimationFade];
}
#pragma mrak- Set floating button Position
-(void)AddFloatingButton
{
    [self.addButton removeFromSuperview];
    int floating_distance=0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height+20;
        if(IS_IPHONE)
        {
            floating_W=44;
            floating_H=44;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=30;
        }
        else
        {
            floating_W=66;
            floating_H=66;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=45;
        }
    }
    else
    {
        //Landscape mode
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height;
        if(IS_IPHONE)
        {
            floating_W=44;
            floating_H=44;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=30;
            
        }
        else
        {
            floating_W=66;
            floating_H=66;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=45;
            
        }
    }
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        floating_Y=SCREEN_HEIGHT-floating_distance-floating_H;
    }
    else
    {
        floating_Y=SCREEN_HEIGHT-self.bannerView.frame.size.height-floating_distance-floating_H;
    }
    [self AddFloatingBtn:floating_X Y:floating_Y W:floating_W H:floating_H];
    
}
#pragma mark- Favorite Button
-(void)AddFavouriteButtonWithTable
{
    [self.menu removeFromSuperview];
    x=53,w=53,h=48;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height+20;
        if(IS_IPHONE)
        {
            my_screenwidth=SCREEN_WIDTH;
            x=my_screenwidth-53;
            w=53;
            h=48;
        }
        else
        {
            my_screenwidth=SCREEN_WIDTH;
            x=my_screenwidth-70;
            w=68;
            h=68;
        }
    }
    else
    {
        //Landscape mode
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height;
        if(IS_IPHONE)
        {
            my_screenwidth=SCREEN_WIDTH;
            x=my_screenwidth-53;
            w=53;
            h=48;
        }
        else
        {
            my_screenwidth=SCREEN_WIDTH;
            x=my_screenwidth-70;
            w=68;
            h=85;
         }
    }
    self.menu = [[DOPDropDownMenu alloc] initWithOrigin:CGPointMake(my_screenwidth-105, 0) andX:x andY:navigationBarHeight andWidth:w andHeight:h];
    self.menu.dataSource = self;
    self.menu.delegate = self;
    self.menu.screenname=@"items";
    
    [self.view addSubview:self.menu];
    self.menu = self.menu;
}
-(void)getUndoItemText:(NSNotification*)pNotification
{
    is_displayUndoToast=true;
    if(pNotification!=nil)
    {
        undoItemName=[pNotification.userInfo objectForKey:@"ItemText"];
    }

}

@end
