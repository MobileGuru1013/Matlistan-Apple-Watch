//
//  ItemListsSortOrder.m
//  Matlistan
//
//  Created by Artem Bakanov on 7/30/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "ItemListsSortOrder.h"

#import "Item_list+Extra.h"

@implementation ItemListsSortOrder

//SuperObject methods

- (NSNumber *)getId {
    return self.itemListId;
}

- (void) deleteObjectWithChildren {
    /*No need to delete virtual objects*/
}

- (BOOL) parentSyncedCheck{
    /*virtual objects have no parents*/
    return YES;
}

+ (BOOL) isInDatabase: (NSNumber *) objectId {
    /*virtual objects are always in database*/
    return YES;
}

+ (NSString *) getObjectURL {
    return @"ItemLists";
}

+ (NSArray *) getNotSyncedObjects {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"sortOrderSyncStatus != %@", [NSNumber numberWithInt:Synced]];
    NSArray *itemArray = [Item_list MR_findAllWithPredicate:predicate];
    
    NSMutableArray *itemListSortOrders = [NSMutableArray new];
    
    for (Item_list *itemList in itemArray) {
        ItemListsSortOrder *newObject = [ItemListsSortOrder new];
        
        newObject.itemListId = itemList.item_listID;
        newObject.sortOrder = itemList.sortOrder;
        newObject.storeId = itemList.sortByStoreId;
        newObject.syncStatus = [NSNumber numberWithInt:Created];
        
        [itemListSortOrders addObject:newObject];
    }
    
    return itemListSortOrders;
}

+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds {
    /*No need to delete virtual objects*/
}

- (void) updateObjectWithResponseForInsert: (id) response{
    /*this object never comes from server*/
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"item_listID == %@", self.itemListId];
        Item_list *itemlist = [Item_list MR_findFirstWithPredicate:predicate inContext:localContext];
        if([itemlist.sortOrder isEqualToString:self.sortOrder]) {
            itemlist.sortOrderSyncStatus = [NSNumber numberWithInt:Synced];
        }
    }];
}

+ (BOOL) needsUpdate {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"sortOrderSyncStatus != %@", [NSNumber numberWithInt:Synced]];
    return [[Item_list MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

- (void) setSyncStatusToObject: (NSNumber *) syncStatus{
    self.syncStatus = syncStatus;
    
}

+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject{
    NSMutableDictionary *objectsAndIds = [NSMutableDictionary new];
    for (NSDictionary * objectJSON in [jsonResposeObject objectForKey:@"list"]){
        [objectsAndIds setObject:objectJSON forKey:[objectJSON valueForKey:@"id"]];
    }
    return objectsAndIds;
}

+ (void)insertObjectWithParentCheckAndJson: (id) objectJson{
    /*this object never comes from server*/
}
+ (void) updateObjectWithJson: (id) objectJson{
    /*this object never comes from server*/
}
- (void) updateObject {
    /*this object never comes from server*/
}

- (NSString *) getUpdateURL{
    return [NSString stringWithFormat:@"ItemLists/%@/SortOrder", [self getId]];
}
- (NSString *) getInsertURL{
    return [NSString stringWithFormat:@"ItemLists/%@/SortOrder", [self getId]];
}

+ (REQUEST_TYPE) getGetRequestType {
    return REQUEST_NONE;
}
+ (REQUEST_TYPE) getInsertRequestType {
    return REQUEST_PUT;
}
+ (REQUEST_TYPE) getUpdateRequestType {
    return REQUEST_NONE;
}
+ (REQUEST_TYPE) getDeleteRequestType {
    return REQUEST_NONE;
}

- (NSDictionary *) parseToInsertJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    if(self.sortOrder) [json setObject:self.sortOrder forKey:@"sortOrder"];
    if(self.storeId && [self.storeId intValue] != 0 && [@"Store" isEqualToString:self.sortOrder]) [json setObject:self.storeId forKey:@"storeId"];
    
    return json;
}

- (NSDictionary *) parseToUpdateJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    if(self.sortOrder) [json setObject:self.sortOrder forKey:@"sortOrder"];
    if(self.storeId && [self.storeId intValue] != 0 && [@"Store" isEqualToString:self.sortOrder]) [json setObject:self.storeId forKey:@"storeId"];
    
    return json;
}

+ (BOOL)isHeavyObject {
    return NO;
}

- (NSString *) getDeleteURL {
    return nil;
}

+ (BOOL) parentsExistForResponse:(id)responseJSON {
    return YES;
}

- (void)updateObjectWithResponseForUpdate:(id)response {
    [self updateObjectWithResponseForInsert:response];
}

@end
