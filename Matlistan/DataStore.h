//
//  DataStore.h
//  MatListan
//
//  Created by Yan Zhang on 07/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Item_list+Extra.h"

#import "SyncStatusEnum.h"


#define SORT_KEY @"SORT_KEY"
typedef enum SORT_TYPE
{
    DATE,
    DEFAULT,
    MANUAL,
    GROUPED,
    STORE,
    UNKNOWN
 
} SORT_TYPE;
typedef enum SORT_TYPE_RECIPE
{
    NEWEST,
    ALPHABETICALLY,
    MOST_COOKED,
    LEAST_COOKED,
    LATEST_COOKED,
    EARLEST_COOKED,
    SHORTEST_TIME,
    HIGHEST_CREDIT,
    RANDOM
    
}SORT_TYPE_RECIPE;
/*
typedef enum {
    Synced = 0,
    Created,
    Updated,
    Deleted
} SYNC_STATUS;
*/
@interface DataStore : NSObject

+ (DataStore *) instance;
- (id)init;
- (void)resetDataStore;

@property (nonatomic,retain)NSString *cookie;
@property (nonatomic,retain)NSMutableDictionary *allItemsForAList;
@property (nonatomic,retain)NSMutableArray *recipeIDs;
@property (nonatomic,retain) NSMutableArray *sorteditemsList;//sorted shoppinglist
@property (nonatomic,retain) NSMutableArray *toBuyItems;
@property (nonatomic,retain) NSMutableArray *recipeList;
@property (nonatomic,retain) NSMutableArray *recipeWithImageList;
@property (nonatomic,retain)NSMutableArray *activeRecipes;
@property (nonatomic,retain)NSMutableArray *items;  //all items in the shoppinglist from /ITEMS request

@property (nonatomic)BOOL isSortingTableRows;

@property (nonatomic)SORT_TYPE previousSortingOrder;
@property (nonatomic,retain)NSNumber *previousSortByStoreID;
@property (nonatomic)SORT_TYPE sortingOrder;
@property (nonatomic,retain)NSNumber *sortByStoreID;

@property (nonatomic)long currentRecipeID;
@property (nonatomic)long currentRecipeIndex;
@property (nonatomic,retain)NSString *ingredientByURL;
@property (nonatomic,retain)NSString * iTemNameNotAddedYet;
@property (nonatomic,retain)NSString *tagByURL;
@property (nonatomic)long timestampForSync;
@property (nonatomic,retain)NSString *userName;
@property (nonatomic,retain)NSString *password;
@property (nonatomic,retain)Item_list *currentList;
@property (nonatomic)int randomDeviceID;
@property (nonatomic,retain)NSMutableArray *viewedRecipes;
@property (nonatomic)BOOL hasListBeenShown;

@property BOOL appPurchased;

- (void) setPreviousSortingOrder;
@end
