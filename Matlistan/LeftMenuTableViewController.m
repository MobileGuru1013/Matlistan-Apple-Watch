//
//  LeftMenuTableViewController.m
//  MatListan
//
//  Created by Yan Zhang on 03/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "LeftMenuTableViewController.h"
#import "ItemsViewController.h"
#import "PlanFoodViewController.h"
#import "RecipesViewController.h"
#import "SettingsTableViewController.h"
#import "HelpViewController.h"
#import "AdsRemovalViewController.h"
#import "ReceptViewController.h"
//Replaced refrosted - Markus
#import "SWRevealViewController.h"
#import "RecipeDetailViewController.h"
#import "DataStore.h"
#import "MatlistanIAPHelper.h"

#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "Recipebox+Extra.h"
#import "AppDelegate.h"
#import "Mixpanel.h"
#import "ItemTableViewViewController.h"
#import "MatlistanHTTPClient.h"
@interface LeftMenuTableViewController ()
{
    NSArray *menuItems;
    NSArray *products;  //App Store products for in-app purchase
    UILabel * noInternetOverlayView;
    int img_y,img_height;
}
@end

@implementation LeftMenuTableViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    UIImageView *imageview = (UIImageView*) [self.view viewWithTag: 1];
    imageview.frame=CGRectMake(-self.revealViewController.rightViewRevealOverdraw/2,img_y,self.revealViewController.rearViewController.view.frame.size.width, img_height);
    
    // Sliding Menu Gesture Management
    [self.revealViewController.frontViewController.view setUserInteractionEnabled:NO];
    [self.revealViewController.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    /*
     developer : Raj
     Date : 21-9-2015
     Description : Just need to load section 1 insted of entire table. I have change this code because as per UI, selected option from menu should be highlited when he/she come back on Menu.
     */
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
   // [self populateRecipe];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[MatlistanIAPHelper sharedInstance] productPurchased:PRODUCT_IDENTIFIER] || [Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [Utility saveInDefaultsWithBool:true andKey:@"hasPremium"];
        
        menuItems = @[NSLocalizedString(@"Shopping List",nil), NSLocalizedString(@"Planned Recipes",nil), NSLocalizedString(@"Recipes",nil),NSLocalizedString(@"Settings",nil),NSLocalizedString(@"Help/About",nil)];
    }
    else
    {
        menuItems = @[NSLocalizedString(@"Shopping List",nil), NSLocalizedString(@"Planned Recipes",nil), NSLocalizedString(@"Recipes",nil),NSLocalizedString(@"Settings",nil),NSLocalizedString(@"Help/About",nil),NSLocalizedString(@"Remove Ads",nil)];
    }
    
    [self.tableView reloadData];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor=[UIColor clearColor];
    
    self.edgesForExtendedLayout=UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars=NO;
    self.automaticallyAdjustsScrollViewInsets=NO;
    
    /* Developer : Raj
       Date : 1-10-15
       Desc : Menu Logo UI Design
     */
    self.tableView.tableHeaderView = ({
        int view_height=110,bg_view_height=50,bg_view_y=50, image_height=20,image_y=15,image_x=70;
        if(IS_IPHONE)
        {
            view_height=110;
            image_height=20;
            image_y=15;
            bg_view_height=50;
            bg_view_y=50;
            image_x=70;
        }
        else
        {
            view_height=160;
            image_height=35;
            image_y=20;
            bg_view_height=75;
            bg_view_y=60;
            image_x=60;
        }
        img_y=image_y;
        img_height=image_height;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH-60,view_height)];
        
        UIView *bg_view=[[UIView alloc] initWithFrame:CGRectMake(0, bg_view_y, SCREEN_WIDTH-60,bg_view_height)];
        bg_view.backgroundColor=[UIColor colorWithRed:50.0/255.0 green:50.0/255.0 blue:50.0/255.0 alpha:1.0];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(image_x, image_y, SCREEN_WIDTH-203, image_height)];
        imageView.tag=1;
        imageView.image = [UIImage imageNamed:@"logo1"];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [bg_view addSubview:imageView];
        [view addSubview:bg_view];
         view;
    });

    //the last cell won't be cut off
    /*
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, self.navigationController.navigationBar.frame.size.height * 5.6 , 0);
    self.tableView.contentInset = insets; //something like margin for content;
    self.tableView.scrollIndicatorInsets = insets; // and for scroll indicator (scroll bar)
     */
    
    NSString *statusText = NSLocalizedString(@"unable to sync error", nil);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetNotReachable:) name:kInternetNotReachable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetReachable:) name:kInternetReachable object:nil];
    
    CGSize sizeForStatus = [Utility getSizeForText:statusText maxWidth:self.view.frame.size.width-60 font:@"helvetica" fontSize:10.0];
    noInternetOverlayView = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - sizeForStatus.height, self.view.frame.size.width-60, sizeForStatus.height)];
    //noInternetOverlayView = [UILabel new];
    noInternetOverlayView.text = statusText;
    noInternetOverlayView.textColor = [UIColor redColor];
    noInternetOverlayView.font = [UIFont systemFontOfSize:11];
    noInternetOverlayView.numberOfLines = 0;
    noInternetOverlayView.backgroundColor = [UIColor yellowColor];
    noInternetOverlayView.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview: noInternetOverlayView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(noInternetOverlayView);
    NSDictionary *metrics = @{@"height":[NSNumber numberWithDouble: sizeForStatus.height]};
    noInternetOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[noInternetOverlayView]-60-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[noInternetOverlayView(height)]-|" options:0 metrics:metrics views:views]];
    
    if([[MatlistanHTTPClient sharedMatlistanHTTPClient] isLoggedIn]) {
        noInternetOverlayView.hidden = YES;
    }
    else {
         [self updateTableViewBottomConstraint: -noInternetOverlayView.frame.size.height];
    }
    
}

- (void)loadProducts{
    // TODO this is not really being used
    [[MatlistanIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *appStoreProducts) {
        if (success) {
            products = appStoreProducts;
        }
    }];
}

#pragma mark -TableView

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
   if(IS_IPHONE)
   {
       cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
   }
   else
   {
       cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:25];

   }
    
   if(cell.selected)
   {
     //  self.tableView.backgroundColor=[UIColor colorWithRed:93.0/255.0 green:187.0/255.0 blue:85.0/255.0 alpha:1.0];
       [cell setSelected:YES animated:NO];
   }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex
{
    
    if (sectionIndex == 0)
        return nil;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 34)];
   
    /*
     developer : Raj
     Date : 21-9-2015
     Description : Add Top & Bottom seperator in Recipe Title.
     */
    
    int lbl_title_font_size=15,sep_x=10,sep_y=33,title_height,sep_width;
    if(IS_IPHONE)
    {
        lbl_title_font_size=15;
        sep_x=10;
        sep_y=33;
        title_height=32;
        sep_width=(SCREEN_WIDTH*73.44)/100;
    }
    else
    {
        lbl_title_font_size=25;
        sep_x=20;
        sep_y=50;
        title_height=45;
        
        if(SCREEN_WIDTH==768)
        {
            sep_width=(SCREEN_WIDTH*78.13)/100;
        }
        else
        {
            sep_width=(SCREEN_WIDTH*84.5)/100;
        }
        
        
    }
    
    
    UILabel *sepLblTop=[[UILabel alloc] initWithFrame:CGRectMake(sep_x, 0,sep_width, 0.5)];
    sepLblTop.backgroundColor=[Utility getGreenColor];
    [view addSubview:sepLblTop];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 7,SCREEN_WIDTH, title_height)];
    label.text = NSLocalizedString(@"LATEST VIEWED RECIPES",nil);
    label.font = [UIFont systemFontOfSize:lbl_title_font_size];
    label.textColor = [UIColor blackColor];
    label.backgroundColor = [UIColor clearColor];
    //label.textAlignment = NSTextAlignmentCenter;
    [label sizeToFit];
    [view addSubview:label];
    
    UILabel *sepLblBottom=[[UILabel alloc] initWithFrame:CGRectMake(sep_x, sep_y, sep_width, 0.5)];
    sepLblBottom.backgroundColor=[Utility getGreenColor];
    [view addSubview:sepLblBottom];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)sectionIndex
{
    if (sectionIndex == 0)
        return 0;
    if(IS_IPHONE)
    {
        return 34;
    }
    else
    {
        return 60;
    }
}

/**
 *Make segue to the viewcontrollers from the sidemenu
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //[tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
            {
                if (indexPath.section == 0){
                    [DataStore instance].ingredientByURL = @"";
                    revealController = self.revealViewController;
                    [revealController setFrontViewPosition:FrontViewPositionRight animated:YES];
                    
                    ItemsViewController *homeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ItemsView"];
                     homeViewController.ingredientSearchText = @"";
                    navigationController1 = [[UINavigationController alloc]initWithRootViewController:homeViewController];
                    navigationController1.navigationBar.tintColor = HIGHLIGHTED_COLOR;
                    [revealController setFrontViewController:navigationController1];
                    
                    [revealController setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
                    [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
                    
                }
                else{
                    
                    revealController = self.revealViewController;
                    [revealController setFrontViewPosition:FrontViewPositionRight animated:YES];
                    
                    ReceptViewController *receptViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LatestRecipe"];
                    
                    navigationController1 = [[UINavigationController alloc]initWithRootViewController:receptViewController];
                    navigationController1.navigationBar.tintColor = HIGHLIGHTED_COLOR;
                    [revealController setFrontViewController:navigationController1];
                    
                    [revealController setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
                    [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];

                }
                break;
            }
            case 1:
            {
               
                
                revealController = self.revealViewController;
                [revealController setFrontViewPosition:FrontViewPositionRight animated:YES];
                
                PlanFoodViewController *planViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PlanList"];
                
                navigationController1 = [[UINavigationController alloc]initWithRootViewController:planViewController];
                navigationController1.navigationBar.tintColor = HIGHLIGHTED_COLOR;
                [revealController setFrontViewController:navigationController1];
                
                [revealController setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
                [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
               
                break;
            }
            case 2:
            {
                
                revealController = self.revealViewController;
                [revealController setFrontViewPosition:FrontViewPositionRight animated:YES];
                
                RecipesViewController *secondViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Recipes"];
                
                navigationController1 = [[UINavigationController alloc]initWithRootViewController:secondViewController];
                navigationController1.navigationBar.tintColor = HIGHLIGHTED_COLOR;
                [revealController setFrontViewController:navigationController1];
                
                [revealController setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
                [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];

                
                
                break;
            }
                
            case 3:
            {
                
                revealController = self.revealViewController;
                [revealController setFrontViewPosition:FrontViewPositionRight animated:YES];
                
                SettingsTableViewController *secondViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Settings"];
                
                navigationController1 = [[UINavigationController alloc]initWithRootViewController:secondViewController];
                navigationController1.navigationBar.tintColor = HIGHLIGHTED_COLOR;
                [revealController setFrontViewController:navigationController1];
                
                [revealController setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
                [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
                
                break;
            }
                
            case 4:
            {
                
                revealController = self.revealViewController;
                [revealController setFrontViewPosition:FrontViewPositionRight animated:YES];
                
                 HelpViewController *secondViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Help"];
                
                navigationController1 = [[UINavigationController alloc]initWithRootViewController:secondViewController];
                navigationController1.navigationBar.tintColor = HIGHLIGHTED_COLOR;
                [revealController setFrontViewController:navigationController1];
                
                [revealController setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
                [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];

                
                break;
            }
            case 5:
            {
                //TO DO: add in-app purchase product in App Store, restore purchase possibly and calculate usage period for the yearly subscription
                //Buy yearly subscription of matlistan
//                SKProduct * product = (SKProduct *) products[0];
//                if (product != nil) {
//                    [[MatlistanIAPHelper sharedInstance] buyProduct:product];
//                }
                
                revealController = self.revealViewController;
                [revealController setFrontViewPosition:FrontViewPositionRight animated:YES];
                
                HelpViewController *secondViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AdsRemoval"];
                
                navigationController1 = [[UINavigationController alloc]initWithRootViewController:secondViewController];
                navigationController1.navigationBar.tintColor = HIGHLIGHTED_COLOR;
                [revealController setFrontViewController:navigationController1];
                
                [revealController setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
                [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];

                
                break;
            }
            default:
                break;
        }

    }
    else{
        
        
        UINavigationController *navigationController = (UINavigationController *)self.revealViewController.frontViewController;
        (theAppDelegate).detailRecipeFlag=false;
        RecipeDetailViewController *recipeController = [self.storyboard instantiateViewControllerWithIdentifier:@"RecipeDetail"];
        recipeController.recipeboxId = [DataStore instance].viewedRecipes[indexPath.row];
        recipeController.barButtonType = NOT_CERTAIN;
        recipeController.activeRecipe = [Recipebox getActiveRecipeByRecipeId:recipeController.recipeboxId];
        //Dimple
        recipeController.screen_name=@"Recent";
        navigationController.viewControllers = @[recipeController];
        
        //[self.revealViewController setFrontViewController:recipeController animated:YES];
        [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];

//        RecipeTimer *selRecipe = self.recipeArr[indexPath.row];
        Recipebox *selectedRecipe = [Recipebox getRecipeById:recipeController.recipeboxId];
        RecipeTimer *selRecipe = [[RecipeTimer alloc] initWithRecipieId:[selectedRecipe.recipeboxID intValue] recipeName:selectedRecipe.title withRecipeDesc:nil];

        recipeController.selectedRecipe = selRecipe;
//        NSLog(@"*************recipe id:%ld,recipe name:%@",(long)selRecipe.recipeboxId,selRecipe.recipeName);
        recipeController.timerOnRecipes = (theAppDelegate).ActiveTimerArr; //_timerOnRecipes;
        selRecipe.recipeListDelegate = (id)theAppDelegate; //the call will goto appdelegate
        selRecipe.recipeTimerdelegate = recipeController; //hear, we need to tell the timer object to update the timer table present in detail controller, so we need to set the timer delegate to newly created detail controller that we are doing hear
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(IS_IPHONE)
    {
        return 44;
    }
    else
    {
        return 70;
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (sectionIndex == 0) {
        return menuItems.count;
    }
    else{
        return [DataStore instance].viewedRecipes.count;   //TO DO: show more latest recipes, needs to ask Michael about max recipes should be shown
    }
    
}

/**
 *Show latest viewed recipes' names
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
   
    
    if (indexPath.section == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"menuCell" forIndexPath:indexPath];
        cell.textLabel.text = menuItems[indexPath.row];
        
        /*
         developer : Raj
         Date : 21-9-2015
         Description : Below code is to display normal image & highlighted image in menu.
         */
        
        if(indexPath.row==0)
        {
            cell.imageView.image=[UIImage imageNamed:@"shopping_list_nor"];
            cell.imageView.highlightedImage=[UIImage imageNamed:@"shopping_list_sel"];
        }
        else if(indexPath.row==1)
        {
            cell.imageView.image=[UIImage imageNamed:@"plan_rec_nor"];
            cell.imageView.highlightedImage=[UIImage imageNamed:@"plan_rec_sel"];
        }
        else if(indexPath.row==2)
        {
            cell.imageView.image=[UIImage imageNamed:@"recipe_normal"];
            cell.imageView.highlightedImage=[UIImage imageNamed:@"recipe_sel"];
        }
        else if(indexPath.row==3)
        {
            cell.imageView.image=[UIImage imageNamed:@"setting_nor"];
            cell.imageView.highlightedImage=[UIImage imageNamed:@"setting_sel"];
        }
        else if(indexPath.row==4)
        {
            cell.imageView.image=[UIImage imageNamed:@"help_nor"];
            cell.imageView.highlightedImage=[UIImage imageNamed:@"help_sel"];
        }
        else if(indexPath.row==5)
        {
            cell.imageView.image=[UIImage imageNamed:@"remAd_nor"];
            cell.imageView.highlightedImage=[UIImage imageNamed:@"remAd_sel"];
        }
        
       
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        
        //cell.textLabel.highlightedTextColor=[UIColor colorWithRed:93.0/255.0 green:187.0/255.0 blue:85.0/255.0 alpha:1.0];
       // cell.textLabel.textColor=[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
       
        
        
    }
    else if(indexPath.section == 1)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"imageMenuCell" forIndexPath:indexPath];

        if ([DataStore instance].viewedRecipes != nil && [DataStore instance].viewedRecipes.count > 0) {
            NSNumber *recipeID = [DataStore instance].viewedRecipes[indexPath.row];
            Recipebox *recipe = [Recipebox getRecipeById:recipeID];
            
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
            if(IS_IPHONE)
            {
                imageView.layer.cornerRadius=18;
            }
            else
            {
                imageView.layer.cornerRadius=30;
            }
            imageView.layer.masksToBounds=YES;
            
            UILabel *textLabel = (UILabel *)[cell viewWithTag:101];
            [textLabel setText:recipe.title];
            
            UIImage *img;
            if(recipe.imageFileName){
                img = [Utility loadLocalRecipeImage:recipe.recipeboxID];
            }
            if (img) {
                imageView.image = img;
            }
            else {
                __weak __typeof(imageView)weakImageView = imageView;

                dispatch_async(dispatch_get_global_queue(0,0), ^{
                    NSURL *url =[NSURL URLWithString:[Utility getCorrectURLFromJson: recipe.imageUrl]];
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                    [imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                        NSString *fileName = [NSString stringWithFormat:@"%@.png", recipe.recipeboxID];
                        [Utility saveImage:image withFileName:fileName];
                        
                        [Recipebox fillImageFileName:fileName forId:recipe.recipeboxID];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            __strong __typeof(weakImageView)strongImageView = weakImageView;
                            strongImageView.image = image;
                        });

                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                        DLog(@"Can't download recipe image from %@", recipe.imageUrl);
                        if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
                        {
                            [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": [NSString stringWithFormat:@"Can't download recipe image from %@, \nerror : %@:", recipe.imageUrl, error.localizedDescription], @"View":@"LeftMenuViewController"}];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            __strong __typeof(weakImageView)strongImageView = weakImageView;
                            strongImageView.image = [UIImage imageNamed:@"placeHolder.png"];
                        });
                    }];
                });
            }
/*
            if (recipe.imageFileName == nil) {
                [self updateCellImage:[UIImage imageNamed:@"placeHolder.png"] forCell:recipe cellID:indexPath];
                DLog(@"Image filename exists.");
                
                //NSURL *url =[NSURL URLWithString:recipe.imageUrl];
                NSURL *url = [NSURL URLWithString:[Utility getCorrectURLFromJson: recipe.imageUrl]];
                DLog(@"getting image from url %@", url);
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                [cell.imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
   
                    NSString *fileName = [NSString stringWithFormat:@"%@.png", recipe.recipeboxID];
                    [Utility saveImage:image withFileName:fileName];
                    DLog(@"Image found from url");
                    //[Recipebox fillImageFileName:fileName for:recipe.recipeboxID];
                    //This should be moved to a seperate method which would get the cell and then set the image - Markus
                    //cell.imageView.image = image;
                    //[self updateCellImage:image forCell:indexPath];
                    //[self updateCellImage:image forCell:recipe cellID:indexPath];
                    cell.imageView.image = image;
        
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    
                    DLog(@"Can't download recipe image from %@", recipe.imageUrl);
                    //cell.imageView.image = [UIImage imageNamed:@"placeHolder.png"];
                    //UIImage *theImage = [UIImage imageNamed:@"placeHolder.png"];
                    //[self updateCellImage:theImage forCell:indexPath];
                    //[Recipebox fillImageFileName:@"placeHolder.png" for:recipe.recipeboxID];
                    //[self updateCellImage:[UIImage imageNamed:@"placeHolder.png"] forCell:recipe cellID:indexPath];
                    cell.imageView.image = [UIImage imageNamed:@"placeHolder.png"];
                    
                }];
            }
            else{
                UIImage *img = [Utility loadLocalRecipeImage:recipe.recipeboxID];
                if (img != nil) {

                    DLog(@"Local image set");
                    cell.imageView.image = img;
                }
                else{
                    [self updateCellImage:[UIImage imageNamed:@"placeHolder.png"] forCell:recipe cellID:indexPath];
                    DLog(@"getting image from url2");
                    NSURL *url =[NSURL URLWithString:recipe.imageUrl];
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                    [cell.imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {

                        NSString *fileName = [NSString stringWithFormat:@"%@.png", recipe.recipeboxID];
                        DLog(@"Image found from url 2");
                        [Utility saveImage:image withFileName:fileName];
                        //[Recipebox fillImageFileName:fileName for:recipe.recipeboxID];
                        //cell.imageView.image = image;
                        //[self updateCellImage:image forCell:recipe cellID:indexPath];
                        cell.imageView.image = image;
                        
                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                        
                        DLog(@"Can't download recipe image from %@", recipe.imageUrl);
                        //cell.imageView.image = [UIImage imageNamed:@"placeHolder.png"];
                        //[self updateCellImage:[UIImage imageNamed:@"placeHolder.png"] forCell:indexPath];
                        //[Recipebox fillImageFileName:@"placeHolder.png" for:recipe.recipeboxID];
                        //[self updateCellImage:[UIImage imageNamed:@"placeHolder.png"] forCell:recipe cellID:indexPath];
                        cell.imageView.image = [UIImage imageNamed:@"placeHolder.png"];
                    }];
                }
            }
 */
        }
    }
    
    cell.textLabel.highlightedTextColor=[Utility getGreenColor];
    cell.textLabel.textColor=[UIColor blackColor];
    

    
   
    cell.backgroundColor=[UIColor clearColor];
    cell.selectedBackgroundView = [[UIView alloc] init];
    bgView = [[UIView alloc] initWithFrame:cell.frame];
   
   /* if(indexPath.row>0)
    {
         UILabel *lbl1=[[UILabel alloc] initWithFrame:CGRectMake(8, 0, 320, 0.5)];
        lbl1.backgroundColor=[UIColor colorWithRed:93.0/255.0 green:187.0/255.0 blue:85.0/255.0 alpha:1.0];
        [bgView addSubview:lbl1];
    }
    if (indexPath.section == 0) {
        if(indexPath.row<(menuItems.count)-1)
        {
            UILabel *lbl2=[[UILabel alloc] initWithFrame:CGRectMake(8, cell.frame.size.height, 320, 0.5)];
            lbl2.backgroundColor=[UIColor colorWithRed:93.0/255.0 green:187.0/255.0 blue:85.0/255.0 alpha:1.0];
            [bgView addSubview:lbl2];
        }
    }
    else
    {
        if(indexPath.row<([DataStore instance].viewedRecipes.count)-1)
        {
            UILabel *lbl2=[[UILabel alloc] initWithFrame:CGRectMake(8, cell.frame.size.height, 320, 0.5)];
            lbl2.backgroundColor=[UIColor colorWithRed:93.0/255.0 green:187.0/255.0 blue:85.0/255.0 alpha:1.0];
            [bgView addSubview:lbl2];
        }

    }
    
    
    
    bgView.backgroundColor=[UIColor clearColor];
    cell.selectedBackgroundView = bgView;*/
    
   

    return cell;
}

-(void)updateCellImage:(UIImage*)image forCell:(Recipebox*)recipe cellID:(NSIndexPath *)indexPath {
    DLog(@"Setting cell image.");
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.imageView.image = image;
    NSString *fileName = [NSString stringWithFormat:@"%@.png",recipe.recipeboxID.stringValue];
    [Utility saveImage:image withFileName:fileName];
    [Recipebox fillImageFileName:fileName forId:recipe.recipeboxID];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    /*
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kInternetReachable object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kInternetNotReachable object:nil];
     */
}

- (void)internetNotReachable:(NSNotification *)notification
{
    noInternetOverlayView.hidden = NO;
    [self updateTableViewBottomConstraint: -noInternetOverlayView.frame.size.height];
}

- (void)internetReachable:(NSNotification *)notification
{
    noInternetOverlayView.hidden = YES;
    [self updateTableViewBottomConstraint: 0];
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
// Sliding Menu Gesture Management
-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.revealViewController.frontViewController.view setUserInteractionEnabled:YES];
}

/*- (void)populateRecipe
{
    if(self.recipeArr == nil)
        self.recipeArr=[[NSMutableArray alloc] init];
    
    for(NSInteger k = 0 ; k < [DataStore instance].viewedRecipes.count ; k++)
    {
        NSNumber *recipeID = [DataStore instance].viewedRecipes[k];
        Recipebox *r = [Recipebox getRecipeById:recipeID];
       // NSLog(@"r.title:%@",[NSString stringWithFormat:@"%@",r.title]);
        RecipeTimer *activeRecipeTimer = [self checkTimerisOnFotThisREcipeId:recipeID];
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
}
*/

- (RecipeTimer *)checkTimerisOnFotThisREcipeId:(NSNumber*)recipeId
{
    RecipeTimer *isActiveTimer = nil;
    NSArray *recipetimerOnArray = (theAppDelegate).ActiveTimerArr; //you chane after ok
    for(RecipeTimer *aTimerOnRecipe in recipetimerOnArray)
    {
//        if(aTimerOnRecipe.recipeboxId == [recipeId integerValue])
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
