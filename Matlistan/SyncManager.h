//
//  SyncManager.h
//  Matlistan
//
//  Created by Artem Bakanov on 7/30/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncThread.h"
#import "MatlistanHTTPClient.h"

@protocol SyncManagerDelegate;

@interface SyncManager : MatlistanHTTPClient<SyncThreadDelegate>

+ (SyncManager *)sharedManager;

@property (nonatomic,weak)id<SyncManagerDelegate> syncManagerDelegate;

- (void) startSync;
- (void) stopSync;
- (void) forceSync;
- (void) finished;
@end

@protocol SyncManagerDelegate <NSObject>
-(void)didUpdateItems;
@optional
-(void) syncFinished;
@end

