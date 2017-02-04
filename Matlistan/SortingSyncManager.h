//
//  SortingSyncManager.h
//  Matlistan
//
//  Created by Artem Bakanov on 9/14/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MatlistanHTTPClient.h"

@protocol SortingSyncManagerDelegate;

@interface SortingSyncManager : MatlistanHTTPClient

@property NSNumber *itemListId;
@property NSNumber *storeId;

@property (nonatomic,weak) id<SortingSyncManagerDelegate> sortingSyncManagerDelegate;

+ (SortingSyncManager *)sharedSortingSyncManager;

- (void) startSync;
- (void) stopSync;

- (void) forceSync;

-(void) runSyncOnce;

- (void) checkHashForStoreID:(NSNumber*)storeId forItemList:(NSNumber*)itemListId;

@end

@protocol SortingSyncManagerDelegate <NSObject>
-(void)sortingSyncFinished: (BOOL) withError;
@end