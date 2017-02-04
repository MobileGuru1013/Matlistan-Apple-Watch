//
//  DataStore.m
//  MatListan
//
//  Created by Yan Zhang on 07/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "DataStore.h"

@implementation DataStore


static DataStore *instance=nil;

+(DataStore*)instance
{
    @synchronized(self)
    {
        if (instance == nil)
        {
            instance = [[DataStore alloc]init];
        }
    }
    return instance;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        self.isSortingTableRows = NO;
        self.allItemsForAList = [[NSMutableDictionary alloc]init];
        self.recipeIDs = [[NSMutableArray alloc]init];
        self.sorteditemsList = [[NSMutableArray alloc]init];
        self.toBuyItems = [[NSMutableArray alloc]init];
        self.recipeList = [[NSMutableArray alloc]init];
        self.recipeWithImageList = [[NSMutableArray alloc]init];
        self.activeRecipes = [[NSMutableArray alloc]init];
        self.items = [[NSMutableArray alloc]init];
        self.viewedRecipes = [[NSMutableArray alloc]init];
        self.ingredientByURL = @"";
        self.iTemNameNotAddedYet = @"";
        self.tagByURL = @"";
        self.timestampForSync = 0;
        self.hasListBeenShown = NO;
        self.appPurchased = NO;
        self.randomDeviceID = [[[NSUserDefaults standardUserDefaults] objectForKey:@"deviceId"] intValue];
        if (self.randomDeviceID == 0) {
            self.randomDeviceID = [Utility getRandomNumber];
            [Utility saveInDefaultsWithObject:[NSNumber numberWithInt:self.randomDeviceID] andKey:@"deviceId"];
        }
    }
    return self;
}

- (void)resetDataStore
{
    self.sortingOrder = DATE;
    self.sortByStoreID = nil;
    self.currentList = nil;
    
    instance = nil;
}

- (void) setPreviousSortingOrder {
    if(!_previousSortingOrder || (_previousSortingOrder == STORE && !_sortByStoreID)){
        _sortByStoreID = nil;
        _sortingOrder = DEFAULT;
    }
    else {
        _sortByStoreID = _previousSortByStoreID;
        _sortingOrder = _previousSortingOrder;
        
        _previousSortByStoreID = nil;
        _previousSortingOrder = DEFAULT;
    }
    
    [Item_list changeList:_currentList byNewOrder:_sortingOrder andStoreID:_sortByStoreID];
}

@end
