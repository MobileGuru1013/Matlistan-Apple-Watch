//
//  EndpointHash+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 10/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "EndpointHash+Extra.h"

@implementation EndpointHash (Extra)
+(void)insertItems:(id)responseObject{
    NSDictionary *allItems = (NSDictionary*)responseObject;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        [EndpointHash MR_importFromObject:allItems inContext:localContext];
        [localContext MR_saveToPersistentStoreAndWait];
    }];
}

+(void)deleteAllItemsInContext:(NSManagedObjectContext*)context{
    if (context == nil) {
        /*
        [EndpointHash MR_truncateAll];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        */
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            [EndpointHash MR_truncateAllInContext:localContext];
            [localContext MR_saveToPersistentStoreAndWait];
        }];
    } else {
        [EndpointHash MR_truncateAll];
        [context MR_saveToPersistentStoreAndWait];
    }

    
}

+(void)updateItems:(id)responseObject{
    [self deleteAllItemsInContext:nil];
    [self insertItems:responseObject];
}

+(void)updateItemsHashWithValue:(NSNumber*) itemsHash{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        EndpointHash *hashes = [EndpointHash MR_findFirstInContext:localContext];
        hashes.itemsHash = itemsHash;
    }];
}

+(void)updateTotalHashWithValue:(NSNumber*) totalHash {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        EndpointHash *hashes = [EndpointHash MR_findFirstInContext:localContext];
        hashes.totalHash = totalHash;
    }];
}


@end
