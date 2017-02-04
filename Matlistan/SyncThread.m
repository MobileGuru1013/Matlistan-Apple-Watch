//
//  SyncThread.m
//  Matlistan
//
//  Created by Artem Bakanov on 7/31/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "SyncThread.h"
#import "SuperObject.h"
#import "SyncFinishedStatusEnum.h"

@interface SyncThread()

@property NSEnumerator *enumerator;
@property NSMutableDictionary *hashesToSave;

@property Class<SuperObject> currentlyProcessedObject;
@property BOOL errorInThread;

@end

@implementation SyncThread

- (void) startSync {
    _hashesToSave = [NSMutableDictionary new];
    _enumerator = [_arrayOfClasses objectEnumerator];
    _errorInThread = NO;
    [self syncNext];
}

- (void) syncNext {
    if(_currentlyProcessedObject = [_enumerator nextObject]){
        BOOL hasRemoteChanges = NO;
        for (NSString *hashKey in [_dictionaryOfClassesAndHashIds objectForKey:[_currentlyProcessedObject getObjectURL]]) {
            if([_localHash[hashKey] isKindOfClass:[NSString class]] || [_remoteHash[hashKey] isKindOfClass:[NSString class]]){
                if(![_localHash[hashKey] isEqualToString: _remoteHash[hashKey]]) {
                    hasRemoteChanges = YES;
                }
            }
            else {
                if([_localHash[hashKey] longValue] != [_remoteHash[hashKey] longValue]) {
                    hasRemoteChanges = YES;
                }
            }
        }

        SyncEngine2 *syncEngine = [[SyncEngine2 alloc] initWithClass:_currentlyProcessedObject andDelegate:self hasRemoteChanges:hasRemoteChanges];
        [syncEngine startSync];
    }
    else {
        [_delegate threadFinishedWithHashes: _hashesToSave andErrors:_errorInThread syncronous:_syncronousOnFirstLoad];
    }
}

- (void) objectSyncFinishedWithStatus:(SYNC_FINISHED_STATUS) status andError:(NSError *) error{
    DLog(@"%@", [_currentlyProcessedObject getObjectURL]);
    for (NSString *hashKey in [_dictionaryOfClassesAndHashIds objectForKey:[_currentlyProcessedObject getObjectURL]]) {
        if(hashKey){
            switch (status) {
                case SYNC_FINISHED_OK:
                case SYNC_FINISHED_REMOTE_ERROR:
                    [_hashesToSave setObject:_remoteHash[hashKey] ? _remoteHash[hashKey] :@0 forKey:hashKey];
                    break;
                case SYNC_FINISHED_GET_ERROR:
                case SYNC_FINISHED_LOCAL_ERROR:
                    [_hashesToSave setObject:_localHash[hashKey] ? _localHash[hashKey] : @0 forKey:hashKey];
                    break;
                default:
                    break;
            }
        }
    }
    
    if (status == SYNC_FINISHED_REMOTE_ERROR || status == SYNC_FINISHED_GET_ERROR) {
        _errorInThread = YES;
    }
    [self syncNext];
}

@end
