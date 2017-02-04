//
//  Item_list.h
//  MatListan
//
//  Created by Yan Zhang on 17/04/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item, Store;

@interface Item_list : NSManagedObject

@property (nonatomic, retain) NSNumber * isDefault;
@property (nonatomic, retain) NSNumber * item_listID;
@property (nonatomic, retain) NSNumber * manualSortOrderIsGrouped;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * sortByStoreId;
@property (nonatomic, retain) NSString * sortOrder;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSNumber * sortOrderSyncStatus;
@property (nonatomic, retain) NSNumber * manualSortingSyncStatus;
@property (nonatomic, retain) NSSet *items;
@property (nonatomic, retain) Store *relatedStore;
@end

@interface Item_list (CoreDataGeneratedAccessors)

- (void)addItemsObject:(Item *)value;
- (void)removeItemsObject:(Item *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
