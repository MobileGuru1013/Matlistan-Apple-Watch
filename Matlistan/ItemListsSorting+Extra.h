//
//  ItemListsSorting+Extra.h
//  Matlistan
//
//  Created by Artem Bakanov on 9/11/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ItemListsSorting.h"

@interface ItemListsSorting (Extra)

+ (ItemListsSorting *) getSortingForItemListId: (NSNumber*) itemListID andShopId: (NSNumber*) shopId;
+ (ItemListsSorting *) insertSortingWithItemListId:(NSNumber*)item_listID andShopId:(NSNumber*)shopID;

- (void) saveObject;

@end
