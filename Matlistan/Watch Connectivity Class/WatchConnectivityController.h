//
//  WatchConnectivityController.h
//  Matlistan
//
//  Created by Moon Technolabs on 09/07/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import "DataStore.h"
#import "SyncManager.h"
#import "Mixpanel.h"
#import "MatlistanHTTPClient.h"
#import "Store+Extra.h"
#import "ItemListsSorting+Extra.h"
#import "Item_list+Extra.h"
#import "ItemsCheckedStatus+Extra.h"
#import "Item+Extra.h"
#import "SortingSyncManager.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>

@interface WatchConnectivityController : NSObject<WCSessionDelegate, SortingSyncManagerDelegate, CLLocationManagerDelegate>
{
    NSManagedObjectID *lastAddedItemID;
}

+ (WatchConnectivityController*)sharedInstance;
-(void)CreateAndActivateSession;
-(void)changeShoppingList;
-(void)sortingSyncFinished:(BOOL)withError;
-(void)showTimerOptionInWatch;
-(void)hideTimerOptionInWatch;
-(void)stopTimerForRecipeID:(NSInteger)recipeID;
-(void)updateTimerForRecipeID:(RecipeTimer*)obj;
//-(void)startTimerForRecipeID:(RecipeTimer*)obj;

@end
