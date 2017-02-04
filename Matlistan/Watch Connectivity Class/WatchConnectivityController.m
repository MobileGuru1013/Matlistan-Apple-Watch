//
//  WatchConnectivityController.m
//  Matlistan
//
//  Created by Moon Technolabs on 09/07/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

#import "WatchConnectivityController.h"
#import "Store+Extra.h"

@implementation WatchConnectivityController
{
    NSNumber *currentListId;
    NSManagedObjectID *currentListObjectId;

    //BOOl
    BOOL getResponce;

    CLLocationManager *locationManager;
    CLLocation *currentLocation;
}

#pragma mark -
+ (WatchConnectivityController*)sharedInstance
{
    static dispatch_once_t pred;
    static WatchConnectivityController *watchConnectionObject = nil;

    dispatch_once(&pred, ^{
        watchConnectionObject = [[WatchConnectivityController alloc] init];
        [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Model.sqlite"];   //create core data with MagicalRecord
        [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelError];
        if ([Utility getDefaultBoolAtKey:@"authorized"]){
            [[SyncManager sharedManager] startSync];
        }
    });

    return watchConnectionObject;
}

-(void)CreateAndActivateSession
{
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
}

#pragma mark - iPhoneToWatch Sync

-(void)changeShoppingList{

    if ([WCSession isSupported]) {
        @try {
            WCSession *session = [WCSession defaultSession];
            NSString *selectedItemName = [DataStore instance].currentList.name;

            while (!selectedItemName) {
                selectedItemName = [DataStore instance].currentList.name;
                [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
            }

            NSString * selectedItemID = [NSString stringWithFormat:@"%@",[DataStore instance].currentList.item_listID];

            NSDictionary *responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:selectedItemID,@"SELECTED_ITEM_ID",selectedItemName,@"SELECTED_ITEM",@"1",@"AUTHORIZED", nil];
            [session updateApplicationContext:responseDict error:nil];
        } @catch (NSException *exception) {
            NSLog(@"Updating the context failed: %@", exception);
        }
    }
}


-(void)showTimerOptionInWatch{
    if ([WCSession isSupported]) {
        @try {
            WCSession *session = [WCSession defaultSession];

            NSMutableArray *recipeArr = [NSMutableArray new];

            [theAppDelegate.ActiveTimerArr enumerateObjectsUsingBlock:^(RecipeTimer  *obj, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *dic = [NSMutableDictionary new];
                [dic setObject:[NSString stringWithFormat:@"%ld",obj.recipeboxId] forKey:@"recipeboxId"];
                [dic setObject:[NSString stringWithFormat:@"%ld",obj.recipeTimerId] forKey:@"recipeTimerId"];
                [dic setObject:[NSString stringWithFormat:@"%@",obj.recipeName] forKey:@"recipeName"];
                [dic setObject:[NSString stringWithFormat:@"%@",obj.recipeDesc] forKey:@"recipeDesc"];
                [dic setObject:[NSString stringWithFormat:@"%@",obj.countTimer] forKey:@"countTimer"];
                [dic setObject:[NSString stringWithFormat:@"%d",obj.seconds] forKey:@"seconds"];
                [dic setObject:[NSString stringWithFormat:@"%d",obj.hours] forKey:@"hours"];
                [dic setObject:[NSString stringWithFormat:@"%d",obj.minutes] forKey:@"minutes"];
                [dic setObject:[NSString stringWithFormat:@"%f",obj.secondsLeft] forKey:@"secondsLeft"];
                [dic setObject:[NSDate date] forKey:@"date"];
                [dic setObject:obj.startDate forKey:@"start_date"];
                [recipeArr addObject:dic];

            }];

            NSDictionary *responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"SHOW_TIMER",recipeArr,@"TIMER_ARR", nil];

            [session updateApplicationContext:responseDict error:nil];
        } @catch (NSException *exception) {
            NSLog(@"Updating the context failed: %@", exception);
        }
    }
}

-(void)hideTimerOptionInWatch{
    if ([WCSession isSupported]) {
        @try {
            WCSession *session = [WCSession defaultSession];

            NSDictionary *responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"SHOW_TIMER", nil];
            [session updateApplicationContext:responseDict error:nil];
        } @catch (NSException *exception) {
            NSLog(@"Updating the context failed: %@", exception);
        }
    }
}

-(void)stopTimerForRecipeID:(NSInteger)recipeID{
    if ([WCSession isSupported]) {
        @try {
            WCSession *session = [WCSession defaultSession];

            NSDictionary *responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",recipeID],@"STOP_TIMER_ID", nil];
            [session updateApplicationContext:responseDict error:nil];
        } @catch (NSException *exception) {
            NSLog(@"Updating the context failed: %@", exception);
        }
    }
}

-(void)updateTimerForRecipeID:(RecipeTimer*)obj{

    if ([WCSession isSupported]) {
        @try {
            WCSession *session = [WCSession defaultSession];

            NSMutableDictionary *dic = [NSMutableDictionary new];
            [dic setObject:[NSString stringWithFormat:@"%ld",obj.recipeboxId] forKey:@"recipeboxId"];
            [dic setObject:[NSString stringWithFormat:@"%ld",obj.recipeTimerId] forKey:@"recipeTimerId"];
            [dic setObject:[NSString stringWithFormat:@"%@",obj.recipeName] forKey:@"recipeName"];
            [dic setObject:[NSString stringWithFormat:@"%@",obj.recipeDesc] forKey:@"recipeDesc"];
            [dic setObject:[NSString stringWithFormat:@"%@",obj.countTimer] forKey:@"countTimer"];
            [dic setObject:[NSString stringWithFormat:@"%d",obj.seconds] forKey:@"seconds"];
            [dic setObject:[NSString stringWithFormat:@"%d",obj.hours] forKey:@"hours"];
            [dic setObject:[NSString stringWithFormat:@"%d",obj.minutes] forKey:@"minutes"];
            [dic setObject:[NSString stringWithFormat:@"%f",obj.secondsLeft] forKey:@"secondsLeft"];
            [dic setObject:[NSDate date] forKey:@"date"];
            [dic setObject:obj.startDate forKey:@"start_date"];

            NSDictionary *responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:dic,@"UPDATE_TIMER", nil];
            [session updateApplicationContext:responseDict error:nil];
        } @catch (NSException *exception) {
            NSLog(@"Updating the context failed: %@", exception);
        }
    }
}

/*
-(void)startTimerForRecipeID:(RecipeTimer*)obj{
    if ([WCSession isSupported]) {
        @try {
            WCSession *session = [WCSession defaultSession];

            NSMutableDictionary *dic = [NSMutableDictionary new];
            [dic setObject:[NSString stringWithFormat:@"%ld",obj.recipeboxId] forKey:@"recipeboxId"];
            [dic setObject:[NSString stringWithFormat:@"%ld",obj.recipeTimerId] forKey:@"recipeTimerId"];
            [dic setObject:[NSString stringWithFormat:@"%@",obj.recipeName] forKey:@"recipeName"];
            [dic setObject:[NSString stringWithFormat:@"%@",obj.recipeDesc] forKey:@"recipeDesc"];
            [dic setObject:[NSString stringWithFormat:@"%@",obj.countTimer] forKey:@"countTimer"];
            [dic setObject:[NSString stringWithFormat:@"%d",obj.seconds] forKey:@"seconds"];
            [dic setObject:[NSString stringWithFormat:@"%d",obj.hours] forKey:@"hours"];
            [dic setObject:[NSString stringWithFormat:@"%d",obj.minutes] forKey:@"minutes"];
            [dic setObject:[NSString stringWithFormat:@"%f",obj.secondsLeft] forKey:@"secondsLeft"];

            NSDictionary *responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:dic,@"START_TIMER", nil];
            [session updateApplicationContext:responseDict error:nil];
        } @catch (NSException *exception) {
            NSLog(@"Updating the context failed: %@", exception);
        }
    }
}
*/
#pragma mark - WatchKitSession Delegate
- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
{

}

- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData replyHandler:(void(^)(NSData *replyMessageData))replyHandler
{

    NSDictionary *msgDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:messageData];

    NSDictionary *responseDict = [NSDictionary new];

    
    if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"ADD_MIN_IN_TIMER"]) {

        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"SUCCESS", nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *recipeID = [msgDictionary valueForKey:@"TIMER_ID"];

            RecipeTimer *stopedTimerObj;

            for (RecipeTimer *recipeObj in theAppDelegate.ActiveTimerArr) {
                if (recipeID.integerValue == recipeObj.recipeboxId) {
                    stopedTimerObj = recipeObj;
                    break;
                }
            }

            stopedTimerObj.tempSecondsLeft = stopedTimerObj.secondsLeft;
            stopedTimerObj.secondsLeft = stopedTimerObj.tempSecondsLeft + 60 ; //update(Add one minute in current timer)


            if([stopedTimerObj.recipeTimerdelegate respondsToSelector:@selector(timerChangedInRecipe:)])
                [stopedTimerObj.recipeTimerdelegate timerChangedInRecipe:stopedTimerObj];

            [self updateTimerForRecipeID:stopedTimerObj];

            dispatch_async(dispatch_get_main_queue(), ^{
                replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
            });
        });
    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"STOP_TIMER_ID"]) {

        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"SUCCESS", nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *recipeID = [msgDictionary valueForKey:@"TIMER_ID"];

            RecipeTimer *stopedTimerObj;

            for (RecipeTimer *recipeObj in theAppDelegate.ActiveTimerArr) {
                if (recipeID.integerValue == recipeObj.recipeboxId) {
                    stopedTimerObj = recipeObj;
                    [recipeObj stopTimer];
                    break;
                }
            }

            if([stopedTimerObj.recipeListDelegate respondsToSelector:@selector(timerFinishForRecipe:)])
                [stopedTimerObj.recipeListDelegate timerFinishForRecipe:stopedTimerObj];

            dispatch_async(dispatch_get_main_queue(), ^{
                replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
            });
    });


    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"GET_TIMER_DATA"]) {

        if (theAppDelegate.ActiveTimerArr.count > 0) {
            [self showTimerOptionInWatch];
        }else{
            [self hideTimerOptionInWatch];
        }
        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"SUCCESS", nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });
    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"PICK_UNPICK_ITEM"]) {
        NSString *storeID = [msgDictionary valueForKey:@"STORE_ID"];
        NSString *shoppingListID = [msgDictionary valueForKey:@"SHOPPING_LIST_ID"];
        NSString *item_id = [msgDictionary valueForKey:@"ITEM_ID"];
        NSString *rowIndex = [msgDictionary valueForKey:@"ACTION_ROW_INDEX"];

//        CHECK_REASON reason = !originalCheck? TAKEN:NOT_THIS_TIME;
        [self getCurrentLocation];

        [self updateItemOfID:item_id fromList:shoppingListID forActionIndex:[rowIndex intValue] forStore:storeID];

        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"SUCCESS", nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });
    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"UPDATE_ITEM_IN_STORE"]) {

        [self getCurrentLocation];

        NSString *storeID = [msgDictionary valueForKey:@"STORE_ID"];
        NSString *shoppingListID = [msgDictionary valueForKey:@"SHOPPING_LIST_ID"];
        NSString *item_id = [msgDictionary valueForKey:@"ITEM_ID"];
        NSString *rowIndex = [msgDictionary valueForKey:@"ACTION_ROW_INDEX"];
        [self updateItemOfID:item_id fromList:shoppingListID forActionIndex:[rowIndex intValue] forStore:storeID];

        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"SUCCESS", nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });
    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"GET_ITEM_LIST_OF_STORE"]) {
        NSString *storeIDStr = [msgDictionary valueForKey:@"STORE_ID"];
        NSNumber *storeID = [NSNumber numberWithInteger:[storeIDStr integerValue]];
        NSString *shoppingListID = [msgDictionary valueForKey:@"SHOPPING_LIST_ID"];

        [[SortingSyncManager sharedSortingSyncManager] checkHashForStoreID:[NSNumber numberWithInteger:[storeID integerValue]] forItemList:[NSNumber numberWithInteger:[shoppingListID integerValue]]];

        getResponce = NO;

        while (!getResponce) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        }

        NSString *sortingType = [self getSortingType];

        NSString *sortedBy = @"";

        NSMutableArray *sortedArr = [NSMutableArray new];

        BOOL isStoreSortingAvailable = NO;

        if (storeID) {
            sortedArr = [self getItemWithSortedByStoreId:storeID forItemList:[NSNumber numberWithInteger:[shoppingListID integerValue]]];
            if (sortedArr.count>0) {
                isStoreSortingAvailable= YES;
                sortedBy = [msgDictionary valueForKey:@"STORE_NAME"];
            }
        }

        NSMutableArray *sortArrForAppStoreID = [NSMutableArray new];

        if ([DataStore instance].sortingOrder == STORE && storeID != [DataStore instance].sortByStoreID) {
            sortArrForAppStoreID = [self getItemWithSortedByStoreId:[DataStore instance].sortByStoreID  forItemList:[NSNumber numberWithInteger:[shoppingListID integerValue]]];
//            if (sortArrForAppStoreID.count>0) {
//                sortedBy = sortingType;
//            }

            if (sortedArr.count<1) {
                sortedArr = sortArrForAppStoreID;
                Store *store = [Store getStoreByID:[DataStore instance].sortByStoreID];
                if (store) {
                    sortedBy = store.name;
                }
            }
        }

        if (sortedArr.count > 0) {
            sortingType = NSLocalizedString(@"Unsorted items", nil);
        }else{

            if ([DataStore instance].sortingOrder == DATE || [DataStore instance].sortingOrder == DEFAULT || [DataStore instance].sortingOrder == GROUPED || [DataStore instance].sortingOrder == MANUAL) {
                NSString *sortedBy = NSLocalizedString(@"Sorted by:", nil);
                sortingType = [sortedBy stringByAppendingString:sortingType];
            }else{
                sortingType = NSLocalizedString(@"Unsorted items", nil);
            }
        }

        NSMutableArray *allLists = [NSMutableArray arrayWithArray:[Item_list getAllLists]];
        NSInteger selectedID = [[msgDictionary valueForKey:@"SHOPPING_LIST_ID"] integerValue];

        Item_list *itemList;
        for (Item_list *item in allLists) {
            if ([item.item_listID integerValue] == selectedID) {
                itemList = item;
            }
        }

        if (!itemList) {
            itemList = [DataStore instance].currentList;
        }

        NSMutableArray *buyItems = [self getBuyItemOfStoreForItemList:itemList];
        NSMutableArray *checkedItems = [self getCheckedItemOfStoreForItemList:itemList];

        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:buyItems,@"BUY_ITEMS",checkedItems,@"CHECKED_ITEMS",sortedArr,@"SORTED_ITEMS",sortingType,@"SORTING_TYPE",sortedBy,@"SORTING_BY",isStoreSortingAvailable?@"1":@"0",@"SHORTING_AVAILABLE",sortArrForAppStoreID,@"APP_STORE_SORT_ARR", nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });
        
    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"GET_STORE_LIST"])
    {
        //Get List Of Store
        NSMutableArray *resultArr = [self LoadStoreHistory];

        NSString *isSortByStore = @"0";

        if ([DataStore instance].sortingOrder == STORE) {
            isSortByStore = @"1";
        }

        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:resultArr,@"STORE_LIST",isSortByStore,@"SORT_BY_STORE", nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });
        
    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"REMOVE_ADDED_ITEM"]) {

        NSString *itemID = [msgDictionary valueForKey:@"ITEM_ID"];
        NSString *listID = [msgDictionary valueForKey:@"LIST_ID"];
        [self deleteItem:itemID forListID:listID];

        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"SUCCESS", nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });

    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"ADD_SUGGESTED_ITEM"]) {

        NSString *itemName = [msgDictionary valueForKey:@"ITEM_NAME"];
        NSString *listID = [msgDictionary valueForKey:@"LIST_ID"];
        responseDict =[self addNewItem:itemName forListID:listID];
        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });

    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"GET_SUGGESTED_ITEM"])
    {
       //Get List Of Suggested Items - Speech To Add
        NSString *addItemStr = [msgDictionary valueForKey:@"SUGESSION_STR"];
        NSMutableArray *resultArr = [self getItemSearchedList:addItemStr];
        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:resultArr,@"SUGGESTED_ITEM", nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });
    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"GET_SELECTED_ITEM"])
    {
        NSString *selectedItemName;
        NSString *selectedItemID;

        if ([Utility getDefaultBoolAtKey:@"authorized"]) {
            @try {
                [self createDataSource];
                selectedItemName = [DataStore instance].currentList.name;
                selectedItemID = [NSString stringWithFormat:@"%@",[DataStore instance].currentList.item_listID];
            } @catch (NSException *exception) {
                selectedItemName = exception.description;
                selectedItemID = @"";
            }

            responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:selectedItemID,@"SELECTED_ITEM_ID",selectedItemName,@"SELECTED_ITEM",@"1",@"AUTHORIZED", nil];
        }
        else{
            responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"AUTHORIZED", nil];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });
    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"GET_ITEM_LIST"]){

        NSMutableArray *allLists = [NSMutableArray arrayWithArray:[Item_list getAllLists]];
        NSMutableArray *responceArr = [NSMutableArray new];

        for (Item_list *items in allLists) {
            NSMutableDictionary *dic = [NSMutableDictionary new];
            [dic setObject:items.name forKey:@"name"];
            [dic setObject:[NSString stringWithFormat:@"%ld",[items.item_listID longValue]] forKey:@"item_listID"];
            [responceArr addObject:dic];
        }

        Item_list *currentList = [DataStore instance].currentList;

        NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:currentList.name,@"name",[NSString stringWithFormat:@"%ld",[currentList.item_listID longValue]],@"item_listID", nil];


         responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:responceArr,@"ITEM_LIST",dic,@"SELECTED_ITEM", nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });
    }
    else if ([[msgDictionary valueForKey:@"REQUEST_TYPE"] isEqualToString:@"CHANGE_SELECTED_ITEM"]){
         NSMutableArray *allLists = [NSMutableArray arrayWithArray:[Item_list getAllLists]];
         NSInteger selectedID = [[msgDictionary valueForKey:@"SELECTED_ITEM_ID"] integerValue];
        
        Item_list *selectedList;
        for (Item_list *item in allLists) {
            if ([item.item_listID integerValue] == selectedID) {
                selectedList = item;
            }
        }

        [DataStore instance].currentList = selectedList;
        [DataStore instance].hasListBeenShown = YES;
        [DataStore instance].sortByStoreID = selectedList.sortByStoreId;
        [DataStore instance].sortingOrder = (SORT_TYPE)[Item_list getSortType:[DataStore instance].currentList];
        responseDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"ITEM_LIST",@"SELECTED_ITEM", nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler([NSKeyedArchiver archivedDataWithRootObject:responseDict]);
        });

        [[SyncManager sharedManager] forceSync];
    }

        NSLog(@"Get Data");
}

-(void)sessionWatchStateDidChange:(WCSession *)session{
    NSLog(@"Test");
}

-(void)sessionReachabilityDidChange:(WCSession *)session{
    if (session.reachable) {

    }
    else{

    }
}
#pragma mark -

-(NSMutableArray*)getItemWithSortedByStoreId:(NSNumber*)storeId forItemList: (NSNumber*)itemListId{

    NSMutableArray *toBuyItems = [NSMutableArray new] ;
    ItemListsSorting *sorting;
    sorting = [ItemListsSorting getSortingForItemListId:itemListId andShopId:storeId];
    if(!sorting) {
        sorting = [ItemListsSorting insertSortingWithItemListId:itemListId andShopId:storeId];
    }

    NSMutableArray *sortingArr = sorting.sortedItems;

    if (sortingArr.count>0) {
        NSMutableArray *buyItemArr = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:[DataStore instance].currentList withId:[DataStore instance].currentList.item_listID andSortInOrder:[DataStore instance].sortingOrder andIsChecked:NO]];

        for (int i=0; i<buyItemArr.count; i++) {

            Item *itemName = [buyItemArr objectAtIndex:i];

            if ([sortingArr containsObject: itemName.itemID]) {
                NSMutableDictionary *dic = [NSMutableDictionary new];
                [dic setObject:itemName.text forKey:@"text"];
                [dic setObject:[NSString stringWithFormat:@"%@",itemName.itemID] forKey:@"id"];
                [dic setObject:[NSString stringWithFormat:@"%@",itemName.isTaken] forKey:@"isTaken"];
                [dic setObject:[NSString stringWithFormat:@"%@",itemName.isChecked] forKey:@"isChecked"];
                [dic setObject:[NSString stringWithFormat:@"%@",itemName.listId] forKey:@"listId"];
                [dic setObject:[NSString stringWithFormat:@"%@",itemName.manualSortIndex] forKey:@"manualSortIndex"];
                [toBuyItems addObject:dic];
            }

        }
    }

    return toBuyItems;
}

-(NSMutableArray*)getBuyItemOfStoreForItemList:(Item_list*)itemList{

    NSMutableArray *toBuyItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:itemList withId:itemList.item_listID andSortInOrder:[DataStore instance].sortingOrder andIsChecked:NO]];

    for (int i=0; i<toBuyItems.count; i++) {
        Item *itemName = [toBuyItems objectAtIndex:i];
        NSMutableDictionary *dic = [NSMutableDictionary new];
        [dic setObject:itemName.text forKey:@"text"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.itemID] forKey:@"id"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.isTaken] forKey:@"isTaken"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.isChecked] forKey:@"isChecked"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.listId] forKey:@"listId"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.manualSortIndex] forKey:@"manualSortIndex"];
        [toBuyItems replaceObjectAtIndex:i withObject:dic];
    }


    return toBuyItems;
}

-(NSMutableArray*)getCheckedItemOfStoreForItemList:(Item_list*)itemList{
    NSMutableArray *checkedItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:itemList withId:itemList.item_listID andSortInOrder:[DataStore instance].sortingOrder andIsChecked:YES]];

    for (int i=0; i<checkedItems.count; i++) {
        Item *itemName = [checkedItems objectAtIndex:i];
        NSMutableDictionary *dic = [NSMutableDictionary new];
        [dic setObject:itemName.text forKey:@"text"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.itemID] forKey:@"id"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.isTaken] forKey:@"isTaken"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.isChecked] forKey:@"isChecked"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.listId] forKey:@"listId"];
        [dic setObject:[NSString stringWithFormat:@"%@",itemName.manualSortIndex] forKey:@"manualSortIndex"];
        [checkedItems replaceObjectAtIndex:i withObject:dic];
    }

    return checkedItems;

}

-(NSMutableArray*)LoadStoreHistory
{
    NSMutableArray *storeHistory=[[NSMutableArray alloc] init];
    storeHistory=[NSMutableArray arrayWithArray:[Store getAllStores]];
    
    if(storeHistory.count>0 && storeHistory != nil)
    {
        NSMutableDictionary *dicT=[[NSMutableDictionary alloc] init];
        [dicT setObject:[NSString stringWithFormat:@"%@...",NSLocalizedString(@"In the store", nil)] forKey:@"name"];
        //[self setStoreTitle:NSLocalizedString(@"In the store", nil)];
        NSMutableDictionary *dic1T=[[NSMutableDictionary alloc] init];
        [dic1T setObject:dicT forKey:@"store"];
        
        NSMutableDictionary *dicB=[[NSMutableDictionary alloc] init];
        [dicB setObject:[NSString stringWithFormat:@"%@...",NSLocalizedString(@"Other store", nil)] forKey:@"name"];
        
        NSMutableDictionary *dic1B=[[NSMutableDictionary alloc] init];
        [dic1B setObject:dicB forKey:@"store"];
        
        [storeHistory insertObject:dic1T atIndex:0];
        
        [storeHistory addObject:dic1B];
        
    }


    if ([storeHistory.firstObject isKindOfClass:[NSMutableDictionary class]]) {
        [storeHistory removeObjectAtIndex:0];
    }

    if ([storeHistory.lastObject isKindOfClass:[NSMutableDictionary class]]) {
        [storeHistory removeLastObject];
    }
    
    for(int i=0;i<storeHistory.count;i++)
    {
//        if( i< storeHistory.count)
        {
            Store *store = [storeHistory objectAtIndex:i];
            NSLog(@"History store %@",store);
            NSMutableDictionary *dic=[[NSMutableDictionary alloc] init];
            [dic setValue:store.address forKey:@"address"];
            [dic setValue:store.city forKey:@"city"];
            [dic setValue:store.distance forKey:@"distance"];
            [dic setValue:store.isFavorite forKey:@"isFavorite"];
            [dic setValue:store.storeID forKey:@"id"];
            [dic setValue:store.itemsSortedPercent forKey:@"itemsSortedPercent"];
            [dic setValue:store.name forKey:@"name"];
            [dic setValue:store.postalAddress forKey:@"postalAddress"];
            [dic setValue:store.postalCode forKey:@"postalCode"];
            [dic setValue:store.title forKey:@"title"];
            NSLog(@"history store name %@", store.name);
            [storeHistory replaceObjectAtIndex:i withObject:dic];
        }
    }
    return storeHistory;
}

- (NSMutableArray*)getItemSearchedList:(NSString*)addItemStr
{
    __block BOOL getResult = NO;
    __block NSMutableArray *responseTextsArr = [NSMutableArray new];
    if(addItemStr != nil && addItemStr.length > 0)
    {
        NSMutableArray *texts = [NSMutableArray new];
        
        NSDictionary *tempDictionary = [NSDictionary dictionaryWithObject:addItemStr forKey:@"text"];
        [texts addObject:tempDictionary];
        
        NSDictionary *parameters = [NSDictionary dictionaryWithObject:texts forKey:@"voiceMatches"];
        
        
        [[MatlistanHTTPClient sharedMatlistanHTTPClient] POST:@"ItemSearch" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSArray *response = (NSArray *)responseObject;
            
            
            if(response.count>0)
            {
                for(NSDictionary *itemFromServer in response)
                {
                    NSString *itemText = itemFromServer[@"text"];
                    if(itemText)
                    {
                        [responseTextsArr addObject:itemText];
                    }
                    
                }
                getResult = YES;
            }
            else
            {
                //No matches
                [responseTextsArr addObject:NSLocalizedString(@"Found no matching items. Please try again.",nil)];
                getResult = YES;
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [responseTextsArr addObject:NSLocalizedString(@"server_problem",nil)];
            getResult = YES;
            
        }];
    }
    
    while (!getResult) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    return responseTextsArr;
}

-(void)createDataSource{

    if([DataStore instance].currentList == nil)
    {

        NSInteger listID = [[NSUserDefaults standardUserDefaults] integerForKey:@"DEFAULT_LIST_ID"];

        if (listID != 0)
        {

            currentListId = [NSNumber numberWithInteger:listID];

            [DataStore instance].currentList = [Item_list getListById:currentListId];

            if ([DataStore instance].currentList == nil)
            {
                [DataStore instance].currentList = [Item_list getDefaultList];

                currentListId = [DataStore instance].currentList.item_listID;
            }
        }
        else
        {
            [DataStore instance].currentList = [Item_list getDefaultList];
            currentListId = [DataStore instance].currentList.item_listID;
        }
    }
    else
    {
        currentListId = [DataStore instance].currentList.item_listID;
        if (currentListId == nil)
        {
            [DataStore instance].currentList = [Item_list getDefaultList];
            currentListId = [DataStore instance].currentList.item_listID;
        }
    }

    currentListObjectId = [DataStore instance].currentList.objectID;

    [DataStore instance].sortingOrder = (SORT_TYPE)[Item_list getSortType:[DataStore instance].currentList];


    if ([DataStore instance].sortingOrder == STORE)
    {
        [DataStore instance].sortByStoreID = [DataStore instance].currentList.sortByStoreId;
    }
}

-(NSDictionary*)addNewItem:(NSString*)newItemName forListID:(NSString*)listID{
    //add new item in core data, sync to server in sync engine later
    Item_list *list = [DataStore instance].currentList;

    if (list.item_listID != [NSNumber numberWithLong:[listID longLongValue]]) {

        NSMutableArray *allLists = [NSMutableArray arrayWithArray:[Item_list getAllLists]];

        for (Item_list *items in allLists) {

            if (items.item_listID == [NSNumber numberWithLong:[listID longLongValue]]) {
                list = items;
                break;
            }
        }
    }

    //DLog(@"Got list from datastore");

    NSString *item_source = @"Voice";

    Item *item = [Item insertItemWithText:newItemName andBarcode:@"" andBarcodeType:@"" belongToList:list withSource:item_source];

    lastAddedItemID = item.objectID;



    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        NSMutableDictionary *properties = [NSMutableDictionary new];
        if(newItemName) properties[@"Text"] = newItemName; else properties[@"Text"] = @"NULL";
        if(list.name) properties[@"list"] = list.name; else properties[@"list"] = @"NULL";
        if(item_source) properties[@"source"] = item_source; else properties[@"source"] = @"NULL";
        [[Mixpanel sharedInstance] track:@"Item Added" properties:properties];
    }

    //if item successfully added then iTemNameNotAddedYet must be empty.
    [DataStore instance].iTemNameNotAddedYet = @"";

    // reload table view to load data when new item added
    //force sync when new item is added
    [[SyncManager sharedManager] forceSync];



    NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:list.name,@"LIST_NAME",[NSString stringWithFormat:@"%@",[NSNumber numberWithInteger:[list.item_listID integerValue]]],@"LIST_ID",newItemName,@"ITEM_NAME",[NSString stringWithFormat:@"%@",[NSNumber numberWithInteger:[item.itemID integerValue]]],@"ITEM_ID", nil];

    return dic;

}

-(void)deleteItem:(NSString*)itemID forListID: (NSString*)listID{

    [Item fakeDelete:lastAddedItemID];

    //Delete in the tableView
    [[SyncManager sharedManager] forceSync];
}

-(void)updateItemOfID:(NSString*)itemID fromList:(NSString*)listID forActionIndex: (int)buttonIndex forStore:(NSString*)storeID{

    Item *theItem = [Item getItemInList:[NSNumber numberWithInteger:[listID integerValue]] withItemID:[NSNumber numberWithInteger:[itemID integerValue]]];

    if (!theItem) {
        theItem = [Item getDeletedItemInList:[NSNumber numberWithInteger:[listID integerValue]] withItemID:[NSNumber numberWithInteger:[itemID integerValue]]];

        if (!theItem) {
            return;
        }
    }

    if(buttonIndex==6)
    {
        BOOL originalCheck = [theItem.isChecked boolValue];
        [self checkItemInCoreData:theItem WithStatus:((CHECK_REASON)buttonIndex) andChecked:originalCheck andTaken:originalCheck forStoreID:[NSNumber numberWithInteger:[storeID integerValue]]];

    }
    else
    {
        BOOL originalCheck = [theItem.isChecked boolValue];
        theItem.isChecked = [NSNumber numberWithBool:!originalCheck];
        theItem.isTaken = [NSNumber numberWithBool:!originalCheck];
        [self checkItemInCoreData:theItem WithStatus:((CHECK_REASON)buttonIndex) andChecked:!originalCheck andTaken:!originalCheck forStoreID:[NSNumber numberWithInteger:[storeID integerValue]]];
    }

    [[SyncManager sharedManager] forceSync];
}

- (void)checkItemInCoreData:(Item*)theItem WithStatus:(CHECK_REASON)reason andChecked:(BOOL)isChecked andTaken:(BOOL)isTaken forStoreID:(NSNumber*)selectd_store_id
{
    CLS_LOG(@"checkItemInCoreData method called in shoppingmodetableviewcontroller");

    [Utility saveInDefaultsWithObject:[NSDate new] andKey:@"lastCheckingActivity"];
    //DLog(@"\n\n\nCheck item: %@\nIs checked: %@ \nwith reason %d\n\n\n",theItem.text, isChecked? @"YES" : @"NO", reason);
    // Add info in ItemsCheckedStatus

    int deviceId = [DataStore instance].randomDeviceID;

    //long secAfterStart = [self getSecondsAfterStart];

    if (reason == REMOVE)
    {
        //Remove this item from the table view


        [Item fakeDelete:theItem.objectID];

        DLog(@"Remove the item in core data");

        return;
        //Remove this item from core data

    }
    else {
        // Update core data if any change is made
        [Item checkItem:theItem.objectID withCheckStatus:isChecked andReason:reason];
    }
    //Apple does not allow developers direct access to the low-level wireless API functions. So leave the networks to be empty
    NSMutableArray *networks = [[NSMutableArray alloc]initWithArray:@[[NSNull null]]];

    NSArray *reasons = @[@"Taken",@"OutOfOrder",@"Moved",@"SoldOut",@"NotInThisStore",@"NotThisTime",@"Remove",@"Unknown"];

    if([DataStore instance].sortingOrder==STORE)
    {
        [ItemsCheckedStatus updateItemCheckedStatus:isChecked andTaken:isTaken forItemObjectId:theItem.objectID forItemId:theItem.itemID inList:theItem.listId andDeviceId:deviceId andCheckedReason:reasons[reason] andLat:currentLocation.coordinate.latitude andLon:currentLocation.coordinate.longitude andAccuracy:(int)currentLocation.horizontalAccuracy andNetworks:networks andSelectedStoreId:[DataStore instance].currentList.sortByStoreId];
    }
    else
    {
        if(selectd_store_id==nil)
        {
            [ItemsCheckedStatus updateItemCheckedStatus:isChecked andTaken:isTaken forItemObjectId:theItem.objectID forItemId:theItem.itemID inList:theItem.listId andDeviceId:deviceId andCheckedReason:reasons[reason] andLat:currentLocation.coordinate.latitude andLon:currentLocation.coordinate.longitude andAccuracy:(int)currentLocation.horizontalAccuracy andNetworks:networks andSelectedStoreId:0];

        }
        else
        {
            [ItemsCheckedStatus updateItemCheckedStatus:isChecked andTaken:isTaken forItemObjectId:theItem.objectID forItemId:theItem.itemID inList:theItem.listId andDeviceId:deviceId andCheckedReason:reasons[reason] andLat:currentLocation.coordinate.latitude andLon:currentLocation.coordinate.longitude andAccuracy:(int)currentLocation.horizontalAccuracy andNetworks:networks andSelectedStoreId:[DataStore instance].currentList.sortByStoreId];
            
        }
    }
}

-(NSString *)getSortingType{

    NSString *sortingType;

    if([DataStore instance].sortingOrder == DATE){

        sortingType = NSLocalizedString(@"Latest first",nil);
        DLog(@"Click Senast överst");

    }
    else if ([DataStore instance].sortingOrder == DEFAULT)
    {
        sortingType = NSLocalizedString(@"Alphabetically",nil);
    }
    else if ([DataStore instance].sortingOrder == GROUPED)
    {
        sortingType = NSLocalizedString(@"By category",nil);
    }
    else if ([DataStore instance].sortingOrder == STORE)
    {
        Store *storeObj = [Store getStoreByID:[DataStore instance].sortByStoreID];
        sortingType = NSLocalizedString(storeObj.name,nil);
    }
    else if ([DataStore instance].sortingOrder == MANUAL)
    {
        sortingType = NSLocalizedString(@"Own sorting",nil);
    }
    else if ([Utility getSortName].length > 0)
    {
        sortingType = [Utility getSortName];
    }
    else
    {
        sortingType = @"Store";
    }
    return sortingType;
}

-(void)checkSortingAvailableForStoreID:(NSString*)storeID{
    NSNumber *itemListId = [DataStore instance].currentList.item_listID;
    NSNumber *storeId = [DataStore instance].sortByStoreID;

    [[SortingSyncManager sharedSortingSyncManager] checkHashForStoreID:storeId forItemList:itemListId];
}

#pragma mark- SortingSyncDelegate

-(void)sortingSyncFinished:(BOOL)withError{
    getResponce = YES;
}


#pragma mark - location

- (void)getCurrentLocation {
    CLS_LOG(@"getCurrentLocation method called in shoppingmodetableviewcontroller");

    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [locationManager requestWhenInUseAuthorization];
    }
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    currentLocation = [locations lastObject];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"didFailWithError: %@", error);
    [self LoadStoreHistory];
    [locationManager stopUpdatingLocation];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if([CLLocationManager locationServicesEnabled])
    {
        locationManager=nil;
    }
    
}



@end
