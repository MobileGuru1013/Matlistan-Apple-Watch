//
//  SyncManager.m
//  Matlistan
//
//  Created by Artem Bakanov on 7/30/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "SyncManager.h"
#import "JSONResponseSerializerWithData.h"

#import "Active_recipe+Extra.h"
#import "Store+Extra.h"
#import "Item_list+Extra.h"
#import "Item+Extra.h"
#import "ItemsCheckedStatus+Extra.h"
#import "EndpointHash+Extra.h"
#import "ItemListsSortOrder.h"
#import "Visit+Extra.h"
#import "Recipebox+Extra.h"
#import "Visit+Extra.h"
#import "SuperObject.h"

#import "AppDelegate.h"
#import "RootViewController.h"

#import "SortingSyncManager.h"
#import "SyncManagerStatusEnum.h"
#import "ItemListsManualSorting.h"
#import "SignificantChangesIndicator.h"
#import "FavoriteItem.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface SyncManager()

@property (nonatomic, strong) dispatch_queue_t backgroundSyncQueue;
@property BOOL syncRunning;
@property SYNC_MANAGER_STATUS syncStatus;
@property NSError * syncError;
@property NSArray *syncThreads;
@property int finishedThreadsCounter;

@property NSMutableDictionary *hashesToSave;

@property BOOL hashesSynched;
@property BOOL isSyncOnce;
@property BOOL oneMoreTime;
@property BOOL wereErrorsInIteration;

@property UIView *loadingView;

@property NSTimer *timer;

@property NSNumber *remoteTotalHash;

@property int syncronousThreadsAmount;

@end

@implementation SyncManager

+ (SyncManager *)sharedManager {
    static SyncManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc]initWithBaseURL:[NSURL URLWithString:[Utility getMatlistanServerURLString]]];
        sharedManager.responseSerializer = [JSONResponseSerializerWithData serializer];
        sharedManager.syncRunning = NO;
        sharedManager.hashesSynched = NO;
        sharedManager.oneMoreTime = NO;
        sharedManager.backgroundSyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            sharedManager.completionQueue = sharedManager.backgroundSyncQueue;
        }
    });
    
    return sharedManager;
}

- (void) startSync {
    if (!_timer) {
        if([Utility getDefaultBoolAtKey:@"firstDataLoad"]) {
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
        }

        [self runSyncOnce];
        _timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(runSyncOnce) userInfo:nil repeats:YES];
    }
}

- (void) runSyncOnce {
    //_isSyncOnce = NO;
    _wereErrorsInIteration = NO;
    _syncStatus = InProgress;
    
    if(_syncRunning) {
        DLog(@"Sync in progress");
        return;
    }
    [[SortingSyncManager sharedSortingSyncManager] runSyncOnce];
    
    
    dispatch_async(self.backgroundSyncQueue, ^{
                
        _syncRunning = YES;
        //DLog(@"Sync started");
        _isSyncOnce = YES;
        _hashesSynched = NO;
        if([self hasLocalChanges]) {
            NSMutableDictionary *latestHashDictionary = [NSMutableDictionary new];
            
            EndpointHash *savedHashes = [EndpointHash MR_findFirst];
            if(savedHashes.storesHash) [latestHashDictionary setObject:savedHashes.storesHash forKey:@"storesHash"];
            if(savedHashes.activeRecipesHash) [latestHashDictionary setObject:savedHashes.activeRecipesHash forKey:@"activeRecipesHash"];
            if(savedHashes.itemsHash) [latestHashDictionary setObject:savedHashes.itemsHash forKey:@"itemsHash"];
            if(savedHashes.itemListsHash) [latestHashDictionary setObject:savedHashes.itemListsHash forKey:@"itemListsHash"];
            if(savedHashes.recipeUpdatedAt) [latestHashDictionary setObject:savedHashes.recipeUpdatedAt forKey:@"updatedAt"];
            if(savedHashes.recipeCount) [latestHashDictionary setObject:savedHashes.recipeCount forKey:@"count"];
            if(savedHashes.favoriteItemsHash) [latestHashDictionary setObject:savedHashes.favoriteItemsHash forKey:@"favoriteItemsHash"];
            _remoteTotalHash = savedHashes.totalHash;
            
            [self formSyncThreadsAndRunWithLatestHashes:latestHashDictionary];
        }
        else {
            [self checkForChanges];
        }
    });
}

- (void) stopSync {
    //[[SortingSyncManager sharedSortingSyncManager] stopSync];
    _syncRunning = NO;
    self.syncStatus = Stopped;
    if ([_timer isValid]) {
        [_timer invalidate];
    }
    _timer = nil;
}

- (void) forceSync {
    if(!_timer){
        return;
    }
    if(_syncRunning) {
        _oneMoreTime = YES;
    }
    else {
        [self runSyncOnce];
    }
}

- (void) checkForChanges {
     [self HEAD:@"" parameters:nil success:^(NSURLSessionDataTask *task)
     {
         if ([task.response respondsToSelector:@selector(allHeaderFields)]) {
             NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
             NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
             f.numberStyle = NSNumberFormatterDecimalStyle;
             NSNumber *recievedHash = [f numberFromString:[r allHeaderFields][@"X-MD5-Sum"]];
             EndpointHash *localHashes = [EndpointHash MR_findFirst];
             if([localHashes.totalHash longValue] != [recievedHash longValue] || [self hasLocalChanges]) {
                 _remoteTotalHash = recievedHash;
                 [self pollForChangesOnWebServer];
             }
             else {
                 _syncRunning = NO;
                 _hashesSynched = YES;
                 //DLog(@"Sync finished. No changes.")
                 if([self.syncManagerDelegate respondsToSelector:@selector(syncFinished)]) {
                     [self.syncManagerDelegate syncFinished];
                 }
                 if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [SVProgressHUD dismiss];
                     });
                 }
                 else {
                     [SVProgressHUD dismiss];
                 }
             }
         }
     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         DLog(@"Fail to get hash %@", [error description]);
         [self tryToLogin];
         _hashesSynched = YES;
         [self finished];
     }];
}

- (BOOL) hasLocalChanges {
    return  [Store needsUpdate] || [ItemListsSortOrder needsUpdate] || [Item_list needsUpdate] || [Item needsUpdate] || [ItemsCheckedStatus needsUpdate] || [ItemListsManualSorting needsUpdate] || [[Recipebox class] needsUpdate] || [[Active_recipe class] needsUpdate];
}

//Please note, structure of dictionary should be plain (No key:dictionary pairs)
- (void) formSyncThreadsAndRunWithLatestHashes:(NSMutableDictionary *) latestHashDictionary{
    
    EndpointHash *savedHashes = [EndpointHash MR_findFirst];
    NSMutableDictionary *localHashes = [NSMutableDictionary new];
    if(savedHashes.storesHash) [localHashes setObject:savedHashes.storesHash forKey:@"storesHash"];
    if(savedHashes.activeRecipesHash) [localHashes setObject:savedHashes.activeRecipesHash forKey:@"activeRecipesHash"];
    if(savedHashes.itemsHash) [localHashes setObject:savedHashes.itemsHash forKey:@"itemsHash"];
    if(savedHashes.itemListsHash) [localHashes setObject:savedHashes.itemListsHash forKey:@"itemListsHash"];
    if(savedHashes.recipeUpdatedAt) [localHashes setObject:savedHashes.recipeUpdatedAt forKey:@"updatedAt"];
    if(savedHashes.recipeCount) [localHashes setObject:savedHashes.recipeCount forKey:@"count"];
    if(savedHashes.favoriteItemsHash) [localHashes setObject:savedHashes.favoriteItemsHash forKey:@"favoriteItemsHash"];
    
    _hashesToSave = localHashes;
    
    long count = [[latestHashDictionary objectForKey:@"count"] longValue];
    NSString *timeStamp = [latestHashDictionary objectForKey:@"updatedAt"];
    
    ////////////////////////
    NSMutableArray *thread1 = [NSMutableArray new];
    NSMutableDictionary *dictionary1 = [NSMutableDictionary new];
    
    if ([Store needsUpdate] || [savedHashes.storesHash longValue] != [[latestHashDictionary objectForKey:@"storesHash"] longValue]) {
        DLog(@"Need to update Stores localChanges:%@, remoteChanges:%@", [Store needsUpdate] ? @"YES": @"NO",  [savedHashes.storesHash longValue] != [[latestHashDictionary objectForKey:@"storesHash"] longValue] ? @"YES": @"NO");
        [thread1 addObject:[Store class]];
        [dictionary1 setObject:@[@"storesHash"] forKey:[[Store class]getObjectURL]];
    }
    if ([ItemListsSortOrder needsUpdate]) {
        DLog(@"Need to update itemLists sort order. Local changes: %@", [ItemListsSortOrder needsUpdate] ? @"YES" : @"NO");
        [thread1 addObject:[ItemListsSortOrder class]];
    }
    if ([Item_list needsUpdate] || [savedHashes.itemListsHash longValue] != [[latestHashDictionary objectForKey:@"itemListsHash"] longValue]) {
        DLog(@"Need to update itemLists. Local changes: %@, remote changes: %@", [Item_list needsUpdate] ? @"YES" : @"NO", [savedHashes.itemListsHash longValue] != [[latestHashDictionary objectForKey:@"itemListsHash"] longValue] ? @"YES":  @"NO");
        [thread1 addObject:[Item_list class]];
        [dictionary1 setObject:@[@"itemListsHash"] forKey:[[Item_list class]getObjectURL]];
    }
    if ([Item needsUpdate] || [savedHashes.itemsHash longValue] != [[latestHashDictionary objectForKey:@"itemsHash"] longValue]) {
        DLog(@"Need to update items");
        [thread1 addObject:[Item class]];
        [dictionary1 setObject:@[@"itemsHash"] forKey:[[Item class]getObjectURL]];
    }
    
    if ([ItemsCheckedStatus needsUpdate]) {
        //Need to force updating items after updating checked status.
        //This made for case when someone restores item status on server after sync was made, thus hashes will not be changed
        [localHashes setObject:@0 forKey:@"itemsHash"];
        [latestHashDictionary setObject:@0 forKey:@"itemsHash"];
        
        DLog(@"Need to update items checked status");
        //First, update Visit!!!
        /*
         I have simplified the API, use the new "secondsAgo" field in POST /Items/Checked instead of secondsAfterStart. This means also that GET /Visits/Current is not needed anymore. /Michael
         */
        /*
        [Visit cleanOldVisits];
        [thread1 addObject:[Visit class]];
         */
        [thread1 addObject:[ItemsCheckedStatus class]];
    }
    if ([ItemListsManualSorting needsUpdate]) {
        DLog(@"Need to update manual sorting");
        [thread1 addObject:[ItemListsManualSorting class]];
    }
    
    SyncThread *syncThread1 = [SyncThread new];
    syncThread1.localHash = localHashes;
    syncThread1.remoteHash = latestHashDictionary;
    syncThread1.delegate = self;
    syncThread1.arrayOfClasses = thread1;
    syncThread1.dictionaryOfClassesAndHashIds = dictionary1;
    syncThread1.syncronousOnFirstLoad = YES;
    //////////////////////////
    
    NSMutableArray *thread2 = [NSMutableArray new];
    NSMutableDictionary *dictionary2 = [NSMutableDictionary new];
    
    if ([[Recipebox class] needsUpdate] || [savedHashes.recipeCount longValue] != count || (timeStamp && ![savedHashes.recipeUpdatedAt isEqualToString:timeStamp])) {
        DLog(@"Need to update recipes. Local changes: %@, remote changes: %@" , [[Recipebox class] needsUpdate] ? @"YES" : @"NO", ([savedHashes.recipeCount longValue] != count || (timeStamp && ![savedHashes.recipeUpdatedAt isEqualToString:timeStamp])) ? @"YES" : @"NO");
        [thread2 addObject:[Recipebox class]];
        [dictionary2 setObject:@[@"count", @"updatedAt"] forKey:[[Recipebox class] getObjectURL]];
    }
    
    if ([[Active_recipe class] needsUpdate] || [savedHashes.activeRecipesHash longValue] != [[latestHashDictionary objectForKey:@"activeRecipesHash"] longValue]) {
        DLog(@"Need to update activeRecipe. Local changes: %@, remote changes: %@", [[Active_recipe class] needsUpdate] ? @"YES" : @"NO", [savedHashes.activeRecipesHash longValue] != [[latestHashDictionary objectForKey:@"activeRecipesHash"] longValue] ? @"YES" : @"NO");
        [thread2 addObject:[Active_recipe class]];
        [dictionary2 setObject:@[@"activeRecipesHash"] forKey:[[Active_recipe class] getObjectURL]];
    }
    SyncThread *syncThread2 = [SyncThread new];
    syncThread2.localHash = localHashes;
    syncThread2.remoteHash = latestHashDictionary;
    syncThread2.delegate = self;
    syncThread2.arrayOfClasses = thread2;
    syncThread2.dictionaryOfClassesAndHashIds = dictionary2;
    syncThread2.syncronousOnFirstLoad = NO;
    
    //////////////////////////
    
    NSMutableArray *thread3 = [NSMutableArray new];
    NSMutableDictionary *dictionary3 = [NSMutableDictionary new];
    
    if ([savedHashes.favoriteItemsHash longValue] != [[latestHashDictionary objectForKey:@"favoriteItemsHash"] longValue]) {
        DLog(@"Need to update Favorite Items");
        [thread3 addObject:[FavoriteItem class]];
        [dictionary3 setObject:@[@"favoriteItemsHash"] forKey:[[FavoriteItem class]getObjectURL]];
    }
    
    SyncThread *syncThread3 = [SyncThread new];
    syncThread3.localHash = localHashes;
    syncThread3.remoteHash = latestHashDictionary;
    syncThread3.delegate = self;
    syncThread3.arrayOfClasses = thread3;
    syncThread3.dictionaryOfClassesAndHashIds = dictionary3;
    syncThread2.syncronousOnFirstLoad = NO;
    
    _syncThreads = @[syncThread1, syncThread2, syncThread3];
    _syncronousThreadsAmount = 1;
    
    [self performSync];
}

- (BOOL) hasUpdatesOnServerWithDictionary: (NSDictionary *) latestHashDictionary {
    EndpointHash *savedHashes = [EndpointHash MR_findFirst];
    NSMutableDictionary *localHashes = [NSMutableDictionary new];
    if(savedHashes.storesHash) [localHashes setObject:savedHashes.storesHash forKey:@"storesHash"];
    if(savedHashes.activeRecipesHash) [localHashes setObject:savedHashes.activeRecipesHash forKey:@"activeRecipesHash"];
    if(savedHashes.itemsHash) [localHashes setObject:savedHashes.itemsHash forKey:@"itemsHash"];
    if(savedHashes.itemListsHash) [localHashes setObject:savedHashes.itemListsHash forKey:@"itemListsHash"];
    if(savedHashes.recipeUpdatedAt) [localHashes setObject:savedHashes.recipeUpdatedAt forKey:@"updatedAt"];
    if(savedHashes.recipeCount) [localHashes setObject:savedHashes.recipeCount forKey:@"count"];
    
    long count = [[latestHashDictionary objectForKey:@"count"] longValue];
    NSString *timeStamp = [latestHashDictionary objectForKey:@"updatedAt"];
    
    return (([savedHashes.storesHash longValue] != [[latestHashDictionary objectForKey:@"storesHash"] longValue]) ||
             ([savedHashes.itemListsHash longValue] != [[latestHashDictionary objectForKey:@"itemListsHash"] longValue]) ||
             ([savedHashes.itemsHash longValue] != [[latestHashDictionary objectForKey:@"itemsHash"] longValue]) ||
             ([savedHashes.recipeCount longValue] != count || (timeStamp && ![savedHashes.recipeUpdatedAt isEqualToString:timeStamp])) ||
             ([savedHashes.activeRecipesHash longValue] != [[latestHashDictionary objectForKey:@"activeRecipesHash"] longValue]));
}

/*
 poll for changes using a hash code instead of transferring and comparing the full data.
 GET Request: "http://api2.matlistan.se/" on the the root (/) endpoint.
 */
-(void)pollForChangesOnWebServer{
    
    [self GET:@"" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *hashes = (NSDictionary *) responseObject;
        NSMutableDictionary *latestHashDictionary = [[NSMutableDictionary alloc] initWithDictionary:hashes];
        
        NSDictionary *recipeBoxIndicators = [latestHashDictionary objectForKey:@"recipeBoxIndicators"];
        long count = [[recipeBoxIndicators objectForKey:@"count"] longValue];
        NSString *timeStamp = [recipeBoxIndicators objectForKey:@"updatedAt"];
        
        [latestHashDictionary setObject:[NSNumber numberWithLong: count] forKey:@"count"];
        if(timeStamp != nil)[latestHashDictionary setObject:timeStamp forKey:@"updatedAt"];
        
        if(![self hasLocalChanges]) {
            _hashesSynched = YES;
            if([self hasUpdatesOnServerWithDictionary:latestHashDictionary]){
            EndpointHash *savedHashes = [EndpointHash MR_findFirst];
            if([savedHashes.totalHash longValue] == [_remoteTotalHash longValue]) {
                [self HEAD:@"" parameters:nil success:^(NSURLSessionDataTask *task)
                 {
                     if ([task.response respondsToSelector:@selector(allHeaderFields)]) {
                         NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                         NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                         f.numberStyle = NSNumberFormatterDecimalStyle;
                         NSNumber *recievedHash = [f numberFromString:[r allHeaderFields][@"X-MD5-Sum"]];
                         _remoteTotalHash = recievedHash;
                    }
                 } failure:^(NSURLSessionDataTask *task, NSError *error) {
                     DLog(@"Fail to get hash %@", [error description]);
                     [self tryToLogin];
                     _hashesSynched = YES;
                     [self finished];
                 }];
            }
            }
        }
        
        [self formSyncThreadsAndRunWithLatestHashes:latestHashDictionary];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to get hash %@", [error description]);
        [self tryToLogin];
        _hashesSynched = YES;
        [self finished];
    }];
}

- (void) performSync {
    _finishedThreadsCounter = 0;
    for (SyncThread *thread in _syncThreads){
        if(thread.arrayOfClasses.count > 0){
            //_hashesSynched = NO;
            [thread startSync];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        }
        else {
            _finishedThreadsCounter++;
            if(_finishedThreadsCounter >= _syncThreads.count) {
                //_hashesSynched = YES;
                [self finished];
            }
        }
    }
}

- (void) failedWithError: (NSError *) error {
    DLog(@"!!!!!FAILED");
    _syncRunning = NO;
    self.syncStatus = Error;
    self.syncError = error;
}

- (void) finished {
    //DLog(@"Sync finished");
    NSMutableDictionary *recipeboxDictionary = [NSMutableDictionary new];
    if([_hashesToSave objectForKey:@"count"])[recipeboxDictionary setObject:[_hashesToSave objectForKey:@"count"] forKey:@"count"];
    if([_hashesToSave objectForKey:@"updatedAt"])[recipeboxDictionary setObject:[_hashesToSave objectForKey:@"updatedAt"] forKey:@"updatedAt"];
    [_hashesToSave setObject:recipeboxDictionary forKey:@"recipeBoxIndicators"];
    if(_remoteTotalHash)[_hashesToSave setObject:_remoteTotalHash forKey:@"totalHash"];
    [_hashesToSave removeObjectForKey:@"count"];
    [_hashesToSave removeObjectForKey:@"updatedAt"];

    [EndpointHash updateItems:_hashesToSave];
    _syncRunning = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if(_loadingView) {
        [_loadingView removeFromSuperview];
        _loadingView = nil;
    }

    if(_wereErrorsInIteration) {
        [self tryToLogin];
    }
    else if(_isSyncOnce) {
        if(_hashesSynched) {
            if(self.syncManagerDelegate) {
                DLog(@"Hashes synced.");
                if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.syncManagerDelegate didUpdateItems];
                    });
                }
                else {
                    [self.syncManagerDelegate didUpdateItems];
                }
            }
            if(_oneMoreTime) {
                _oneMoreTime = NO;
                [self runSyncOnce];
            }
        }
        else {
            DLog(@"Hashes NOT synced. New iteration");
            ////////////////
            //TODO: may be too much spam?
            //But it was added for portions...
            if(self.syncManagerDelegate) {
                if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.syncManagerDelegate didUpdateItems];
                    });
                }
                else {
                    [self.syncManagerDelegate didUpdateItems];
                }
            }
            /////////////////
            
            _syncRunning = YES;
            //DLog(@"Sync started");
            [self pollForChangesOnWebServer];
        }
    }
    if([Utility getDefaultBoolAtKey:@"firstDataLoad"]) {
        //Raj- 17-10-2015, to fix issue : "user's default list is not display after login"
         if(_hashesSynched) {
              if(self.syncManagerDelegate) {
                    [SignificantChangesIndicator sharedIndicator].itemsChanged = YES;
                  if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
                      dispatch_async(dispatch_get_main_queue(), ^{
                          [self.syncManagerDelegate didUpdateItems];
                      });
                  }
                  else {
                      [self.syncManagerDelegate didUpdateItems];
                  }
                }
         }
        [Utility saveInDefaultsWithBool:NO andKey:@"firstDataLoad"];
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
        else {
            [SVProgressHUD dismiss];
        }
    }
}

- (void) threadFinishedWithHashes: (NSDictionary *) hashes andErrors:(BOOL)wereErrors  syncronous: (BOOL) syncronous{
    [_hashesToSave addEntriesFromDictionary:hashes];
    _finishedThreadsCounter++;
    if (wereErrors) {
        _wereErrorsInIteration = YES;
    }
    if(_finishedThreadsCounter >= _syncThreads.count) {
        [self finished];
    }
    
    if([Utility getDefaultBoolAtKey:@"firstDataLoad"]) {
        if(syncronous) {
            _syncronousThreadsAmount -= 1;
            if(_syncronousThreadsAmount == 0) {
                if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(self.syncManagerDelegate) {
                            [self.syncManagerDelegate didUpdateItems];
                        }
                        [SVProgressHUD dismiss];
                    });
                }
                else {
                    if(self.syncManagerDelegate) {
                        [self.syncManagerDelegate didUpdateItems];
                    }
                    [SVProgressHUD dismiss];
                }
            }
        }
    }
}

- (void) tryToLogin {
    [self stopSync];
    //[[MatlistanHTTPClient sharedMatlistanHTTPClient] retryLogin];
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(loginIn10Seconds) userInfo:nil repeats:NO];
        });
    }
    else {
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(loginIn10Seconds) userInfo:nil repeats:NO];
    }
}

- (void) loginIn10Seconds {
    [[MatlistanHTTPClient sharedMatlistanHTTPClient] retryLogin];
}

@end
