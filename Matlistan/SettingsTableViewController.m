//
//  SettingsTableViewController.m
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "MatlistanHTTPClient.h"
#import "SyncManager.h"
#import <Fabric/Fabric.h>
#import <Google/SignIn.h>
#import "AppDelegate.h"

#define DATA_COLLECTION_ROW 1
#define LINKED_ACCOUNTS_ROW 2
#define LOGIN_ROW 3

@interface SettingsTableViewController ()
{
    UIActivityIndicatorView * spinner;
    UIImageView * bgimage;
    UILabel * loadingLabel;
    NSArray *menuItemsTexts;
    NSArray *menuItemsDetails;
    BOOL isLoggedIn;
    BOOL didAppear;
}
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonMenu;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *heightOFDescriptionLabel;
@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets=NO;
    //Dimple -7-11-2015
    self.title =NSLocalizedString(@"Settings",nil);
    
    SWRevealViewController *revealController = self.revealViewController;
    revealController=[[SWRevealViewController alloc]init];
    revealController = [self revealViewController];
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    revealController.delegate=self;
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];

    
    //isLoggedIn = [MatlistanHTTPClient sharedMatlistanHTTPClient].ticket.length > 0;
    //isLoggedIn = [MatlistanHTTPClient sharedMatlistanHTTPClient].isLoggedIn;
    isLoggedIn = [Utility getDefaultBoolAtKey:@"authorized"];
    NSString *userName = @"";
    if (isLoggedIn) {
        menuItemsTexts = @[NSLocalizedString(@"Vibrate",nil),NSLocalizedString(@"Data Collection",nil),NSLocalizedString(@"Link account",nil),NSLocalizedString(@"Change account",nil)];
        NSString *showLoginTypeName;
        if ([Utility getCurrentLoginType] == LoginTypeFacebook) {
            showLoginTypeName = NSLocalizedString(@"Facebook account", nil);
        }else if ([Utility getCurrentLoginType] == LoginTypeEmail){
            showLoginTypeName = [Utility getObjectFromDefaults:@"userName"];
        }
        if ([Utility getCurrentLoginType] == LoginTypeGoogle) {
            showLoginTypeName = NSLocalizedString(@"Google account", nil);
        }
        userName = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"You have logged in as",nil), showLoginTypeName];

        if ([Utility getCurrentLoginType] == LoginTypeAnonymous) {
            menuItemsTexts = @[NSLocalizedString(@"Vibrate", nil),NSLocalizedString(@"Data Collection",nil),NSLocalizedString(@"Link account",nil),NSLocalizedString(@"Sign in",nil)];
            userName = [NSString stringWithFormat:@"%@",NSLocalizedString(@"Login to get access to all the functions of menus is offering",nil)];
        }
    }
    else{
        menuItemsTexts = @[NSLocalizedString(@"Vibrate", nil),NSLocalizedString(@"Data Collection",nil),NSLocalizedString(@"Link account",nil),NSLocalizedString(@"Log in",nil)];
        userName =  NSLocalizedString(@"You are not logged in",nil);
    }
    menuItemsDetails = @[@"",NSLocalizedString(@"If an error happens, the app can report the error to the developer.",nil), NSLocalizedString(@"Link you account together with another account to see the same lists",nil), userName];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOut:) name:@"SyncStopped" object:nil];
    
    /*Developer : Dimple
     Date : 28-9-15
     Description : Sliding menu swipe gesture management.*/
    
   // SWRevealViewController *revealController = self.revealViewController;
   // [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    
    didAppear = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing SettingsTableViewController");
    didAppear = YES;
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
}
- (void)removeAds
{
    if (self.bannerView)
    {
        [self.bannerView removeConstraints:self.bannerView.constraints];
        [self.bannerView removeFromSuperview];
        [Utility updateConstraint:self.view toView:self.tableView withConstant:0];
    }
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SWRevealViewController *reveal = self.revealViewController;
    reveal.panGestureRecognizer.enabled = YES;

    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOut:) name:@"SyncStopped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //[[NSNotificationCenter defaultCenter]removeObserver:self name:@"SyncStopped" object:nil];
}

#pragma mark - Table view
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    // To "clear" the footer view
    return [UIView new];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    DLog(@"count = %lu",(unsigned long)menuItemsTexts.count);
    return menuItemsTexts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *strDescription = [NSString stringWithFormat:@"%@",[menuItemsDetails objectAtIndex:indexPath.row]];
    
    CGSize sizeForDescriptionLabel = [self getSizeForText:strDescription maxWidth:tableView.frame.size.width-20 font:@"helvetica" fontSize:14.0];
    
    if (indexPath.row==0)
    {
        if(IS_IPHONE)
        {
            return 55.0;
        }
        else
        {
            return 90;
        }
    }
   else if (indexPath.row==1)
    {
        if(IS_IPHONE)
        {
            return 55.0;
        }
        else
        {
            return 90;
        }
    }
    else
    {
        return sizeForDescriptionLabel.height+70;
    }
    //return 110.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    // Configure the cell...
    UILabel *labelTitle = (UILabel*)[cell viewWithTag:1];
    UILabel *labelDetail = (UILabel*)[cell viewWithTag:2];
    labelTitle.text = menuItemsTexts[indexPath.row];
    
    labelDetail.text = menuItemsDetails[indexPath.row];
    if(indexPath.row==1)
    {
        labelDetail.hidden=YES;
    }
    for (NSLayoutConstraint *height in labelDetail.constraints)
    {
        if (height.firstAttribute == NSLayoutAttributeHeight)
        {
            NSString *strDescription = [NSString stringWithFormat:@"%@",[menuItemsDetails objectAtIndex:indexPath.row]];
            
            CGSize sizeForDescriptionLabel = [self getSizeForText:strDescription maxWidth:tableView.frame.size.width-20 font:@"helvetica" fontSize:14.0];

            height.constant = sizeForDescriptionLabel.height;
        }
    }
    
    UISwitch *onOff = (UISwitch*)[cell viewWithTag:3];
    if (indexPath.row == 0)
    {
        [onOff addTarget:self action:@selector(vibrateOnPickDropItemMethod:) forControlEvents:UIControlEventValueChanged];
        [onOff setOn:[Utility getDefaultBoolAtKey:@"vibrateOnPickDropItemBool"]];
        [onOff setHidden:NO];
        for (NSLayoutConstraint *height in labelDetail.constraints)
        {
            if (height.firstAttribute == NSLayoutAttributeHeight)
            {
                height.constant = 0;
            }
        }
    }
    else if (indexPath.row == menuItemsTexts.count-2 && LoginTypeAnonymous == [Utility getDefaultIntAtKey:@"LoginType"])
    {
        labelTitle.enabled = NO;
        labelDetail.enabled = NO;
        [onOff setHidden:YES];
    }
    else
    {
        [onOff setHidden:YES];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == DATA_COLLECTION_ROW)
    {
        [self performSegueWithIdentifier:@"DataCollectionSegue" sender:nil];
    }
    else if (indexPath.row == LOGIN_ROW)
    {
        if (isLoggedIn)
        {
            if ([Utility getCurrentLoginType] == LoginTypeAnonymous)
            {
                [Utility saveInDefaultsWithBool:NO andKey:@"authorized"];
                [[DataStore instance] resetDataStore];
                [Utility saveInDefaultsWithInt:0 andKey:@"DEFAULT_LIST_ID"];
                [self performSegueWithIdentifier:@"settingsToLogin" sender:self];
                //[self logOut];
            }
            else
            {
                [self showConfirmLogOutAlert:NSLocalizedString(@"Are you sure you want to logout?", nil)];
            }
        }
        else
        {
            [Utility saveInDefaultsWithBool:NO andKey:@"authorized"];
            [self logOut];
        }
    }
    else if (indexPath.row == LINKED_ACCOUNTS_ROW)
    {
        if ([Utility getCurrentLoginType] == LoginTypeAnonymous)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info",nil) message:NSLocalizedString(@"register now", nil) delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
            alert.tag = 1201;
            [alert show];
        }
        else
        {
            [self performSegueWithIdentifier:@"LinkedAccounts" sender:nil];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark  Get Size For Text
- (CGSize)getSizeForText:(NSString *)text maxWidth:(CGFloat)width font:(NSString *)fontName fontSize:(float)fontSize
{
    text = [text stringByReplacingOccurrencesOfString:@"&" withString:@"ABC"];
    
    CGSize constraintSize;
    constraintSize.height = MAXFLOAT;
    constraintSize.width = width;
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:fontName size:fontSize], NSFontAttributeName,
                                          nil];
    
    CGRect frame = [text boundingRectWithSize:constraintSize
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:attributesDictionary
                                      context:nil];
    
    CGSize stringSize = frame.size;
    stringSize = CGSizeMake(stringSize.width, stringSize.height+5);
    return stringSize;
    
}


#pragma mark- UI related

- (IBAction)showMenu
{
    //[self.frostedViewController presentMenuViewController];
    [self.revealViewController revealToggle:self];

}

- (void)vibrateOnPickDropItemMethod:(id)sender
{
    UISwitch *onOff = (UISwitch*)sender;
    [Utility saveInDefaultsWithBool:onOff.isOn andKey:@"vibrateOnPickDropItemBool"];
}

#pragma mark- log out
/* Remove core data and cookie
 Truncate all the tables in Core data
 */
-(void)logOut{
    [[SyncManager sharedManager] finished];
    [[SyncManager sharedManager] stopSync];
    
    for(RecipeTimer *aRecipe in (theAppDelegate).ActiveTimerArr)
    {
        [aRecipe stopTimer];
    }

    [[WatchConnectivityController sharedInstance] hideTimerOptionInWatch];

    (theAppDelegate).ActiveTimerArr=[[NSMutableArray alloc]init];
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *context) {
        [FavoriteItem MR_truncateAllInContext:context];// Dimple 21-12-15
        [Active_recipe MR_truncateAllInContext:context];
        [EndpointHash MR_truncateAllInContext:context];
        [Ingredient MR_truncateAllInContext:context];
        [Item MR_truncateAllInContext:context];
        [Item_list MR_truncateAllInContext:context];
        [ItemsCheckedStatus MR_truncateAllInContext:context];
        [Recipebox MR_truncateAllInContext:context];
        [Recipebox_tag MR_truncateAllInContext:context];
        [Store MR_truncateAllInContext:context];
        [Visit MR_truncateAllInContext:context];
        
        [Utility saveInDefaultsWithObject:[NSArray new] andKey:@"viewedRecipes"];
        [DataStore instance].viewedRecipes = [NSMutableArray new];
        
        
        
        
    } completion:^(BOOL success, NSError *error) {
        if (success) {
            DLog(@"Successfully removed user data");
            [self clearUserdefaultsAndMoveToLoginScreen];
        }
        else {
            DLog(@"Cannot remove user data: %@", [error localizedDescription]);
            [self clearUserdefaultsAndMoveToLoginScreen];
        }
    }];
}

- (void)clearUserdefaultsAndMoveToLoginScreen
{
//    [self removeWaitOverlay];
    [SVProgressHUD dismiss];
    
    //Remove all local notification and value
   // [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    
    /*if((theAppDelegate).Timer_recipeIdArr!=nil && (theAppDelegate).Timer_recipeIdArr.count>0)
    {
        for(int i=0;i<(theAppDelegate).Timer_recipeIdArr.count;i++)
        {
            DLog(@"afer remove :%@",[[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"timer_%@",(theAppDelegate).Timer_recipeIdArr[i]]]);
            
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timerRecipeTitle_%@",(theAppDelegate).Timer_recipeIdArr[i]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timerDescString_%@",(theAppDelegate).Timer_recipeIdArr[i]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"updated_timer_%@",(theAppDelegate).Timer_recipeIdArr[i]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timer_%@",(theAppDelegate).Timer_recipeIdArr[i]]];
            //            [[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"uniqueTimerId_%@",(theAppDelegate).Timer_recipeIdArr[i]]];
            
            
            NSData *data= [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"uniqueTimerId_%@",(theAppDelegate).Timer_recipeIdArr[i]]];
            if(data!=nil)
            {
                UILocalNotification *localNotif = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                DLog(@"Remove localnotification  are %@", localNotif);
                [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"uniqueTimerId_%@",(theAppDelegate).Timer_recipeIdArr[i]]];
            }
            
            NSData *data1= [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"uniqueDismissTimerId_%@",(theAppDelegate).Timer_recipeIdArr[i]]];
            if(data1!=nil)
            {
                UILocalNotification *localNotif1 = [NSKeyedUnarchiver unarchiveObjectWithData:data1];
                DLog(@"Remove localnotification  are %@", localNotif1);
                [[UIApplication sharedApplication] cancelLocalNotification:localNotif1];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"uniqueDismissTimerId_%@",(theAppDelegate).Timer_recipeIdArr[i]]];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"InvalidateTimer" object:nil];
        
        
    }
    [[UIApplication sharedApplication]cancelAllLocalNotifications];*/
    
    
    [Utility setItemscustomImage:nil];
    [Utility setItemscustomLandImage:nil];
    [Utility setRecipecustomImage:nil];
    [Utility setRecipecustomLandImage:nil];
    [Utility setPlanRecipecustomImage:nil];
    [Utility setPlanRecipecustomLandImage:nil];
    [Utility setTempEmailID:nil];
    
    
    [Utility saveInDefaultsWithBool:NO andKey:@"authorized"];   //not authorized any longer
    if([Utility getCurrentLoginType] != LoginTypeAnonymous){
        [Utility saveInDefaultsWithObject:@"" andKey:@"userName"];  //clean user profile
        [Utility saveInDefaultsWithObject:@"" andKey:@"password"];
    }
    [Utility saveInDefaultsWithInt:0 andKey:@"DEFAULT_LIST_ID"];  //reset default list id
    // Reset all DataStore values when logout
    [[DataStore instance] resetDataStore];
    
    //[self dismissViewControllerAnimated:YES completion:^{[self performSegueWithIdentifier:@"settingsToLogin" sender:self];}];
    [self performSegueWithIdentifier:@"settingsToLogin" sender:self];
    //[(AppDelegate *)[UIApplication sharedApplication].delegate switchToLoginViewController];
}

#pragma mark - segue

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"settingsToLogin"])
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        //[Utility saveInDefaultsWithObject:[NSArray new] andKey:@"viewedRecipes"];
        LoginViewController *loginController = (LoginViewController*)segue.destinationViewController;
        loginController.isSwitchingUser = YES;
    }
}

#pragma mark- show progress for logging out
/*
-(void)createWaitOverlay:(NSString*)message
{
    // fade the overlay in
    loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 50,self.view.bounds.size.height/2 - 30,200.0, 20.0)];
    
    loadingLabel.text = message;
    loadingLabel.textColor = [UIColor whiteColor];
    bgimage = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height)];
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
    // Disable User Interaction When Spinner is spining/ @ Ashish
    self.view.userInteractionEnabled = NO;
    self.buttonMenu.enabled = NO;
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
    // Enable User Interaction When Spinner is spining/ @ Ashish
    
    self.view.userInteractionEnabled = YES;
    self.buttonMenu.enabled = YES;
    bgimage = nil;
    loadingLabel = nil;
    spinner = nil;
    
}
*/
#pragma mark- alerts
- (void)showConfirmLogOutAlert:(NSString*)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info",nil) message:msg delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    [alert show];
    alert.tag = 1202;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1201)
    {
        if (buttonIndex == 1)
        {
            [Utility saveInDefaultsWithBool:NO andKey:@"authorized"];
            [self logOut];
        }
    }
    else if(1202){
        // Set buttonIndex == 1 to handel "Ok"/"Yes" button response
        if (buttonIndex == 0)
        {
            //cancel logout
        }
        else if(buttonIndex == 1)
        {
            if ([Utility getCurrentLoginType] == LoginTypeFacebook)
            {
                FBSDKLoginManager *manager = [[FBSDKLoginManager alloc] init];
                [manager logOut];
            }
            else if ([Utility getCurrentLoginType] == LoginTypeGoogle) {
                [[GIDSignIn sharedInstance] signOut];
            }
            //[Utility saveInDefaultsWithObject:[NSArray new] andKey:@"viewedRecipes"];

            //Stop sync and perform logout
//            [self createWaitOverlay:[NSString stringWithFormat:@"%@ ...", NSLocalizedString(@"Log out",nil)]];
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
            [self logOut];
        }
    }
}

#pragma mark- memory

- (void)dealloc {
    
    // we are no longer interested in these notifications:
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SyncStopped" object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
