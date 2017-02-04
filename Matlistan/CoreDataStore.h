//
//  CoreDataStore.h
//  MatListan
//
//  Created by Yan Zhang on 03/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataStore : NSObject

+(id)sharedInstance;

- (NSManagedObjectContext *)masterManagedObjectContext;
- (NSManagedObjectContext *)backgroundManagedObjectContext;
- (NSManagedObjectContext *)newManagedObjectContext;
- (void)saveMasterContext;
- (void)saveBackgroundContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
-(void)saveChanges:(NSManagedObjectContext*)context;
@end
