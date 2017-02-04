//
//  Item_list+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 08/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Item_list.h"
#import "DataStore.h"
#import "SuperObject.h"

@interface Item_list (Extra)<SuperObject>
+(void)insertItems:(id)responseObject;

+(void)deleteAllItemsInContext:(NSManagedObjectContext*)context;
+(NSNumber*)getDefaultListId;
+(NSString*)getDefaultListName;
+(Item_list*)getListById:(NSNumber*)itemID;
+(NSArray*)getAllLists;
+(void)insertNewListWithName:(NSString*)name;
+(void)switchList:(NSNumber*)listID IsDefaultTo:(BOOL)isDefault;
+(Item_list*)getListById:(NSNumber*)listID andName:(NSString*)name;
+(void)fakeDelete:(NSNumber*)itemListID;
+(void)realDelete;
+(NSArray*)getAllFakeDeletedLists;
+(NSArray*)getNewLists;
+(void)updateListFromServer:(id)responseObject ByObjectID:(NSManagedObjectID*)objectID;
+(Item_list*)getDefaultList;
+(Item_list*)getUpdatedDefaultList;
//+(void)changeSyncStatusFor:(NSNumber*)itemListId;
+(int)getSortType:(Item_list*)itemList;
+(void)changeList:(Item_list*)item_list byNewOrder:(int)sortOrder andStoreID:(NSNumber*)storeID;
+(void)changeSyncStatusFor:(Item_list*)item_list;
+(void)setManualSortOrderSyncStatusFor:(Item_list*)item_list to: (SYNC_STATUS) syncStatus;

+(void) setToDefaultList:(NSNumber*)listID unsetList: (NSNumber*)listToUnsetID;

@end
