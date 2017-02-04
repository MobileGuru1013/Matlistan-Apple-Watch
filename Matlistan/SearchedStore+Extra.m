//
//  SearchedStore+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 21/03/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "SearchedStore+Extra.h"

@implementation SearchedStore (Extra)
+(void)insertSearchedStores:(id)responseObject{
    NSArray *itemArray = (NSArray*)responseObject;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        
        [SearchedStore MR_importFromArray:itemArray inContext:localContext];
        
    }];
    
}

+(void)deleteAllItems{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [SearchedStore MR_truncateAll];
        [localContext MR_saveToPersistentStoreAndWait];
    }completion:^(BOOL success, NSError *error) {
    }];
}

+(NSArray*)getAllStores{
    
    NSArray *itemArray = [SearchedStore MR_findAll];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"itemsSortedPercent" ascending:NO];
    
    NSSortDescriptor *sortByDistance = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    
    return [itemArray sortedArrayUsingDescriptors:@[sortByDistance, sort]];
    
}


@end
