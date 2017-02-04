//
//  ItemsCheckedStatus+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 16/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ItemsCheckedStatus+Extra.h"
#import "Visit+Extra.h"
#import "EndpointHash+Extra.h"

@implementation ItemsCheckedStatus (Extra)
+(void)updateItemCheckedStatus:(BOOL)checked andTaken:(BOOL)taken forItemObjectId:(NSManagedObjectID*)itemObjId forItemId:(NSNumber*)itemId inList:(NSNumber*)listID andDeviceId:(int)deviceId andCheckedReason:(NSString*)reason andLat:(float)lat andLon:(float)lon andAccuracy:(int)acc andNetworks:(NSMutableArray*)networks andSelectedStoreId: (NSNumber*) storeId {
    
    CLS_LOG(@"Checking item.\nChecked:%@\nTaken:%@\nItem id:%@\nList id:%@\nDevice id:%d\nReason:%@\nLatitude: %f\nLongitude: %f\nAccuracy: %d\nStore id:%@", checked ? @"Y" : @"N", taken ? @"Y" : @"N", itemId, listID, deviceId, reason, lat, lon, acc, storeId);
    
    NSString *itemObjectID = [[itemObjId URIRepresentation]absoluteString];
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"itemObjectID == %@", itemObjectID];
    
    //NSManagedObjectContext *localContext = [NSManagedObjectContext MR_context];
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        ItemsCheckedStatus *status = [ItemsCheckedStatus MR_findFirstWithPredicate:predicate inContext:localContext];
        if (status == nil) {
            status = [ItemsCheckedStatus MR_createEntityInContext:localContext];
            status.syncStatus = [NSNumber numberWithInt: Created];
        }
        else {
            if([status.syncStatus intValue] == Synced) {
                status.syncStatus = [NSNumber numberWithInt: Updated];
            }
            else {
                status.syncStatus = [NSNumber numberWithInt: UpdatedAgain];
            }
        }
        status.isChecked = [NSNumber numberWithBool:checked];
        status.isTaken = [NSNumber numberWithBool:taken];
        status.itemObjectID = itemObjectID;
        status.itemID = itemId;
        status.listID = listID;
        status.deviceId = [NSNumber numberWithInt:deviceId];
        status.latitude = [NSNumber numberWithFloat:lat];
        status.longitude = [NSNumber numberWithFloat:lon];
        status.positionAccuracy = [NSNumber numberWithInt:acc];
        status.checkedReason = reason;
        status.networks = networks;
        status.selectedStoreId = storeId;
        status.dateChecked_local = [NSDate new];
    }];
}

+(NSArray*)getAllNotSyncedItemsCheckedStatusWithListId: (NSNumber *) listId {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(listID == %@) AND (syncStatus != %@)",listId, [NSNumber numberWithInt:Synced]];
    NSArray *item = [ItemsCheckedStatus MR_findAllWithPredicate:predicate];
    return item;
}

+(void)changeToSyncedStatus:(NSManagedObjectID*)itemStatusObjectId{
    
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_context];
    [localContext performBlock:^{
        ItemsCheckedStatus *itemStatus = (ItemsCheckedStatus *)[localContext objectWithID:itemStatusObjectId];
        if (nil != itemStatus)
        {
            itemStatus.syncStatus = [NSNumber numberWithInt:Synced];
            [localContext MR_saveToPersistentStoreAndWait];
        }
    }];
    
}

+(void)deleteItemsStatusWithObjectID:(NSManagedObjectID*)itemsStatusObjectID{
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_context];
    [localContext performBlockAndWait:^{
        ItemsCheckedStatus *itemStatus = (ItemsCheckedStatus *)[localContext objectWithID:itemsStatusObjectID];
        if (nil != itemStatus)
        {
            NSManagedObject *localObject = [itemStatus MR_inContext:localContext];
            [localObject MR_deleteEntityInContext:localContext];
            [localContext MR_saveToPersistentStoreAndWait];
        }
    }];
}

+(void)deleteItemStatusWithItemID:(NSNumber*)itemID{
    NSManagedObjectContext*  context    = [NSManagedObjectContext MR_context];
    
    NSArray *items = [ItemsCheckedStatus MR_findByAttribute:@"itemID" withValue:itemID];
    if (items.count > 0) {
        for (ItemsCheckedStatus *item in items){
            NSManagedObject *localObject = [item MR_inContext:context];
            [localObject MR_deleteEntityInContext:context];
        }
        [context MR_saveToPersistentStoreAndWait];
    }
}

+(NSArray*)getAllItemsCheckedStatus{

    NSArray *items = [ItemsCheckedStatus MR_findAll];
    return items;
}

//SuperObject methods
- (NSNumber *)getId {
    return (NSNumber *)self.itemID;
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
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"itemObjectID == %@", objectId];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSString *) getObjectURL {
    return @"Items";
}

+ (NSArray *) getNotSyncedObjects {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@ AND itemID != 0", [NSNumber numberWithInt:Synced]];
    NSArray *itemArray = [self MR_findAllWithPredicate:predicate];
    return itemArray;
}

+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds {
    NSPredicate *predicate =[NSPredicate predicateWithFormat: @"syncStatus == %@ AND NOT (itemID IN %@)", [NSNumber numberWithInt:Synced], objectIds];
    NSArray *itemArray = [self MR_findAllWithPredicate:predicate];
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        for (ItemsCheckedStatus *item in itemArray){
            NSManagedObject *localObject = [item MR_inContext:localContext];
            [localObject MR_deleteEntityInContext:localContext];
            
        }
    }];
}

- (void) updateObjectWithResponseForInsert: (id) response{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext){
        
        ItemsCheckedStatus *ics = [self MR_inContext:localContext];
        if([ics.syncStatus intValue] == UpdatedAgain) {
            ics.syncStatus = [NSNumber numberWithInt:Updated];
        }
        else {
            ics.syncStatus = [NSNumber numberWithInt:Synced];
        }

        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"itemID == %@", [response objectForKey:@"id"]];
        Item *item = [Item MR_findFirstWithPredicate:predicate inContext:localContext];
        item.checkedAfterStart = [response objectForKey:@"checkedAfterStart"];
        item.checkOrder = nil;
    }];
}

+ (BOOL) needsUpdate {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject{
    NSMutableDictionary *objectsAndIds = [NSMutableDictionary new];
    for (NSDictionary * objectJSON in [jsonResposeObject objectForKey:@"list"]){
        [objectsAndIds setObject:[NSDictionary new] forKey:[objectJSON valueForKey:@"id"]];
    }
    return objectsAndIds;
}

+ (void)insertObjectWithParentCheckAndJson: (id) objectJson{
    /*
    No responses from server
     */
}
+ (void) updateObjectWithJson: (id) objectJson{
    /*
     No responses from server
     */
}
- (void) updateObject {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext){
        ItemsCheckedStatus *ics = [self MR_inContext:localContext];
        if([ics.syncStatus intValue] == UpdatedAgain) {
            ics.syncStatus = [NSNumber numberWithInt:Updated];
        }
        else {
            ics.syncStatus = [NSNumber numberWithInt:Synced];
        }
    }];
}

- (NSString *) getUpdateURL{
    return [NSString stringWithFormat:@"Items/%@/Checked", self.itemID];
}
- (NSString *) getInsertURL{
    return [NSString stringWithFormat:@"Items/%@/Checked", self.itemID];
}

+ (REQUEST_TYPE) getGetRequestType {
    return REQUEST_GET;
}
+ (REQUEST_TYPE) getInsertRequestType {
    return REQUEST_PUT;
}
+ (REQUEST_TYPE) getUpdateRequestType {
    return REQUEST_PUT;
}
+ (REQUEST_TYPE) getDeleteRequestType {
    return REQUEST_NONE;
}

- (NSDictionary *) parseToInsertJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];
    /*
    Visit *visit = [Visit getVisitByList:self.listID];
    NSNumber* timeDiff = visit.time_diff;
    if(timeDiff.intValue == INT32_MIN){
        timeDiff = @0;
    }

    NSNumber *newSecondsAfterStart = [NSNumber numberWithInt: (self.secondsAfterStart.intValue + timeDiff.intValue)];
    */
    if(self.deviceId) [json setObject:self.deviceId forKey:@"deviceId"];
    if(self.isChecked) [json setObject:self.isChecked forKey:@"isChecked"];
    if(self.checkedReason && [self.isChecked boolValue]) [json setObject:self.checkedReason forKey:@"checkedReason"];
    if(self.dateChecked_local) {
        NSNumber *secondsAgo = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSinceDate:self.dateChecked_local]];
        [json setObject:secondsAgo forKey:@"secondsAgo"];
    }
/*
    if(newSecondsAfterStart) {
        [json setObject:newSecondsAfterStart forKey:@"secondsAfterStart"];
    }
    else {
        [json setObject:@0 forKey:@"secondsAfterStart"];
    }
 */
    if(self.latitude && [self.latitude intValue] != 0) [json setObject:self.latitude forKey:@"latitude"];
    if(self.longitude && [self.longitude intValue] != 0) [json setObject:self.longitude forKey:@"longitude"];
    if(self.positionAccuracy && [self.positionAccuracy intValue] != 0) [json setObject:self.positionAccuracy forKey:@"positionAccuracy"];

    //if(self.networks) [json setObject:self.networks forKey:@"networks"];
    if(self.selectedStoreId) [json setObject:self.selectedStoreId forKey:@"selectedStoreId"];
    DLog(@"%@", json);
    return json;
}
- (NSDictionary *) parseToUpdateJSON {
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
