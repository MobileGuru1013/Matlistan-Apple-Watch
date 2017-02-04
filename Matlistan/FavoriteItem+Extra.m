//
//  FavoriteItem+Extra.m
//  Matlistan
//
//  Created by Artem Bakanov on 12/8/15.
//  Copyright © 2015 Consumiq AB. All rights reserved.
//

#import "FavoriteItem+Extra.h"

@implementation FavoriteItem (Extra)

//SuperObject methods

- (id)getId {
    return self.text;
}

- (void) deleteObjectWithChildren {
    /*No need to delete virtual objects*/
}

- (BOOL) parentSyncedCheck{
    /*this object have no parents*/
    return YES;
}

+ (BOOL) isInDatabase: (NSNumber *) objectId {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"text == %@", objectId];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSString *) getObjectURL {
    return @"Items/Favorites";
}

+ (NSArray *) getNotSyncedObjects {
    return [NSArray new];
}

+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds {
    NSPredicate *predicate =[NSPredicate predicateWithFormat: @"NOT (text IN %@)", objectIds];
    
    NSArray *itemArray = [self MR_findAllWithPredicate:predicate];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        for (FavoriteItem *item in itemArray){
            NSManagedObject *localObject = [item MR_inContext:localContext];
            [localObject MR_deleteEntityInContext:localContext];
        }
    }];
}

- (void) updateObjectWithResponseForInsert: (id) response{
    //No insert responses
}

+ (BOOL) needsUpdate {
    return NO;
}

- (void) setSyncStatusToObject: (NSNumber *) syncStatus{
    //no sync status here
}

+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject{
    NSMutableDictionary *objectsAndIds = [NSMutableDictionary new];
    int i = 0;
    for (NSDictionary * objectJSON in [jsonResposeObject objectForKey:@"list"]){
        NSMutableDictionary *zzz = [NSMutableDictionary dictionaryWithDictionary:objectJSON];
        [zzz setObject:[NSNumber numberWithInt:i] forKey:@"sortOrder"];
        [objectsAndIds setObject:zzz forKey:[objectJSON valueForKey:@"text"]];
        i++;
    }
    return objectsAndIds;
}

+ (void)insertObjectWithParentCheckAndJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        [self MR_importFromObject:objectJson inContext:localContext];
    }];
}

+ (void) updateObjectWithJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"text == %@", [objectJson valueForKey:@"text"]];
        FavoriteItem *item = [self MR_findFirstWithPredicate:predicate inContext:localContext];
        item.text = [objectJson valueForKey:@"text"];
        item.sortOrder = [objectJson valueForKey:@"sortOrder"];
        item.matchingItem = [objectJson valueForKey:@"matchingItem"];
    }];
}

- (void) updateObject {
}

- (NSString *) getUpdateURL{
    return nil;
}
- (NSString *) getInsertURL{
    return nil;
}

+ (REQUEST_TYPE) getGetRequestType {
    return REQUEST_GET;
}
+ (REQUEST_TYPE) getInsertRequestType {
    return REQUEST_NONE;
}
+ (REQUEST_TYPE) getUpdateRequestType {
    return REQUEST_NONE;
}
+ (REQUEST_TYPE) getDeleteRequestType {
    return REQUEST_NONE;
}

- (NSDictionary *) parseToInsertJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];
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

- (NSNumber *) syncStatus {
    return [NSNumber numberWithInt:Synced];
}

@end
