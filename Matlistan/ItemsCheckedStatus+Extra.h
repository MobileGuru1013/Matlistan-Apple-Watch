//
//  ItemsCheckedStatus+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 16/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ItemsCheckedStatus.h"
#import "DataStore.h"
#import "Item+Extra.h"
#import "SuperObject.h"

@interface ItemsCheckedStatus (Extra)<SuperObject>

+(void)updateItemCheckedStatus:(BOOL)checked andTaken:(BOOL)taken forItemObjectId:(NSManagedObjectID*)itemObjId forItemId:(NSNumber*)itemId inList:(NSNumber*)listID andDeviceId:(int)deviceId andCheckedReason:(NSString*)reason andLat:(float)lat andLon:(float)lon andAccuracy:(int)acc andNetworks:(NSMutableArray*)networks andSelectedStoreId: (NSNumber*) storeId;
+(NSArray*)getAllItemsCheckedStatus;
+(void)deleteItemStatusWithItemID:(NSNumber*)itemID;
+(void)changeToSyncedStatus:(NSManagedObjectID*)itemStatusObjectId;
+(void)deleteItemsStatusWithObjectID:(NSManagedObjectID*)itemsStatusObjectID;
+(NSArray*)getAllNotSyncedItemsCheckedStatusWithListId: (NSNumber *) listId;

@end
