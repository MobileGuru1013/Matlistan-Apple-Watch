//
//  SyncThread.h
//  Matlistan
//
//  Created by Artem Bakanov on 7/31/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncEngine2.h"

@protocol SyncThreadDelegate;

@interface SyncThread : NSObject<SyncEngine2Delegate>

@property id<SyncThreadDelegate> delegate;
@property NSDictionary *localHash;
@property NSDictionary *remoteHash;

@property NSDictionary *dictionaryOfClassesAndHashIds;
@property NSArray *arrayOfClasses;

@property BOOL syncronousOnFirstLoad;

- (void) startSync;

@end

@protocol SyncThreadDelegate <NSObject>

- (void) threadFinishedWithHashes: (NSDictionary *) hashes andErrors: (BOOL) wasErrors syncronous: (BOOL) syncronous;

@end