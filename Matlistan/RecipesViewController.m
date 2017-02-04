//
//  RecipesViewController.m
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "RecipesViewController.h"
#import "Recipebox+Extra.h"
#import "Recipebox_tag+Extra.h"
#import "UIImageView+AFNetworking.h"
#import "AFNetworking.h"
#import "MatlistanHTTPClient.h"
#import "RecipeDetailViewController.h"
#import "RecipePlanTableViewController.h"
#import "AppDelegate.h"
#import "RecipeCustomCell.h"
#import "HelpDialogManager.h"
#import "SignificantChangesIndicator.h"

#define MAX_RELOAD_TIMES 10

@interface RecipesViewController ()<UISearchBarDelegate>
{
    NSMutableArray *searchResults;
    NSMutableArray *recipes;
    NSNumber *currectRecipeId;
    NSIndexPath *selectedCellIndexPath;
    Recipebox *selectedRecipe;
    // UIActivityIndicatorView * spinner;
    UIImageView * bgimage;
    UILabel * loadingLabel;
    int reloadTimes;
    NSArray *ratingImages;
    
    SORT_TYPE_RECIPE selectedSortType;
    
    __weak IBOutlet UILabel *userHintLabel;
    __weak IBOutlet UISearchBar *searchBar;
    __weak IBOutlet UIActivityIndicatorView *userHintActivityIndicator;
    
    BOOL is_open;
    NSArray *pickerArr;
    NSInteger selected_picker_index;
    
    //Dimple 30-9-15
    NSNumber *selectedRecipeId;
    NSIndexPath *expandableIndexPath;
    int navigation_height;
    int expand_height, collaps_height;
    int expand_v_y,expand_v_h;
    
    NSMutableArray *randomArr;
    NSArray *final_randomArr;
    
    UIBarButtonItem *sortButton,*addBtn,*helpButton,*optionButton;
    int navigationBarHeight,more_tableview_height,more_tbl_distance;
    NSMutableArray *popupArr;
    BOOL is_dropDownOpen;
    BOOL tagsCached;
}
@end

@implementation RecipesViewController

-(void) didUpdateItems {
    if([SignificantChangesIndicator sharedIndicator].recipeChanged) {
        [self loadRecipesFromCoreData];
        [self.tableview reloadData];
        [[SignificantChangesIndicator sharedIndicator] resetData];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(IS_IPHONE)
    {
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        {
            self.edgesForExtendedLayout = UIRectEdgeNone;
            [self.navigationController.view setBackgroundColor:[UIColor whiteColor]];
        }
    }

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
    
    is_dropDownOpen=true;
    popupArr=[[NSMutableArray alloc]init];
    popupArr=[[NSMutableArray alloc]initWithObjects:@{@"menuItem":NSLocalizedString(@"New recipe", nil)},@{@"menuItem":NSLocalizedString(@"Only Help", nil)},nil];
    
    //Dimple -7-11-2015
    self.title =NSLocalizedString(@"Recipes",nil);
    randomArr=[[NSMutableArray alloc]init];
    //    if((theAppDelegate).RecipecustomImage!=nil)
    //    {
    //        self.testImage.hidden=NO;
    //        self.testImage.image=(theAppDelegate).RecipecustomImage;
    //    }
    userHintLabel.hidden=YES;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        if([Utility getRecipecustomImage]!=nil)
        {
            self.testImage.image=[Utility getRecipecustomImage];
            self.testImage.hidden=NO;
            
        }
    }
    else
    {
        // do something for Landscape mode
        if([Utility getRecipecustomLandImage]!=nil)
        {
            self.testImage.image=[Utility getRecipecustomLandImage];
            self.testImage.hidden=NO;
            
        }
    }
    
    
    //Dimple-8-12-2015
    pickerArr=@[NSLocalizedString(@"Latest",nil),NSLocalizedString(@"Alphabetically",nil),NSLocalizedString(@"Most cooked",nil),NSLocalizedString(@"At least cooked",nil),NSLocalizedString(@"Last prepared",nil),NSLocalizedString(@"Earliest cooked",nil),NSLocalizedString(@"The shortest cooking time",nil),NSLocalizedString(@"Top Rated",nil),NSLocalizedString(@"Random",nil)];
    // [self.picker selectRow:pickerArr.count/2-1 inComponent:0 animated:YES];
    is_open=true;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [SyncManager sharedManager].syncManagerDelegate = self;
        
        self.tableview.separatorColor = [UIColor clearColor];
        searchResults = [[NSMutableArray alloc]init];
        
        DLog(@"loadRecipesFromCoreData Log");
        [self loadRecipesFromCoreData];
    });
    
    ratingImages = @[@"star1",@"star2",@"star3",@"star4",@"star5"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MenuSlideLeftFinished:) name:@"MenuSlideLeftFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(wakeUp:) name: @"UpdateUINotification" object: nil];
    
    
    
    
    if(IS_IPHONE)
    {
        expand_height=139;
        collaps_height=91;
        expand_v_y=91;
        expand_v_h=48;
        
    }
    else
    {
        expand_height=173;
        collaps_height=100;
        expand_v_y=100;
        expand_v_h=73;
        
    }
    tagsCached = NO;
//    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc] initWithTitle:@"Add Recipe" style:UIBarButtonItemStylePlain target:self action:@selector(gotoAddNewRecipeView:)];
//    self.navigationItem.rightBarButtonItems = @[addBtn];
    
   
}
-(IBAction)gotoAddNewRecipeView:(id)sender
{
    AddNewRecipeViewVC *nav=[[AddNewRecipeViewVC alloc]initWithNibName:@"AddNewRecipeViewVC" bundle:nil];
    nav.screenName=@"Add";
    [self.navigationController pushViewController:nav animated:YES];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing RecipesViewController");
    [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
    
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if((theAppDelegate).open_from_recipeList)
    {
        (theAppDelegate).open_from_recipeList=false;
        (theAppDelegate).globalRecipeId=nil;
    }
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
        self.more_tableview.frame=CGRectMake(SCREEN_WIDTH-self.more_tableview.frame.size.width-more_tbl_distance-1, 0, self.more_tableview.frame.size.width, 0);
    }
    else
    {
        self.more_tableview.translatesAutoresizingMaskIntoConstraints=YES;
        self.more_tableview.frame=CGRectMake(SCREEN_WIDTH-self.more_tableview.frame.size.width-more_tbl_distance-1, 64, self.more_tableview.frame.size.width, 0);
    }

    [DataStore instance].tagByURL = @"";
    
    SWRevealViewController *revealController = self.revealViewController;
    revealController=[[SWRevealViewController alloc]init];
    revealController = [self revealViewController];
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    revealController.delegate=self;
    revealController.panGestureRecognizer.enabled = YES;
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    
    if(_tagSearchText.length>0){
        [self.searchDisplayController setActive:YES];
        [searchBar setText:_tagSearchText];
    }
    
    self.clearView.hidden=YES;
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }
    
    if((theAppDelegate).isNewRecipeAdded)
    {
        (theAppDelegate).isNewRecipeAdded=false;
        [self loadRecipesFromCoreData];
        [self.tableview reloadData];
        if ([self.searchDisplayController isActive]) {
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPremiumAccountPurchased object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateUINotification" object:nil];
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
        
        [Utility updateConstraint:self.view toView:self.tableview withConstant:0];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    self.tagSearchText = @"";
    self.expandedIndexPath = nil;
   // [self populateRecipe:recipes];
}
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self collapseaMenu];
    //Dimple 21-10-2015
    self.expandedIndexPath=nil;
    [self.tableview reloadData];
    self.tagSearchText = @"";
    self.picker_main_view.hidden=YES;
}

#pragma mark- UI related

- (IBAction)showMenu
{
    (theAppDelegate).is_random=false;
    //[self.frostedViewController presentMenuViewController];
    [self.revealViewController revealToggle:self];
}

/**
 Get to know that the slide menu has been hidden completely at left
 */
-(void)MenuSlideLeftFinished:(NSNotification*) notif{
    if (recipes== nil || recipes.count == 0) {
        [self reloadRecipes];
    }
}

- (void) threadStartAnimating:(id)data {
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
    
    //    [self createWaitOverlay:[NSString stringWithFormat:@"%@ ...", NSLocalizedString(@"Loading",nil)]];
}

-(IBAction)showSortMenu :(id)sender{
    /* UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:NSLocalizedString(@"Sorting",nil) delegate:self cancelButtonTitle: NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles: NSLocalizedString(@"Latest",nil), NSLocalizedString(@"Alphabetically",nil), NSLocalizedString(@"Most cooked",nil),NSLocalizedString(@"At least cooked",nil), NSLocalizedString(@"Last prepared",nil), NSLocalizedString(@"Earliest cooked",nil), NSLocalizedString(@"The shortest cooking time",nil), NSLocalizedString(@"Top Rated",nil), nil];
     actionSheet.tag = 2;
     
     [actionSheet showFromBarButtonItem:sortButton animated:YES];*/
    
    
    /*Developer : Dimple
     Date : 28-9-15
     Description : Sliding menu swipe gesture management.*/
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    {
        navigation_height=self.navigationController.navigationBar.frame.size.height;
    }
    else
    {
        if(IS_IPHONE)
        {
            navigation_height=64;
        }
        else
        {
            navigation_height=64;
        }
    }
    
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if(is_open)
                         {
                             [self openPicker];
                         }
                         else{
                             [self closedPicker];
                         }
                         
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
    [UIView commitAnimations];
    
    
}

#pragma mark- load data

-(void)loadRecipesFromCoreData{
    // recipes = [NSMutableArray arrayWithArray:[Recipebox getAllRecipesExceptDeleted]];
    recipes = [NSMutableArray arrayWithArray:[Recipebox getAllRecipesExceptDeletedOrderBy:selectedSortType]];

    // here I'm updating the user hints base on the recipes
    if (recipes.count>0) {
        [self.tableview setHidden:NO];
        [userHintLabel setText:@"Please wait..."];
        [self.tableview reloadData];
        userHintLabel.hidden=YES;
        self.testImage.hidden=YES;
        [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(takePic) userInfo:nil repeats:NO];
        
        [userHintActivityIndicator setHidden:YES];
       // [self populateRecipe:recipes];
    }
    else{
        NSString *str_msg;
        userHintLabel.hidden=NO;
        [self.tableview setHidden:YES];
        self.testImage.hidden=YES;
        if(![Utility getDefaultBoolAtKey:@"firstDataLoad"]){
            str_msg = [NSString stringWithFormat:@"%@\n%@",NSLocalizedString(@"Your Recipe Box is empty.", nil), NSLocalizedString(@"Currently, recipes can only be added by logging into www.matlistan.se or using the Android app.", nil)];
            [userHintActivityIndicator setHidden:YES];
        }
        else {
            str_msg = [NSString stringWithFormat:@"%@",NSLocalizedString(@"recipes_loading", nil)];
        }
        [userHintLabel setText:str_msg];
    }
}

-(void)takePic
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(self.view.bounds.size);
    
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        [Utility setRecipecustomImage:UIGraphicsGetImageFromCurrentImageContext()];
        UIGraphicsEndImageContext();
    }
    else
    {
        // do something for Landscape mode
        UIGraphicsBeginImageContext(self.view.bounds.size);
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        [Utility setRecipecustomLandImage:UIGraphicsGetImageFromCurrentImageContext()];
        UIGraphicsEndImageContext();
    }
    
}
-(void)reloadRecipes{
    [NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
    
    while (recipes == nil || recipes.count == 0) {
        [self loadRecipesFromCoreData];
        [NSThread sleepForTimeInterval:0.2]; //wait for 0.2 second and then try to log in
        reloadTimes++;
        DLog(@"Reload recipes %d times", reloadTimes);
        if (reloadTimes >= MAX_RELOAD_TIMES) {
            DLog(@"Reload recipes finished");
            break;
        }
    }
    if(recipes == nil || recipes.count == 0){
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30,140,280.0, 20.0)];
        label.text = NSLocalizedString(@"Your recipe collection is empty.", nil) ;
        [self.view addSubview:label];
    }
    [SVProgressHUD dismiss];
    //[self removeWaitOverlay];   //this must be made in the main thread, that's why a dispatch_async cannot be used here.
    
}

#pragma mark - Table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    if(tableView.tag==1)
    {
        return popupArr.count;
    }
    else
    {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return searchResults.count;
        }
        else{
            return recipes.count;
        }
    }
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
        if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame) {
            
            return expand_height; // Expanded height
        }
        else
        {
            return collaps_height;
        }
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
        }    // Configure the cell...
        int font_size;
        if(IS_IPHONE)
        {
            font_size=14.0;
            self.more_tableview.layer.borderWidth=0.5;
        }
        else{
            font_size=20.0;
            
            self.more_tableview.layer.borderWidth=1;
        }
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:font_size]];
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
        RecipeCustomCell *cell=[tableView dequeueReusableCellWithIdentifier:@"cell"];
        if(cell==nil)
        {
            
            cell=[[RecipeCustomCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
            NSArray *menuarray=[[NSBundle mainBundle]loadNibNamed:@"RecipeCustomCell" owner:self options:nil];
            cell=[menuarray objectAtIndex:0];
            cell.clipsToBounds=YES;
        }
        Recipebox *recipe = nil;
        /* if (tableView == self.searchDisplayController.searchResultsTableView) {
         recipe = [searchResults objectAtIndex:indexPath.row];
         }
         else
         {
         recipe = [recipes objectAtIndex:indexPath.row];
         }*/
        //Dimple-8-12-2015
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            recipe = [searchResults objectAtIndex:indexPath.row];
        }
        else
        {
            if((theAppDelegate).is_random)
            {
                NSDictionary *random_dic=[final_randomArr objectAtIndex:indexPath.row];
                recipe=[random_dic objectForKey:@"recipeDetails"];
            }
            else
            {
                recipe = [recipes objectAtIndex:indexPath.row];
            }
        }
        
        
        NSString *title = recipe.title;
        
        // Add utility buttons
        //    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
        //
        //    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] title:NSLocalizedString(@"More",nil)];
        //    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor colorWithRed:93.0/255.0 green:187.0/255.0 blue:83.0/255.0 alpha:1.0] title:NSLocalizedString(@"Plan",nil)];
        //
        //    cell.rightUtilityButtons = rightUtilityButtons;
        //    cell.delegate = self;
        
        
        
        ////FOR DEBUG PURPOSE////
        /*
         switch (selectedSortType) {
         case NEWEST:
         cell.titleLabel.text = [NSString stringWithFormat:@"%@", recipe.createdAt];
         break;
         case ALPHABETICALLY:
         cell.titleLabel.text = [NSString stringWithFormat:@"%@", recipe.title];
         break;
         case MOST_COOKED:
         case LEAST_COOKED:
         cell.titleLabel.text = [NSString stringWithFormat:@"%@", recipe.cookCount];
         break;
         case LATEST_COOKED:
         case EARLEST_COOKED:
         cell.titleLabel.text = [NSString stringWithFormat:@"%@", recipe.lastCookedAtTime];
         break;
         case SHORTEST_TIME:
         cell.titleLabel.text = [NSString stringWithFormat:@"%@ : %@ : %@", recipe.cookTime, recipe.originalCookTime, recipe.originalCookTimeSpanLower];
         break;
         case HIGHEST_CREDIT:
         cell.titleLabel.text = [NSString stringWithFormat:@"%@", recipe.rating];
         break;
         default:
         cell.titleLabel.text = [NSString stringWithFormat:@"%@", recipe.createdAt];
         break;
         }
        */
        ////////////////////////
        
        cell.titleLabel.text = title;
        cell.recipeId = recipe.recipeboxID;
        [cell.spinner setHidden:YES];
        cell.sourceLabel.text = recipe.source_text;
        cell.timeLabel.text = [Recipebox getCookTimeStringFromRecipe:recipe];
        cell.ratingImageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.ratingImageView.image = [self getImageByRating:[recipe.rating intValue]];
        
        NSString *newUrl = [Utility getCorrectURLFromJson: recipe.imageUrl];
        cell.recipeImageView.contentMode =UIViewContentModeScaleAspectFill;
        cell.recipeImageView.clipsToBounds = YES;
        //Raj - 26-9-15
        cell.recipeImageView.layer.cornerRadius=40;
        
        cell.tag = indexPath.row;
        cell.recipeImageView.image = [UIImage imageNamed:@"placeHolder.png"];
        //[cell.spinner setHidden:NO];
        //[cell.spinner startAnimating];
        UIImage *img;
        if(recipe.imageFileName){
            img = [Utility loadLocalRecipeImage:recipe.recipeboxID];
        }
        if (img) {
            //[cell.spinner setHidden:YES];
            cell.recipeImageView.image = img;
        }
        else {
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                // [cell.spinner setHidden:NO];
                // [cell.spinner startAnimating];
                NSURL *url =[NSURL URLWithString:newUrl];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                [cell.recipeImageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    if (cell.tag == indexPath.row) {
                        NSString *fileName = [NSString stringWithFormat:@"%@.png", recipe.recipeboxID];
                        /*
                         developer : Raj
                         Date : 21-9-2015
                         Description : Compress image before save.
                         */
                        [Utility saveImage:[Utility imageWithImage:image scaledToMaxWidth:150 maxHeight:150] withFileName:fileName];
                        
                        [Recipebox fillImageFileName:fileName forId:recipe.recipeboxID];
                        recipe.imageFileName = fileName;
                        cell.recipeImageView.image = image;
                        //[cell.spinner stopAnimating];
                        // [cell.spinner setHidden:YES];
                    }
                    
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    DLog(@"Can't download recipe image from %@", newUrl);
                    //[cell.spinner stopAnimating];
                    // [cell.spinner setHidden:YES];
                    // cell.recipeImageView.image = [UIImage imageNamed:@"placeHolder.png"];
                    // [Recipebox fillImageFileName:@"placeHolder.png" forId:recipe.recipeboxID];
                    
                }];
                
            });
        }
        
        cell.planBtn.tag = indexPath.row;
        NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
        
        //cell.planBtn.titleLabel.text=NSLocalizedString(@"Plan",nil);
        //cell.editBtn.titleLabel.text=NSLocalizedString(@"Change",nil);
        //cell.deleteBtn.titleLabel.text=NSLocalizedString(@"Delete",nil);
        
        [cell.planBtn setTitle:NSLocalizedString(@"Plan",nil) forState: UIControlStateNormal];
        [cell.editBtn setTitle:NSLocalizedString(@"Change",nil) forState: UIControlStateNormal];
        [cell.deleteBtn setTitle:NSLocalizedString(@"Delete",nil) forState: UIControlStateNormal];
        
        
        if(![language isEqualToString:@"en"])
        {
            if(IS_IPHONE)
            {
                [cell.planBtn setTitleEdgeInsets:UIEdgeInsetsMake(29, -31, 0, 1)];
                [cell.editBtn setTitleEdgeInsets:UIEdgeInsetsMake(29, -23, 0, 1)];
                [cell.deleteBtn setTitleEdgeInsets:UIEdgeInsetsMake(29, -22, 0, 1)];
                [cell.deleteBtn setImageEdgeInsets:UIEdgeInsetsMake(-14,20, 0, 1)];

            }
            else
            {
                [cell.planBtn setTitleEdgeInsets:UIEdgeInsetsMake(50, -46, 0, 0)];
                [cell.editBtn setTitleEdgeInsets:UIEdgeInsetsMake(53, -40, 0, 0)];
                [cell.deleteBtn setTitleEdgeInsets:UIEdgeInsetsMake(50, -50, 0, 0)];
                
            }
        }
        
        
        [cell.planBtn addTarget:self action:@selector(planBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.editBtn.tag = indexPath.row;
        [cell.editBtn addTarget:self action:@selector(editBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.deleteBtn.tag = indexPath.row;
        [cell.deleteBtn addTarget:self action:@selector(deleteBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        //Dimple-5-11-2015
        
        
        // Raj - 26-9-15
        if(indexPath.row%2==0)
        {
            cell.backgroundColor=CELL_BG_COLOR;
        }
        else
        {
            cell.backgroundColor=[UIColor whiteColor];
        }
        
        /*Developer : Dimple
         Date : 30-9-15
         Description : Expand cell UI Improvment.*/
        
        if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame)
        {
            [cell.expandbutton setImage:[UIImage imageNamed:@"upimg"] forState:UIControlStateNormal];
        }
        else
        {
            [cell.expandbutton setImage:[UIImage imageNamed:@"backimg"] forState:UIControlStateNormal];
        }
        [cell.expandbutton addTarget:self action:@selector(expandViewBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.selectionStyle=UITableViewScrollPositionNone;
        
        cell.editBtn.titleLabel.textColor=[Utility getGreenColor];
        cell.planBtn.titleLabel.textColor=[Utility getGreenColor];
        cell.deleteBtn.titleLabel.textColor=[Utility getGreenColor];
        tempCell=cell;
    }
    
    return tempCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag==1)
    {
        self.expandedIndexPath=nil;
        [self.tableview reloadData];
        
        if(indexPath.row==0)// Add new recipe
        {
            if([[MatlistanHTTPClient sharedMatlistanHTTPClient] isLoggedIn]) {
                AddNewRecipeViewVC *nav=[[AddNewRecipeViewVC alloc]initWithNibName:@"AddNewRecipeViewVC" bundle:nil];
                nav.screenName=@"Add";
                [self.navigationController pushViewController:nav animated:YES];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:NSLocalizedString(@"internet_connection_required",nil)
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
        else if (indexPath.row==1)//Help
        {
            [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self force:YES];
        }
    }
    else
    {
        if(tableView==self.searchDisplayController.searchResultsTableView)
        {
            //[self populateRecipe:searchResults];

        }
        (theAppDelegate).detailRecipeFlag=true;
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        self.selected_index=indexPath;

        RecipeCustomCell *cell = (RecipeCustomCell*)[tableView cellForRowAtIndexPath:indexPath];
        selectedRecipe = [Recipebox getRecipeById:cell.recipeId];
        
        [self performSegueWithIdentifier:@"recipeboxToDetail" sender:self];
    }
    [self collapseaMenu];
}
//- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state{
//    if (state == kCellStateRight) {
//
//        NSArray *indxPathsArray = [self.tableview indexPathsForVisibleRows];
//        for (NSIndexPath *indxPath in indxPathsArray) {
//            RecipeListSWCell *tmpCell = (RecipeListSWCell *)[self.tableview cellForRowAtIndexPath:indxPath];
//            if (tmpCell != cell) {
//                [tmpCell hideUtilityButtonsAnimated:NO];
//            }
//        }
//    }
//}
#pragma mark - helper method

-(UIImage*)getImageByRating:(int)rating{
    if (rating > 5 || rating < 1) {
        return  nil;
    }
    else{
        UIImage *image = [UIImage imageNamed:ratingImages[rating-1]];
        return image;
    }
}

#pragma mark- swipe cell

//- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
//{
//    RecipeListSWCell *recipeCell = (RecipeListSWCell*)cell;
//    currectRecipeId = recipeCell.recipeId;
//
//    switch (index) {
//        case 0:
//        {
//            selectedCellIndexPath = [self.tableview indexPathForCell:cell];
//            // More button is pressed
//            UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Change",nil), nil];
//
//            popup.tag = 1;
//            if (IS_IPHONE)
//            {
//                [popup showInView:[UIApplication sharedApplication].keyWindow];
//            }
//            else
//            {
//                [popup showFromRect:cell.frame inView:self.view animated:YES];
//            }
//
//            [cell hideUtilityButtonsAnimated:YES];
//            break;
//        }
//        case 1:
//        {
//            // Plan button is pressed
//            [DataStore instance].currentRecipeID = [currectRecipeId longValue];
//            [self performSegueWithIdentifier:@"recipeToPlan" sender:self];
//
//            [cell hideUtilityButtonsAnimated:YES];
//
//            break;
//        }
//        default:
//            break;
//    }
//}

- (void)showDeleteChoice:(NSString*)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil) message:msg delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)showErrorInputAlert:(NSString*)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info",nil) message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:Nil, nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Set buttonIndex == 1 to handel "Ok"/"Yes" button response
    if (buttonIndex == 1)
    {
        
        
        if ([self.searchDisplayController isActive]) {
            [self.searchDisplayController.searchResultsTableView beginUpdates];
            //Fake delete in core data
            BOOL canBeDeleted = [Recipebox fakeDeleteById:selectedRecipeId];
            if (!canBeDeleted)  //It is also an active recipe so it can't be deleted
            {
                [self showErrorInputAlert:NSLocalizedString(@"Recipe cannot be deleted", nil)];
            }
            else
            {
                Recipebox *recipe = nil;
                recipe = [searchResults objectAtIndex:expandableIndexPath.row];
                [recipes removeObject:recipe];
                [self.tableview reloadData];
                
                [searchResults removeObjectAtIndex:expandableIndexPath.row];
                
                
                [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:@[expandableIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                self.expandedIndexPath=nil;
            }
            [self.searchDisplayController.searchResultsTableView endUpdates];
            
        }
        else
        {
            [self.tableview beginUpdates];
            //Fake delete in core data
            BOOL canBeDeleted = [Recipebox fakeDeleteById:selectedRecipeId];
            if (!canBeDeleted)  //It is also an active recipe so it can't be deleted
            {
                [self showErrorInputAlert:NSLocalizedString(@"Recipe cannot be deleted", nil)];
            }
            else
            {
                [recipes removeObjectAtIndex:expandableIndexPath.row];
                [self.tableview deleteRowsAtIndexPaths:@[expandableIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                self.expandedIndexPath=nil;
            }
            [self.tableview endUpdates];
        }
    }
    //    else if(buttonIndex == 0)
    //    {
    //        [self.tableview reloadData];    //to make the more/delete buttons disappear
    //
    //    }
}


#pragma Actionsheet
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (popup.tag)
    {
        case ACTIONSHEET_SWIPE:
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    [self showDeleteChoice:NSLocalizedString(@"Do you want to remove the recipe?", nil)];
                    break;
                }
                case 1:
                {
                    //http://www.matlistan.se/Account/LogOn?ticket=<ticket>&returnUrl=/RecipeBox/Edit/<recipeId>
                    NSString *link = [NSString stringWithFormat:@"http://www.matlistan.se/Account/LogOn?ticket=%@&returnUrl=/RecipeBox/Edit/%@",
                                      [MatlistanHTTPClient sharedMatlistanHTTPClient].ticket,currectRecipeId];
                    
                    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:link]];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case ACTIONSHEET_SORT:
        {
            selectedSortType = (SORT_TYPE_RECIPE)buttonIndex;
            recipes = [NSMutableArray arrayWithArray:[Recipebox getAllRecipesExceptDeletedOrderBy:(SORT_TYPE_RECIPE)buttonIndex]];
            [self.tableview reloadData];
            break;
        }
        default:
            break;
    }
    
}

#pragma mark - Search methods

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [searchResults removeAllObjects];
    
    //Raj- 9-2-2016 #152
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSMutableDictionary *recipeIdsAndScores = [NSMutableDictionary new];
    for(Recipebox *recipe in recipes) {
        float recipeScore = 0;
        
        float titleMultiplier = 1;
        float tagsMultiplier = 0.8;
        float ingredientsMultiplier = 0.5;
        
        //TITLES
        recipeScore += titleMultiplier * [self countWordsWithInput:searchText inString:recipe.title];
        
        //TAGS
        for (Recipebox_tag *tag in recipe.relatedTags) {
            recipeScore += tagsMultiplier * [self countWordsWithInput:searchText inString:tag.text];
        }

        //INGREDIENTS
        
        recipeScore += ingredientsMultiplier * [self countWordsWithInput:searchText inString:recipe.ingredients];
        
        if(recipeScore > 0){
            [recipeIdsAndScores setObject:[NSNumber numberWithFloat:recipeScore] forKey:recipe.recipeboxID];
            [searchResults addObject:recipe];
        }
    }

    [searchResults sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {

        if([obj1 isKindOfClass:[Recipebox class]] && [obj2 isKindOfClass:[Recipebox class]])
        {
            Recipebox *recipe1 = (Recipebox *) obj1;
            Recipebox *recipe2 = (Recipebox *) obj2;
            float recipe1Score = [(NSNumber *) recipeIdsAndScores[recipe1.recipeboxID] floatValue];
            float recipe2Score = [(NSNumber *) recipeIdsAndScores[recipe2.recipeboxID] floatValue];
            
            if(recipe1Score > recipe2Score) {
                return NSOrderedAscending;
            }
            else if(recipe1Score < recipe2Score) {
                return NSOrderedDescending;
            }
            else {
                return NSOrderedSame;
            }
        }
        return NSOrderedSame;
    }];
}

- (float) countWordsWithInput:(NSString *)input inString:(NSString *)string {
    float wordsScore = 0;
    
    float fullWordHitScore = 1;
    float prefixHitScore = 0.5;
    float otherHitScore = 0.2;

    NSArray *stringWords = [string componentsSeparatedByString:@" "];
    NSArray *inputWords = [input componentsSeparatedByString:@" "];
    
    NSCharacterSet *charactersToRemove = [[ NSCharacterSet alphanumericCharacterSet ] invertedSet ];

    for (NSString *stringWordRaw in stringWords) {
        for (NSString *inputWordRaw in inputWords) {
            NSString *stringWord = [stringWordRaw stringByTrimmingCharactersInSet:charactersToRemove];
            NSString *inputWord = [inputWordRaw stringByTrimmingCharactersInSet:charactersToRemove];
            if(stringWord.length == 0 || inputWord.length == 0){
                continue;
            }
            /*
            if([stringWord isEqualToString:inputWord]) {
                wordsScore += fullWordHitScore;
            }
            else {
                NSRange range = [stringWord rangeOfString:inputWord options:NSCaseInsensitiveSearch];
                if(range.location != NSNotFound) {
                    if(range.location == 0 && range.length > 0){
                        wordsScore += prefixHitScore;
                    } else {
                        wordsScore += otherHitScore;
                    }
                }
            }
             */
            NSRange range = [stringWord rangeOfString:inputWord options:NSCaseInsensitiveSearch];
            if(range.location != NSNotFound) {
                if(range.location == 0 && inputWord.length == stringWord.length){
                    wordsScore += fullWordHitScore;
                } else if(range.location == 0 && range.length > 0){
                    wordsScore += prefixHitScore;
                } else {
                    wordsScore += otherHitScore;
                }
            }

        }
    }
    return wordsScore;
}

-(NSArray*)getTagsForRecipe:(Recipebox*)recipe{
    NSArray *tagsObjects = [recipe.relatedTags allObjects];
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    for (Recipebox_tag *tag in tagsObjects) {
        [tags addObject:tag.text];
    }
    return [tags copy];
    
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    if ([Utility isStringEmpty:searchString]) {
        return NO;
    }
    else{
        [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar  scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
        self.searchDisplayController.searchResultsTableView.separatorColor=[UIColor clearColor];
        self.searchDisplayController.searchResultsTableView.showsVerticalScrollIndicator=NO;
        return YES;
    }
}

#pragma mark- segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"recipeboxToDetail"]){
        (theAppDelegate).open_from_recipeList=true;
        self.expandedIndexPath=nil;
        [self.tableview reloadData];
        
        RecipeDetailViewController *detailView =  (RecipeDetailViewController *)segue.destinationViewController;
        detailView.screen_name=@"RecipeScreen"; //Dimple 9-10-15
        detailView.recipeboxId = selectedRecipe.recipeboxID;
        detailView.activeRecipe = [Recipebox getActiveRecipeByRecipeId:selectedRecipe.recipeboxID];
        detailView.barButtonType = NOT_CERTAIN;
        
//        RecipeTimer *selRecipe = self.recipeArr[self.selected_index.row];
        RecipeTimer *selRecipe = [[RecipeTimer alloc] initWithRecipieId:[selectedRecipe.recipeboxID intValue] recipeName:selectedRecipe.title withRecipeDesc:nil];
        detailView.selectedRecipe = selRecipe;
        detailView.timerOnRecipes = (theAppDelegate).ActiveTimerArr; //_timerOnRecipes;
        selRecipe.recipeListDelegate = (id)theAppDelegate; //the call will goto appdelegate

    }
    
}

#pragma mark- showSpinner
/*
 -(void)createWaitOverlay:(NSString*)message
 {
 // fade the overlay in
 loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(90,230,200.0, 20.0)];
 
 loadingLabel.text = message;
 loadingLabel.textColor = [UIColor whiteColor];
 bgimage = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,320,480)];
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
 spinner.frame = CGRectMake(137, 160, 50, 50);
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
 
 [bgimage removeFromSuperview];
 [loadingLabel removeFromSuperview];
 
 [spinner stopAnimating];
 [spinner removeFromSuperview];
 bgimage = nil;
 loadingLabel = nil;
 spinner = nil;
 
 }
 */

#pragma mark- memory
- (void)dealloc {
    // we are no longer interested in these notifications:
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MenuSlideLeftFinished" object:nil];
    self.timerOnRecipes = nil;//hear all the timer will ne deallcoated, to keep this we need to make timeronrecipes global

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - otherMehods
-(void)reloadTheseCells:(NSArray *)arrayIn{
    [self.tableview beginUpdates];
    [self.tableview reloadRowsAtIndexPaths:arrayIn withRowAnimation:UITableViewRowAnimationNone];
    [self.tableview endUpdates];
}
#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [view setAlpha:1];
    [UIView commitAnimations];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [view setAlpha:0];
    [UIView commitAnimations];
}

/*Developer : Dimple
 Date : 28-9-15
 Description : Sliding menu swipe gesture management.*/

#pragma mark - picker view
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return pickerArr.count;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *title;
    selected_picker_index=row;
    title=[pickerArr objectAtIndex:row];  // give titles
    if([title isEqualToString:NSLocalizedString(@"Random", nil)])
    {
        (theAppDelegate).is_random=true;
    }
    else{
        (theAppDelegate).is_random=false;
    }
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [pickerArr objectAtIndex:row];  // give titles
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return pickerView.frame.size.width;
}

#pragma mark - Expanded button click
-(void)expandViewBtn:(UIButton*)sender
{
     [self collapseaMenu];
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController.searchResultsTableView reloadData];
        CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.searchDisplayController.searchResultsTableView];
        expandableIndexPath = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:buttonPosition];
        
        Recipebox *recipe=nil;
        recipe = [searchResults objectAtIndex:expandableIndexPath.row];
        selectedRecipeId=recipe.recipeboxID;
    }
    else
    {
        [self.tableview reloadData];
        CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableview];
        expandableIndexPath = [self.tableview indexPathForRowAtPoint:buttonPosition];
        
        Recipebox *recipe=nil;
        recipe = [recipes objectAtIndex:expandableIndexPath.row];
        selectedRecipeId=recipe.recipeboxID;
        
    }
    [self expandCell:expandableIndexPath];
    
}
-(IBAction)planBtn:(id)sender
{
    //[self.tableview beginUpdates];
    self.expandedIndexPath=nil;
    [DataStore instance].currentRecipeID = [selectedRecipeId longValue];
    if([[MatlistanHTTPClient sharedMatlistanHTTPClient] isLoggedIn]) {
        [self performSegueWithIdentifier:@"recipeToPlan" sender:self];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"internet_connection_required",nil)
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    // [self.tableview endUpdates];
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    else
    {
        [self.tableview reloadData];
    }
    
}

-(IBAction)editBtn:(id)sender
{
    //[self.tableview beginUpdates];
    self.expandedIndexPath=nil;
    
//    NSString *link = [NSString stringWithFormat:@"http://www.matlistan.se/Account/LogOn?ticket=%@&returnUrl=/RecipeBox/Edit/%@",
//                      [MatlistanHTTPClient sharedMatlistanHTTPClient].ticket,selectedRecipeId];
//    
//    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:link]];
    
    
    //[self.tableview endUpdates];
    
//    AddNewRecipeViewVC *nav=[[AddNewRecipeViewVC alloc]initWithNibName:@"AddNewRecipeViewVC" bundle:nil];
//    nav.descString=
//    [self.navigationController pushViewController:nav animated:YES];

    Recipebox *recipe = nil;
    if ([self.searchDisplayController isActive]) {
        recipe = [searchResults objectAtIndex:expandableIndexPath.row];
    }
    else
    {
        recipe = [recipes objectAtIndex:expandableIndexPath.row];
    }
    AddNewRecipeViewVC *nav=[[AddNewRecipeViewVC alloc]initWithNibName:@"AddNewRecipeViewVC" bundle:nil];
    nav.editRecipe=recipe;
    nav.screenName=@"Edit";
    
    [self.navigationController pushViewController:nav animated:YES];
    
    
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    else
    {
        [self.tableview reloadData];
    }
    
}

-(IBAction)deleteBtn:(id)sender
{
    [self showDeleteChoice:NSLocalizedString(@"Do you want to remove the recipe?", nil)];
}

#pragma mark - Expand Cell
- (void)expandCell:(NSIndexPath *)indexPath
{
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController.searchResultsTableView beginUpdates];
        
        if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame)
        {
            self.expandedIndexPath = nil;
            [self.searchDisplayController.searchResultsTableView endUpdates];
            
        }
        else
        {
            self.expandedIndexPath = indexPath;
            [self.searchDisplayController.searchResultsTableView endUpdates];
            
            [UIView animateWithDuration:0.7
                                  delay:0.0
                 usingSpringWithDamping:1.0
                  initialSpringVelocity:4.0
                                options: UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 if([indexPath row]==((NSIndexPath*)[[self.searchDisplayController.searchResultsTableView indexPathsForVisibleRows]lastObject]).row)
                                 {
                                     
                                     [self.searchDisplayController.searchResultsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.expandedIndexPath.row inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                                 }
                                 
                             }
                             completion:^(BOOL finished){
                                 
                             }];
            [UIView commitAnimations];
        }
        
    }
    else
    {
        [self.tableview beginUpdates];
        
        if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame)
        {
            self.expandedIndexPath = nil;
            [self.tableview endUpdates];
            
        }
        else
        {
            self.expandedIndexPath = indexPath;
            [self.tableview endUpdates];
            
            [UIView animateWithDuration:0.7
                                  delay:0.0
                 usingSpringWithDamping:1.0
                  initialSpringVelocity:4.0
                                options: UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 if([indexPath row]==((NSIndexPath*)[[self.tableview indexPathsForVisibleRows]lastObject]).row)
                                 {
                                     
                                     [self.tableview scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.expandedIndexPath.row inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                                 }
                                 
                             }
                             completion:^(BOOL finished){
                                 
                             }];
            [UIView commitAnimations];
        }
        
    }
    
}

#pragma mark - Picker View Show Hide
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
//    [self.searchDisplayController setActive:NO animated:YES];
    [self closedPicker];
    is_open=true;
    self.clearView.hidden=YES;
    [self collapseaMenu];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self addBarButtons];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if(IS_IPHONE)
    {
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            navigationBarHeight=self.navigationController.navigationBar.frame.size.height+20;
        }
        self.more_tableview.frame=CGRectMake(SCREEN_WIDTH-self.more_tableview.frame.size.width-6, 0, self.more_tableview.frame.size.width, 0);

    }
    [self takePic];
}
-(void)openPicker
{
    [self collapseaMenu];
    int picker_y=0;
    if(IS_IPHONE)
    {
        picker_y=25;
    }
    else
    {
        picker_y=0;
    }
    self.picker_main_view.hidden=NO;
    self.picker_main_view.translatesAutoresizingMaskIntoConstraints=YES;
    if(IS_IPHONE)
    {
        self.picker.frame=CGRectMake(self.picker.frame.origin.x, 25, self.picker.frame.size.width, 200);
        self.picker_main_view.frame=CGRectMake(self.picker_main_view.frame.origin.x, 0, self.picker_main_view.frame.size.width, 200);
    }
    else
    {
        self.picker.frame=CGRectMake(self.picker.frame.origin.x, 0, self.picker.frame.size.width, self.picker_main_view.frame.size.height);
        self.picker_main_view.frame=CGRectMake(self.picker_main_view.frame.origin.x, 64, self.picker_main_view.frame.size.width, 240);
    }
    
    
    is_open=false;
    [UIView animateWithDuration:0.2
                          delay:20
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.picker.hidden=NO;
                         self.clearView.hidden=NO;
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
    
    
}

-(void)closedPicker
{
    self.picker_main_view.translatesAutoresizingMaskIntoConstraints=NO;
    if(IS_IPHONE)
    {
        self.picker_main_view.frame=CGRectMake(self.picker_main_view.frame.origin.x, 0, self.picker_main_view.frame.size.width, 0);
        self.picker.frame=CGRectMake(self.picker.frame.origin.x, -150, self.picker.frame.size.width, 200);
    }
    else
    {
        
        self.picker_main_view.frame=CGRectMake(self.picker_main_view.frame.origin.x, navigation_height, self.picker_main_view.frame.size.width, 0);
        self.picker.frame=CGRectMake(self.picker.frame.origin.x, -176, self.picker.frame.size.width, 240);
    }
    self.picker.hidden=YES;
    self.clearView.hidden=YES;
    //self.picker_main_view.hidden=YES;
    is_open=true;
    
    if(selectedSortType != selected_picker_index) {
        [self.tableview setContentOffset:CGPointZero animated:YES];
    }
    selectedSortType = (SORT_TYPE_RECIPE)selected_picker_index;
    NSString *sort_type=[NSString stringWithFormat:@"%u",selectedSortType];
    
    if([sort_type isEqualToString:@"8"])
    {
        (theAppDelegate).is_random=true;
    }
    else{
        (theAppDelegate).is_random=false;
        
    }
    if((theAppDelegate).is_random)
    {
        randomArr=[[NSMutableArray alloc]init];
        [self generateRandomSortedArray:recipes];
        [self.tableview reloadData];
        
    }
    else{
        recipes = [NSMutableArray arrayWithArray:[Recipebox getAllRecipesExceptDeletedOrderBy:(SORT_TYPE_RECIPE)selected_picker_index]];
    }
    [self.tableview reloadData];
    
}
//Dimple-8-12-2015
#pragma mark- generate random number
-(NSArray*)generateRandomSortedArray:(NSMutableArray*)arr
{
    
    int milliseconds = ([[NSDate date] timeIntervalSince1970] * 1000.0);
    
    for(int i=0;i<arr.count;i++)
    {
        
        int r = arc4random_uniform(milliseconds);
        
        NSDictionary *randomDic=[[NSMutableDictionary alloc] initWithObjectsAndKeys:arr[i],@"recipeDetails",
                                 [NSNumber numberWithInt:r], @"randomNumber",nil];
        [randomArr addObject:randomDic];
    }
    
    NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"randomNumber" ascending:true] ;
    final_randomArr= [randomArr sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    //    DLog(@"randomArr=%@",final_randomArr);
    
    return final_randomArr;
}
//Dimple 26-10-2015
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView setContentInset:UIEdgeInsetsZero];
    [tableView setScrollIndicatorInsets:UIEdgeInsetsZero];
}

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    if(!tagsCached){
        ///THIS CODE IS NOT USELESS!!!//////////
        //It is used to load recipe tags to cache.
        for (Recipebox *recipe in recipes) {
            for (Recipebox_tag *tag in recipe.relatedTags) {
                NSString *recipeScore = tag.text;
            }
        }
        ////////////////////////////////////////////
        tagsCached = YES;
    }
}


- (void) wakeUp: (NSNotification*)notification {
    [SyncManager sharedManager].syncManagerDelegate = self;
    [self didUpdateItems];
}

- (IBAction)showHelp:(id)sender {
    [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self force:YES];
}
-(void)showSortMenu{
    /* UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:NSLocalizedString(@"Sorting",nil) delegate:self cancelButtonTitle: NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles: NSLocalizedString(@"Latest",nil), NSLocalizedString(@"Alphabetically",nil), NSLocalizedString(@"Most cooked",nil),NSLocalizedString(@"At least cooked",nil), NSLocalizedString(@"Last prepared",nil), NSLocalizedString(@"Earliest cooked",nil), NSLocalizedString(@"The shortest cooking time",nil), NSLocalizedString(@"Top Rated",nil), nil];
     actionSheet.tag = 2;
     
     [actionSheet showFromBarButtonItem:sortButton animated:YES];*/
    
    
    /*Developer : Dimple
     Date : 28-9-15
     Description : Sliding menu swipe gesture management.*/
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    {
        navigation_height=self.navigationController.navigationBar.frame.size.height;
    }
    else
    {
        if(IS_IPHONE)
        {
            navigation_height=64;
        }
        else
        {
            navigation_height=64;
        }
    }
    
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if(is_open)
                         {
                             [self openPicker];
                         }
                         else{
                             [self closedPicker];
                         }
                         
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
    [UIView commitAnimations];
    
    
}
#pragma mark- open drop drown menu from navigationbar
-(IBAction)openMenuDropDown:(id)sender
{
    if(is_dropDownOpen)
    {
        [self expandMenu];
    }
    else
    {
        [self collapseaMenu];
    }
}
-(void)expandMenu
{
    [self closedPicker];
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
-(void)collapseaMenu
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
                         NSLog(@"Done!");
                     }];
    
    
}
#pragma mark- Scrollview delegate Method
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self collapseaMenu];
}
/*- (void)populateRecipe :(NSMutableArray*)arr
{
    
    self.recipeArr=[[NSMutableArray alloc] init];
    
    for(NSInteger k = 0 ; k < arr.count ; k++)
    {
        Recipebox *r = arr[k];
        //NSLog(@"r.title:%@",[NSString stringWithFormat:@"%@",r.title]);
        RecipeTimer *activeRecipeTimer = [self checkTimerisOnFotThisREcipeId:r.recipeboxID];
        if(activeRecipeTimer)
        {
            [self.recipeArr addObject:activeRecipeTimer];
        }
        else
        {
            RecipeTimer *recipe = [[RecipeTimer alloc] initWithRecipieId:[r.recipeboxID intValue] recipeName:r.title withRecipeDesc:nil];
            [self.recipeArr addObject:recipe];
        }
    }
}*/


- (RecipeTimer *)checkTimerisOnFotThisREcipeId:(NSNumber*)recipeId
{
    RecipeTimer *isActiveTimer = nil;
    NSArray *recipetimerOnArray = (theAppDelegate).ActiveTimerArr; //you chane after ok
    for(RecipeTimer *aTimerOnRecipe in recipetimerOnArray)
    {
//        if(aTimerOnRecipe.recipeboxId == [recipeId integerValue])
//        {
        if(aTimerOnRecipe.recipeDesc != nil)
        {
            isActiveTimer = aTimerOnRecipe;
            break;
        }
        else
            NSLog(@"*********************************recipe desc is nil************");
    }
    return isActiveTimer;
}
#pragma mark- add buttuns in navigation bar
-(void)addBarButtons
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    if(IS_IPHONE)
    {
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            optionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ItemSelection_more"]  style:UIBarButtonItemStylePlain target:self action:@selector(openMenuDropDown:)];
            sortButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sort_recipe"] style:UIBarButtonItemStylePlain target:self action:@selector(showSortMenu)];
            self.navigationItem.rightBarButtonItems = @[optionButton,sortButton];
        }
        else
        {
            addBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddRecipe"]  style:UIBarButtonItemStylePlain target:self action:@selector(gotoAddNewRecipeView:)];
            sortButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sort_recipe"] style:UIBarButtonItemStylePlain target:self action:@selector(showSortMenu)];
            helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?" style:UIBarButtonItemStylePlain target:self action:@selector(showHelp:)];
            self.navigationItem.rightBarButtonItems = @[helpButton,addBtn,sortButton];
        }
    }
    else
    {
        addBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddRecipe"]  style:UIBarButtonItemStylePlain target:self action:@selector(gotoAddNewRecipeView:)];
        sortButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sort_recipe"] style:UIBarButtonItemStylePlain target:self action:@selector(showSortMenu)];
        helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?" style:UIBarButtonItemStylePlain target:self action:@selector(showHelp:)];
        self.navigationItem.rightBarButtonItems = @[helpButton,addBtn,sortButton];
    }
}
@end
