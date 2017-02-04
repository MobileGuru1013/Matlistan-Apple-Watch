//
//  AppDelegate.h
//  MatListan
//
//  Created by Yan Zhang on 03/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "Item.h"
#import "SyncManager.h"
#import "RecipeTimer.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>

#define theAppDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

#define PRODUCT_IDENTIFIER          @"com.consumiq.matlistan.premium_subscription.yearly"

#define MIXPANEL_TOKEN @"136dcdd2ed5b5c8490e7c99d11a5a8fc"

@interface AppDelegate : UIResponder <UIApplicationDelegate, SyncManagerDelegate>
{
    UIStoryboard *mainStoryBoard;
}
@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property  BOOL detailRecipeFlag;
@property(strong,nonatomic) UIImage *customImage; //Dimple 9-10-15
//@property(strong,nonatomic) UIImage *ItemscustomImage;
@property(strong,nonatomic) UIImage *RecipecustomImage;
@property(strong,nonatomic) UIImage *PlanRecipecustomImage;
//Dimple-26-11-2015
@property  BOOL no_fav_item_flag;
@property  BOOL is_random;
@property  BOOL is_scan_start;
@property  BOOL add_success;
//@property (strong,nonatomic) NSManagedObjectID *barcode_itemObjectId;
//@property (strong,nonatomic) Item *barcode_item;
//@property (strong,nonatomic) NSNumber *barcode_itemId;
@property (strong,nonatomic) NSDictionary *storeDict;
@property  BOOL multiple_edit;
@property  BOOL speakAgain_flag;
@property  BOOL AddViaVoice;
@property  BOOL voice_not_found;
@property  BOOL isNewRecipeAdded;
@property  BOOL gotoSettingFromSearchShops;
@property  BOOL isShopsTableviewController;

@property (strong,nonatomic) NSArray *voiceResult;
//@property  BOOL open_from_notification;
@property (strong, nonatomic) NSMutableArray *Timer_recipeIdArr;

@property (strong,nonatomic) void (^backgroundFetchCompletionHandler)(UIBackgroundFetchResult);

-(void)switchRootViewController;
-(void)switchToLoginViewController;

//10-3-16
@property  BOOL open_from_notification;
@property(strong,nonatomic) NSMutableArray *ActiveTimerArr;
@property (weak, nonatomic) id currentRecipeDetailController;
@property(strong,nonatomic) AVAudioPlayer *playerAudio;

@property(strong,nonatomic) NSString *globalRecipeId;
@property BOOL open_from_recipeList;
@end
