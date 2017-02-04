//
//  SyncEngine.h
//  MatListan
//
//  Created by Yan Zhang on 31/08/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"
#import "CoreDataStore.h"
#import "Visit+Extra.h"
#import "Ingredient+Extra.h"
#import "DataStore.h"
#import "Item_list+Extra.h"

@protocol SyncEngineDelegate;

@interface SyncEngine : AFHTTPSessionManager

@property (nonatomic,weak)id<SyncEngineDelegate>delegate;

+ (SyncEngine *)sharedEngine;
@property (atomic, readonly) BOOL syncInProgress;
@property (nonatomic,retain)NSString* cookie;

-(void)startSync;
-(void)stopSync;

-(void)pollForChangesOnWebServer;
-(void)getItemsFromServer;
-(void)searchStoresFromServer:(NSString*)query withLatitude:(NSNumber*)latitude andLongitude:(NSNumber*)longitude;
-(void)sendItemListOrderUpdate:(NSNumber*)listID andSortOrder:(SORT_TYPE)sortType andStoreID:(NSNumber*)storeID;
-(void)sendItemListOrderUpdates;
-(void)sendItemListDefaultUpdates;
@end

@protocol SyncEngineDelegate <NSObject>

@optional
-(void)SyncEngine:(SyncEngine*)engine didUpdateItems:(id)allItems;

@end