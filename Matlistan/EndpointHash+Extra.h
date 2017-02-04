//
//  EndpointHash+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 10/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "EndpointHash.h"

@interface EndpointHash (Extra)

+(void)insertItems:(id)responseObject;
+(void)deleteAllItemsInContext:(NSManagedObjectContext*)context;
+(void)updateItems:(id)responseObject;
+(void)updateItemsHashWithValue:(NSNumber*) itemsHash;
+(void)updateTotalHashWithValue:(NSNumber*) totalHash;
@end
