//
//  PlanFoodViewController.m
//  MatListan
//  A table view to show all planened recipes
//  Created by Yan Zhang on 23/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "PlanFoodViewController.h"
#import "RecipeDetailViewController.h"
#import "DataStore.h"
#import "RecipeCellView.h"
#import "Active_recipe+Extra.h"
#import "Recipebox+Extra.h"
#import "MatlistanHTTPClient.h"
#import "AppDelegate.h"
#import "SignificantChangesIndicator.h"

//#define TO_BUY_SECTION 0
//#define TO_COOK_SECTION 1

@interface PlanFoodViewController ()
{
    int currentIndex;

    NSMutableArray *toBuyRecipes;
    NSMutableArray *toCookRecipes;
    Active_recipe *selectedActiveRecipe;
    NSNumber *currectActiveRecipeId;
    NSIndexPath *selectedCellIndexPath;
    NSArray *sectionNames;
    BAR_BUTTON_TYPE barButtonType;
    __weak IBOutlet UILabel *userHintLabel;
    
    //Dimple 3-10-15
    NSIndexPath *expandableIndexPath;
    int navigation_height;
    int expand_height, collaps_height,occationcell_height;
    
    NSNumber *myactiveRecipeId,*mycookedRecipeId;
    int expand_v_y,expand_v_h;
    
    NSMutableArray *Arr_buy;
    NSMutableArray *Arr_cook;

}
@end

@implementation PlanFoodViewController

- (void) didUpdateItems {
    if([SignificantChangesIndicator sharedIndicator].activeRecipeChanged) {
        [self loadDataFromCoreData];
        [[SignificantChangesIndicator sharedIndicator] resetData];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    if((theAppDelegate).PlanRecipecustomImage!=nil)
//    {
//        self.testImage.hidden=NO;
//        self.testImage.image=(theAppDelegate).PlanRecipecustomImage;
//    }
    int nav_title_x=70,nav_title_width=180;
    if(IS_IPHONE)
    {
        nav_title_x=70;
        nav_title_width=180;
    }
    else
    {
        nav_title_x=10;
        nav_title_width=280;
    }

    UILabel *ListTitle=[[UILabel alloc]initWithFrame:CGRectMake(0,0,200,30)];
    ListTitle.text=NSLocalizedString(@"Planned Recipes",nil);
    ListTitle.textAlignment=NSTextAlignmentCenter;
    self.navigationItem.titleView=ListTitle;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        if([Utility getPlanRecipecustomImage]!=nil)
        {
            self.testImage.image=[Utility getPlanRecipecustomImage];
            self.testImage.hidden=NO;
        }
    }
    else
    {
        if([Utility getPlanRecipecustomLandImage]!=nil)
        {
            self.testImage.image=[Utility getPlanRecipecustomLandImage];
            self.testImage.hidden=NO;
        }
    }

    //Dimple-3-10-2015
    if(IS_IPHONE)
    {
        expand_height=139;
        collaps_height=91;
        expand_v_y=91;
        expand_v_h=48;
        occationcell_height=21;
        
    }
    else
    {
        expand_height=173;
        collaps_height=100;
        expand_v_y=100;
        expand_v_h=73;
        occationcell_height=30;
        
    }


    
    [Active_recipe cleanDuplicatedRecipes];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero]; //remove extra empty cells after rows


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
    /*Developer : Dimple
     Date : 28-9-15
     Description : Sliding menu swipe gesture management.*/
    SWRevealViewController *revealController = self.revealViewController;
    revealController=[[SWRevealViewController alloc]init];
    revealController = [self revealViewController];
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    revealController.delegate=self;
    revealController.panGestureRecognizer.enabled = YES;
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];

    userHintLabel.text=@"Please wait...";
    dispatch_async(dispatch_get_main_queue(), ^(void) {
    [self loadDataFromCoreData];
    
    [SyncManager sharedManager].syncManagerDelegate = self;
    
    if (toBuyRecipes.count == 0 && toCookRecipes.count == 0) {
        NSString *str_msg = [NSString stringWithFormat:@"%@\n%@",NSLocalizedString(@"No recipes are planned.", nil),NSLocalizedString(@"Add a recipe to your plan by selecting it in your Recipe Box.", nil)];
        
        userHintLabel.text = str_msg ;
        [self.tableView setHidden:YES];
        
    }
    else{
        
       
        
        [self.tableView setHidden:NO];
        [userHintLabel setText:@""];
    }
        

    });
   
   
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(wakeUp:) name: @"UpdateUINotification" object: nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }
    
    self.expandedIndexPath=nil;
}
-(void)takePic1
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(window.bounds.size);
    
    
    //(theAppDelegate).PlanRecipecustomImage = UIGraphicsGetImageFromCurrentImageContext();
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        [Utility setPlanRecipecustomImage:UIGraphicsGetImageFromCurrentImageContext()];
        UIGraphicsEndImageContext();
    }
    else
    {
        // do something for Landscape mode
        UIGraphicsBeginImageContext(self.view.bounds.size);
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        [Utility setPlanRecipecustomLandImage:UIGraphicsGetImageFromCurrentImageContext()];
        UIGraphicsEndImageContext();

    }

   
    

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        
        [Utility updateConstraint:self.view toView:self.tableView withConstant:0];
    }
}

#pragma mark - Helper methods

-(void)loadDataFromCoreData{
    //self.expandedIndexPath=nil;
    toBuyRecipes = [NSMutableArray arrayWithArray:[Active_recipe getAllActiveRecipesWithPurchaseStatus:NO]];
    toCookRecipes = [NSMutableArray arrayWithArray:[Active_recipe getAllActiveRecipesWithPurchaseStatus:YES]];
    
    //***********************************************************************
    Arr_cook = [self makeArrayWithOccasions:toCookRecipes];
    Arr_buy = [self makeArrayWithOccasions:toBuyRecipes];
    //*********************************************************************
    
    
    // Shop To buy
    /*
     Was left here just for fun. Does the same as makeArrayWithOccasions: =)
    
    NSMutableArray *Occasion=[[NSMutableArray alloc]init];
    
    
    for(int i=0;i<[toBuyRecipes count];i++)
    {
        
        [Occasion addObject:[NSString stringWithFormat:@"%@",[[toBuyRecipes objectAtIndex:i] occasion]]];
        
    }
    for(int i=0;i<[Occasion count];i++)
    {
        if([[Occasion objectAtIndex:i] isEqual:@"(null)"])
        {
            [Occasion replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"%@",@"0"]];
            
        }
    }
    
    dic=[[NSMutableDictionary alloc]init];
    
    for(int i=0;i<[Occasion count];i++)
    {
        for( NSString *str in [dic allKeys])
        {
            if([[Occasion objectAtIndex:i]caseInsensitiveCompare: str] == NSOrderedSame)
            {
                break;
            }
        }
        NSMutableArray *object_arr=[[NSMutableArray alloc]init];
        
        for(int j=0;j<[toBuyRecipes count];j++)
        {
            
            if([[Occasion objectAtIndex:i] isEqualToString:[[toBuyRecipes objectAtIndex:j] occasion]]  )
            {
                
                [object_arr addObject:[toBuyRecipes objectAtIndex:j]];
            }
            
            else
            {
                if([[Occasion objectAtIndex:i] isEqualToString:@"0"] && [[toBuyRecipes objectAtIndex:j] occasion]==nil )
                {
                    [object_arr addObject:[toBuyRecipes objectAtIndex:j]];
                    
                }
                
            }
            
        }
        
        [dic setObject:object_arr forKey:[Occasion objectAtIndex:i]];
    }
    //*********************************************************************
    
    //Array of Dictionary:For Shop to Buy items
    
    Arr_buy=[[NSMutableArray alloc]init];
    NSMutableDictionary *temp_Buy_recipe;
    
    NSString *temp=@"";
    
    for(int i=0;i<[dic count];i++)
    {
        temp=@"";
        for(int j=0;j<[[dic valueForKey:[[dic allKeys]objectAtIndex:i]]count];j++)
        {
            temp_Buy_recipe=[[NSMutableDictionary alloc]init];
            
            if([[[dic allKeys]objectAtIndex:i] isEqualToString:@"0"])
            {
                [temp_Buy_recipe setObject:[[dic valueForKey:[[dic allKeys]objectAtIndex:i]]objectAtIndex:j] forKey:@"Recipe"];
                [temp_Buy_recipe setObject:[[dic allKeys]objectAtIndex:i] forKey:@"Occasion"];
                temp=[[dic allKeys]objectAtIndex:i];
                [Arr_buy addObject:temp_Buy_recipe];
            }
        }
    }
    for(int i=0;i<[dic count];i++)
    {
        temp=@"";
        
        
        for(int j=0;j<[[dic valueForKey:[[dic allKeys]objectAtIndex:i]]count];j++)
        {
            temp_Buy_recipe=[[NSMutableDictionary alloc]init];
            if(![[[dic allKeys]objectAtIndex:i] isEqualToString:@"0"])
            {
                
                if([[[dic allKeys]objectAtIndex:i] isEqualToString:temp])
                {
                    [temp_Buy_recipe setObject:[[dic valueForKey:[[dic allKeys]objectAtIndex:i]]objectAtIndex:j] forKey:@"Recipe"];
                    
                    [temp_Buy_recipe setObject:@"" forKey:@"Occasion"];
                    [Arr_buy addObject:temp_Buy_recipe];
                    
                }
                else
                {
                    
                    [temp_Buy_recipe setObject:@"" forKey:@"Recipe"];
                    [temp_Buy_recipe setObject:[[dic allKeys]objectAtIndex:i] forKey:@"Occasion"];
                    [Arr_buy addObject:temp_Buy_recipe];
                    
                    temp_Buy_recipe=[[NSMutableDictionary alloc]init];
                    
                    [temp_Buy_recipe setObject:[[dic valueForKey:[[dic allKeys]objectAtIndex:i]]objectAtIndex:j] forKey:@"Recipe"];
                    [temp_Buy_recipe setObject:@"" forKey:@"Occasion"];
                    [Arr_buy addObject:temp_Buy_recipe];
                    
                    temp=[[dic allKeys]objectAtIndex:i];
                    
                }
                
            }
        }
    }
    */

    [self.tableView reloadData];
    self.testImage.hidden=YES;
    userHintLabel.text=@"";
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(takePic1) userInfo:nil repeats:NO];
   // [self populateRecipe];
}

- (NSMutableArray *) makeArrayWithOccasions: (NSArray *) recipesArray {
    NSMutableArray *result = [NSMutableArray new];
    NSMutableArray *occasions =[NSMutableArray new];
    NSMutableDictionary *dicTemp=[NSMutableDictionary new];
    
    for (Active_recipe *recipe in recipesArray) {
        NSString *key = recipe.occasion ? recipe.occasion : @"0";
        if(![occasions containsObject:key]) {
            [occasions addObject:key];
        }
        NSMutableArray *recipesByKey = dicTemp[key];
        if(recipesByKey == nil) {
            recipesByKey = [NSMutableArray new];
        }
        [recipesByKey addObject:recipe];
        dicTemp[key] = recipesByKey;
    }
    
    result=[NSMutableArray new];
    
    for(NSString *occasion in occasions) {
        if(![occasion isEqualToString:@"0"]){
            NSMutableDictionary *row = [NSMutableDictionary new];
            row[@"Recipe"] = @"";
            row[@"Occasion"] = occasion;
            [result addObject:row];
        }
        for(Active_recipe *ar in dicTemp[occasion]){
            NSMutableDictionary *row = [NSMutableDictionary new];
            row[@"Recipe"] = ar;
            row[@"Occasion"] = @"";
            [result addObject:row];
        }
    }
    return result;
}

-(NSString*)getCookTimeString:(Recipebox*)recipe{
    NSString *timeString = @"";
    if (recipe.cookTime != nil && [recipe.cookTime intValue]!= 0) {
        timeString = [NSString stringWithFormat:@"\t%@ min", [recipe.cookTime stringValue]];
    }
    else {
        if (recipe.originalCookTime != nil && [recipe.originalCookTime intValue] != 0) {
            timeString = [NSString stringWithFormat:@"\t%@ min", [recipe.originalCookTime stringValue]];
        }
    }
    return timeString;
}

#pragma mark- UI related

- (IBAction)showMenu
{
    //[self.frostedViewController presentMenuViewController];
    [self.revealViewController revealToggle:self];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if(Arr_cook.count>0 && Arr_buy.count>0)
    {
        return 2;
    }
    else
    {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
      if(section==0)
      {
          if(Arr_cook.count>0)
          {
              activeRecipes =  [[NSMutableArray alloc] initWithArray:Arr_cook];
              return  Arr_cook.count;

          }
          else
          {
              activeRecipes =  [[NSMutableArray alloc] initWithArray:Arr_buy];
              return  Arr_buy.count;
          }
      }
      else
      {
          if(Arr_cook.count>0)
          {
              activeRecipes =  [[NSMutableArray alloc] initWithArray:Arr_buy];
              return  Arr_buy.count;
          }
          else
          {
              return 0;
          }
      }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ActiveRecipeSWCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.clipsToBounds=YES;
    
    Active_recipe *recipe = [[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Recipe"];
    
    if(([[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Occasion"] isEqualToString:@""]||[[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Occasion"] isEqualToString:@"0"]) && ![[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Recipe"]isEqual:@""])
    {
        
        Recipebox *recipeBox = [Recipebox getRecipeById:recipe.recipeID];
        cell.activeRecipeId = recipe.active_recipeID;
        cell.recipeId = recipeBox.recipeboxID;
        NSString *newUrl = [Utility getCorrectURLFromJson: recipeBox.imageUrl];
        UIImage *img = [UIImage imageNamed:@"placeHolder"];
        cell.recipeImageView.image=img;
        
        
        if(newUrl.length>0 && newUrl!=nil)
        {
            
            UIImage *img = [Utility loadLocalRecipeImage:recipeBox.recipeboxID];
           
            if(img==nil)
            {
                [cell.recipeImageView setImageWithURL:[NSURL URLWithString:newUrl]];
            }
            else{
                cell.recipeImageView.image=img;
            }
        }
        else
        {
            
            UIImage *img = [UIImage imageNamed:@"placeHolder"];
            cell.recipeImageView.image=img;
           
        }

        //DLog(@"active recipe id= %@, recipe id=%@", recipe.active_recipeID, recipeBox.recipeboxID);
        if(indexPath.section==0)
        {
            if(Arr_cook.count>0)
            {
                timeStr=[self getCookTimeString:recipeBox];
            }
            else
            {
                timeStr=@"";
            }
        }
        else
        {
            timeStr=@"";
        }
        
        NSString *title = recipeBox.title;
        
//        NSString *portionStr = @"";
        
//        if ([recipe.portions integerValue] > 0) {
//            portionStr = [NSString stringWithFormat:@"%@ portioner", [recipe.portions stringValue]];
//        }
        
//        NSString *newUrl = [Utility getCorrectURLFromJson: recipeBox.imageUrl];
        cell.recipeImageView.contentMode =UIViewContentModeScaleAspectFill;
        cell.recipeImageView.clipsToBounds = YES;
//        [cell.recipeImageView setImageWithURL:[NSURL URLWithString:newUrl]];
        //Raj - 26-9-15
        cell.recipeImageView.layer.cornerRadius=40;
        
        cell.labelTitle.text = title;
        
//        cell.labelDetail.text = [NSString stringWithFormat:@"%@\t%@", portionStr,timeStr];
        NSString *portionStr = @"";
        NSString *portionType=recipeBox.portionType;
        NSString *numberOfportion = recipe.portionsStr;
        if(!numberOfportion) {
            numberOfportion = [NSString stringWithFormat:@"%@", recipe.portions];
        }
        portionStr = [numberOfportion isEqualToString: @"1"] ? NSLocalizedString(@"portion", nil) : NSLocalizedString(@"portions", nil);

        if(numberOfportion && ![numberOfportion isEqualToString:@"0"]){
            if(portionType!=nil && portionType.length>0)
            {
                cell.labelDetail.text=[NSString stringWithFormat:@"%@ %@",numberOfportion,portionType];
            }
            else
            {
                cell.labelDetail.text=[NSString stringWithFormat:@"%@ %@",numberOfportion,portionStr];
                
            }
        }
        else {
            cell.labelDetail.text = @"";
        }
        
        cell.Occasion_label.hidden = YES;
        cell.labelDetail.text = [NSString stringWithFormat:@"%@\t%@", cell.labelDetail.text,timeStr];
        cell.recipeImageView.hidden=NO;
        cell.labelDetail.hidden=NO;
        cell.labelTitle.hidden=NO;
        cell.expanded_view.hidden=NO;
        cell.expandViewBtn.hidden=NO;

    }
    else
    {
        cell.Occasion_label.text=[NSString stringWithFormat:@"%@",[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Occasion"]];
        cell.Occasion_label.hidden=NO;
        cell.recipeImageView.hidden=YES;
        cell.labelDetail.hidden=YES;
        cell.labelTitle.hidden=YES;
        cell.expanded_view.hidden=YES;
        cell.expandViewBtn.hidden=YES;
    }
    
    
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
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    
   
    [cell.boughtBtn setTitle:NSLocalizedString(@"Bought",nil) forState: UIControlStateNormal];
    [cell.editBtn setTitle:NSLocalizedString(@"Change",nil) forState: UIControlStateNormal];
    [cell.cookedBtn setTitle:NSLocalizedString(@"Cooked",nil) forState: UIControlStateNormal];
    [cell.deleteBtn setTitle:NSLocalizedString(@"Delete",nil) forState: UIControlStateNormal];

    
    if(![language isEqualToString:@"en"])
    {
        if(IS_IPHONE)
        {
            [cell.boughtBtn setTitleEdgeInsets:UIEdgeInsetsMake(27, -21, 0, 1)];
            [cell.editBtn setTitleEdgeInsets:UIEdgeInsetsMake(27, -23, 0, 1)];
            [cell.cookedBtn setTitleEdgeInsets:UIEdgeInsetsMake(24, -20, 0, 0)];
            [cell.deleteBtn setTitleEdgeInsets:UIEdgeInsetsMake(28, -29, 0, 1)];
            cell.boughtBtn.frame=CGRectMake(13, 0, 67, 48);
        }
        else
        {
            [cell.boughtBtn setTitleEdgeInsets:UIEdgeInsetsMake(51, -37, 0, 0)];
            [cell.editBtn setTitleEdgeInsets:UIEdgeInsetsMake(53, -46, 0, 0)];
            [cell.cookedBtn setTitleEdgeInsets:UIEdgeInsetsMake(50, -39, 0, 0)];
            [cell.deleteBtn setTitleEdgeInsets:UIEdgeInsetsMake(51, -43, 0, 0)];
        }
    }
    
    if (indexPath.section == 0) {
        
        if(Arr_cook.count>0)
        {
            cell.cookedBtn.hidden=NO;
            cell.cookedImg.hidden=NO;
            cell.cookedLbl.hidden=NO;
            
            
            cell.boughtBtn.hidden=YES;
            cell.boughtImg.hidden=YES;
            cell.boughtLbl.hidden=YES;
            
            cell.editBtn.hidden=YES;
            cell.editImg.hidden=YES;
            cell.editLbl.hidden=YES;
            
            cell.deleteBtn.hidden=YES;
            cell.deleteImg.hidden=YES;
            cell.deleteLbl.hidden=YES;
        }
        else
        {
            cell.cookedBtn.hidden=YES;
            cell.cookedImg.hidden=YES;
            cell.cookedLbl.hidden=YES;
            
            cell.boughtBtn.hidden=NO;
            cell.boughtImg.hidden=NO;
            cell.boughtLbl.hidden=NO;
            
            cell.editBtn.hidden=NO;
            cell.editImg.hidden=NO;
            cell.editLbl.hidden=NO;
            
            cell.deleteBtn.hidden=NO;
            cell.deleteImg.hidden=NO;
            cell.deleteLbl.hidden=NO;

        }
        
    }
    else{
        cell.cookedBtn.hidden=YES;
        cell.cookedImg.hidden=YES;
        cell.cookedLbl.hidden=YES;
        
        cell.boughtBtn.hidden=NO;
        cell.boughtImg.hidden=NO;
        cell.boughtLbl.hidden=NO;
        
        cell.editBtn.hidden=NO;
        cell.editImg.hidden=NO;
        cell.editLbl.hidden=NO;
        
        cell.deleteBtn.hidden=NO;
        cell.deleteImg.hidden=NO;
        cell.deleteLbl.hidden=NO;
    }
    
    
    if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame)
    {
        [cell.expandViewBtn setImage:[UIImage imageNamed:@"upimg"] forState:UIControlStateNormal];
    }
    else
    {
        [cell.expandViewBtn setImage:[UIImage imageNamed:@"backimg"] forState:UIControlStateNormal];
    }
    
    [cell.expandViewBtn addTarget:self action:@selector(expandViewBtn:) forControlEvents:UIControlEventTouchUpInside];
    cell.selectionStyle=UITableViewScrollPositionNone;
    
    cell.boughtBtn.titleLabel.textColor=[Utility getGreenColor];
    cell.editBtn.titleLabel.textColor=[Utility getGreenColor];
    cell.deleteBtn.titleLabel.textColor=[Utility getGreenColor];
    cell.cookedBtn.titleLabel.textColor=[Utility getGreenColor];

    return cell;
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
    if (section == 0) {
        
        if (Arr_cook.count > 0) {
            if(IS_IPHONE){
                height = 40.0;
            }
            else
            {
                height = 60.0;
            }
        }
        else if (Arr_buy.count > 0 ) {
            if(IS_IPHONE)
            {
                height = 40.0;
            }
            else
            {
                height = 60.0;
            }
        }
    }
    else if (section == 1) {
        if (Arr_buy.count > 0 ) {
            if(IS_IPHONE)
            {
                height = 40.0;
            }
            else
            {
                height = 60.0;
            }
        }
    }
   
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row_height;
    
    if(indexPath.section==0)
    {
        if(Arr_cook.count>0)
        {
            activeRecipes=Arr_cook;
        }
        else
        {
            activeRecipes=Arr_buy;
        }
    }
    else
    {
        activeRecipes=Arr_buy;
    }
    
    
//    if(Arr_cook.count>0)
//    {
//        activeRecipes = indexPath.section == TO_BUY_SECTION ? Arr_cook : Arr_buy;
//    }
//    else
//    {
//       activeRecipes = indexPath.section == TO_BUY_SECTION ? Arr_buy : Arr_cook;
//    }
    
    if ([indexPath compare:self.expandedIndexPath] == NSOrderedSame) {
        
        if(([[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Occasion"] isEqualToString:@""] || [[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Occasion"] isEqualToString:@"0"]) && ![[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Recipe"]isEqual:@""])
        {
            row_height= expand_height;
            
        }
        else
        {
            row_height=occationcell_height ;
        }
    }
    else
    {
        if(([[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Occasion"] isEqualToString:@""] || [[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Occasion"] isEqualToString:@"0"]) && ![[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Recipe"]isEqual:@""])
        {
            row_height= collaps_height;
            
        }
        else
        {
            row_height=occationcell_height ;
        }
    }
   
    CGFloat height = 0;
    if (indexPath.section == 0) {
        if(Arr_cook.count>0)
        {
            height = row_height;
        }
        else if(Arr_buy.count>0)
        {
            height = row_height;
        }
        else
        {
            height=0;
        }
       // height = Arr_buy.count > 0 ? row_height:0;
       // DLog(@"section %ld, height %f", indexPath.section, height);
    }
    else if(indexPath.section == 1){
        if(Arr_buy.count>0)
        {
            height = row_height;
        }
        else
        {
            height=0;
        }
       
        // DLog(@"section %ld, height %f", (long)indexPath.section, height);
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    (theAppDelegate).detailRecipeFlag=true;
    
    if(indexPath.section==0)
    {
        selected_index=(int)indexPath.row;

        if(Arr_cook.count>0)
        {
            activeRecipes=Arr_cook;
        }
        else
        {
            activeRecipes=Arr_buy;
        }
    }
    else
    {
        if(Arr_cook.count>0)
        {
            selected_index=(int)Arr_cook.count+(int)indexPath.row;
        }
        else
        {
            selected_index=(int)indexPath.row;
        }

        activeRecipes=Arr_buy;
    }

    
//    if(Arr_cook.count>0)
//    {
//        activeRecipes = indexPath.section == TO_BUY_SECTION ? Arr_cook :Arr_buy ;
//    }
//    else
//    {
//        activeRecipes = indexPath.section == TO_BUY_SECTION ? Arr_buy : Arr_cook;
//    }
    
    if(([[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Occasion"] isEqualToString:@""]||[[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Occasion"] isEqualToString:@"0"]) && ![[[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Recipe"]isEqual:@""])
    {
        selectedActiveRecipe = [[activeRecipes objectAtIndex:indexPath.row]valueForKey:@"Recipe"];
        if(indexPath.section==0)
        {
            if(Arr_cook.count>0)
            {
                barButtonType=TO_COMMENT;
            }
            else
            {
                barButtonType=TO_BUY;
            }
        }
        else
        {
            barButtonType=TO_BUY;
        }
        //barButtonType = indexPath.section == TO_BUY_SECTION ? TO_BUY:TO_COMMENT;
        [self performSegueWithIdentifier:@"toDetail" sender:self];
    }
}

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section{
    sectionNames = nil;
  
        if(Arr_cook.count > 0 && Arr_buy.count > 0)
        {
            sectionNames = @[NSLocalizedString(@"Recipes to cook", nil), NSLocalizedString(@"Recipes to shop", nil)];
        }
        else if(Arr_cook.count > 0)
        {
            sectionNames = @[NSLocalizedString(@"Recipes to cook", nil),@""];
        }
        else if(Arr_buy.count > 0)
        {
            sectionNames = @[NSLocalizedString(@"Recipes to shop", nil),@""];
        }

//    if (Arr_buy.count > 0 && Arr_cook.count > 0) {
//        sectionNames = @[NSLocalizedString(@"Recipes to cook", nil), NSLocalizedString(@"Recipes to shop", nil)];
//    }
//    else if(Arr_buy.count > 0){
//        sectionNames = @[NSLocalizedString(@"Recipes to shop", nil),@""];
//    }
//    else{
//        
//        sectionNames = @[@"", NSLocalizedString(@"Recipes to cook", nil)];
//    }
    NSString *sectionTitle =[sectionNames objectAtIndex:section];
    
    int font_size=17,view_height=40;
    if(IS_IPHONE)
    {
       font_size=17;
        view_height=40;
    }
    else
    {
       font_size=25;
         view_height=60;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, view_height)];
    /* Create custom view to display section header... */
    
     UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, view_height)];
     [label setFont:[UIFont systemFontOfSize:font_size]];
     label.textAlignment = NSTextAlignmentCenter;
     [label setText:sectionTitle];
    label.textColor = [UIColor whiteColor];
    if (sectionTitle.length == 0) {
        return view;
    }
    else{
        [view addSubview:label];
        [view setBackgroundColor:[Utility getGreenColor]];
    }
    return view;
}
//- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state{
//    if (state == kCellStateRight) {
//        
//        NSArray *indxPathsArray = [self.tableView indexPathsForVisibleRows];
//        for (NSIndexPath *indxPath in indxPathsArray) {
//            
//            SWTableViewCell *tmpCell = (SWTableViewCell *)[self.tableView cellForRowAtIndexPath:indxPath];
//            if (tmpCell != cell) {
//                [tmpCell hideUtilityButtonsAnimated:NO];
//            }
//        }
//    }
//}
//#pragma mark- Swipe function
//
//- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
//    
//    ActiveRecipeSWCell *recipeCell = (ActiveRecipeSWCell*)cell;
//    currectActiveRecipeId = recipeCell.activeRecipeId;
//    
//    switch (index) {
//        case 0:
//        {
//            selectedCellIndexPath = [self.tableView indexPathForCell:cell];
//            if (selectedCellIndexPath.section == TO_BUY_SECTION){
//                // More button is pressed
//                UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Change",nil), NSLocalizedString(@"Bought",nil), nil];
//                
//                popup.tag = 1;
//                if (IS_IPHONE) {
//                    [popup showInView:[UIApplication sharedApplication].keyWindow];
//                }
//                else{
//                    [popup showFromRect:cell.frame inView:self.view animated:YES];
//                }
//                
//                [cell hideUtilityButtonsAnimated:YES];
//            }
//            else{
//                // Cooked button is pressed
//                //TO DO: show comment view
//                DLog(@"Show comment view");
//                DLog(@"recipeCell %ld",[recipeCell.recipeId longValue]);
//                
//                [DataStore instance].currentActiveRecipeID = currectActiveRecipeId;
//                [DataStore instance].currentRecipeID = [recipeCell.recipeId longValue];
//                [self performSegueWithIdentifier:@"planToCooked" sender:self];
//            
//            }
//            break;
//        }
//        case 1:
//        {
//            // Delete button is pressed
//            selectedCellIndexPath = [self.tableView indexPathForCell:cell];
//            [self showDeleteChoice:NSLocalizedString(@"Do you want to remove the recipe?",nil)];
//            break;
//        }
//        default:
//            break;
//    }
//    
//}
//
/** for swipe
 *Returns a customized snapshot of a given view.
 */
- (UIView *)customSnapshotFromView:(UIView *)inputView {
    
    UIView *snapshot = [inputView snapshotViewAfterScreenUpdates:YES];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
}

-(void)showDeleteChoice:(NSString*)msg{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil) message:msg delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // Set buttonIndex == 1 to handel "Ok"/"Yes" button response
    if (buttonIndex == 1) {
        
//        BOOL arrCookWasEmpty = Arr_cook.count==0;
//        BOOL arrBuyWasEmpty = Arr_buy.count==0;
        
        [self.tableView beginUpdates];
        self.expandedIndexPath=nil;

        
        //Delete in the tableView
        if(selectedCellIndexPath.section==0)
        {
            if(Arr_cook.count>0)
            {
                [Arr_cook removeObjectAtIndex:selectedCellIndexPath.row];
            }
            else
            {
                [Arr_buy removeObjectAtIndex:selectedCellIndexPath.row];
            }
        }
        else
        {
            [Arr_buy removeObjectAtIndex:selectedCellIndexPath.row];
        }

        
        BOOL lastRow = FALSE;
        if ((Arr_buy.count==0  && Arr_cook.count==0) ) {
            lastRow = false;
        }
        else if ((Arr_buy.count==0  && Arr_cook.count>0) ) {
            lastRow = true;
        }
        if(lastRow)
        {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:selectedCellIndexPath.section] withRowAnimation:NO];
        }
        else
        {
            [self.tableView deleteRowsAtIndexPaths:@[selectedCellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
        }
        
        
        //Fake delete in core data
        [Active_recipe fakeDeleteById:myactiveRecipeId];
        [[SyncManager sharedManager] forceSync];
        
        [self.tableView endUpdates];
        
        
        if (Arr_buy.count == 0 && Arr_cook.count == 0) {
            NSString *str_msg = [NSString stringWithFormat:@"%@\n%@",NSLocalizedString(@"No recipes are planned.", nil),NSLocalizedString(@"Add a recipe to your plan by selecting it in your Recipe Box.", nil)];
            
            userHintLabel.text = str_msg ;
            [self.tableView setHidden:YES];
            
        }
    }
//    else if(buttonIndex == 0)
//    {
//        [self.tableView reloadData];    //to make the more/delete buttons disappear
//    }
}

#pragma mark- Actionsheet
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:{
                    //http://www.matlistan.se/Account/LogOn?ticket=<ticket>&returnUrl=/ActiveRecipe/Edit/<recipeId>
                    NSString *link = [NSString stringWithFormat:@"http://www.matlistan.se/Account/LogOn?ticket=%@&returnUrl=/ActiveRecipe/Edit/%@",
                                      [MatlistanHTTPClient sharedMatlistanHTTPClient].ticket,currectActiveRecipeId];
                    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:link]];
                    break;
                }
                case 1:
                {
                    DLog(@"Handlat");
                    [Active_recipe boughtActiveRecipe:currectActiveRecipeId];
                    [[SyncManager sharedManager] forceSync];
                    [self loadDataFromCoreData];
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

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"toDetail"]){
        RecipeDetailViewController *detailView =  (RecipeDetailViewController *)segue.destinationViewController;
         detailView.screen_name=@"PlanFoodScreen";
        detailView.activeRecipe = selectedActiveRecipe;
        detailView.recipeboxId = selectedActiveRecipe.recipeID;
        detailView.barButtonType = barButtonType;
        
        
//        RecipeTimer *selRecipe = self.recipeArr[selected_index];
        Recipebox *selectedRecipe = [Recipebox getRecipeById:selectedActiveRecipe.recipeID];
        RecipeTimer *selRecipe = [[RecipeTimer alloc] initWithRecipieId:[selectedRecipe.recipeboxID intValue] recipeName:selectedRecipe.title withRecipeDesc:nil];
        detailView.selectedRecipe = selRecipe;
        detailView.timerOnRecipes = (theAppDelegate).ActiveTimerArr; //_timerOnRecipes;
        selRecipe.recipeListDelegate =  (id)theAppDelegate;
        selRecipe.recipeTimerdelegate = detailView; //hear, we need to tell the timer object to update the timer table present in detail controller, so we need to set the timer delegate to newly created detail controller that we are doing hear

    }
    else if([segue.identifier isEqualToString:@"planToCooked"]){
        AfterCookViewController *controller = (AfterCookViewController*)segue.destinationViewController;
        NSNumber *recipeID = [NSNumber numberWithLong:[DataStore instance].currentRecipeID];
        controller.recipe = [Recipebox getRecipeById:recipeID];
    }
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



#pragma mark - Expanded button click
-(void)expandViewBtn:(UIButton*)sender
{
    [self.tableView reloadData];
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    expandableIndexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
   if( expandableIndexPath.section==0)
   {
       if(Arr_cook.count>0)
       {
           activeRecipes=Arr_cook;
       }
       else
       {
           activeRecipes=Arr_buy;
       }
   }
   else
   {
       activeRecipes=Arr_buy;
   }
//    if(Arr_buy.count>0 && Arr_cook.count>0)
//    {
//        activeRecipes = expandableIndexPath.section == TO_BUY_SECTION ? Arr_buy : Arr_cook;
//    }
//    else  if(Arr_buy.count==0 && Arr_cook.count>0)
//    {
//        activeRecipes=Arr_cook;
//    }
//    else if(Arr_buy.count>0 && Arr_cook.count==0)
//    {
//         activeRecipes=Arr_buy;
//    }
   
   
    if(activeRecipes != nil)
    {
        if(activeRecipes.count>0)
        {
            if(([[[activeRecipes objectAtIndex:expandableIndexPath.row]valueForKey:@"Occasion"] isEqualToString:@""]||[[[activeRecipes objectAtIndex:expandableIndexPath.row]valueForKey:@"Occasion"] isEqualToString:@"0"]) && ![[[activeRecipes objectAtIndex:expandableIndexPath.row]valueForKey:@"Recipe"]isEqual:@""])
            {
                Active_recipe *recipe = [[activeRecipes objectAtIndex:expandableIndexPath.row]valueForKey:@"Recipe"];
                DLog(@"Recipe id %@",recipe.recipeID);
                Recipebox *recipeBox = [Recipebox getRecipeById:recipe.recipeID];
                edit_recipe=recipeBox;
                myactiveRecipeId = recipe.active_recipeID;
                mycookedRecipeId= recipeBox.recipeboxID;
            }
        }
    }
    
    
    
   // DLog(@"My Active recipe id :%d ",expandableIndexPath.row);
    
    //    Recipebox *recipe=nil;
    //    recipe = [recipes objectAtIndex:expandableIndexPath.row];
    //    selectedRecipeId=recipe.recipeboxID;
    if(([[[activeRecipes objectAtIndex:expandableIndexPath.row]valueForKey:@"Occasion"] isEqualToString:@""]||[[[activeRecipes objectAtIndex:expandableIndexPath.row]valueForKey:@"Occasion"] isEqualToString:@"0"]) && ![[[activeRecipes objectAtIndex:expandableIndexPath.row]valueForKey:@"Recipe"]isEqual:@""])
    {
        [self expandCell:expandableIndexPath];
    }
    
}
-(IBAction)boughtBtn:(id)sender
{
    //    [self.tableView beginUpdates];
    //    self.expandedIndexPath=nil;
    
    [Active_recipe boughtActiveRecipe:myactiveRecipeId];
    [[SyncManager sharedManager] forceSync];
    [self loadDataFromCoreData];
    
    //   [self.tableView endUpdates];
    
}

-(IBAction)editBtn:(id)sender
{
    //[self.tableView beginUpdates];
    self.expandedIndexPath=nil;
    
//    NSString *link = [NSString stringWithFormat:@"http://www.matlistan.se/Account/LogOn?ticket=%@&returnUrl=/ActiveRecipe/Edit/%@",
//                      [MatlistanHTTPClient sharedMatlistanHTTPClient].ticket,myactiveRecipeId];
//    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:link]];
    AddNewRecipeViewVC *nav=[[AddNewRecipeViewVC alloc]initWithNibName:@"AddNewRecipeViewVC" bundle:nil];
    nav.editRecipe=edit_recipe;
    nav.screenName=@"Edit";
    
    [self.navigationController pushViewController:nav animated:YES];

    [self.tableView reloadData];
    //[self.tableView endUpdates];
    
}

-(IBAction)deleteBtn:(id)sender
{
    selectedCellIndexPath = expandableIndexPath;
    [self showDeleteChoice:NSLocalizedString(@"Do you want to remove the Plan recipe?",nil)];
    
}
-(IBAction)cookedBtn:(id)sender
{
    [DataStore instance].currentRecipeID = [mycookedRecipeId longValue];
    [self performSegueWithIdentifier:@"planToCooked" sender:self];
    
}
#pragma mark - Expand Cell
- (void)expandCell:(NSIndexPath *)indexPath
{
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
#pragma mark - rotation
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self takePic1];
}

- (void) wakeUp: (NSNotification*)notification {
    [SyncManager sharedManager].syncManagerDelegate = self;
    [self didUpdateItems];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing PlanFoodViewController");
}
#pragma mark- populateRecipe recipe for timer
/*- (void)populateRecipe
{
    NSMutableArray *combine_RecipeArr=[[NSMutableArray alloc]init];
    if(Arr_buy!=nil && Arr_cook!=nil)
    {
        combine_RecipeArr =  [[NSMutableArray alloc] initWithArray:Arr_cook];
        combine_RecipeArr = [[combine_RecipeArr arrayByAddingObjectsFromArray:Arr_buy] mutableCopy];
    }
    
    self.recipeArr=[[NSMutableArray alloc] init];
    
    for(NSInteger k = 0 ; k < combine_RecipeArr.count ; k++)
    {
        Active_recipe *aRecipe = [[combine_RecipeArr objectAtIndex:k]valueForKey:@"Recipe"];
        Recipebox *r = [Recipebox getRecipeById:aRecipe.recipeID];
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
    }
    return isActiveTimer;
}
- (void)dealloc {
    self.timerOnRecipes = nil;//hear all the timer will ne deallcoated, to keep this we need to make timeronrecipes global
}
@end
