//
//  Item+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 08/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Item.h"
#import "DataStore.h"
#import "SuperObject.h"

/*
 Taken
 OutOfOrder
 SoldOut
 NotInThisStore
 NotThisTime
 Remove
 Unknown
 */
typedef enum CHECK_REASON
{
    TAKEN,
    OUT_OF_ORDER,
    MOVED,
    SOLD_OUT,
    NOT_IN_STORE,
    NOT_THIS_TIME,
    REMOVE,
    UNKNOWN_REASON
    
} CHECK_REASON;

@interface Item (Extra)<SuperObject>
+(void)insertItems:(id)responseObject;
+(void)updateItem:(id)responseObject forItemWithID:(NSManagedObjectID*)itemObjID;
+(void)insertItemWithText:(NSString*)text andBarcode:(NSString*)barcode andBarcodeType:(NSString*)barcodeType andListId:(NSNumber*)listId andAddedAt:(NSString*)addedAt;
+(void)deleteAllItemsInContext:(NSManagedObjectContext*)context;
+(void)fakeDelete:(NSNumber*)itemId withText:(NSString*)text andListID:(NSNumber*)listId;
+(void)updateItemWithId:(NSNumber*)itemId andText:(NSString*)text andisPermanent:(NSNumber*)isPermanent andMatchingItem:(NSString*)matchingItem andIsDefaultMatch:(NSNumber *)isDefaultMatch;
+(void)realDeleteWithPredicate:(NSPredicate*)predicate;
+(void)realDelete;
+(void)fakeDelete:(NSManagedObjectID*)itemObjectId;
+(void)checkItem:(NSManagedObjectID*)itemObjectId withCheckStatus:(BOOL)checked andReason:(CHECK_REASON)reason;
+(NSArray*)getSortDescriptor:(SORT_TYPE)type;

+(NSArray*)getAllItemsFakeDeletedInList;
+(void)updateItem:(NSNumber*)itemId WithManualIndex:(NSUInteger)index;
+(void)insertItemWithID:(NSNumber*)itemId andText:(NSString*)text andBarcode:(NSString*)barcode andBarcodeType:(NSString*)barcodeType andListId:(NSNumber*)listId andAddedAt:(NSString*)addedAt;
+(NSArray*)getAllItemsByStatus:(SYNC_STATUS)status;
+(void)changeSyncStatus:(SYNC_STATUS)status for:(NSNumber*)itemId;
+(Item*)getItemInList:(NSNumber*)listId withItemID:(NSNumber*)itemID;
+(Item*)getDeletedItemInList:(NSNumber*)listId withItemID:(NSNumber*)itemID;

+ (Item *)insertItemWithText:(NSString*)text andBarcode:(NSString*)barcode andBarcodeType:(NSString*)barcodeType belongToList:(Item_list*)list withSource:(NSString *)source;

+(NSArray*)getItemsToBuyFromList:(NSNumber*)listId andList:(Item_list*)list andSortInOrder:(SORT_TYPE)sortIndex;

//+(Item*)getItemInList:(NSNumber*)listId WithObjectId:(NSManagedObjectID*)listObjectId withItemID:(NSNumber*)itemID andItemObjectID:(NSManagedObjectID*)itemObjID;
+(NSArray*)getAllItemsExceptDeletedFromList:(Item_list*)list withId:(NSNumber*)listId andSortInOrder:(SORT_TYPE)sortIndex andIsChecked:(BOOL)isChecked;

-(void)updateItemWithText:(NSString *)text andisPermanent:(NSNumber *)isPermanent andMatchingItem:(NSString *)matchingItem andIsDefaultMatch:(NSNumber *)isDefaultMatch withKnownItemText:(NSString *)knownItemText andItemListId: (NSNumber *) itemListId;
-(void)updateItemWithMatchingText:(NSString*)matchingItem andIsPossibleMatch:(NSNumber *)isPossibleMatch;
-(void) updateItemWithItemListId:(NSNumber *)itemListId;

+ (NSArray *)getAllItemsInList:(NSNumber*)listId exceptItemIds:(NSMutableArray *)arrItemIds;

+ (void) clearUncheckedItems;
+(Item*)insertItemWithTextBarcode:(NSString*)text andBarcode:(NSString*)barcode andBarcodeType:(NSString*)barcodeType belongToList:(Item_list*)list withSource:(NSString *)source;
+(void) fakeDeleteItem:(Item *) itemToDelete;
@end
