//
//  SyncEngine2.h
//  Matlistan
//
//  Created by Artem Bakanov on 7/27/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SuperObject.h"
#import "SyncFinishedStatusEnum.h"

#import "MatlistanHTTPClient.h"

@protocol SyncEngine2Delegate;

@interface SyncEngine2 : MatlistanHTTPClient

- (void)startSync;
- (id) initWithClass:(Class<SuperObject>) objectClass andDelegate: (id<SyncEngine2Delegate>) delegate hasRemoteChanges: (BOOL) hasRemoteChanges;

@end

@protocol SyncEngine2Delegate <NSObject>

- (void) objectSyncFinishedWithStatus:(SYNC_FINISHED_STATUS) status andError:(NSError *) error;

@end