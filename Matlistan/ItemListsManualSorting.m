//
//  ItemListsManualSorting.m
//  Matlistan
//
//  Created by Artem Bakanov on 9/21/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "ItemListsManualSorting.h"

#import "Item_list+Extra.h"
#import "Item+Extra.h"

@implementation ItemListsManualSorting

/*
 NSString *request = @"Items/ManualSort";
 NSDictionary *parameters = @{@"listId":currentListId,
 @"sortedIds": sortedIDs,
 @"basedOnSortOrder": @"Manual"
 };
 MatlistanHTTPClient *httpClient = [MatlistanHTTPClient sharedMatlistanHTTPClient];
 [httpClient PUT:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
 DLog(@"Sent manual sortedIDs for list %@",currentListId);
 
 } failure:^(NSURLSessionDataTask *task, NSError *error) {
 DLog(@"Fail to send manual sortedIDs for list %@",currentListId);
 }];
 */

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
    return @"Items";
}

+ (NSArray *) getNotSyncedObjects {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"manualSortingSyncStatus != %@", [NSNumber numberWithInt:Synced]];
    NSArray *itemArray = [Item_list MR_findAllWithPredicate:predicate];
    
    NSMutableArray *itemListSortOrders = [NSMutableArray new];
    
    for (Item_list *itemList in itemArray) {
        ItemListsManualSorting *newObject = [ItemListsManualSorting new];
        
        newObject.itemListId = itemList.item_listID;
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
        itemlist.manualSortingSyncStatus = [NSNumber numberWithInt:Synced];
    }];
}

+ (BOOL) needsUpdate {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"manualSortingSyncStatus != %@", [NSNumber numberWithInt:Synced]];
    return [[Item_list MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

- (void) setSyncStatusToObject: (NSNumber *) syncStatus{
    self.syncStatus = syncStatus;
    
}

+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject{
    return nil;
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
    return [NSString stringWithFormat:@"/Items/ManualSort"];
}
- (NSString *) getInsertURL{
    return [NSString stringWithFormat:@"/Items/ManualSort"];
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
    NSMutableArray *sortedIDs = [NSMutableArray new];
    
    for (Item *item in [Item getItemsToBuyFromList:self.itemListId andList:[Item_list getListById:self.itemListId] andSortInOrder:MANUAL]) {
        if (item.itemID != nil && [item.itemID intValue] != 0) {
            [sortedIDs addObject:item.itemID];
        }
    }
    
    [json setObject:self.itemListId forKey:@"listId"];
    [json setObject:sortedIDs forKey:@"sortedIds"];
    [json setObject:@"Manual" forKey:@"basedOnSortOrder"];
    
    return json;
}

- (NSDictionary *) parseToUpdateJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];
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
