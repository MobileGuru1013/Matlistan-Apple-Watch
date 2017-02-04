//
//  AppDelegate.m
//  MatListan
//
//  Created by Yan Zhang on 03/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "AppDelegate.h"
#import "ItemsViewController.h"
#import "RecipesViewController.h"
#import "RootViewController.h"
#import "Item_list+Extra.h"
#import "Item+Extra.h"
#import "Store+Extra.h"
#import "Recipebox+Extra.h"
#import "Active_recipe+Extra.h"
#import "MatlistanIAPHelper.h"
#import "Appirater.h"
#import "Mixpanel.h"
#import "Environment.h"
#import "AFNetworkReachabilityManager.h"
#import <Google/SignIn.h>

#import "EndpointHash.h"
#import "Ingredient.h"
#import "ItemsCheckedStatus.h"
#import "Recipebox_tag.h"
#import "EndpointHash+Extra.h"

#define BACKGROUND_SYNC_PERIOD 14400 //4 hours

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize detailRecipeFlag;
@synthesize customImage;
//@synthesize ItemscustomImage;
@synthesize RecipecustomImage;
@synthesize no_fav_item_flag;
@synthesize is_random;
@synthesize is_scan_start;
@synthesize add_success;
//@synthesize barcode_itemObjectId;
//@synthesize barcode_item;
//@synthesize barcode_itemId;
@synthesize multiple_edit;
@synthesize storeDict;
@synthesize speakAgain_flag;
@synthesize AddViaVoice;
@synthesize voiceResult;
@synthesize voice_not_found;
//@synthesize open_from_notification;
@synthesize Timer_recipeIdArr;
@synthesize isNewRecipeAdded;
//10-3-16
@synthesize open_from_notification;
@synthesize ActiveTimerArr;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    Timer_recipeIdArr=[[NSMutableArray alloc]init];
    self.gotoSettingFromSearchShops=false;
    self.isShopsTableviewController=false;

    [[WatchConnectivityController sharedInstance] CreateAndActivateSession];
    
    //10-3-16
    ActiveTimerArr = [[NSMutableArray alloc] init];;
    open_from_notification=false;

    
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError: &configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    //Google login init
    [[GIDSignIn sharedInstance] setServerClientID:[Environment sharedInstance].googleServerClientId];
    [[GIDSignIn sharedInstance] setClientID:[Environment sharedInstance].googleClientId];
    

    ////////////////
    
    //Facebook login init
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    [FBSDKSettings setAppID:[Environment sharedInstance].facebookAppID];
    ///////////////////////
    
    if (![Utility hasDefaultKey:@"sendBugReport"])
    {
        [Utility saveInDefaultsWithBool:YES andKey:@"sendBugReport"];
    }
    if (![Utility hasDefaultKey:@"sendAnalyticsReport"])
    {
        if([[Utility getAppUrlScheme] isEqualToString:@"matlistan"])
        {
            [Utility saveInDefaultsWithBool:YES andKey:@"sendAnalyticsReport"];
        }
        else
        {
            [Utility saveInDefaultsWithBool:NO andKey:@"sendAnalyticsReport"];
        }
    }
    
    DLog(@"Environment %@", [Environment sharedInstance].baseUrl);
    
    detailRecipeFlag=false;
    no_fav_item_flag =false;
    is_random=false;
    add_success=false;
    multiple_edit=false;
    speakAgain_flag=false;
    AddViaVoice=false;
    voice_not_found=false;
    isNewRecipeAdded=false;
    //open_from_notification=false;
    self.open_from_recipeList=false;
    CLS_LOG(@"CoreData setup");
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Model.sqlite"];   //create core data with MagicalRecord
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelError];
    
    [DataStore instance].viewedRecipes = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"viewedRecipes"] mutableCopy];
    if ([DataStore instance].viewedRecipes == nil) {
        [DataStore instance].viewedRecipes = [[NSMutableArray alloc]init];
    }
    
    DLog(@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
    
    //register MatlistanIAPHelper class as a transaction observer
//    [MatlistanIAPHelper sharedInstance];
    
    if ([Utility getDefaultBoolAtKey:@"firstLaunchComplete"]) {
        
        if(IS_IPHONE)
        {
            mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        }
        else
        {
             mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
        }
       // mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        UINavigationController *navController;

        if ([Utility getDefaultBoolAtKey:@"authorized"])
        {
            [[MatlistanHTTPClient sharedMatlistanHTTPClient] loginWithPostSession];
            navController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"rootController"];
        }
        else
        {
            navController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"UINavigationControllerID"];
        }
        self.window.rootViewController = navController;
    }
    
    
    
    [Appirater setAppId:@"1003750643"];
    [Appirater setDaysUntilPrompt:7];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater setDebug:NO];
    [Appirater appLaunched:YES];
    
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        if (mixpanel)
        {
            [mixpanel identify:[MatlistanHTTPClient sharedMatlistanHTTPClient].accountId];
            [mixpanel track:@"app opened"];
        }
    }
    else
    {
        [[Mixpanel sharedInstance] registerSuperProperties:@{@"$ignore":@"Yes"}];
    }
    
    [Utility migrateUserDefaultsToSharedDefaults];
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval: BACKGROUND_SYNC_PERIOD];
    
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        
        [application registerUserNotificationSettings:[UIUserNotificationSettings
                                                       settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|
                                                       UIUserNotificationTypeSound categories:nil]];
    }
    // Handle launching from a notification
    UILocalNotification *localNotif =
    [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotif) {
        //DLog(@"Recieved Notification %@",localNotif);
    }
    
    [EndpointHash updateItemsHashWithValue:@0];
    [EndpointHash updateTotalHashWithValue:@0];

    [self.window makeKeyAndVisible];

    return YES;
}

////////////////////////////////////////////////////////////////////////////////////
-(void) application:(UIApplication *)application performFetchWithCompletionHandler: (void (^)(UIBackgroundFetchResult))completionHandler {
    
    CLS_LOG(@"Background fetch started...");
    
    //---do background fetch here---
    // You have up to 30 seconds to perform the fetch
    if([NSManagedObjectContext MR_defaultContext] == nil) {
        CLS_LOG(@"CoreData init in background (again)");
        [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Model.sqlite"];   //create core data with MagicalRecord

    }
    
    self.backgroundFetchCompletionHandler = completionHandler;
    [SyncManager sharedManager].syncManagerDelegate = self;
    [[SyncManager sharedManager] startSync];
    
}

-(void)didUpdateItems {
    BOOL downloadSuccessful = YES;
    [[SyncManager sharedManager] stopSync];
    [SyncManager sharedManager].syncManagerDelegate = nil;
    if (downloadSuccessful) {
        //---set the flag that data is successfully downloaded---
        _backgroundFetchCompletionHandler(UIBackgroundFetchResultNewData);
    } else {
        //---set the flag that download is not successful---
        _backgroundFetchCompletionHandler(UIBackgroundFetchResultFailed);
    }
    
    CLS_LOG(@"Background fetch completed...");

}

- (void) syncFinished {
    BOOL downloadSuccessful = YES;
    [[SyncManager sharedManager] stopSync];
    [SyncManager sharedManager].syncManagerDelegate = nil;
    if (downloadSuccessful) {
        //---set the flag that data is successfully downloaded---
        _backgroundFetchCompletionHandler(UIBackgroundFetchResultNoData);
    } else {
        //---set the flag that download is not successful---
        _backgroundFetchCompletionHandler(UIBackgroundFetchResultFailed);
    }
    
    CLS_LOG(@"Background fetch completed...");
}

////////////////////////////////////////////////////////////////////////////////////

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    //Show shoppinglist or recipelist viewcontroller and set new ingredient value or recipe searching value
    
    [self parseURL:[url query]];
    
    if(IS_IPHONE)
    {
        mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    }
    else
    {
        mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    // mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    
    
    RootViewController *rootViewController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"rootController"];
    
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}
/*URL format: ingredient*tag
 * e.g.  <a href=\"matlistan://?morot*\">morot</a>"
         <a href=\"matlistan://?*veg\">*veg</a>"
 */
-(void)parseURL:(NSString*)url{

    url = [self decodeFromPercentEscapeString:url];
    if (url.length == 0) {
        return;
    }
    NSArray *components = [url componentsSeparatedByString:@"*"];
    
    DLog(@"%@",components);
    [DataStore instance].ingredientByURL = [components objectAtIndex:0];
    [DataStore instance].tagByURL = [components objectAtIndex:1];
    [DataStore instance].sortByStoreID = [components objectAtIndex:2];
    DLog(@"ingredient: %@, tag: %@, storeID %@",[DataStore instance].ingredientByURL,[DataStore instance].tagByURL,[DataStore instance].sortByStoreID);
}
- (NSString*) decodeFromPercentEscapeString:(NSString *) string {
    return (__bridge NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                         (__bridge CFStringRef) string,
                                                                                         CFSTR(""),
                                                                                         kCFStringEncodingUTF8);
}

- (void)applicationWillResignActive:(UIApplication *)application
{

    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[SyncManager sharedManager] stopSync];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    // -- Stop monitoring network reachability -- //
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if ([Utility getDefaultBoolAtKey:@"authorized"])
    {
        NSDate *lastLoggedInDate = [Utility getObjectFromDefaults:@"LastLoggedInDateKey"];
        if([Utility secondsBetweenDate:lastLoggedInDate andDate:[NSDate new]] >= 3600){
            [[MatlistanHTTPClient sharedMatlistanHTTPClient] loginWithPostSession];
        }
        else {
            [[SyncManager sharedManager] startSync];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateUINotification" object: nil];
    
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if(self.isShopsTableviewController)
    {
         if([CLLocationManager locationServicesEnabled])
         {
            if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)
            {
               
                if(self.gotoSettingFromSearchShops)
                {
                    NSDictionary *dic=@{@"key_retrieveLocation":@"1"};
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieveLocation" object:self userInfo:dic];
                }
            }
            else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setEnableLocalationServiceArr" object:self userInfo:nil];
                }
            
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieveLocation" object:self userInfo:nil];
        
         }
         else
         {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setEnableLocalationServiceArr" object:self userInfo:nil];
         }
    }
    [[UIApplication sharedApplication] cancelAllLocalNotifications]; // Remove all notification

    [FBSDKAppEvents activateApp];
    
    //sendBugReport
    if ([Utility getDefaultBoolAtKey:@"sendBugReport"])
    {
        [Fabric with:@[CrashlyticsKit]];
        [Crashlytics startWithAPIKey:@"21794aa12eeef1dfbe87cffba19decc2219a1b16"];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    //[self RemoveAllNotificationWhenAppRemoveFromBackground];
    [MagicalRecord cleanUp];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
        return [[GIDSignIn sharedInstance] handleURL:url
                                   sourceApplication:sourceApplication
                                          annotation:annotation]
    ||
                [[FBSDKApplicationDelegate sharedInstance] application:application
                                                              openURL:url
                                                    sourceApplication:sourceApplication
                                                           annotation:annotation];

}

-(void)switchRootViewController{
    
    [UIView transitionWithView:self.window
                      duration:0.5
                       options:UIViewAnimationOptionTransitionNone
                    animations:^{
                        if(IS_IPHONE)
                        {
                            mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
                        }
                        else
                        {
                            mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
                        }
                       // mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
                        RootViewController *rootViewController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"rootController"];
                        self.window.rootViewController = rootViewController;
                    }
                    completion:nil];
}

-(void)switchToLoginViewController
{
    
    /*
     Assuming this method will be called only on logout, here is the procedure of logout.
     */
    
        [[SyncManager sharedManager] finished];
        [[SyncManager sharedManager] stopSync];
        
        
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
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
        }];

        [SVProgressHUD dismiss];
        [Utility setItemscustomImage:nil];
        [Utility setItemscustomLandImage:nil];
        [Utility setRecipecustomImage:nil];
        [Utility setRecipecustomLandImage:nil];
        [Utility setPlanRecipecustomImage:nil];
        [Utility setPlanRecipecustomLandImage:nil];
        [Utility setTempEmailID:nil];
        
        
        [Utility saveInDefaultsWithBool:NO andKey:@"authorized"];

        //not authorized any longer
        if([Utility getCurrentLoginType] != LoginTypeAnonymous){
            [Utility saveInDefaultsWithObject:@"" andKey:@"userName"];  //clean user profile
            [Utility saveInDefaultsWithObject:@"" andKey:@"password"];
        }
    if ([Utility getCurrentLoginType] == LoginTypeGoogle) {
        [[GIDSignIn sharedInstance] signOut];
    }
        [Utility saveInDefaultsWithInt:0 andKey:@"DEFAULT_LIST_ID"];  //reset default list id
        // Reset all DataStore values when logout
        [[DataStore instance] resetDataStore];
    
    if(IS_IPHONE)
    {
        mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    }
    else
    {
        mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    // mainStoryBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    UINavigationController *navController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"UINavigationControllerID"];
    self.window.rootViewController = navController;
}
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
    if (application.applicationState == UIApplicationStateBackground || application.applicationState == UIApplicationStateInactive )
    {
        [Utility setTimerRecipeId:[notification.userInfo objectForKey:@"recipe_id"]];
        
        if(![(theAppDelegate).globalRecipeId isEqualToString:[notification.userInfo objectForKey:@"recipe_id"]])
        {
            (theAppDelegate).open_from_notification=true;
            [theAppDelegate switchRootViewController]; //after switching to detail screen
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTableViewData" object:nil];
        }
        (theAppDelegate).open_from_notification=true;
        [theAppDelegate switchRootViewController]; //after switching to detail screen
    }

}
/* //Dimple
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
   // DLog(@"user info***** :%@",notification.userInfo);
    
    if([notification.userInfo objectForKey:@"Time out"])
    {
        //Remove particular notification from notification bar
        NSData *data= [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"uniqueDismissTimerId_%@",[notification.userInfo objectForKey:@"Time out"]]];
        if(data!=nil)
        {
            UILocalNotification *localNotif = [NSKeyedUnarchiver unarchiveObjectWithData:data];
           // DLog(@"Remove localnotification  are %@", localNotif);
            [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"uniqueDismissTimerId_%@",[notification.userInfo objectForKey:@"Time out"]]];
        }
        
    }
    if (application.applicationState == UIApplicationStateBackground || application.applicationState == UIApplicationStateInactive )
    {
        //DLog(@"userinfo:%@",notification.userInfo);
        if([notification.userInfo objectForKey:@"timer_recipe_id"])
        {
            NSString *timer_recipe_id=[notification.userInfo objectForKey:@"timer_recipe_id"];
            [Utility setTimerRecipeId:timer_recipe_id];
            
            open_from_notification=true;
            [self switchRootViewController];
        }
        //    }
        //    else
        //    {
        if([notification.userInfo objectForKey:@"Time out"])
        {
            [Utility setTimerRecipeId:[notification.userInfo objectForKey:@"Time out"]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timerRecipeTitle_%@",[Utility getTimerRecipeId]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timerDescString_%@",[Utility getTimerRecipeId]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"updated_timer_%@",[Utility getTimerRecipeId]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timer_%@",[Utility getTimerRecipeId]]];
            if([(theAppDelegate).Timer_recipeIdArr containsObject:[Utility getTimerRecipeId]])
            {
                [(theAppDelegate).Timer_recipeIdArr removeObject:[Utility getTimerRecipeId]];
            }
            open_from_notification=true;
            [self switchRootViewController];
        }
        
        
    }
    else{
        if([notification.userInfo objectForKey:@"Time out"])
        {
            [Utility setTimerRecipeId:[notification.userInfo objectForKey:@"Time out"]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timerRecipeTitle_%@",[Utility getTimerRecipeId]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timerDescString_%@",[Utility getTimerRecipeId]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"updated_timer_%@",[Utility getTimerRecipeId]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timer_%@",[Utility getTimerRecipeId]]];
            if([(theAppDelegate).Timer_recipeIdArr containsObject:[Utility getTimerRecipeId]])
            {
                [(theAppDelegate).Timer_recipeIdArr removeObject:[Utility getTimerRecipeId]];
            }
            open_from_notification=true;
            [self switchRootViewController];
        }
        
    }
    
}*/
/*
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler {
    
    
    
    if ([notification.category isEqualToString:@"SetTimer"])
    {
        // Handle actions of local notifications here. You can identify the action by using "identifier" and perform appropriate operations
        NSString *timer_recipe_id=[notification.userInfo objectForKey:@"timer_recipe_id"];
        [Utility setTimerRecipeId:timer_recipe_id];
        
        if([identifier isEqualToString:@"Show Recipe"])
        {
            open_from_notification=true;
            [self switchRootViewController];
            DLog(@"show recipe redirect");
        }
        else{
            [[NSUserDefaults standardUserDefaults]setObject:nil forKey:[NSString stringWithFormat:@"timerRecipeTitle_%@",timer_recipe_id]];
            [[NSUserDefaults standardUserDefaults]setObject:nil forKey:[NSString stringWithFormat:@"timerDescString_%@",timer_recipe_id]];
            [[NSUserDefaults standardUserDefaults]setObject:nil forKey:[NSString stringWithFormat:@"updated_timer_%@",timer_recipe_id]];
            [[NSUserDefaults standardUserDefaults]setObject:nil forKey:[NSString stringWithFormat:@"timer_%@",timer_recipe_id]];
            if([(theAppDelegate).Timer_recipeIdArr containsObject:timer_recipe_id])
            {
                [(theAppDelegate).Timer_recipeIdArr removeObject:timer_recipe_id];
            }
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"InvalidateTimer" object:nil];
            DLog(@"stop timer redirect");
        }
    }
    if(completionHandler != nil)    //Finally call completion handler if its not nil
        completionHandler();
}*/
/*
#pragma mark- Remove All Notification When App Remove From Background
-(void)RemoveAllNotificationWhenAppRemoveFromBackground
{
    if(Timer_recipeIdArr!=nil && Timer_recipeIdArr.count>0)
    {
        for(int i=0;i<Timer_recipeIdArr.count;i++)
        {
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timerRecipeTitle_%@",Timer_recipeIdArr[i]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timerDescString_%@",Timer_recipeIdArr[i]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"updated_timer_%@",Timer_recipeIdArr[i]]];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"timer_%@",Timer_recipeIdArr[i]]];
            //            [[NSUserDefaults standardUserDefaults]removeObjectForKey:[NSString stringWithFormat:@"uniqueTimerId_%@",Timer_recipeIdArr[i]]];
            
            NSData *data= [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"uniqueTimerId_%@",Timer_recipeIdArr[i]]];
            if(data!=nil)
            {
                UILocalNotification *localNotif = [NSKeyedUnarchiver unarchiveObjectWithData:data];
              //  DLog(@"Remove localnotification  are %@", localNotif);
                [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"uniqueTimerId_%@",Timer_recipeIdArr[i]]];
            }
            
            NSData *data1= [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"uniqueDismissTimerId_%@",Timer_recipeIdArr[i]]];
            if(data1!=nil)
            {
                UILocalNotification *localNotif1 = [NSKeyedUnarchiver unarchiveObjectWithData:data1];
               // DLog(@"Remove localnotification  are %@", localNotif1);
                [[UIApplication sharedApplication] cancelLocalNotification:localNotif1];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"uniqueDismissTimerId_%@",Timer_recipeIdArr[i]]];
            }
            
            
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"InvalidateTimer" object:nil];
        
    }
    [[UIApplication sharedApplication]cancelAllLocalNotifications];
    
}
*/

#pragma mark- Timer Finish
- (void)timerFinishForRecipe:(RecipeTimer *)recipe
{
    NSString *recipeDesc = recipe.recipeDesc;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@!",NSLocalizedString(@"Done",nil)] message:recipeDesc delegate:self cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil, nil]; //handle this in root or appdelate
    alert.tag=222;
    [alert show];

    //hear we need to assign the timeronrecipe to recipedetail controller
    if(self.currentRecipeDetailController)
    {
        if([self.currentRecipeDetailController respondsToSelector:@selector(removeTimerFinishedRecipe:)])
            [self.currentRecipeDetailController removeTimerFinishedRecipe:recipe];

        if ([self.currentRecipeDetailController isKindOfClass:[RecipeDetailViewController class]]) {
            RecipeDetailViewController *obj = (RecipeDetailViewController*)self.currentRecipeDetailController;
            if (obj.timerOnRecipes.count < 1) {
                [[WatchConnectivityController sharedInstance] hideTimerOptionInWatch];
            }

        }

    }
    else
    {
        //  NSInteger index = [self.timerOnRecipes indexOfObject:recipe];
        for(RecipeTimer *arecipe in self.ActiveTimerArr)
        {
            arecipe.tempSecondsLeft = arecipe.secondsLeft;
            [arecipe stopTimer];
        }

        [[WatchConnectivityController sharedInstance] updateTimerForRecipeID:recipe];

        [self.ActiveTimerArr removeObject:recipe];

        if (self.ActiveTimerArr.count < 1) {
            [[WatchConnectivityController sharedInstance] hideTimerOptionInWatch];
        }

        [self.ActiveTimerArr enumerateObjectsUsingBlock:^(RecipeTimer  *obj, NSUInteger idx, BOOL *stop) {
            obj.recipeTimerId = idx;
            obj.secondsLeft = obj.tempSecondsLeft;
            [obj startTimer];
        }];
    }
    
    [self PlayAudioToNotifyUser]; //hanlde sound hear insted of recipelist
    NSString *r_id=[NSString stringWithFormat:@"%ld",(long)recipe.recipeboxId];
    [Utility setTimerRecipeId:r_id];
    if(![(theAppDelegate).globalRecipeId isEqualToString:r_id])
    {
        (theAppDelegate).open_from_notification=true;
        [theAppDelegate switchRootViewController]; //after switching to detail screen
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTableViewData" object:nil];
    }
    
}
#pragma mak- play sound when recipe is runs out
-(void)PlayAudioToNotifyUser

{   NSError *error=nil,*sessionError = nil;
    NSString * soundFile = [[NSBundle mainBundle] pathForResource:@"notification_sound" ofType:@"mp3"];
    NSURL *fileURL = [NSURL fileURLWithPath:soundFile];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers
                                           error:&sessionError];
    if (sessionError) {
        NSLog(@"ERROR: setCategory %@", [sessionError localizedDescription]);
    }
    [[AVAudioSession sharedInstance] setActive: YES error: &error];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    self.playerAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    
    [[AVAudioSession sharedInstance] setActive: YES error: &error];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    self.playerAudio.numberOfLoops = -1;
    self.playerAudio.volume=1;
    if([self.playerAudio prepareToPlay])
    {
        [self.playerAudio play];
    }
}

#pragma mark- alertview delgate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Set buttonIndex == 1 to handel "Ok"/"Yes" button response
    
    if([self.playerAudio isPlaying])
        [self.playerAudio stop];
    
}
- (void)setCurrentRecipeDetailController:(id)currentRecipeDetailController
{
    
    _currentRecipeDetailController = currentRecipeDetailController;
    if(currentRecipeDetailController == nil)
        NSLog(@"********************currentRecipeDetailController is NIL ******************************************");//it should not be nil unless u  are navigate back to recipes detail controller
}

@end
