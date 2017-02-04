//
//  SuperObject.h
//  Matlistan
//
//  Created by Artem Bakanov on 7/27/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncStatusEnum.h"
#import "RequestTypeEnum.h"

@protocol SuperObject
/*
 Get 'remote' id of an object
 In case of virtual objects, the id of an object they are related to (for example itemID for ItemCheckedStatus)
 NOTE: ALL following ids are 'remote' ids
 */
- (id)getId;

/*
 Object to sync must have syncStatus variable
 */
- (NSNumber *) syncStatus;


/*
 Physically delete object and its related objects (for example you should delete Ites wen deleting Item_list)
 */
- (void) deleteObjectWithChildren;

/*
 Save object to database
 */
- (void) updateObject;

/*
 Method is called when application recieves response for insert request.
 Usually response include an object.
 Use manual 'field-by-field' updating in order not to rewrite local data with null, if some data is not come from server.
 */
- (void) updateObjectWithResponseForInsert: (id) response;

/*
 Method is called when application recieves response for update request.
 Usually response include an object.
 Use manual 'field-by-field' updating in order not to rewrite local data with null, if some data is not come from server.
 */
- (void) updateObjectWithResponseForUpdate: (id) response;

/*
 Method is called when object, came with response for GET request is not in database.
 Do not perform actual insert if 'parent' of the object doesn't exist in local database
 For example do not insert Active_recipe if there is no Recipebox for it.
 */
+ (void)insertObjectWithParentCheckAndJson: (id) objectJson;

/*
 Method is called when object, came with response for GET request is in database and synced.
 Do not perform actual update if 'parent' of the object doesn't exist in local database
 For example do not insert Active_recipe if there is no Recipebox for it.
 */
+ (void) updateObjectWithJson: (id) objectJson;

/*
 Delete objects !!!with Synced status!!!, except objects with ids in parameter.
 Method is called to delete objects from database that are deleted on server.
 objectIds parameter will contain ids of existing objects from server
 */
+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds;

/*
 Return parameters for Insert request
 */
- (NSDictionary *) parseToInsertJSON;

/*
 Return parameters for Update request
 */
- (NSDictionary *) parseToUpdateJSON;
/*
 Method is used to prevent sending object to server before its parents were successfully created on server.
 Check that object has exising 'parents' that are NOT of Inserted status
 Return YES if there are no parens
 */
- (BOOL) parentSyncedCheck;

/*
 Method is used to prevent saving object to local db before its parents were successfully created.
 Check that object has exising 'parents'
 Return YES if there are no parens
 */
+ (BOOL) parentsExistForResponse: (id) responseJSON;

/*
 Is object physically presents in local database
 */
+ (BOOL) isInDatabase: (NSNumber *) objectId;

/*
 Get all objects with syncStatus NOT Synced
 */
+ (NSArray *) getNotSyncedObjects;

/*
 If there are >0 objects syncStatus NOT Synced
 */
+ (BOOL) needsUpdate;

/*
 Create NSDictionary with object ids as keys and corresponding JSONs as values
 For 'heavy' objects just use empty dictionaries for values
 */
+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject;

//URL for initial GET request
+ (NSString *) getObjectURL;
//URL for delete object
- (NSString *) getDeleteURL;
//URL for update object
- (NSString *) getUpdateURL;
//URL for insert object
- (NSString *) getInsertURL;

//Request type for initial GET request
+ (REQUEST_TYPE) getGetRequestType;
//Request type for insert request
+ (REQUEST_TYPE) getInsertRequestType;
//Request type for update request
+ (REQUEST_TYPE) getUpdateRequestType;
//Request type for delete request
+ (REQUEST_TYPE) getDeleteRequestType;

/*
 Return YES if initial GET request returns just an ID list and object itself must be retrieved with other link (usually conaining ID)
 Currently, Recipebox and Vsit are heavy objects
 */
+ (BOOL)isHeavyObject;

/*NOTE!! following metods are REQUIRED if the object is heavy*/
@optional

/*
 url for heavy object get (usuallu contains object id)
 */
+ (NSString*) heavyObjectURL: (NSNumber *) objectId;

//Request type for heavy object get request
+ (REQUEST_TYPE) heavyObjectGetRequestType;

//Parameters for heavy object get request
+ (NSDictionary *) getHeavyParameters;

//remove all ids that are not needed to update
+ (NSDictionary *) removeIdsNotNeededToUpdate: (NSDictionary *) remoteObjectsIdsAndObjects;

@end
