//
//  Item_list+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 08/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Item_list+Extra.h"
#import "Store+Extra.h"
#import "Item+Extra.h"
#import "Mixpanel.h"
#import "SignificantChangesIndicator.h"
#import "DataStore.h"

@implementation Item_list (Extra)
+(void)insertItems:(id)responseObject{
    NSDictionary *allItems = (NSDictionary*)responseObject;
    NSArray *itemArray = [allItems objectForKey:@"list"];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [Item_list MR_truncateAllInContext:localContext];   //clear the table before insert lists. TODO - check if this is a reasonable way for synchronization
        //Can probably be improved - Markus
        [Item_list MR_importFromArray:itemArray inContext:localContext];
        [localContext MR_saveToPersistentStoreAndWait];
    }completion:^(BOOL success, NSError *error) {
        if (error)
        {
            if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
            {
                [[Mixpanel sharedInstance] track:@"Error" properties:@{@"Message": error.localizedDescription ? error.localizedDescription : @"NULL", @"action":[NSString stringWithFormat:@"%s", __FUNCTION__]}];
            }
        }
    }];
    
}

+(void)deleteAllItemsInContext:(NSManagedObjectContext*)context{
    if (context == nil) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            
            [Item_list MR_truncateAll];
            
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
    } else {

    [Item_list MR_truncateAll];

    [context MR_saveToPersistentStoreAndWait];
    }
}

+(NSNumber*)getDefaultListId{
    
    Item_list *list = [Item_list MR_findFirstByAttribute:@"isDefault" withValue:@YES];
    if (list == nil) {
        list = [Item_list MR_findFirst];
    }
    return list.item_listID;
}

+(Item_list*)getDefaultList{
    
    Item_list *list = [Item_list MR_findFirstByAttribute:@"isDefault" withValue:@YES];
    if (list == nil) {
        list = [Item_list MR_findFirst];
    }
    return list;
}

+(Item_list*)getUpdatedDefaultList{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(isDefault == 1) AND (syncStatus == %@)", [NSNumber numberWithInt:Updated]];
    
    Item_list *list = [Item_list MR_findFirstWithPredicate:predicate];
    return list;
}

+(Item_list*)getListById:(NSNumber*)listID {
    if (listID == nil) {
        Item_list *list = [Item_list getDefaultList];
        return list;
    }
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(item_listID == %@) AND (syncStatus != %@)", listID, [NSNumber numberWithInt:Deleted]];

    Item_list *list = [Item_list MR_findFirstWithPredicate:predicate];

//    NSArray *array = [Item_list MR_findAll];
//    for (Item_list *item_list in array) {
//        DLog(@"id: %@ name:%@", item_list.item_listID, item_list.name);
//    }
    return list;
}

+(Item_list*)getListById:(NSNumber*)listID andName:(NSString*)name{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(item_listID == %@) (name == %@) AND (syncStatus != %@)", listID, name, [NSNumber numberWithInt:Deleted]];
    return [Item_list MR_findFirstWithPredicate:predicate];
}

+(NSString*)getDefaultListName{
    Item_list *list = [Item_list MR_findFirstByAttribute:@"isDefault" withValue:@YES];
    return list.name;
}

+(NSArray*)getAllLists{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Deleted]];
    NSArray *itemArray = [Item_list MR_findAllWithPredicate:predicate];
    return [itemArray sortedArrayUsingDescriptors:[self getSortDescriptor]];

}

+(NSArray*)getSortDescriptor{
  NSSortDescriptor *sort = [[NSSortDescriptor alloc]init];
  sort = [NSSortDescriptor sortDescriptorWithKey:@"item_listID" ascending:YES];
  
  return @[sort];
}

+(NSArray*)getNewLists{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus == %@ || item_listID == 0", [NSNumber numberWithInt:Created]];
    NSArray *itemArray = [Item_list MR_findAllWithPredicate:predicate];
    return itemArray;
}

+(NSArray*)getAllFakeDeletedLists{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus == %@", [NSNumber numberWithInt:Deleted]];
    NSArray *itemArray = [Item_list MR_findAllWithPredicate:predicate];
    return itemArray;
}

+(void)insertNewListWithName:(NSString*)name{
    CLS_LOG(@"Insert list.\nName:%@", name);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item_list *item = [Item_list MR_createEntityInContext:localContext];
        item.name = name;
        item.syncStatus = [NSNumber numberWithInt:Created];
    }];
}

// Fixed : 71 : ItemsLists Unable to change favourite list #iPhone4
+(void)switchList:(NSNumber*)listID IsDefaultTo:(BOOL)isDefault{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item_list *item_list = [Item_list MR_findFirstByAttribute:@"item_listID" withValue:listID inContext:localContext];
        item_list.isDefault = [NSNumber numberWithBool:isDefault];
        if([item_list.syncStatus intValue] == Synced){
            item_list.syncStatus = [NSNumber numberWithInt:Updated];
        }
    }];

}

+(void) setToDefaultList:(NSNumber*)listID unsetList: (NSNumber*)listToUnsetID {
    CLS_LOG(@"Set to default list id:%@\nUnset default list id:%@", listID, listToUnsetID);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item_list *item_list = [Item_list MR_findFirstByAttribute:@"item_listID" withValue:listID inContext:localContext];
        item_list.isDefault = [NSNumber numberWithBool:YES];
        if([item_list.syncStatus intValue] == Synced){
            item_list.syncStatus = [NSNumber numberWithInt:Updated];
        }
        
        Item_list *item_list2 = [Item_list MR_findFirstByAttribute:@"item_listID" withValue:listToUnsetID inContext:localContext];
        item_list2.isDefault = [NSNumber numberWithBool:NO];
        if([item_list2.syncStatus intValue] == Synced){
            item_list2.syncStatus = [NSNumber numberWithInt:Updated];
        }
    }];
}


+(void)changeSyncStatusFor:(Item_list*)item_list{
    
    NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_context];
    item_list.syncStatus = [NSNumber numberWithInt:Synced];
    [localContext MR_saveToPersistentStoreAndWait];
}

+(void)setManualSortOrderSyncStatusFor:(Item_list*)item_list to: (SYNC_STATUS) syncStatus {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item_list *list = [item_list MR_inContext:localContext];
        list.manualSortingSyncStatus = [NSNumber numberWithInt:syncStatus];
    }];
}

+(void)updateListFromServer:(id)responseObject ByObjectID:(NSManagedObjectID*)objectID{
    NSDictionary *response = (NSDictionary*)responseObject;
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_context];
    [localContext performBlockAndWait:^{
        Item_list *item = (Item_list *)[localContext objectWithID:objectID];
        if (nil != item)
        {
            item.item_listID = [response objectForKey:@"id"];
            item.sortOrder = [response objectForKey:@"sortOrder"];
            item.manualSortOrderIsGrouped = [response objectForKey:@"manualSortOrderIsGrouped"];
            item.syncStatus = [NSNumber numberWithInt:Synced];
            [localContext MR_saveToPersistentStoreAndWait];
            
        }
    }];

}

/**
 Set syncStatus to be Deleted. This is done before sync with server.
 */
+(void)fakeDelete:(NSNumber*)itemListID{
    CLS_LOG(@"Deleting list id: %@", itemListID);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item_list *item = [Item_list MR_findFirstByAttribute:@"item_listID" withValue:itemListID inContext:localContext];
        item.syncStatus = @(Deleted);       
        [localContext MR_saveToPersistentStoreAndWait];
    }];
}

+(void)realDelete{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus = %@",[NSNumber numberWithInt:Deleted]];
        NSArray *items = [Item_list MR_findAllWithPredicate:predicate inContext:localContext];
        
        if (items.count > 0) {
            for (Item_list *item in items){
                NSManagedObject *localObject = [item MR_inContext:localContext];
                [localObject MR_deleteEntityInContext:localContext];
                
            }
        }
    }];
}

/*Change sort order and sort by storeID
 
 DATE,
 DEFAULT,
 MANUAL,
 GROUPED,
 STORE,
 UNKNOWN
 */

+(void)changeList:(Item_list*)item_list byNewOrder:(int)sortOrder andStoreID:(NSNumber*)storeID{
    CLS_LOG(@"Cahnging item list sort order.\nList id: %@\nSort order: %d\nStore id: %@", item_list.item_listID, sortOrder, storeID);
    NSArray *typesNames = @[@"Date",@"Default",@"Manual",@"Grouped",@"Store",@"Unknown"];
    if (sortOrder > typesNames.count -1 || sortOrder < 0) {
        return;
    }
    if (![item_list isFault]) {
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            Item_list *itemList = [item_list MR_inContext:localContext];
            itemList.sortOrder = typesNames[sortOrder];
            if (storeID != nil && [storeID intValue] != 0) {
                itemList.sortByStoreId = storeID;
            }
            if([itemList.sortOrderSyncStatus intValue] == Synced){
                
                itemList.sortOrderSyncStatus = [NSNumber numberWithInt:Updated];
            }
        }];
    }
}

/*Convert string name of sort order into SORT_TYPE
 Unknown
 Date
 Default
 Manual
 Grouped
 Store
 */
+(int)getSortType:(Item_list*)itemList{
    NSArray *typesNames = @[@"Date",@"Default",@"Manual",@"Grouped",@"Store",@"Unknown"];
    NSString *sortTypeName =itemList.sortOrder;
    for (int i=0; i< typesNames.count; i++) {
        if ([sortTypeName isEqualToString:typesNames[i]]) {
            return i;
        }
    }
    return 0;

}

//SuperObject methods

- (NSNumber *)getId {
    return self.item_listID;
}

- (void) deleteObjectWithChildren {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            NSManagedObject *localObject = [self MR_inContext:localContext];
            [localObject MR_deleteEntityInContext:localContext];
    }];
}

- (BOOL) parentSyncedCheck{
    return YES;
}

+ (BOOL) isInDatabase: (NSNumber *) objectId {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"item_listID == %@", objectId];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSString *) getObjectURL {
    return @"ItemLists";
}

+ (NSArray *) getNotSyncedObjects {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    NSArray *itemArray = [Item_list MR_findAllWithPredicate:predicate];
    return itemArray;
}

+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds {
    NSPredicate *predicate =[NSPredicate predicateWithFormat: @"syncStatus == %@ AND NOT (item_listID IN %@)", [NSNumber numberWithInt:Synced], objectIds];
    NSArray *itemArray = [Item_list MR_findAllWithPredicate:predicate];
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        for (Item_list *item in itemArray){
            if([[DataStore instance].currentList.item_listID longValue] == [item.item_listID longValue]) {
                [SignificantChangesIndicator sharedIndicator].currentItemListChanged = YES;
            }
            NSManagedObject *localObject = [item MR_inContext:localContext];
            [localObject MR_deleteEntityInContext:localContext];
            
        }
    }];
}

- (void) updateObjectWithResponseForInsert: (id) response{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item_list *list = [self MR_inContext:localContext];
        list.item_listID = [response objectForKey:@"id"];

        if([list.sortOrder intValue] == [[response objectForKey:@"sortOrder"] intValue]) {
            list.sortOrderSyncStatus = [NSNumber numberWithInt:Synced];
        }
        else {
            list.sortOrderSyncStatus = [NSNumber numberWithInt:Updated];
        }
        list.manualSortOrderIsGrouped = [response objectForKey:@"manualSortOrderIsGrouped"];
        list.syncStatus = [NSNumber numberWithInt:Synced];
        
        //here all related items should be updated
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listObjectID == %@)",[[list.objectID URIRepresentation]absoluteString]];
        NSArray *itemArray = [Item MR_findAllWithPredicate:predicate inContext:localContext];
        for (Item *item in itemArray) {
            item.listId = list.item_listID;
        }
    }];
}

+ (BOOL) needsUpdate {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject{
    NSMutableDictionary *objectsAndIds = [NSMutableDictionary new];
    for (NSDictionary * objectJSON in [jsonResposeObject objectForKey:@"list"]){
        [objectsAndIds setObject:objectJSON forKey:[objectJSON valueForKey:@"id"]];
    }
    return objectsAndIds;
}

+ (void)insertObjectWithParentCheckAndJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item_list *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt: Synced];
    }];
}
+ (void) updateObjectWithJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item_list *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt: Synced];
    }];
}
- (void) updateObject {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Item_list *list = [self MR_inContext:localContext];
        list.syncStatus = [NSNumber numberWithInt:Synced];
    }];
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
    
    if(self.name) [json setObject:self.name forKey:@"name"];
    
    return json;
}
- (NSDictionary *) parseToUpdateJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    if(self.isDefault != nil) [json setObject:self.isDefault forKey:@"isDefault"];
    
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
        Item_list *list = [self MR_inContext:localContext];
        list.item_listID = [response objectForKey:@"id"];
        if ([list.sortOrderSyncStatus intValue] != Updated) {
            list.sortOrder = [response objectForKey:@"sortOrder"];
        }
        list.manualSortOrderIsGrouped = [response objectForKey:@"manualSortOrderIsGrouped"];
        list.syncStatus = [NSNumber numberWithInt:Synced];
    }];
}

@end
