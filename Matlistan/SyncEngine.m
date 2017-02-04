//
//  SyncEngine.m
//  MatListan
//
//  Created by Yan Zhang on 31/08/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "SyncEngine.h"
#import "JSONResponseSerializerWithData.h"
#import "DataStore.h"
#import "EndpointHash+Extra.h"
#import "Item+Extra.h"
#import "Active_recipe+Extra.h"
#import "Recipebox+Extra.h"
#import "Store+Extra.h"
#import "Item_list+Extra.h"
#import "ItemsCheckedStatus+Extra.h"
#import "FavoriteItem.h"

//static NSString * const matlistanServerURLString = @"http://api2.matlistan.se/";//Old API
//static NSString * const matlistanServerURLString = @"http://api.test.matlistan.se";//New API

@interface SyncEngine()

@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;
@property (nonatomic)double idleTimeStamp;
@property (nonatomic,retain)NSMutableDictionary *latestHashDictionary;
@property (nonatomic,retain)NSMutableDictionary *oldHashDictionary;
@property (nonatomic,strong)NSManagedObjectContext *masterContext;
@property (nonatomic, strong) dispatch_queue_t backgroundSyncQueue;

@end

@implementation SyncEngine

@synthesize registeredClassesToSync= _registeredClassesToSync;
@synthesize latestHashDictionary,oldHashDictionary,masterContext;

//to access the Singleton’s instance.

+ (SyncEngine *)sharedEngine {
    static SyncEngine *sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedEngine = [[self alloc]initWithBaseURL:[NSURL URLWithString:[Utility getMatlistanServerURLString]]];
        sharedEngine.responseSerializer = [JSONResponseSerializerWithData serializer];
        
    });
    
    return sharedEngine;
}
- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        
    }
    
    return self;
}
-(void)startSync{
    /*
    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        
        self.backgroundSyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);    //DISPATCH_QUEUE_PRIORITY_BACKGROUND
        
        dispatch_async(self.backgroundSyncQueue, ^{
            
            //[self getItemsFromServer];   //get all items from the server for the 1st time

            while (_syncInProgress) {
                DLog(@"start sync");
                [self sendUpdatesToServer];
                [self sendDeletesToServer];
                [self sendInsertsToServer];
                [self downloadUpdatesFromServer];

                //test--
                //[self getVisitFromServerForList:[NSNumber numberWithInt:1783]];
                //---
                [NSThread sleepForTimeInterval:10];
            }
            [[NSNotificationCenter defaultCenter]postNotificationName:@"SyncStopped" object:nil];
        });
    }
     */
    
}

-(void)stopSync{
    [self willChangeValueForKey:@"syncInProgress"];
    _syncInProgress = NO;
    [self didChangeValueForKey:@"syncInProgress"];
    
}

#pragma mark - send updates to server
-(void)sendUpdatesToServer{
    //1. send edits from Item table
    [self sendItemUpdates];   //tested, work
    //2. send update for default item list, send directly instead
   // [self sendItemListDefaultUpdates];
    //3. send updates for item list orders
    [self sendItemListOrderUpdates]; //this is always missed. So send it also directly after changing order
    //4. send edits from Store table
    [self sendStoreUpdates];  //tested, work
    //5.
    [self sendActiveRecipeUpdates];
    //6.
    [self sendRecipeUpdates];
    //7. update item checked status
    [self sendItemCheckedStatusUpdates];
    
}
-(void)sendItemUpdates {
    // Let's not do changes if we have delete calls pending
    if (![self checkForPendingDeletes]) {
        // TODO this should check for multiple statuses for one item, we don't want to send old changes
        NSArray *changedItems = [Item getAllItemsByStatus:Updated];
        DLog(@"Send %lu item updates", (unsigned long) changedItems.count);
        for (Item *item in changedItems) {
            if (item == nil || item.itemID.intValue == 0) {
                continue;
            }
            NSString *request = [NSString stringWithFormat:@"Items/%@", item.itemID];
            NSString *text = [Utility isStringEmpty:item.text] ? @"" : item.text;
            NSString *matchingItemText = [Utility isStringEmpty:item.matchingItemText] ? @"" : item.matchingItemText;

            DLog(@"Item: Text: %@,isPermanent:%@,matchingItem:%@,isDefaultMatch:%@", item.text, item.isPermanent, item.matchingItemText, item.isDefaultMatch);
            NSDictionary *parameters = @{@"text" : text,
                    @"isPermanent" : item.isPermanent,
                    @"matchingItem" : matchingItemText,
                    @"isDefaultMatch" : item.isDefaultMatch
            };

            [self PUT:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                DLog(@"Changed item %@", item.text);
                //Reset status locally in core data to synced
                [Item changeSyncStatus:Synced for:item.itemID];

            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                DLog(@"Fail to send changed item %@", request);
            }];

        }
    }
}

-(void)sendItemListOrderUpdates{
    // TODO this should check for multiple order for one item, we don't want to send old changes
    
    NSArray *allLists = [Item_list getAllLists];
    for (Item_list *list in allLists) {
        if ([list.syncStatus intValue] != Updated) {
            continue;
        }
        DLog(@"Send item list order update");

        NSString *request = [NSString stringWithFormat:@"ItemLists/%@/SortOrder", list.item_listID];
        NSDictionary *parameters = [[NSDictionary alloc]init];

        parameters = @{@"sortOrder":list.sortOrder};
        if ([list.sortOrder isEqualToString:@"Store"] && list.sortByStoreId != nil) {
            parameters = @{@"sortOrder":list.sortOrder,
                           @"storeId": list.sortByStoreId
                           };
        }
        
        [self PUT:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            DLog(@"Changed %@ sort order to %@, store %@",list.name,list.sortOrder, list.sortByStoreId);
            [Item_list changeSyncStatusFor:list];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Fail to change sort order %@",request);
        }];
    }
}


-(void)sendItemListDefaultUpdates{
    
    Item_list *defaultList = [Item_list getUpdatedDefaultList];
    if (defaultList == nil) {
        return;
    }
    NSString *request = [NSString stringWithFormat:@"ItemLists/%@", defaultList.item_listID];
    NSDictionary *parameters = @{@"isDefault": [NSNumber numberWithBool:YES]};
    [self PUT:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject){
        [Item_list changeSyncStatusFor:defaultList];
        DLog(@"Changed default list %@",defaultList.name);
    }failure:^(NSURLSessionDataTask *task, id responseObject){
        DLog(@"Fail to send changed default list %@",request);
    }];
}


/*This is called by ItemsViewController.m
 SortType:
 DATE,
 DEFAULT,
 MANUAL,
 GROUPED,
 STORE,
 UNKNOWN
 */
-(void)sendItemListOrderUpdate:(NSNumber*)listID andSortOrder:(SORT_TYPE)sortType andStoreID:(NSNumber*)storeID{
    if (sortType == STORE && storeID == nil) {
        return;
    }
    NSArray *sortTypeNames = @[@"Date",@"Default",@"Manual",@"Grouped",@"Store",@"Unknown"];
    NSString *sortName = sortTypeNames[sortType];
    
    DLog(@"Send item list order update");
    id storeIDParam = (storeID == nil)? [NSNull null]:storeID;
    NSString *request = [NSString stringWithFormat:@"ItemLists/%@/SortOrder", listID];
    NSDictionary *parameters = @{@"sortOrder":sortName,
                                 @"storeId": storeIDParam
                                 };
    
    [self PUT:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        DLog(@"Changed sort order %@",storeID);
        [Item_list changeSyncStatusFor:[Item_list getListById:listID]];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to change sort order %@",request);
    }];
}

-(void)sendItemCheckedStatusUpdates{
    
    NSArray *itemsStatusList = [ItemsCheckedStatus getAllItemsCheckedStatus];
    
    DLog(@"Send item %lu checked status updates", (unsigned long)itemsStatusList.count);
    for (ItemsCheckedStatus *itemStatus in itemsStatusList) {
        if (itemStatus == nil || itemStatus.itemID == nil || itemStatus.itemID.intValue == 0) {
            DLog(@"ItemsStatus has invalid itemID 0");
            [ItemsCheckedStatus deleteItemsStatusWithObjectID:itemStatus.objectID];

            continue;
        }
        Item *relatedItem = nil;//[Item getItemByObjectIDInString:itemStatus.itemObjectID]; //[Item getItemInList:itemStatus.listID withItemID:itemStatus.itemID];
        if (relatedItem == nil || [relatedItem.syncStatus intValue] ==  Deleted) {
            
            [ItemsCheckedStatus deleteItemsStatusWithObjectID:itemStatus.objectID];
            DLog(@"Not sending check status because the item is invalid now");
            continue; //  if the item is deleted or does't exist, don't send request
        }
        /*
        //Visit *visit = [Visit getVisitByList:itemStatus.listID];
        //__block NSNumber* timeDiff = visit.time_diff;
        if(timeDiff.intValue == INT32_MIN){
            
            NSString *request = [NSString stringWithFormat:@"Visits/Current/%@", itemStatus.listID];
            [self GET:request parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                NSDictionary *visitFromServer = (NSDictionary*)responseObject;
                DLog(@"Get visits from server %@",responseObject);
                timeDiff = [visitFromServer objectForKey:@"secondsAfterStart"];
                //[Visit updateVisitTimeDiff:timeDiff forList:itemStatus.listID];
                [self sendCheckedStatus:itemStatus andTimeDiff:timeDiff];
                
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                DLog(@"Fail to get visit from server");
                timeDiff = @0;
                //[Visit updateVisitTimeDiff:timeDiff forList:itemStatus.listID];
                [self sendCheckedStatus:itemStatus andTimeDiff:timeDiff];
            }];
        }
        else{
            [self sendCheckedStatus:itemStatus andTimeDiff:timeDiff];
        }
         */
    }
}


-(void)sendCheckedStatus:(ItemsCheckedStatus*)itemStatus andTimeDiff:(NSNumber*)timeDiff{
    
    DLog(@"Send checked status");
    if (itemStatus == nil) {
        DLog(@"ItemsCheckedStatus is nil for %@", itemStatus.itemID);
        return;
    }
   
    NSNumber *newSecondsAfterStart = [NSNumber numberWithInt: (itemStatus.secondsAfterStart.intValue + timeDiff.intValue)];
    NSDictionary *parameters;
    //These if statements could be cleaned up later with a NSMutableDictionary or something
    if (itemStatus.latitude == [NSNumber numberWithInt:0] && itemStatus.longitude == [NSNumber numberWithInt:0]) {
        parameters = @{@"deviceId": itemStatus.deviceId,
                @"isChecked": itemStatus.isChecked,
                @"checkedReason":itemStatus.checkedReason,
                @"secondsAfterStart":newSecondsAfterStart,
                @"positionAccuracy":itemStatus.positionAccuracy
        };
    } else {
        parameters = @{@"deviceId": itemStatus.deviceId,
                @"isChecked": itemStatus.isChecked,
                @"checkedReason":itemStatus.checkedReason,
                @"secondsAfterStart":newSecondsAfterStart,
                @"latitude": itemStatus.latitude,
                @"longitude":itemStatus.longitude,
                @"positionAccuracy":itemStatus.positionAccuracy
        };
    }
    NSString *request =  [NSString stringWithFormat:@"Items/%@/Checked", itemStatus.itemID];
    if (![itemStatus.isTaken boolValue] && ![itemStatus.isChecked boolValue]) {
        //regret checked and taken, don't send checked reason
        DLog(@"uncheck item");

        if (itemStatus.latitude == [NSNumber numberWithInt:0] && itemStatus.longitude == [NSNumber numberWithInt:0]) {
            parameters = @{@"deviceId" : itemStatus.deviceId,
                    @"isChecked" : itemStatus.isChecked,
                    @"secondsAfterStart" : newSecondsAfterStart,
                    @"positionAccuracy" : itemStatus.positionAccuracy
            };
        } else {
            parameters = @{@"deviceId" : itemStatus.deviceId,
                    @"isChecked" : itemStatus.isChecked,
                    @"secondsAfterStart" : newSecondsAfterStart,
                    @"latitude" : itemStatus.latitude,
                    @"longitude" : itemStatus.longitude,
                    @"positionAccuracy" : itemStatus.positionAccuracy
            };
        }
    }
    
    if (itemStatus.positionAccuracy == nil || [itemStatus.positionAccuracy intValue] == 0) {
        NSMutableDictionary *allParameters = [[NSMutableDictionary alloc]initWithDictionary:parameters];
        [allParameters removeObjectForKey:@"positionAccuracy"];
        parameters = [NSDictionary dictionaryWithDictionary:allParameters];
    }
    [self PUT:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [ItemsCheckedStatus deleteItemsStatusWithObjectID:itemStatus.objectID];
        DLog(@"Sent item checked status: %@",itemStatus.itemID);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSString *info = [error.userInfo objectForKey:@"NSLocalizedDescription"];
        if([Utility containsSubstring:@"400" inString:info]){
            [ItemsCheckedStatus deleteItemsStatusWithObjectID:itemStatus.objectID]; //Remove the wrong checked status request which causes 400 error from server.
            DLog(@"Wrong input for: %@",itemStatus.itemID);
        }
        DLog(@"Fail to send item checked status: %@, error:%@",request, error.description);
    }];

}

// TODO this is not used getVisitFromServerForList - Markus
-(void)getVisitFromServerForList:(NSNumber*)listID{

    NSString *request = [NSString stringWithFormat:@"Visits/Current/%@", listID];
    [self GET:request parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        DLog(@"Get visits from server %@",responseObject);

    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to get visit from server");
    }];
}

-(void)sendStoreUpdates{

    // TODO this should check for multiple statuses for one item, we don't want to send old changes
    NSArray *changedItems = [Store getAllStoresByStatus:Updated];
    
    DLog(@"Send %lu store updates", (unsigned long)changedItems.count);
    for (Store *store in changedItems) {
        NSString *request = [NSString stringWithFormat:@"Stores/%@", store.storeID];
        NSDictionary *parameters = @{@"isFavorite": store.isFavorite};
        [self PATCH:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            DLog(@"Changed store %@",store.name);
            [Store changeSyncStatus:Synced for:store.storeID];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Fail to send changed store %@",request);
        }];
    }
}
-(void)sendActiveRecipeUpdates{
    // TODO this should check for multiple statuses for one item, we don't want to send old changes
    NSArray *changedItems = [Active_recipe getAllActiveRecipesByStatus:Updated];
    
    DLog(@"Send %lu ActiveRecipe updates", (unsigned long)changedItems.count);
    for (Active_recipe *item in changedItems) {
        if (item == nil || item.active_recipeID.intValue == 0) {
            continue;
        }
        NSString *request = [NSString stringWithFormat:@"ActiveRecipes/%@", item.active_recipeID];
        NSDictionary *parameters = @{@"isCooked": @NO,
                                     @"isPurchased": item.isPurchased};
        [self PATCH:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            DLog(@"Changed active recipe %@", item.active_recipeID);
            [Active_recipe changeSyncStatus:Synced forObjectID:item.objectID];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Fail to send changed store %@",request);
        }];
    }
}


-(void)sendRecipeUpdates{
    // TODO this should check for multiple statuses for one item, we don't want to send old changes
    NSArray *changedRecipes = [Recipebox getAllRecipesByStatus:Updated];
    DLog(@"Send %lu recipe updates", (unsigned long)changedRecipes.count);
    for (Recipebox *recipe in changedRecipes) {
        NSString *request = [NSString stringWithFormat:@"RecipeBox/%@",recipe.recipeboxID];
        NSDictionary *parameters = @{@"rating": recipe.rating,
                                     @"cookTime": recipe.cookTime};
        [self PATCH:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            DLog(@"Changed recipe %@", recipe.title);
            [Recipebox changeSyncStatus:Synced forObjectID:recipe.objectID];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Fail to send changed recipe %@",request);
        }];
    }
}
#pragma mark - send records to be deleted to server
-(void)sendDeletesToServer{
    //Send deletes in Item table
    DLog(@"Sending deletes to server...");
    [self sendItemDeletes];
    [self sendItemListDeletes];
    [self sendRecipeBoxDeletes];
    [self sendActiveRecipeDeletes];
}

-(bool)checkForPendingDeletes{
    NSArray *toDeleteItems = [Item getAllItemsFakeDeletedInList];
    NSArray *toDeleteItems2 = [Item_list getAllFakeDeletedLists];
    NSArray *toDeleteItems3 = [Recipebox getAllRecipesFakeDeleted];
    NSArray *toDeleteItems4 = [Active_recipe getAllActiveRecipesFakeDeleted];
    if (toDeleteItems.count > 0 || toDeleteItems2.count > 0 || toDeleteItems3.count > 0 || toDeleteItems4.count > 0) {
        return TRUE;
    }
    return FALSE;
}

/**
 Send the items to be deleted
 */
-(void)sendItemDeletes{
    NSArray *toDeleteItems = [Item getAllItemsFakeDeletedInList];
    
    DLog(@"To delete items %lu ",(unsigned long)toDeleteItems.count);
    for (Item *toDeleteItem in toDeleteItems) {
        if ([toDeleteItem.itemID intValue] == 0) {
            DLog(@"Item was added locally and should not be deleted");
            //continue;   //there are items that are added locally and with itemID 0, these should not be sent to the server.
        }
        NSString *request = [NSString stringWithFormat:@"Items/%@",toDeleteItem.itemID];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [self DELETE:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            DLog(@"Deleted item %@",request);
            //Delete locally in core data for real
            [Item realDelete];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSString *errorInfo = [error.userInfo objectForKey:@"NSLocalizedDescription"];
            if ([Utility containsSubstring:@"404" inString:errorInfo]) {
                //Delete locally in core data for real
                [Item realDelete];
            }
            DLog(@"Fail to delete item %@, reason: %@",request, errorInfo);
        }];
    }
}
-(void)sendItemListDeletes{
    NSArray *toDeleteItems = [Item_list getAllFakeDeletedLists];

    DLog(@"To delete lists %lu ",(unsigned long)toDeleteItems.count);
    for (Item_list *toDeleteItem in toDeleteItems) {
        NSString *request = [NSString stringWithFormat:@"ItemLists/%@",toDeleteItem.item_listID];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [self DELETE:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            DLog(@"Deleted item list %@",request);
            //Delete locally in core data for real
           [Item_list realDelete];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Fail to delete list %@",request);
            NSString *errorInfo = [error.userInfo objectForKey:@"NSLocalizedDescription"];
            if ([Utility containsSubstring:@"404" inString:errorInfo]) {
                //Delete locally in core data for real
                [Item_list realDelete];
            }
        }];
    }
}

-(void)sendRecipeBoxDeletes{
    NSArray *toDeleteItems = [Recipebox getAllRecipesFakeDeleted];

    DLog(@"To delete recipe %lu ",(unsigned long)toDeleteItems.count);
    for (Recipebox *toDeleteItem in toDeleteItems) {
        NSString *request = [NSString stringWithFormat:@"RecipeBox/%@",toDeleteItem.recipeboxID];
        DLog(@"Request: %@",request);
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [self DELETE:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            DLog(@"Deleted recipe %@",request);
            //Delete locally in core data for real
            [Recipebox realDelete];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Fail to delete recipe %@",request);
            NSString *errorInfo = [error.userInfo objectForKey:@"NSLocalizedDescription"];
            if ([Utility containsSubstring:@"404" inString:errorInfo]) {
                //Delete locally in core data for real
                [Recipebox realDelete];
            }
        }];
    }
}
-(void)sendActiveRecipeDeletes{
    NSArray *toDeleteItems = [Active_recipe getAllActiveRecipesFakeDeleted];
    DLog(@"To delete recipe %lu ",(unsigned long)toDeleteItems.count);
    for (Active_recipe *toDeleteItem in toDeleteItems) {
        if ([toDeleteItem.active_recipeID intValue] == 0) {
            continue;
        }
        NSString *request = [NSString stringWithFormat:@"ActiveRecipes/%@",toDeleteItem.active_recipeID];
        DLog(@"Request: %@",request);
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [self DELETE:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            DLog(@"Deleted active recipe %@",request);
            //Delete locally in core data for real
            [Active_recipe realDelete];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Fail to delete ActiveRecipe %@",request);
            NSString *errorInfo = [error.userInfo objectForKey:@"NSLocalizedDescription"];
            if ([Utility containsSubstring:@"404" inString:errorInfo]) {
                //Delete locally in core data for real
                [Active_recipe realDelete];
            }
        }];
    }
}

#pragma mark - send inserts to server
-(void)sendInsertsToServer{

    [self sendInsertItem];
    [self sendInsertActiveRecipe];
    [self sendInsertItemList];
}
-(void)sendInsertActiveRecipe{
    NSArray *recipes = [Active_recipe getAllActiveRecipesByStatus:Created];
    DLog(@"Send insert %lu active recipe", (unsigned long)recipes.count);
    
    for (Active_recipe *recipe in recipes) {
        NSManagedObjectID *recipeObjectID = recipe.objectID;
        NSArray *ingredients = [Ingredient getIngredientsOfRecipeID:recipe.recipeID];
        NSMutableArray *ingredientList = [[NSMutableArray alloc]init];
        for (Ingredient *ingredient in ingredients) {
            NSString *matchText = ingredient.possibleMatchText == nil? ingredient.text:ingredient.possibleMatchText;
            if (ingredient.isSelected != nil && [ingredient.isSelected boolValue] == YES) {

                NSDictionary *dict = @{@"text":ingredient.text,
                                       @"isSelected":ingredient.isSelected,
                                       @"possibleMatchText":matchText
                                       };

                [ingredientList addObject:dict];
            }
        }

        NSString *request = @"ActiveRecipes";
        
        NSDictionary *parameters = [[NSDictionary alloc]init];
        
        if (ingredientList.count > 0) {
            parameters = @{@"recipeId": recipe.recipeID,
                           @"portions": recipe.portions,
                           @"itemListId":recipe.listID,
                           @"ingredients":ingredientList,
                           @"occasion": recipe.occasion,
                           @"notes":recipe.notes
                           };
        }
        else{
            parameters = @{@"recipeId": recipe.recipeID,
                           @"portions": recipe.portions,
                           @"itemListId":recipe.listID,
                           @"occasion": recipe.occasion,
                           @"notes":recipe.notes
                           };
        }
        
        [self POST:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            [Active_recipe changeSyncStatus:Synced forObjectID:recipeObjectID];
            [Active_recipe cleanDuplicatedRecipes];
            DLog(@"Sent active recipe: %@", recipe.recipeID);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            
            DLog(@"Fail to send active recipe: %@",error.description);
        }];
        

    }
}

-(void)sendInsertItem{
    NSArray *items = [Item getAllItemsByStatus:Created];
    if (items == nil || items.count == 0) {
        return;
    }
    
    DLog(@"Send insert %lu items", (unsigned long)items.count);
    
    for (Item *item in items) {
        if (item == nil || item.listId == nil || [item.listId integerValue] == 0 ) {
            continue;
        }
        NSManagedObjectID *objID = item.objectID;
        NSString *request =  [NSString stringWithFormat:@"Items"];
        NSString *barcode = item.barcode == nil? @"":item.barcode;
        NSString *barcodeType = item.barcodeType == nil? @"":item.barcodeType;
        NSDictionary *parameters = @{@"text": item.text,
                                     @"barcode": barcode,
                                     @"barcodeType":barcodeType,
                                     @"listId":item.listId,
                                     @"addedAt": item.addedAt,
                                     @"source": item.source
                                     };

        DLog(@"Insert items sum: %lu, parameters %@", (unsigned long)items.count,parameters);
        [self POST:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

            [Item updateItem:responseObject forItemWithID:objID];
            
            DLog(@"Success to send new item : %@ for %@",request, item.text);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            
            DLog(@"Fail to send new item : %@",request);
        }];
        
    }
    
}
-(void)sendInsertItemList{
    NSArray *lists = [Item_list getNewLists];
    if (lists == nil || lists.count == 0) {
        return;
    }
    
    DLog(@"Send insert %lu item lists", (unsigned long)lists.count);
    for (Item_list *list in lists) {
        if (list == nil) {
            continue;
        }
        NSManagedObjectID *objID = list.objectID;
        NSString *request =  [NSString stringWithFormat:@"ItemLists"];
        NSDictionary *parameters = @{@"name": list.name
                                     };
        [self POST:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            [Item_list updateListFromServer:responseObject ByObjectID:objID];
            DLog(@"Success to send new list");
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
             DLog(@"Fail to send new item : %@",request);
        
        }];
        
    }
    
}

#pragma mark - Download updates from the server
-(void)downloadUpdatesFromServer{
    //Get timestamp
    [DataStore instance].timestampForSync = [[NSDate date] timeIntervalSince1970];
    DLog(@"timestamp %ld",[DataStore instance].timestampForSync);
    
    //Download updates from server
    [self pollForChangesOnWebServer];
}


/*
 poll for changes using a hash code instead of transferring and comparing the full data.
 GET Request: "http://api2.matlistan.se/" on the the root (/) endpoint.
 
 */
-(void)pollForChangesOnWebServer{
        [self GET:@"" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                        
            NSDictionary *hashes = (NSDictionary *) responseObject;
            latestHashDictionary = [[NSMutableDictionary alloc] initWithDictionary:hashes];
            NSDictionary *recipeBoxIndicators = [latestHashDictionary objectForKey:@"recipeBoxIndicators"];
            long count = [[recipeBoxIndicators objectForKey:@"count"] longValue];
            NSString *timeStamp = [recipeBoxIndicators objectForKey:@"updatedAt"];

            EndpointHash *savedHashes = [EndpointHash MR_findFirst];

            if ([savedHashes.activeRecipesHash longValue] != [[latestHashDictionary objectForKey:@"activeRecipesHash"] longValue]) {
                [self getActiveRecipesFromServer];  //need to update activeRecipe
            }
            if ([savedHashes.itemListsHash longValue] != [[latestHashDictionary objectForKey:@"itemListsHash"] longValue]) {
                [self getItemListsFromServer];  //need to update itemListsHash
            }
            if ([savedHashes.itemsHash longValue] != [[latestHashDictionary objectForKey:@"itemsHash"] longValue]) {
                [self getItemsFromServer];  //need to update itemsHash
            }
            if ([savedHashes.recipeCount longValue] != count || ![savedHashes.recipeUpdatedAt isEqualToString:timeStamp]) {
                [self getRecipesFromServer];    //need to update recipes
            }
            if ([savedHashes.storesHash longValue] != [[latestHashDictionary objectForKey:@"storesHash"] longValue]) {
                [self getStoresFromServer]; //need to update storesHash
            }

            [EndpointHash updateItems:latestHashDictionary];
            //TO DO: add favorite items?
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Fail to get hash %@", [error description]);
        }];
}


-(void)getItemsFromServer{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"format"] = @"json";
    
    [self GET:@"Items" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        
        
        DLog(@"Get %lu items from server",(unsigned long)[responseObject count]);
        //TODO this should check to make sure all updates have been sent before taking updates.
        [Item insertItems:responseObject];
        
        if ([self.delegate respondsToSelector:@selector(SyncEngine:didUpdateItems:)]) {
            [self.delegate SyncEngine:self didUpdateItems:responseObject];
            
        }

        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to getItemsFromServer");
    }];
    
}
-(void)getActiveRecipesFromServer{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"format"] = @"json";
    
    [self GET:@"ActiveRecipes" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        DLog(@"Get %lu active recipes from server", (unsigned long)[responseObject count]);
        [Active_recipe insertItems:responseObject];

    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to getActiveRecipesFromServer");
    }];
    
}
-(void)getRecipesFromServer{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"format"] = @"json";
    __block NSArray *itemArray;
    [self GET:@"RecipeBox" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *allItems = (NSDictionary*)responseObject;
        itemArray = [allItems objectForKey:@"list"];
        DLog(@"Get %lu recipes from server", (unsigned long)[itemArray count]);
        //if not exist in the database, download from the server
        for (NSDictionary *dict in itemArray) {
            NSNumber *recipeID = (NSNumber*)[dict valueForKey:@"id"];
            [self getRecipeFromServerByID:recipeID];
        }

        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to getRecipesFromServer");
    }];
    
}

-(void)getRecipeFromServerByID:(NSNumber*)recipeId{
    NSString *recipeID = [NSString stringWithFormat:@"%@",recipeId];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"format"] = @"json";
    
    NSString *partialURL = [NSString stringWithFormat:@"RecipeBox/%@",recipeID];
    
    [self GET:partialURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [Recipebox insertItems:responseObject];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to getRecipeFromServerByID");
    }];
}


-(void)getStoresFromServer{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"format"] = @"json";
    
    [self GET:@"Stores" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [Store insertStores:responseObject];
        DLog(@"Get %lu stores from server",(unsigned long)[responseObject count]);
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to getStoresFromServer");
    }];
}

-(void)searchStoresFromServer:(NSString*)query withLatitude:(NSNumber*)latitude andLongitude:(NSNumber*)longitude{
    NSDictionary *parameters;
    if (latitude == [NSNumber numberWithInt:0] && longitude == [NSNumber numberWithInt:0]) {
        parameters = @{@"query": query};
    } else {
        parameters = @{@"query": query,
                @"lat": latitude,
                @"long":longitude
        };
    }
    
    [self GET:@"StoreSearch" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [Store insertSearchedStores:responseObject];
        
        DLog(@"Get stores from server %@",responseObject);
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to search stores");
    }];
}

-(void)getItemListsFromServer{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"format"] = @"json";
    
    [self GET:@"ItemLists" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [Item_list insertItems:responseObject];
        DLog(@"Get %lu item lists from server",(unsigned long)[responseObject count]);

    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to get item lists");
    }];
}



@end
