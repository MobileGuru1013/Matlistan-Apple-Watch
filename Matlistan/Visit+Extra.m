//
//  Visit+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 26/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Visit+Extra.h"
#import "ItemsCheckedStatus+Extra.h"

#define SECONDS_FOR_TWO_HOURS 7200
@implementation Visit (Extra)

+ (NSDate *) getLastCheckTime {
    return [NSDate dateWithTimeIntervalSince1970:[[Visit MR_aggregateOperation:@"max:" onAttribute:@"updated_at" withPredicate:nil] doubleValue]];
}

+(NSArray*)getAllVisits{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Deleted]];
    NSArray *itemArray = [Visit MR_findAllWithPredicate:predicate];
    return itemArray;
}

+(Visit*)getVisitByList:(NSNumber*)listID{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"list =%@", listID];
    Visit *visit = [Visit MR_findFirstWithPredicate:predicate];
    return visit;
}

+(void)insertVisitWithStarted:(NSNumber*)startedAt andUpdated:(NSNumber*)updatedAt andTimeDiff:(NSNumber*)timeDiff forListID:(NSNumber*)listID{
    CLS_LOG(@"Insert Visit.\nStarted at:%@\nUpdated at%@\n Time diff:%@\nList id:%@", startedAt, updatedAt, timeDiff, listID);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Visit *visit = [Visit MR_createEntityInContext:localContext];
        visit.started_at = startedAt;
        visit.updated_at = updatedAt;
        visit.time_diff = timeDiff;
        visit.list = listID;
        visit.syncStatus = [NSNumber numberWithInt:Updated];
    }];
}

+(void)updateVisitUpdatedAt:(NSNumber*)listId{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"list= %@", listId];
        Visit *visit = [Visit MR_findFirstWithPredicate:predicate];
        long timestamp = (long)[Utility getTimeStamp];
        visit.updated_at = [NSNumber numberWithLong:timestamp];
    }completion:^(BOOL success, NSError *error) {
    }];
}

+(void)updateVisitTimeDiff:(NSNumber*)timeDiff forList:(NSNumber*)listId{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"list= %@", listId];
        Visit *visit = [Visit MR_findFirstWithPredicate:predicate];
        visit.time_diff = timeDiff;
    }completion:^(BOOL success, NSError *error) {
    }];
}

+(void)cleanOldVisits{
    
    long oldestTimeStamp = [Utility getTimeStamp] - SECONDS_FOR_TWO_HOURS;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"updated_at < %@",[NSNumber numberWithLong:oldestTimeStamp]];
        NSArray *items = [Visit MR_findAllWithPredicate:predicate inContext:localContext];
        
        if (items.count > 0) {
            for (Visit *item in items){
                NSManagedObject *localObject = [item MR_inContext:localContext];
                [localObject MR_deleteEntityInContext:localContext];
                
            }
        }
    }];

}

//SuperObject methods

- (NSNumber *)getId {
    return self.list;
}

- (void) deleteObjectWithChildren {
    //No need to delete
}

- (BOOL) parentSyncedCheck{
    return YES;
}

+ (BOOL) isInDatabase: (NSNumber *) objectId {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"list == %@", objectId];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSString *) getObjectURL {
    return @"Visits";
}

+ (NSArray *) getNotSyncedObjects {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    NSMutableArray *visitsArray = [NSMutableArray arrayWithArray:[Visit MR_findAllWithPredicate:predicate]];
    
    NSArray *itemsChackedArray = [ItemsCheckedStatus MR_findAllWithPredicate:predicate];
    for (ItemsCheckedStatus *icStatus in itemsChackedArray) {
        Visit *visit = [Visit getVisitByList:icStatus.listID];
        long currentTime = (long)[Utility getTimeStamp];
        if (visit == nil) {
            //create a new visit: startedAt = updatedAt = now() time_diff=int.minvalue
            DLog(@"create a new visit");
            [Visit insertVisitWithStarted:[NSNumber numberWithLong:currentTime] andUpdated:[NSNumber numberWithLong:currentTime] andTimeDiff:[NSNumber numberWithLong:INT32_MIN] forListID:icStatus.listID];
            visit = [Visit getVisitByList:icStatus.listID];
            [visitsArray addObject:visit];
        }
    }
    
    return visitsArray;
}

+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds {
    //No need to delete objects
}

+ (BOOL) needsUpdate {
    //Never called, updates automatically when ItemsCheckedStatus requires update
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    return [[ItemsCheckedStatus MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject{
    NSMutableDictionary *objectsAndIds = [NSMutableDictionary new];
    for (NSDictionary * objectJSON in [jsonResposeObject objectForKey:@"list"]){
        Visit *visit = [Visit getVisitByList:[objectJSON valueForKey:@"id"]];
        NSNumber* timeDiff = visit.time_diff;
        if(timeDiff.intValue == INT32_MIN){
            [objectsAndIds setObject:[NSDictionary new] forKey:[objectJSON valueForKey:@"id"]];
        }
    }
    return objectsAndIds;
}

+ (void)insertObjectWithParentCheckAndJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Visit *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt: Synced];
    }];
}

- (void) updateObjectWithResponseForInsert: (id) response {
    //no need in this
}

- (void) updateObjectWithResponseForUpdate: (id) response {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Visit *visit = [self MR_inContext:localContext];
        visit.time_diff = [response objectForKey:@"secondsAfterStart"];
        //self.store = [response objectForKey:@"store"];
        visit.syncStatus = Synced;
    }];
}

+ (void) updateObjectWithJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Visit *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt: Synced];
    }];
}
- (void) updateObject {
    [[self managedObjectContext] MR_saveToPersistentStoreAndWait];
}

- (NSString *) getUpdateURL{
    return [NSString stringWithFormat:@"Visits/Current/%@", self.list];
}
- (NSString *) getInsertURL{
    return nil;
}

+ (REQUEST_TYPE) getGetRequestType {
    return REQUEST_NONE;
}
+ (REQUEST_TYPE) getInsertRequestType {
    return REQUEST_NONE;
}
+ (REQUEST_TYPE) getUpdateRequestType {
    return REQUEST_GET;
}
+ (REQUEST_TYPE) getDeleteRequestType {
    return REQUEST_NONE;
}

- (NSDictionary *) parseToInsertJSON {
    return nil;
}
- (NSDictionary *) parseToUpdateJSON {
    return nil;
}

+ (BOOL)isHeavyObject {
    return NO;
}

- (NSString *) getDeleteURL {
    return nil;
}

+ (NSString*) heavyObjectURL: (NSNumber *) objectId{
    return [NSString stringWithFormat:@"Visits/Current/%@", objectId];
}
+ (REQUEST_TYPE) heavyObjectGetRequestType{
    return REQUEST_NONE;
}

+ (NSDictionary *) getHeavyParameters{
    return  nil;
}

+ (BOOL) parentsExistForResponse:(id)responseJSON {
    return YES;
}

//remove all ids that are not needed to update
+ (NSDictionary *) removeIdsNotNeededToUpdate: (NSDictionary *) remoteObjectsIdsAndObjects{
    return remoteObjectsIdsAndObjects;
}


@end
