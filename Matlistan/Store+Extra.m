//
//  Store+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 08/09/14.
//  Copyright (c) 2014 Flame Soft.All rights reserved
//

#import "Store+Extra.h"
#import "Item_list+Extra.h"
#import "AppDelegate.h"

#define NEAREST_STORE_DISTANCE 3000

@implementation Store (Extra)

+(BOOL)fakeDeleteById:(NSNumber*)storeId{
    CLS_LOG(@"Deleting store with id: %@", storeId);
    if ([DataStore instance].sortingOrder == STORE && [[DataStore instance].sortByStoreID longValue] == [storeId longValue]) {
        [DataStore instance].sortingOrder = DEFAULT;
        [DataStore instance].sortByStoreID = nil;
        [DataStore instance].currentList.sortByStoreId= nil;
        [DataStore instance].currentList.sortOrder = @"Default";
    }
    if([((AppDelegate *)[UIApplication sharedApplication].delegate).storeDict[@"id"] longValue] == [storeId longValue]) {
        ((AppDelegate *)[UIApplication sharedApplication].delegate).storeDict = nil;
    }

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Store *store = [Store MR_findFirstByAttribute:@"storeID" withValue:storeId inContext:localContext];
        store.syncStatus = [NSNumber numberWithInt:Deleted];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"sortByStoreId == %@", storeId];
        NSArray *itemLists = [Item_list MR_findAllWithPredicate:predicate inContext:localContext];
        for (Item_list *list in itemLists) {
            list.sortOrder = @"Default";
            if([list.sortOrderSyncStatus intValue] == Synced){
                list.sortOrderSyncStatus = [NSNumber numberWithInt:Updated];
            }

        }
    }];
    return YES;
}


+(Store*) createStoreWithResponse:(id) response forContext: (NSManagedObjectContext*)context {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Store *store = [Store MR_createEntityInContext:localContext];
        store.storeID = [response objectForKey:@"id"];
        store.name = [response objectForKey:@"name"];
        store.postalAddress =  [response objectForKey:@"postalAddress"];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        store.postalCode =[f numberFromString:[response objectForKey:@"postalCode"]];
        store.city = [response objectForKey:@"city"];
        store.isFavorite = [response objectForKey:@"isFavorite"];
        store.itemsSortedPercent = [response objectForKey:@"itemsSortedPercent"];
        store.distance = [response objectForKey:@"distance"];
        store.syncStatus = Synced;
    }];
    return [self MR_findFirstByAttribute:@"storeID" withValue:[response objectForKey:@"id"] inContext:context];
}

+(void)insertStores:(id)responseObject
{
    NSDictionary *allItems = (NSDictionary*)responseObject;
    NSArray *itemArray = [allItems objectForKey:@"list"];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        [Store MR_importFromArray:itemArray inContext:localContext];
    }];
}

/*Insert stores by GET/StoreSearch request
 */
+(void)insertSearchedStores:(id)responseObject{

    NSArray *itemArray = (NSArray*)responseObject;
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        [Store MR_importFromArray:itemArray inContext:localContext];
    }];
}

/**
 store address for new store
 @ModifiedDate: September 11, 2015
 @Version:1.14
 @Author: 
 @Modified by: Yousuf
 */
+(void)insertSearchedStore:(SearchedStore*)newStore
{
    CLS_LOG(@"Insert store.\nTitle: %@\nName: %@", newStore.title, newStore.name);
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext)
     {
        Store *item = [Store MR_createEntityInContext:localContext];
        item.title = newStore.title;
        item.city = newStore.city;
        item.postalAddress = newStore.postalAddress;
        item.postalCode = newStore.postalCode;
        item.name = newStore.name;
        item.distance = newStore.distance;
        item.isFavorite = newStore.isFavorite;
        item.itemsSortedPercent = newStore.itemsSortedPercent;
        item.storeID = newStore.searchedStoreID;
        item.address = newStore.address;

    } completion:^(BOOL success, NSError *error) {
        
    }];
}

+(Store *)insertSearchedStore:(NSString*)storeTitle storeCity:(NSString *)storeCity postalAddress:(NSString *)postalAddress postalCode:(NSNumber *)postalCode  name:(NSString *)name distance:(NSNumber *)distance isFavorite:(NSNumber *)isFavorite itemsSortedPercent:(NSNumber *)itemsSortedPercent storeID:(NSNumber *)storeID address:(NSString *)address
{
    CLS_LOG(@"Insert store.\nTitle: %@\nName: %@", storeTitle, name);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Store *item = [Store MR_createEntityInContext:localContext];
        item.title = storeTitle;
        item.city = storeCity;
        item.postalAddress = postalAddress;
        item.postalCode = postalCode;
        item.name = name;
        item.distance = distance;
        item.isFavorite = isFavorite;
        item.itemsSortedPercent = itemsSortedPercent;
        item.storeID = storeID;
        item.address = address;

    }];
    
    Store *insertedStore = [Store MR_findFirstByAttribute:@"storeID" withValue:storeID];
    return insertedStore;
}
+(void)deleteAllItems
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [Store MR_truncateAll];
        
        [localContext MR_saveToPersistentStoreAndWait];
    }completion:^(BOOL success, NSError *error) {
    
    }];
    
    
}

+(NSArray*)getAllStores
{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Deleted]];
    NSArray *itemArray = [Store MR_findAllWithPredicate:predicate];
   // DLog(@"itemArray %@",itemArray);
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"itemsSortedPercent" ascending:NO];
    NSSortDescriptor *sortByDistance = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    return [itemArray sortedArrayUsingDescriptors:@[sortByDistance, sort]];
}

+(NSArray*)getStoresCloseby {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"distance <= %@", @NEAREST_STORE_DISTANCE];
    NSArray *resultArray = [Store MR_findAllWithPredicate:predicate];
    return resultArray;
}

+ (Store*)getFavoriteStore
{   
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"isFavorite == %@", @YES];
    NSArray *resultArray = [Store MR_findAllWithPredicate:predicate];
    if (resultArray.count > 0) {
        Store *store = resultArray[0];
        return store;
    }
    else{
        NSArray *itemArray = [Store MR_findAllSortedBy:@"name" ascending:YES];
        if (itemArray.count > 0) {
            return (Store*)itemArray[0];
        }
        else{
            return nil;
        }
    }
}

+(NSArray*)getAllStoresByStatus:(SYNC_STATUS)status{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(syncStatus = %@)", [NSNumber numberWithInt:status]];
    NSArray *itemArray = [Store MR_findAllWithPredicate:predicate];
    
    return itemArray;
}

+ (Store*)getStoreByID:(NSNumber*)storeID
{
    if (storeID == nil) {
        return nil;
    }
    Store *store = [Store MR_findFirstByAttribute:@"storeID" withValue:storeID];
    return store;
}


+(void)setFavorite:(BOOL)isFavorite forStore:(Store*)store{
    CLS_LOG(@"Set favourite store.\nStore id: %@\nIs favourite: %@", store.storeID, isFavorite ? @"Y" : @"N");
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Store *localStore = [store MR_inContext:localContext];
        localStore.isFavorite = [NSNumber numberWithBool:isFavorite];
        if([localStore.syncStatus intValue] == Synced){
            localStore.syncStatus = [NSNumber numberWithInt:Updated];
        }
    }];
}

+(void)changeSyncStatus:(SYNC_STATUS)status for:(NSNumber*)storeID{

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Store *store = [Store MR_findFirstByAttribute:@"storeID" withValue:storeID];
        store.syncStatus = [NSNumber numberWithInt:status];
        [localContext MR_saveToPersistentStoreAndWait];
    }completion:^(BOOL success, NSError *error) {
        
    }];
}


+(NSArray*)getFavouriteStoresArray{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isFavorite == %@", @YES];
    return [[Store getAllStores] filteredArrayUsingPredicate:pred];
}

+(BOOL)checkIfOneOftheFavouriteStoresWithName:(NSString *)storeNameIn{
    //NSArray *favoriteStores = [[Store getAllStores] filteredArrayUsingPredicate:predicateIn];
    NSArray *favoriteStores = [self getFavouriteStoresArray];
    NSArray *matchedStore = nil;
    if (favoriteStores && favoriteStores.count > 0)
        matchedStore = [favoriteStores filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@",storeNameIn]];
    if (matchedStore && matchedStore.count > 0){
        DLog(@"someStore.name = %@",((Store *)[matchedStore firstObject]).name)
        return YES;
    }
    return NO;
}
+(Store *)getFavoriteStoreWithName:(NSString *)nameIn{
    NSArray *favoriteStores = [self getFavouriteStoresArray];
    NSArray *matchedStore = nil;
    if (favoriteStores && favoriteStores.count > 0)
        matchedStore = [favoriteStores filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@",nameIn]];
    if (matchedStore && matchedStore.count > 0){
        Store *someStore = (Store *)[matchedStore firstObject];
        DLog(@"someStore.name = %@",someStore.name)
        return someStore;
    }
    return nil;
}

+(int) getNumberOfFavouriteStores {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite == %@", @YES];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue];
}

//SuperObject methods
- (void) updateObject {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Store *store = [self MR_inContext:localContext];
        store.syncStatus = [NSNumber numberWithInt:Synced];
    }];
}

- (NSNumber *)getId {
    return self.storeID;
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
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"storeID == %@", objectId];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSString *) getObjectURL {
    return @"Stores";
}

+ (NSArray *) getNotSyncedObjects {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    NSArray *itemArray = [self MR_findAllWithPredicate:predicate];
    return itemArray;
}

+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds {
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat: @"syncStatus == %@ AND NOT (storeID IN %@)", [NSNumber numberWithInt:Synced], objectIds];
    NSArray *itemArray = [self MR_findAllWithPredicate:predicate];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        for (Store *item in itemArray){
            NSManagedObject *localObject = [item MR_inContext:localContext];
            [localObject MR_deleteEntityInContext:localContext];
            
        }
    }];
}


- (void) updateObjectWithResponseForInsert: (id) response{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Store *store = [self MR_inContext:localContext];
        store.storeID = [response objectForKey:@"id"];
        store.name = [response objectForKey:@"name"];
        store.postalAddress =  [response objectForKey:@"postalAddress"];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        store.postalCode =[f numberFromString:[response objectForKey:@"postalCode"]];
        store.city = [response objectForKey:@"city"];
        store.isFavorite = [response objectForKey:@"isFavorite"];
        store.itemsSortedPercent = [response objectForKey:@"itemsSortedPercent"];
        store.distance = [response objectForKey:@"distance"];
        
        store.syncStatus = [NSNumber numberWithInt:Synced];
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
        Store *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt: Synced];
    }];
}

+ (void) updateObjectWithJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Store *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt: Synced];
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
    return REQUEST_PATCH;
}
+ (REQUEST_TYPE) getDeleteRequestType {
    return REQUEST_DELETE;
}

- (NSDictionary *) parseToInsertJSON{
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    if (self.isFavorite) [json setObject:self.isFavorite forKey:@"isFavorite"];
    
    return json;
}
- (NSDictionary *) parseToUpdateJSON{
    return [self parseToInsertJSON];
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
    [self updateObjectWithResponseForInsert:response];
}

@end
