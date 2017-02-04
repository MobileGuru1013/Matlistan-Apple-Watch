//
//  SyncEngine2.m
//  Matlistan
//
//  Created by Artem Bakanov on 7/27/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "SyncEngine2.h"
#import "CommandObject.h"
#import "JSONResponseSerializerWithData.h"

#import "RequestTypeEnum.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface SyncEngine2()

@property (nonatomic,weak)id<SyncEngine2Delegate>syncEngineDelegate;
@property Class<SuperObject> objectClass;

@property long objectsUpdated;
@property long objectsToUpdate;

@property SYNC_FINISHED_STATUS syncFinishedStatus;

@property BOOL hasLocalChanges;
@property BOOL hasRemoteChanges;

@end

@implementation SyncEngine2

- (id) initWithClass:(Class<SuperObject>) objectClass andDelegate: (id<SyncEngine2Delegate>) delegate hasRemoteChanges: (BOOL) hasRemoteChanges {
    if(self = [self init]){
        _objectClass = objectClass;
        _syncEngineDelegate = delegate;
        _objectsUpdated = 0;
        _objectsToUpdate = 0;
        _syncFinishedStatus = SYNC_FINISHED_OK;
        _hasRemoteChanges = hasRemoteChanges;
    }
    return self;
}

- (id)init {
    if(self = [super initWithBaseURL:[NSURL URLWithString:[Utility getMatlistanServerURLString]]]) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            self.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        }
        _hasLocalChanges = YES;
    }
    return self;
}

- (void)startSync {
    if(_hasRemoteChanges) {
        [self getAllObjectsFromServer];
    }
    else {
        NSArray *localObjects = [_objectClass getNotSyncedObjects];
        NSMutableDictionary *remoteObjectsIdsAndObjectsParameter = [NSMutableDictionary new];
        for (id<SuperObject> localObject in localObjects) {
            if([localObject getId]!=nil)
            {
                [remoteObjectsIdsAndObjectsParameter setObject:[NSDictionary new] forKey:[localObject getId]];
            }
        }
        [self processObjectsFromServer:remoteObjectsIdsAndObjectsParameter];
    }
}

- (void) getAllObjectsFromServer {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"format"] = @"json";
    [self performRequest:[_objectClass getGetRequestType] URL:[_objectClass getObjectURL] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

        CLS_LOG(@"Get\nRequest:%@ \nParameters:%@ Response: %@", [_objectClass getObjectURL] , parameters, responseObject);

        [self processObjectsFromServer:[_objectClass getIdsAndObjectFromResponse: responseObject]];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        CLS_LOG(@"Fail Get\nRequest:%@ \nParameters:%@ Error: %@", [_objectClass getObjectURL] , parameters, error.description);
        [self objectSyncFinishedWithStatus:SYNC_FINISHED_GET_ERROR];
    }];
    }

- (void) processObjectsFromServer: (NSDictionary *) remoteObjectsIdsAndObjectsParameter {
    
    NSArray *localObjects = [_objectClass getNotSyncedObjects];
    
    NSMutableArray *commandsArray = [NSMutableArray new];
    NSMutableDictionary *remoteObjectsIdsAndObjects = [NSMutableDictionary dictionaryWithDictionary:remoteObjectsIdsAndObjectsParameter];
    
    for (id<SuperObject> localObject in localObjects) {
        
        CommandObject *commandObject = [CommandObject new];
        commandObject.objectToSync = localObject;
        commandObject.localCommand = NO_ACTION;
        commandObject.remoteCommand = NO_ACTION;
        
        switch ([[localObject syncStatus] intValue]) {
            case Created:
                commandObject.localCommand = NO_ACTION;
                commandObject.remoteCommand = INSERT;
                break;
            case Updated:
            case UpdatedAgain:
                if([[remoteObjectsIdsAndObjects allKeys] containsObject:[localObject getId]]) {
                    commandObject.localCommand = NO_ACTION;
                    commandObject.remoteCommand = UPDATE;
                }
                else {
                    commandObject.localCommand = DELETE;
                    commandObject.remoteCommand = NO_ACTION;
                }
                break;
            case Deleted:
                if([[remoteObjectsIdsAndObjects allKeys] containsObject:[localObject getId]]) {
                    commandObject.localCommand = DELETE;
                    commandObject.remoteCommand = DELETE;
                }
                else {
                    commandObject.localCommand = DELETE;
                    commandObject.remoteCommand = NO_ACTION;
                }
                break;
            default:
                break;
        }
        
        [commandsArray addObject:commandObject];
        
        if([localObject getId]!=nil){
            [remoteObjectsIdsAndObjects removeObjectForKey:[localObject getId]];
        }
    }

    if(_hasRemoteChanges) {
        [_objectClass deleteSyncedObjectsExceptIds:[remoteObjectsIdsAndObjects allKeys]];
    }

    
    if(![_objectClass isHeavyObject]){
        [self updateObjects:remoteObjectsIdsAndObjects commandsArray:commandsArray];
    }
    else {
        [self updateHeavyObjectsJSON:[_objectClass removeIdsNotNeededToUpdate:remoteObjectsIdsAndObjects] commandsArray:commandsArray];
    }
}

- (void)updateHeavyObjectsJSON:(NSDictionary *)remoteObjectsIdsAndObjects commandsArray:(NSMutableArray *)commandsArray {
    int objectsAmount = (int)[remoteObjectsIdsAndObjects allKeys].count;
    __block NSNumber *objectProcessedCount = 0;
    __block NSMutableDictionary *mutableRemoteObjectsIdsAndObjects = [NSMutableDictionary dictionaryWithDictionary:remoteObjectsIdsAndObjects];
    __block BOOL updateLaunched = NO;//temp solution...
    
    if([remoteObjectsIdsAndObjects allKeys].count > 0){
    
        for (NSNumber *key in [remoteObjectsIdsAndObjects allKeys]) {
            [self performRequest:[_objectClass heavyObjectGetRequestType] URL:[_objectClass heavyObjectURL: key] parameters:[_objectClass getHeavyParameters] success:^(NSURLSessionDataTask *task, id responseObject) {
                @synchronized(objectProcessedCount) {
                    objectProcessedCount = [NSNumber numberWithInt:[objectProcessedCount intValue] + 1];
                    CLS_LOG(@"Heavy get\nRequest:%@ \nParameters:%@ Respone: %@", [_objectClass heavyObjectURL: key] , [_objectClass getHeavyParameters], responseObject);
                    
                    [mutableRemoteObjectsIdsAndObjects setObject:responseObject forKey:key];
                    if([objectProcessedCount intValue] >= objectsAmount && !updateLaunched){
                        updateLaunched = YES;
                        [self updateObjects:mutableRemoteObjectsIdsAndObjects commandsArray:commandsArray];
                    }
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                @synchronized(objectProcessedCount) {
                    objectProcessedCount = [NSNumber numberWithInt:[objectProcessedCount intValue] + 1];
                    [mutableRemoteObjectsIdsAndObjects removeObjectForKey:key];
                    CLS_LOG(@"Fail Heavy get\nRequest:%@ \nParameters:%@ Error: %@", [_objectClass heavyObjectURL: key] , [_objectClass getHeavyParameters], error.description);
                    [self updateTotalStatusWithStatus:SYNC_FINISHED_GET_ERROR];
                    if([objectProcessedCount intValue] >= objectsAmount && !updateLaunched){
                        updateLaunched = YES;
                        [self updateObjects:mutableRemoteObjectsIdsAndObjects commandsArray:commandsArray];
                    }
                }
            }];
        }
        
    }
    else {
        [self updateObjects:mutableRemoteObjectsIdsAndObjects commandsArray:commandsArray];
    }
}

- (void)updateObjects:(NSDictionary *)remoteObjectsIdsAndObjects commandsArray:(NSMutableArray *)commandsArray {
    for (NSNumber * remoteObjectId in [remoteObjectsIdsAndObjects allKeys]) {
        if([_objectClass parentsExistForResponse:[remoteObjectsIdsAndObjects objectForKey:remoteObjectId]]){
            if (![_objectClass isInDatabase : remoteObjectId]) {
                [_objectClass insertObjectWithParentCheckAndJson: [remoteObjectsIdsAndObjects objectForKey:remoteObjectId]];
            }
            else {
                [_objectClass updateObjectWithJson: [remoteObjectsIdsAndObjects objectForKey:remoteObjectId]];
            }
        }
        else {
            [self updateTotalStatusWithStatus:SYNC_FINISHED_LOCAL_ERROR];
        }
    }
    
    [self processCommandsArray:commandsArray];
}


- (void) processCommandsArray: (NSArray *) commandsArray {
    
    if(commandsArray.count == 0) {
        [self objectSyncFinishedWithStatus:SYNC_FINISHED_OK];
        return;
    }
    _objectsToUpdate = commandsArray.count;
    
    NSDictionary * parameters = [NSDictionary new];
    
    for (CommandObject *commandObject in commandsArray) {
        
        
        switch (commandObject.remoteCommand) {
            case NO_ACTION:
                [self processLocalCommand:commandObject];
                break;
            case INSERT:
            {
                parameters = [commandObject.objectToSync parseToInsertJSON];
                if([commandObject.objectToSync parentSyncedCheck]) {
                    [self performRequest:[_objectClass getInsertRequestType] URL:[commandObject.objectToSync getInsertURL] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                        if([_objectClass parentsExistForResponse: responseObject]){
                            [commandObject.objectToSync updateObjectWithResponseForInsert: responseObject];
                        }
                        
                        
                        CLS_LOG(@"Inserted\nRequest:%@ \nParameters:%@ Response: %@", [commandObject.objectToSync getInsertURL] , parameters, responseObject);
                        
                        [self processLocalCommand:commandObject];
                        
                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                        CLS_LOG(@"Fail to insert\nRequest:%@ \nParameters:%@ Response: %@", [commandObject.objectToSync getInsertURL] , parameters, error.description);
                        NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
                        long statusCode = (long)r.statusCode;
                        if(statusCode >=400 && statusCode < 500){
                            //This happens when object was deleted on server after we get it from there, but before we send an update
                            //It means that thereis no object with sch ID on server
                            commandObject.localCommand = DELETE;
                            [self processLocalCommand:commandObject];
                            CLS_LOG(@"Remove the wrong object which causes 400-500 error from server.");
                        }
                        else {
                            [self objectSyncFinishedWithStatus:SYNC_FINISHED_REMOTE_ERROR];
                        }
                    }];
                }
                else {
                    CLS_LOG(@"Fail to insert %@ to server, parent not synced", commandObject.objectToSync);
                    [self objectSyncFinishedWithStatus:SYNC_FINISHED_LOCAL_ERROR];
                }
                break;
            }
            case UPDATE:
            {
                parameters = [commandObject.objectToSync parseToUpdateJSON];
                [self performRequest:[_objectClass getUpdateRequestType] URL:[commandObject.objectToSync getUpdateURL] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                    CLS_LOG(@"Updated\nRequest:%@ \nParameters:%@ Response: %@", [commandObject.objectToSync getUpdateURL] , parameters, responseObject);
                    if([_objectClass parentsExistForResponse: responseObject]){
                        [commandObject.objectToSync updateObjectWithResponseForUpdate: responseObject];
                    }
                    [self processLocalCommand:commandObject];
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    CLS_LOG(@"Fail update\nRequest:%@ \nParameters:%@ Error: %@", [commandObject.objectToSync getUpdateURL] , parameters, error.description);
                    NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
                    long statusCode = (long)r.statusCode;
                    if(statusCode >=400 && statusCode < 500){
                        //This happens when object was deleted on server after we get it from there, but before we send an update
                        //It means that thereis no object with sch ID on server
                        commandObject.localCommand = DELETE;
                        [self processLocalCommand:commandObject];
                        CLS_LOG(@"Remove the wrong object which causes 400-500 error from server.");
                    }
                    else {
                        [self objectSyncFinishedWithStatus:SYNC_FINISHED_REMOTE_ERROR];
                    }
                }];
                break;
            }
            case DELETE:
            {
                [self performRequest:[_objectClass getDeleteRequestType] URL:[commandObject.objectToSync getDeleteURL] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                    CLS_LOG(@"Deleted\nRequest:%@ \nResponse: %@",[commandObject.objectToSync getDeleteURL] , responseObject);
                    
                    [self processLocalCommand:commandObject];
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    CLS_LOG(@"Fail to delete %@ from server: %@", commandObject.objectToSync, error.description);
                    NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
                    long statusCode = (long)r.statusCode;
                    if(statusCode >=400 && statusCode < 500){
                        //This happens when object was deleted on server after we get it from there, but before we send an update
                        //It means that thereis no object with sch ID on server
                        commandObject.localCommand = DELETE;
                        [self processLocalCommand:commandObject];
                        CLS_LOG(@"Remove the wrong object which causes 400-500 error from server.");
                    }
                    else {
                        [self objectSyncFinishedWithStatus:SYNC_FINISHED_REMOTE_ERROR];
                    }
                }];
                break;
            }
            default:
                break;
        }
    }
}

- (void) processLocalCommand: (CommandObject *) commandObject {
    switch (commandObject.localCommand) {
        case NO_ACTION:
            break;
        case INSERT:
            //Will never come here
            //[commandObject.objectToSync insertObjectWithParentCheck];
            break;
        case UPDATE:
            [commandObject.objectToSync updateObject];
            break;
        case DELETE:
            [commandObject.objectToSync deleteObjectWithChildren];
            break;
        default:
            break;
    }
    [self objectSyncFinishedWithStatus:SYNC_FINISHED_OK];
}

- (NSURLSessionDataTask *)performRequest: (REQUEST_TYPE) requestType URL:(NSString *)URLString
                    parameters:(id)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                 failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    switch (requestType) {
        case REQUEST_NONE:
            success(nil,[NSDictionary new]);
            return nil;
            break;
        case REQUEST_GET:
            return [self GET:URLString parameters:parameters success:success failure:failure];
            break;
        case REQUEST_PUT:
            return [self PUT:URLString parameters:parameters success:success failure:failure];
            break;
        case REQUEST_POST:
            return [self POST:URLString parameters:parameters success:success failure:failure];
            break;
        case REQUEST_DELETE:
            return [self DELETE:URLString parameters:parameters success:success failure:failure];
            break;
        case REQUEST_PATCH:
            return [self PATCH:URLString parameters:parameters success:success failure:failure];
            break;
        default:
            break;
    }
    
    return nil;
    
}

- (void) updateTotalStatusWithStatus:(SYNC_FINISHED_STATUS) status{
    //weak- OK->remote->local->get -strong
    //
    if(_syncFinishedStatus == SYNC_FINISHED_GET_ERROR || status == SYNC_FINISHED_OK) {
        return;
    }
    else if(_syncFinishedStatus == SYNC_FINISHED_OK || status == SYNC_FINISHED_GET_ERROR){
        _syncFinishedStatus = status;
    }
    else if(_syncFinishedStatus == SYNC_FINISHED_LOCAL_ERROR || status == SYNC_FINISHED_REMOTE_ERROR) {
        return;
    }
    else {
        _syncFinishedStatus = status;
    }
}

- (void) objectSyncFinishedWithStatus: (SYNC_FINISHED_STATUS) status {
    [self updateTotalStatusWithStatus:status];
    _objectsUpdated++;
    if(_objectsUpdated >= _objectsToUpdate) {
        [_syncEngineDelegate objectSyncFinishedWithStatus:_syncFinishedStatus andError:nil];
    }
}



@end
