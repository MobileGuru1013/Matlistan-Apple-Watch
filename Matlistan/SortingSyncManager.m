//
//  SortingSyncManager.m
//  Matlistan
//
//  Created by Artem Bakanov on 9/14/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "SortingSyncManager.h"
#import "SyncStatusEnum.h"
#import "JSONResponseSerializerWithData.h"
#import "SyncManagerStatusEnum.h"
#import "DataStore.h"
#import "ItemListsSorting+Extra.h"

@interface SortingSyncManager()
@property NSTimer *timer;
@property BOOL syncRunning;
@property SYNC_MANAGER_STATUS syncStatus;
@property (nonatomic, strong) dispatch_queue_t backgroundSyncQueue;
@property BOOL informDelegate;
@property BOOL forcedSync;
@property BOOL onceMore;

@end

@implementation SortingSyncManager

+ (SortingSyncManager *)sharedSortingSyncManager {
    static SortingSyncManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc]initWithBaseURL:[NSURL URLWithString:[Utility getMatlistanServerURLString]]];
        sharedManager.responseSerializer = [JSONResponseSerializerWithData serializer];
        sharedManager.syncRunning = NO;
        sharedManager.backgroundSyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);    //DISPATCH_QUEUE_PRIORITY_BACKGROUND
        sharedManager.informDelegate = NO;
        sharedManager.forcedSync = NO;
        sharedManager.onceMore = NO;
    });
    
    return sharedManager;
}

- (void) startSync {
    if (!_timer) {
        [self runSyncOnce];
        _timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(runSyncOnce) userInfo:nil repeats:YES];
    }
}

- (void) runSyncOnce {
    if(_sortingSyncManagerDelegate) {
        dispatch_async(self.backgroundSyncQueue, ^{
                if(!_syncRunning){
                    _syncRunning = YES;
                    //DLog(@"Sortng sync started");
                    [self checkHash];
                }
                else {
                    DLog(@"Sortng sync in progress");
                }
        });
    }
}

- (void) stopSync {
    self.syncStatus = Stopped;
    if ([_timer isValid]) {
        [_timer invalidate];
    }
    _timer = nil;
}

- (void) forceSync {
    /*
    if(!_timer){
        return;
    }
     */
    if (!_syncRunning) {
        _forcedSync = YES;
        [self runSyncOnce];
    }
    else {
        _onceMore = YES;
    }
}

- (void) checkHash {
    if ([DataStore instance].currentList.item_listID && [DataStore instance].sortingOrder == STORE){
        NSNumber *itemListId = [DataStore instance].currentList.item_listID;
        NSNumber *storeId = [DataStore instance].sortByStoreID;
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc]init];
        NSString *request = [NSString stringWithFormat:@"ItemLists/%@/SortedByStore/%@", itemListId, storeId];
        
        [self HEAD:request parameters:parameters success:^(NSURLSessionDataTask *task)
         {
             if ([task.response respondsToSelector:@selector(allHeaderFields)]) {
                 NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                 ItemListsSorting *sorting;
                 sorting = [ItemListsSorting getSortingForItemListId:itemListId andShopId:storeId];
                 if(!sorting) {
                     sorting = [ItemListsSorting insertSortingWithItemListId:itemListId andShopId:storeId];
                 }
                 NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                 f.numberStyle = NSNumberFormatterDecimalStyle;
                 NSNumber *recievedHash = [f numberFromString:[r allHeaderFields][@"X-MD5-Sum"]];
                 if ([recievedHash longValue] != [sorting.sortingHashCode longValue]) {
                     [self updateSorting:sorting forItemListId:itemListId andStoreId:storeId andHash: recievedHash];
                 }
                 else {
                     [self finished:NO];
                 }
             }
             else {
                 [self finished:YES];
             }
         } failure:^(NSURLSessionDataTask *task, NSError *error) {
             if([ItemListsSorting getSortingForItemListId:itemListId andShopId:storeId] != nil) {
                 [self finished:NO];
             }
             else {
                 [[DataStore instance] setPreviousSortingOrder];
                 [self finished:YES];
             }
         }];
    }
    else {
        [self finished:NO];
    }
}

- (void) checkHashForStoreID:(NSNumber*)storeId forItemList:(NSNumber*)itemListId  {

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc]init];
    NSString *request = [NSString stringWithFormat:@"ItemLists/%@/SortedByStore/%@", itemListId, storeId];

    [self HEAD:request parameters:parameters success:^(NSURLSessionDataTask *task)
     {
         if ([task.response respondsToSelector:@selector(allHeaderFields)]) {
             NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
             ItemListsSorting *sorting;
             sorting = [ItemListsSorting getSortingForItemListId:itemListId andShopId:storeId];
             if(!sorting) {
                 sorting = [ItemListsSorting insertSortingWithItemListId:itemListId andShopId:storeId];
             }
             NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
             f.numberStyle = NSNumberFormatterDecimalStyle;
             NSNumber *recievedHash = [f numberFromString:[r allHeaderFields][@"X-MD5-Sum"]];
             if ([recievedHash longValue] != [sorting.sortingHashCode longValue]) {
                 [self updateSortingForWatch:sorting forItemListId:itemListId andStoreId:storeId andHash: recievedHash];
             }
             else {
                 NSMutableArray *sortingArr = sorting.sortedItems;
                 if (sortingArr.count>0) {
                     [self finishedForWatchWithError:NO];
                 }else{
                     [self finishedForWatchWithError:YES];
                 }

             }
         }
         else {
             [self finishedForWatchWithError:YES];
         }
     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         [self finishedForWatchWithError:YES];
     }];
}

- (void) updateSortingForWatch:(ItemListsSorting *) sorting forItemListId: (NSNumber*) itemListId andStoreId:(NSNumber *) storeId  andHash: (NSNumber*) hash {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc]init];

    NSString *request = [NSString stringWithFormat:@"ItemLists/%@/SortedByStore/%@", itemListId, storeId];
    [self GET:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject)
     {
         NSDictionary *dict = (NSDictionary*)responseObject;
         DLog(@"%@" ,dict);
         sorting.sortingHashCode = hash;
         sorting.sortedItems = [dict objectForKey:@"sortedItems"];
         sorting.unknownItems = [dict objectForKey:@"unknownItems"];
         [[sorting managedObjectContext] MR_saveToPersistentStoreAndWait];

         NSMutableArray *sortingArr = sorting.sortedItems;
         if (sortingArr.count>0) {
             [self finishedForWatchWithError:NO];
         }else{
             [self finishedForWatchWithError:YES];
         }

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         DLog(@"Fail to get sorted stores");
         [self finishedForWatchWithError:YES];
     }];
}

- (void) updateSorting:(ItemListsSorting *) sorting forItemListId: (NSNumber*) itemListId andStoreId:(NSNumber *) storeId  andHash: (NSNumber*) hash {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc]init];
    
    NSString *request = [NSString stringWithFormat:@"ItemLists/%@/SortedByStore/%@", itemListId, storeId];
    [self GET:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject)
     {
         NSDictionary *dict = (NSDictionary*)responseObject;
         DLog(@"%@" ,dict);
         sorting.sortingHashCode = hash;
         sorting.sortedItems = [dict objectForKey:@"sortedItems"];
         sorting.unknownItems = [dict objectForKey:@"unknownItems"];
         [[sorting managedObjectContext] MR_saveToPersistentStoreAndWait];
         _informDelegate = YES;
         [self finished:NO];
         
     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         DLog(@"Fail to get sorted stores");
         [[DataStore instance] setPreviousSortingOrder];
         [self finished:YES];
     }];
}

- (void) finishedForWatchWithError: (BOOL) withError{
    //DLog(@"Sync finished");

    [[WatchConnectivityController sharedInstance] sortingSyncFinished:withError];
}

- (void) finished: (BOOL) withError {
    //DLog(@"Sync finished");

    if(self.sortingSyncManagerDelegate  && (_informDelegate || _forcedSync)) {
        _forcedSync = NO;
        _informDelegate = NO;
        [_sortingSyncManagerDelegate sortingSyncFinished: withError];
    }
    
    if (_onceMore) {
        _onceMore = NO;
        [self checkHash];
        _forcedSync = YES;
    }
    else {
        _syncRunning = NO;
    }
}

@end
