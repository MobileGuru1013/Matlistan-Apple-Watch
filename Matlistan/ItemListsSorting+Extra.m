//
//  ItemListsSorting+Extra.m
//  Matlistan
//
//  Created by Artem Bakanov on 9/11/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "ItemListsSorting+Extra.h"

@implementation ItemListsSorting (Extra)

+ (ItemListsSorting *) getSortingForItemListId:(NSNumber *)itemListID andShopId: (NSNumber*) shopId
{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"item_listID = %@ AND shopID == %@", itemListID, shopId];
    return [ItemListsSorting MR_findFirstWithPredicate:predicate];
}

+ (ItemListsSorting*)insertSortingWithItemListId:(NSNumber*)item_listID andShopId:(NSNumber*)shopID
{

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext)
     {
         ItemListsSorting *itemSorting = [ItemListsSorting MR_createEntityInContext:localContext];
         itemSorting.item_listID = item_listID;
         itemSorting.shopID = shopID;
         itemSorting.sortingHashCode = @0;
     }];

    ItemListsSorting *insertedItem = [self getSortingForItemListId: item_listID andShopId: shopID];
    return insertedItem;
}

- (void) saveObject
{
    [[self managedObjectContext] MR_saveToPersistentStoreAndWait];
}

@end
