//
//  Item+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 08/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Item+Extra.h"
#import "SignificantChangesIndicator.h"
#import "ItemsCheckedStatus+Extra.h"
#import "Mixpanel.h"
#import "SyncManager.h"

#define SECONDS_FOR_TWO_HOURS 7200

@implementation Item (Extra)

+ (void) clearUncheckedItems {
    /*
     
     !!WARNING
     This code contains potential bugs
     Please, test carefully if you uncomment this
     
    if (![Utility getObjectFromDefaults:@"lastCheckingActivity"]) {
        [Utility saveInDefaultsWithObject:[NSDate new] andKey:@"lastCheckingActivity"];
    }
    NSDate *dateNow = [NSDate new];
    NSDate *lastActivityDate = (NSDate *)[Utility getObjectFromDefaults:@"lastCheckingActivity"];
    long second =[Utility secondsBetweenDate:lastActivityDate andDate: dateNow];
    
    if (second >= SECONDS_FOR_TWO_HOURS) {
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(syncStatus != %@) AND (isChecked!=%@)", [NSNumber numberWithInt:Deleted], @NO, @NO];
            NSArray *itemArray = [Item MR_findAllWithPredicate:predicate];
            for (Item * item in itemArray) {
                if([item.isPermanent boolValue]) {
                    item.isChecked = [NSNumber numberWithBool:NO];
                }
                else {
                    item.isArchived = [NSNumber numberWithBool:YES];
                }
            }
        }];
    }
     */
}

+(void)insertItems:(id)responseObject{
    NSDictionary *allItems = (NSDictionary*)responseObject;
    NSArray *itemArray = [allItems objectForKey:@"list"];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *items = [Item MR_importFromArray:itemArray inContext:localContext];
       
        for (int index = 0; index < items.count; index++) {
            Item* item = items[index];
            item.serverIndex = @(index);
            item.addedAtTime = [Utility getDateFromString:item.addedAt];
            item.syncStatus = @(Synced);
        }
    } completion:^(BOOL success, NSError *error) {
        DLog(@"finish inserting items");
        [[NSNotificationCenter defaultCenter]postNotificationName:@"FinishInsertingItems" object:nil];
        if (error)
        {
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription ? error.localizedDescription : @"NULL", @"action":[NSString stringWithFormat:@"%s", __FUNCTION__]}];
            }
        }
    }];
}

+(void)updateItem:(id)responseObject forItemWithID:(NSManagedObjectID*)itemObjID{
    
    NSDictionary *response = (NSDictionary*)responseObject;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {[localContext performBlockAndWait:^{
        Item *item = (Item *)[localContext objectWithID:itemObjID];
        if (nil != item)
        {
            item.addedAt = [NSString stringWithFormat:@"%@" ,[response objectForKey:@"addedAt"]];
            item.groupedSortIndex = [response objectForKey:@"groupedSortIndex"];
            item.itemID =  [response objectForKey:@"id"];
            item.isChecked = [response objectForKey:@"isChecked"];
            item.isDefaultMatch = [response objectForKey:@"isDefaultMatch"];
            item.isPermanent = [response objectForKey:@"isPermanent"];
            item.isPossibleMatch = [response objectForKey:@"isPossibleMatch"];
            item.isTaken = [response objectForKey:@"isTaken"];
            item.knownItemText = [response objectForKey:@"knownItemText"];
            item.listId = [response objectForKey:@"listId"];
            item.matchingItemText = [response objectForKey:@"matchingItemText"];
            item.mayBeDefaultMatch = [response objectForKey:@"mayBeDefaultMatch"];
            item.placeCategory = [response objectForKey:@"placeCategory"];
            item.searchedText = [response objectForKey:@"searchedText"];
            item.text = [response objectForKey:@"text"];
            item.possibleMatches = [responseObject objectForKey:@"possibleMatches"];
            item.checkedAfterStart = [responseObject objectForKey:@"checkedAfterStart"];
            item.syncStatus = [NSNumber numberWithInt:Synced];
            [localContext MR_saveToPersistentStoreAndWait];
        }
    }];
    }completion:^(BOOL success, NSError *error) {
        if (error)
        {
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"action":[NSString stringWithFormat:@"%s", __FUNCTION__]}];
            }
        }
    }];
    
}

//it is used only for tests
+(void)insertItemWithText:(NSString*)text andBarcode:(NSString*)barcode andBarcodeType:(NSString*)barcodeType andListId:(NSNumber*)listId andAddedAt:(NSString*)addedAt{
    CLS_LOG(@"Insert item.\nText: %@\nBarcode: %@\nBarcode type: %@\nList id: %@\nAdded at:%@", text, barcode, barcodeType, listId, addedAt);
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Item *item = [Item MR_createEntityInContext:localContext];
        item.text = text;
        item.isPermanent = @0;
        item.matchingItemText = text;
        item.isDefaultMatch = @1;
        item.barcode = barcode;
        item.barcodeType = barcodeType;
        item.listId = listId;
        item.addedAt = addedAt;
        item.syncStatus = [NSNumber numberWithInt:Created];
    } completion:^(BOOL success, NSError *error) {
        if (error)
        {
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"action":[NSString stringWithFormat:@"%s", __FUNCTION__]}];
            }
        }
    }];
}


/**
 Modification: Added new parameter 'source'
 @ModifiedDate: September 4 , 2015
 @Version:1.14
 @Modified by: Yousuf
 */
+(Item*)insertItemWithText:(NSString*)text andBarcode:(NSString*)barcode andBarcodeType:(NSString*)barcodeType belongToList:(Item_list*)list withSource:(NSString *)source
{
    CLS_LOG(@"Insert item.\nText: %@\nBarcode: %@\nBarcode type: %@\nList id: %@\nSource:%@", text, barcode, barcodeType, list.item_listID, source);
    
    NSString *listObjectID = [[list.objectID URIRepresentation]absoluteString];
    NSDate *addAtTimeLocal = [NSDate date];
    NSString *addedAt = [Utility getStringFromDate:addAtTimeLocal];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext)
     {
         Item *item = [Item MR_createEntityInContext:localContext];
         item.text = text;
         item.isPermanent = @0;
         item.matchingItemText = text;
         item.isDefaultMatch = @1;
         item.barcode = barcode;
         item.barcodeType = barcodeType;
         item.listId = list.item_listID;
         item.addedAt = addedAt;
         item.syncStatus = [NSNumber numberWithInt:Created];
         item.listObjectID = listObjectID;
         item.addedAtTime_local = addAtTimeLocal;
         item.source = source;
    }];
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listObjectID=%@) AND (text == %@) AND (addedAt == %@)",listObjectID, text, addedAt];
    Item *insertedItem = [Item MR_findFirstWithPredicate:predicate];
    return insertedItem;
}

//is used just for tests
+(void)insertItemWithID:(NSNumber*)itemId andText:(NSString*)text andBarcode:(NSString*)barcode andBarcodeType:(NSString*)barcodeType andListId:(NSNumber*)listId andAddedAt:(NSString*)addedAt
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Item *item = [Item MR_findFirstByAttribute:@"itemID" withValue:itemId];
        if (item == nil) {
            item = [Item MR_createEntityInContext:localContext];
        }
        
        item.itemID = itemId;
        item.text = text;
        item.barcode = barcode;
        item.barcodeType = barcodeType;
        item.listId = listId;
        item.addedAt = addedAt;
        item.syncStatus = [NSNumber numberWithInt:Created];
        
    }completion:^(BOOL success, NSError *error) {
        if (error)
        {
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"action":[NSString stringWithFormat:@"%s", __FUNCTION__]}];
            }
        }
    }];
}

+(void)updateItemWithId:(NSNumber*)itemId andText:(NSString*)text andisPermanent:(NSNumber*)isPermanent andMatchingItem:(NSString*)matchingItem andIsDefaultMatch:(NSNumber *)isDefaultMatch{
    CLS_LOG(@"Updating item.\nId: %@\nText: %@\nIs permanent: %@\nMatching item: %@\nIs default match: %@", itemId, text, isPermanent, matchingItem, isDefaultMatch);
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Item *item = [Item MR_findFirstByAttribute:@"itemID" withValue:itemId];
        item.text = text;
        item.isPermanent = isPermanent;
        item.matchingItemText = matchingItem;
        item.isDefaultMatch = isDefaultMatch;
        if([item.syncStatus intValue] == Synced) {
            item.syncStatus = [NSNumber numberWithInt:Updated];
        }
        [localContext MR_saveToPersistentStoreAndWait];
    }completion:^(BOOL success, NSError *error) {
        if (error)
        {
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription? error.localizedDescription : @"NULL", @"action":[NSString stringWithFormat:@"%s", __FUNCTION__]}];
            }
        }
    }];
}

+(void)updateItem:(NSNumber*)itemId WithManualIndex:(NSUInteger)index{
    CLS_LOG(@"Set manual index.\nItem id: %@\nSort index: %lu", itemId, (unsigned long)index);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item *item = [Item MR_findFirstByAttribute:@"itemID" withValue:itemId inContext:localContext];
        item.manualSortIndex = [NSNumber numberWithInteger:index];
    }];
}

-(void) updateItemWithItemListId:(NSNumber *)itemListId {
    CLS_LOG(@"Update Item\nList id: %@", itemListId);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item *item = [self MR_inContext:localContext];
        item.listId = itemListId;
        item.syncStatus = @(Updated);
    }];
}

+(void)checkItem:(NSManagedObjectID*)itemObjectId withCheckStatus:(BOOL)checked andReason:(CHECK_REASON)reason {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item *item = (Item *)[localContext objectWithID:itemObjectId];
        CLS_LOG(@"Checking item.\nItem id: %@\nChecked: %@\nReason: %u", item.itemID, checked ? @"Y" : @"N", reason);
        if (nil != item)
        {

            if(checked) {
                item.checkOrder = [NSNumber numberWithLong:[[Item MR_aggregateOperation:@"max:" onAttribute:@"checkOrder" withPredicate:nil inContext:localContext] longValue] + 1];
                item.checkedAfterStart = nil;
            }
            else {
                item.checkedAfterStart = nil;
                item.checkOrder = nil;
            }
            
            item.isChecked = [NSNumber numberWithBool:checked];
            if (reason == TAKEN || reason == OUT_OF_ORDER || reason == MOVED) {
                item.isTaken = [NSNumber numberWithBool:YES];
            }
            else{
                item.isTaken = [NSNumber numberWithBool:NO];
            }
        }
    }];
}
     
+(void)deleteAllItemsInContext:(NSManagedObjectContext*)context{
    if (context == nil) {
        //TODO check this implementation for fault - Markus T
        context    = [NSManagedObjectContext MR_context];
    }
    NSArray *items = [Item MR_findAll];
    if (items.count > 0) {
        for (Item *item in items){
            NSManagedObject *localObject = [item MR_inContext:context];
            [localObject MR_deleteEntityInContext:context];
            
        }
        [context MR_saveToPersistentStoreAndWait];
    }
}

+ (NSArray*)getAllItemsExceptDeletedFromList:(Item_list*)list withId:(NSNumber*)listId andSortInOrder:(SORT_TYPE)sortIndex andIsChecked:(BOOL)isChecked
{
    NSArray *itemArray = [[NSArray alloc]init];
    if ([listId intValue] == 0)
    {
        NSString *listObjId = [[list.objectID URIRepresentation]absoluteString];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listObjectID=%@) AND (syncStatus != %@) AND (isChecked==%i)",listObjId,[NSNumber numberWithInt:Deleted],isChecked];
        itemArray = [Item MR_findAllWithPredicate:predicate];
    }
    else
    {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listId == %@) AND (syncStatus != %@) AND (isChecked==%i)",list.item_listID,[NSNumber numberWithInt:Deleted],isChecked];
        itemArray = [Item MR_findAllWithPredicate:predicate];
    }
    // Added this code to fix issue # 245
    if (isChecked)
    {
        NSSortDescriptor *sortByCheckOrder = [NSSortDescriptor sortDescriptorWithKey:@"checkOrder" ascending:NO];
        NSSortDescriptor *sortByLocalUpdatedTime = [NSSortDescriptor sortDescriptorWithKey:@"checkedAfterStart" ascending:NO];
        
        return [itemArray sortedArrayUsingDescriptors:@[sortByCheckOrder, sortByLocalUpdatedTime]];
    }
    return [itemArray sortedArrayUsingDescriptors:[self getSortDescriptor:sortIndex]];
    
}

+ (NSArray*)getItemsToBuyFromList:(NSNumber*)listId andList:(Item_list*)list andSortInOrder:(SORT_TYPE)sortIndex
{
    NSArray *sortedArray = [[NSArray alloc]init];
    if ([listId intValue] == 0) {
        NSString *listObjId = [[list.objectID URIRepresentation]absoluteString];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listObjectID=%@) AND (syncStatus != %@) AND ((isPermanent == %@) OR (isTaken == %@))",listObjId, [NSNumber numberWithInt:Deleted], @YES, @NO];
        NSArray *itemArray = [Item MR_findAllWithPredicate:predicate];
        sortedArray = [itemArray sortedArrayUsingDescriptors:[self getSortDescriptor:sortIndex]];

    }
    else{
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listId=%@) AND (syncStatus != %@) AND ((isPermanent == %@) OR (isTaken == %@))",listId, [NSNumber numberWithInt:Deleted], @YES, @NO];
        NSArray *itemArray = [Item MR_findAllWithPredicate:predicate];
        sortedArray = [itemArray sortedArrayUsingDescriptors:[self getSortDescriptor:sortIndex]];
    }
    return sortedArray;
}

+(Item*)getItemInList:(NSNumber*)listId withItemID:(NSNumber*)itemID{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listId == %@) AND (syncStatus != %@) AND (itemID == %@) AND ((isChecked == %@) OR (isPermanent == %@))",listId, [NSNumber numberWithInt:Deleted],itemID, @NO, @YES];
    Item *item = [Item MR_findFirstWithPredicate:predicate];
    return item;
}

+(Item*)getDeletedItemInList:(NSNumber*)listId withItemID:(NSNumber*)itemID{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listId == %@) AND (itemID == %@)",listId,itemID];
    Item *item = [Item MR_findFirstWithPredicate:predicate];
    return item;
}

+ (NSArray *)getAllItemsInList:(NSNumber*)listId exceptItemIds:(NSMutableArray *)arrItemIds
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(listId == %@) AND (syncStatus != %@) AND ((isChecked == %@) OR (isPermanent == %@)) AND NOT itemID IN %@", listId, [NSNumber numberWithInt:Deleted], @NO, @YES, arrItemIds];
    NSArray *items = [Item MR_findAllWithPredicate:predicate];
    return items;
}

+(NSArray*)getAllItemsFakeDeletedInList{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(syncStatus == %@)", [NSNumber numberWithInt:Deleted]];
    NSArray *itemArray = [Item MR_findAllWithPredicate:predicate];
    
    return itemArray;
}

+(NSArray*)getAllItemsByStatus:(SYNC_STATUS)status{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(syncStatus == %@)", [NSNumber numberWithInt:status]];
    NSArray *itemArray = [Item MR_findAllWithPredicate:predicate];
    
    return itemArray;
}

+(NSArray*)getSortDescriptor:(SORT_TYPE)type{
    NSArray *sortDescriptors = [[NSArray alloc]init];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]init];
    NSSortDescriptor *sortByLocalAddedTime = [NSSortDescriptor sortDescriptorWithKey:@"addedAtTime_local" ascending:NO];    //this is used for newly-added items which still have not got "addedAtTime" from the server.
    switch (type) {
            
        case UNKNOWN:
        {
            sort = [NSSortDescriptor sortDescriptorWithKey:@"addedAtTime" ascending:NO];  //unknow sort type from server, from older version of Android app
            sortDescriptors = @[sortByLocalAddedTime,sort];
            break;
        }
        case DEFAULT:
        {
            sort = [NSSortDescriptor sortDescriptorWithKey:@"serverIndex" ascending:YES];  //Sort alphabetically
            sortDescriptors = @[sort];
            break;
        }
        case DATE:
        {
            sort = [NSSortDescriptor sortDescriptorWithKey:@"addedAtTime" ascending:NO];
            sortDescriptors = @[sortByLocalAddedTime,sort];
            break;
        }
        case MANUAL:
        {
            sort = [NSSortDescriptor sortDescriptorWithKey:@"manualSortIndex" ascending:YES];
            sortDescriptors = @[sort];
            break;
        }
        case GROUPED:
        {
            sort = [NSSortDescriptor sortDescriptorWithKey:@"groupedSortIndex" ascending:YES];  //Sort by category
            sortDescriptors = @[sort];
            break;
        }
        case STORE:
        {
            sort = [NSSortDescriptor sortDescriptorWithKey:@"text" ascending:YES];//TO DO: fix list for store sorting
            sortDescriptors = @[sort];
            break;
        }
        default:
            break;
    }
   
    return sortDescriptors;
}
/**
 Set syncStatus to be Deleted. This is done before sync with server.
 */
+(void)fakeDelete:(NSNumber*)itemId withText:(NSString*)text andListID:(NSNumber*)listId{
    CLS_LOG(@"Deleting item.\nId: %@\nText: %@", itemId, text);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(itemID = %@) AND (listId=%@) AND (text = %@)",itemId, listId, text];
        Item *item = [Item MR_findFirstWithPredicate:predicate inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt:Deleted];
    }];
}

+(void) fakeDeleteItem:(Item *) itemToDelete {
    CLS_LOG(@"Deleting item.\nId: %@\nText: %@", itemToDelete.itemID, itemToDelete.text);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext){
        Item *item = [itemToDelete MR_inContext:localContext];
        if (nil != item)
        {
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                if(item.text!=nil)
                {
                    [[Mixpanel sharedInstance] track:@"Item Deleted" properties:@{@"Item Text": item.text}];
                }
            }
            
            //if (item.itemID == nil || [item.itemID intValue] == 0) {
            if(NO) {
                //DELETE RELATED ITEMS CHECKED STATUS
                ////
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemObjectID == %@",[[item.objectID URIRepresentation] absoluteString]];
                ItemsCheckedStatus * ics = [ItemsCheckedStatus MR_findFirstWithPredicate:predicate inContext:localContext];
                if(ics) [ics MR_deleteEntityInContext:localContext];
                [item MR_deleteEntityInContext:localContext];
                ////
            }
            else{
                item.syncStatus = [NSNumber numberWithInt:Deleted];
            }
        }
    }];
}

+(void)fakeDelete:(NSManagedObjectID*)itemObjectId{
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext){
        Item *item = (Item *)[localContext objectWithID:itemObjectId];
        CLS_LOG(@"Deleting item.\nId: %@\nText: %@", item.itemID, item.text);
        if (nil != item)
        {
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                if(item.text!=nil)
                {
                    [[Mixpanel sharedInstance] track:@"Item Deleted" properties:@{@"Item Text": item.text}];
                }
            }

            if (item.itemID == nil || [item.itemID intValue] == 0) {
                //DELETE RELATED ITEMS CHECKED STATUS
                ////
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemObjectID == %@",[[item.objectID URIRepresentation] absoluteString]];
                ItemsCheckedStatus * ics = [ItemsCheckedStatus MR_findFirstWithPredicate:predicate inContext:localContext];
                [ics MR_deleteEntityInContext:localContext];
                [item MR_deleteEntityInContext:localContext];
                ////
                //[localContext MR_saveToPersistentStoreAndWait];
            }
            else{
                item.syncStatus = [NSNumber numberWithInt:Deleted];
                //[localContext MR_saveToPersistentStoreAndWait];
            }
        }
    }];
    
}

+(void)realDelete{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus == %@",[NSNumber numberWithInt:Deleted]];
        NSArray *items = [Item MR_findAllWithPredicate:predicate inContext:localContext];
        
        if (items.count > 0) {
            for (Item *item in items){
                NSManagedObject *localObject = [item MR_inContext:localContext];
                [localObject MR_deleteEntityInContext:localContext];
            }
        }
    }];
}

+(void)changeSyncStatus:(SYNC_STATUS)status for:(NSNumber*)itemId{
    NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_context];
    Item *item = [Item MR_findFirstByAttribute:@"itemID" withValue:itemId];
    item.syncStatus = [NSNumber numberWithInt:status];
    [localContext MR_saveToPersistentStoreAndWait];
}

+(void)realDeleteWithPredicate:(NSPredicate*)predicate{
    //TODO Check saveWithBlockAndWait for fault - Markus
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        
        NSArray *items = [Item MR_findAllWithPredicate:predicate];
        if (items.count > 0) {
            for (Item *item in items){
                NSManagedObject *localObject = [item MR_inContext:localContext];
                [localObject MR_deleteEntityInContext:localContext];
                
            }
        }
    }];
}

- (void)updateItemWithText:(NSString *)text andisPermanent:(NSNumber *)isPermanent andMatchingItem:(NSString *)matchingItem andIsDefaultMatch:(NSNumber *)isDefaultMatch withKnownItemText:(NSString *)knownItemText andItemListId: (NSNumber *) itemListId
{
    CLS_LOG(@"Updating item.\nId: %@\nText: %@\nIs permanent: %@\nMatching item: %@\nIs default match: %@\nKnown item text: %@\nItem list id: %@", self.itemID, text, isPermanent, matchingItem, isDefaultMatch, knownItemText, itemListId);
    
    self.text = text;
    self.isPermanent = isPermanent;
    self.matchingItemText = matchingItem;
    self.isDefaultMatch = isDefaultMatch;
    self.knownItemText = knownItemText;
    self.listId = itemListId;
    
    if([self.syncStatus intValue] == Synced)
    {
        self.syncStatus = [NSNumber numberWithInt:Updated];
    }
    
    [[self managedObjectContext] MR_saveToPersistentStoreAndWait];
}

- (void)updateItemWithMatchingText:(NSString*)matchingItem andIsPossibleMatch:(NSNumber *)isPossibleMatch
{
    CLS_LOG(@"Updating item.\nId: %@\nMatching item: %@\nPossibleMatch: %@", self.itemID, matchingItem, isPossibleMatch);
    self.matchingItemText = matchingItem;
    self.isPossibleMatch = isPossibleMatch;
    if([self.syncStatus intValue] == Synced) {
        self.syncStatus = [NSNumber numberWithInt:Updated];
    }
    [[self managedObjectContext] MR_saveToPersistentStoreAndWait];
}

//SuperObject methods
- (void) updateObject {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item *item = [self MR_inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt:Synced];
    }];
}

- (NSNumber *)getId {
    return self.itemID;
}

- (void) deleteObjectWithChildren {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSManagedObject *localObject = [self MR_inContext:localContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemObjectID == %@",[[localObject.objectID URIRepresentation] absoluteString]];
        ItemsCheckedStatus * ics = [ItemsCheckedStatus MR_findFirstWithPredicate:predicate inContext:localContext];
        [ics MR_deleteEntityInContext:localContext];
        [localObject MR_deleteEntityInContext:localContext];
    }];
}

- (BOOL) parentSyncedCheck{
    return YES;
}

+ (BOOL) isInDatabase: (NSNumber *) objectId {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"itemID == %@", objectId];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSString *) getObjectURL {
    return @"Items";
}

+ (NSArray *) getNotSyncedObjects {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    NSArray *itemArray = [self MR_findAllWithPredicate:predicate];
    return itemArray;
}

+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds {
    
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat: @"syncStatus == %@ AND NOT (itemID IN %@)", [NSNumber numberWithInt:Synced], objectIds];
    if([[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0) {
        [SignificantChangesIndicator sharedIndicator].itemsChanged = YES;
    }

    NSArray *itemArray = [self MR_findAllWithPredicate:predicate];
   
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        for (Item *item in itemArray){
           
            NSManagedObject *localObject = [item MR_inContext:localContext];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemObjectID == %@",[[localObject.objectID URIRepresentation] absoluteString]];
            ItemsCheckedStatus * ics = [ItemsCheckedStatus MR_findFirstWithPredicate:predicate inContext:localContext];
            [ics MR_deleteEntityInContext:localContext];
            [localObject MR_deleteEntityInContext:localContext];
            
        }
    }];
}


- (void) updateObjectWithResponseForInsert: (id) response{    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"itemID == %@", response[@"id"]];
        Item *item = [Item MR_findFirstWithPredicate:predicate inContext:localContext];
        if(item) {
            Item *selfDeleteItem = [self MR_inContext:localContext];
            selfDeleteItem.syncStatus = @(Deleted);
        }
        else {
            item = [self MR_inContext:localContext];
        }
        
        item.itemID =  [response objectForKey:@"id"];
        
        if([item.syncStatus intValue] != Deleted) {
        
            if([item.isChecked intValue] != [[response objectForKey:@"isChecked"] intValue] || ![item.text isEqualToString:[response objectForKey:@"text"]] || [item.groupedSortIndex intValue] != [[response objectForKey:@"groupedSortIndex"] intValue]) {
                [SignificantChangesIndicator sharedIndicator].itemsChanged = YES;
            }
            
            item.addedAt = [NSString stringWithFormat:@"%@" ,[response objectForKey:@"addedAt"]];
            item.groupedSortIndex = [response objectForKey:@"groupedSortIndex"];
            //isChecked and isTaken are commented to prevent a moment when item was created and checked offline.
            //So on the first sync iteration item appers to be checked
            //and unchecks itself only at the second iteration
            //I assume that they are always 0 at item creation on server
            //self.isChecked = [response objectForKey:@"isChecked"];
            //self.isTaken = [response objectForKey:@"isTaken"];
            item.isDefaultMatch = [response objectForKey:@"isDefaultMatch"];
            if([item.isPermanent intValue] == [[response objectForKey:@"isPermanent"] intValue]) {
                item.syncStatus = [NSNumber numberWithInt:Synced];
            }
            else {
                item.syncStatus = [NSNumber numberWithInt:Updated];
            }
            item.isPossibleMatch = [response objectForKey:@"isPossibleMatch"];
            item.knownItemText = [response objectForKey:@"knownItemText"];
            if(item.knownItemText) {
                [SignificantChangesIndicator sharedIndicator].itemsChanged = YES;
            }
            item.listId = [response objectForKey:@"listId"];
            item.matchingItemText = [response objectForKey:@"matchingItemText"];
            item.mayBeDefaultMatch = [response objectForKey:@"mayBeDefaultMatch"];
            item.placeCategory = [response objectForKey:@"placeCategory"];
            item.searchedText = response[@"searchedText"];
            item.text = response[@"text"];
            item.possibleMatches = response[@"possibleMatches"];
            item.addedAtTime = [Utility getDateFromString:item.addedAt];
            
            item.addedAtTime_local = nil;
            item.checkOrder = nil;
        }
        
        NSString *itemObjectID = [[item.objectID URIRepresentation]absoluteString];
        NSPredicate *predicate1 =[NSPredicate predicateWithFormat:@"itemObjectID = %@",itemObjectID];
  
        ItemsCheckedStatus* status = [ItemsCheckedStatus MR_findFirstWithPredicate:predicate1 inContext:localContext];
        
        if(status){
            status.itemID = item.itemID;
        }
    }];
    
    //Raj-27-10-15
    
//    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"itemID = %@",self.itemID];
//    NSMutableArray *items = [NSMutableArray arrayWithArray:[Item MR_findAllWithPredicate:predicate]];
//    [items removeObject:self];
//    if (items.count > 0) {
//        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
//            for (Item *itemToDelete in items){
//                NSManagedObject *localObject = [itemToDelete MR_inContext:localContext];
//                [localObject MR_deleteEntityInContext:localContext];
//                
//            }
//        }];
//    }
    
}

+ (BOOL) needsUpdate {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject{
    NSMutableDictionary *objectsAndIds = [NSMutableDictionary new];
    for(int i = 0; i < [[jsonResposeObject objectForKey:@"list"] count] ; i++) {
        NSMutableDictionary * objectJSON =  [NSMutableDictionary dictionaryWithDictionary:[jsonResposeObject objectForKey:@"list"][i]];
        [objectJSON setObject:[NSNumber numberWithInt:i] forKey:@"serverIndex"];
        [objectsAndIds setObject:objectJSON forKey:[objectJSON valueForKey:@"id"]];
    }
    return objectsAndIds;
}

+ (void)insertObjectWithParentCheckAndJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        [SignificantChangesIndicator sharedIndicator].itemsChanged = YES;
        
        Item *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.addedAtTime = [Utility getDateFromString:item.addedAt];
        item.syncStatus = [NSNumber numberWithInt: Synced];
    }];
}
+ (void) updateObjectWithJson: (id) objectJson{

    ///CHECK ITEM FOR CHANGED SYNC STATUS///
    //perform update only if status is Synced
    //and checked status is synced
    //for really fast changes
    NSPredicate *predicate2 =[NSPredicate predicateWithFormat:@"(itemID == %@) AND (itemID != 0)", objectJson[@"id"]];
    Item *localItem = [Item MR_findFirstWithPredicate:predicate2];
    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"itemObjectID == %@",[[localItem.objectID URIRepresentation] absoluteString]];
    ItemsCheckedStatus * localItemCheckedStatus = [ItemsCheckedStatus MR_findFirstWithPredicate:predicate3];
    
    if([localItem.syncStatus intValue] == Synced && (localItemCheckedStatus == nil || [localItemCheckedStatus.syncStatus intValue] == Synced)) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"itemID == %@ AND (NOT (text LIKE %@) OR NOT (isChecked == %@) OR NOT (groupedSortIndex == %@))", [objectJson objectForKey:@"id"], [objectJson objectForKey:@"text"], [objectJson objectForKey:@"isChecked"], [objectJson objectForKey:@"groupedSortIndex"]];
        
        if([[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0) {
            [SignificantChangesIndicator sharedIndicator].itemsChanged = YES;
        }
        
        
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            Item *item = [self MR_importFromObject:objectJson inContext:localContext];
            item.addedAtTime = [Utility getDateFromString:item.addedAt];
            item.syncStatus = [NSNumber numberWithInt: Synced];
            
            item.addedAtTime_local = nil;
            item.checkOrder = nil;
        }];
    }
}

- (NSString *) getUpdateURL{
    return [NSString stringWithFormat:@"%@/%@", [[self class] getObjectURL], [self getId]];
}
- (NSString *) getInsertURL{
    return [[self class] getObjectURL];
}

+ (REQUEST_TYPE) getGetRequestType {
    return REQUEST_GET;
}
+ (REQUEST_TYPE) getInsertRequestType {
    return REQUEST_POST;
}
+ (REQUEST_TYPE) getUpdateRequestType {
    return REQUEST_PUT;
}
+ (REQUEST_TYPE) getDeleteRequestType {
    return REQUEST_DELETE;
}

- (NSDictionary *) parseToInsertJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];

    
    if (self.text) [json setObject:self.text forKey:@"text"];
    //if (self.barcode) [json setObject:self.barcode forKey:@"barcode"];
    //if (self.barcodeType) [json setObject:self.barcodeType forKey:@"barcodeType"];
    if (self.listId) [json setObject:self.listId forKey:@"listId"];
    if(self.addedAtTime_local){
        NSNumber *secondsAgo = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSinceDate:[self addedAtTime_local]]];
        [json setObject:secondsAgo forKey:@"secondsAgo"];
    }
    if (self.source) [json setObject:self.source forKey:@"source"];
    /*
     [json setObject:self.voiceSearchText forKey:@"voiceSearchText"];
     [json setObject:self.source forKey:@"source"];
     */
    
    return json;
}

/**
 Omit isDefaultMatch because we dont have functionality for this right now
 Omit barcode stuff as this is also not yet done
 @ModifiedDate: September 9 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (NSDictionary *) parseToUpdateJSON
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    if (self.text) [json setObject:self.text forKey:@"text"];
    [json setObject:self.isPermanent forKey:@"isPermanent"];
    if (self.matchingItemText) [json setObject:self.matchingItemText forKey:@"matchingItem"];
    if (self.listId) [json setObject:self.listId forKey:@"listId"];

    // this field should not be sent until we do IOS-29
//    if (![self.matchingItemText isEqualToString:@""])
//    {
//        [json setObject:[NSNumber numberWithBool:self.isDefaultMatch] forKey:@"isDefaultMatch"];
//    }
    
    // as we are not adding/updating barcodes, uncomment when functionality added
//    if (self.barcode) [json setObject:self.barcode forKey:@"barcode"];
//    if (self.barcodeType) [json setObject:self.barcodeType forKey:@"barcodeType"];
    
    return json;

}

+ (BOOL)isHeavyObject {
    return NO;
}

- (NSString *) getDeleteURL {
    return [NSString stringWithFormat:@"%@/%@", [[self class] getObjectURL], [self getId]];
}

+ (BOOL) parentsExistForResponse:(id)responseJSON {
    return YES;
}

- (void)updateObjectWithResponseForUpdate:(id)response {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item *item = [self MR_inContext:localContext];
        if([item.isChecked intValue] != [[response objectForKey:@"isChecked"] intValue] || ![item.text isEqualToString:[response objectForKey:@"text"]]) {
            [SignificantChangesIndicator sharedIndicator].itemsChanged = YES;
        }
        
        item.addedAt = [NSString stringWithFormat:@"%@" ,[response objectForKey:@"addedAt"]];
        item.groupedSortIndex = [response objectForKey:@"groupedSortIndex"];
        item.itemID =  [response objectForKey:@"id"];
        item.isChecked = [response objectForKey:@"isChecked"];
        item.isDefaultMatch = [response objectForKey:@"isDefaultMatch"];
        item.isPermanent = [response objectForKey:@"isPermanent"];
        item.syncStatus = [NSNumber numberWithInt:Synced];
        item.isPossibleMatch = [response objectForKey:@"isPossibleMatch"];
        item.isTaken = [response objectForKey:@"isTaken"];
        item.knownItemText = [response objectForKey:@"knownItemText"];
        item.listId = [response objectForKey:@"listId"];
        item.matchingItemText = [response objectForKey:@"matchingItemText"];
        item.mayBeDefaultMatch = [response objectForKey:@"mayBeDefaultMatch"];
        item.placeCategory = [response objectForKey:@"placeCategory"];
        item.searchedText = [response objectForKey:@"searchedText"];
        
        item.text = [response objectForKey:@"text"];
        item.possibleMatches = [response objectForKey:@"possibleMatches"];
        item.addedAtTime = [Utility getDateFromString:item.addedAt];
        
        [[SyncManager sharedManager] forceSync];
    }];
    
    
    //Raj-27-10-15
    
//    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"itemID = %@",self.itemID];
//    NSMutableArray *items = [NSMutableArray arrayWithArray:[Item MR_findAllWithPredicate:predicate]];
//    [items removeObject:self];
//    if (items.count > 0) {
//        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
//            for (Item *itemToDelete in items){
//                DLog(@"ITEM TO DELETE %@",itemToDelete.text);
//                NSManagedObject *localObject = [itemToDelete MR_inContext:localContext];
//               [localContext performBlockAndWait:^{
//                   [localObject MR_deleteEntityInContext:localContext];
//                }];
//            }
//        }];
//    }
}
+(Item*)insertItemWithTextBarcode:(NSString*)text andBarcode:(NSString*)barcode andBarcodeType:(NSString*)barcodeType belongToList:(Item_list*)list withSource:(NSString *)source
{
    NSString *listObjectID = [[list.objectID URIRepresentation]absoluteString];
    NSDate *addAtTimeLocal = [NSDate date];
    NSString *addedAt = [Utility getStringFromDate:addAtTimeLocal];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext)
     {
         Item *item = [Item MR_createEntityInContext:localContext];
         item.text = text;
         item.isPermanent = @0;
         item.matchingItemText = text;
         item.isDefaultMatch = @1;
         item.barcode = barcode;
         item.barcodeType = barcodeType;
         item.listId = list.item_listID;
         item.addedAt = addedAt;
         item.syncStatus = [NSNumber numberWithInt:Synced];
         item.listObjectID = listObjectID;
         item.addedAtTime_local = addAtTimeLocal;
         item.source = source;
     }];
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listObjectID=%@) AND (text == %@) AND (addedAt == %@)",listObjectID, text, addedAt];
    Item *insertedItem = [Item MR_findFirstWithPredicate:predicate];
    
    DLog(@"Inserted item");
    return insertedItem;
}

@end
