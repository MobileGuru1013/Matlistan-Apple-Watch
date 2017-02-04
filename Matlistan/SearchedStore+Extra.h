//
//  SearchedStore+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 21/03/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "SearchedStore.h"

@interface SearchedStore (Extra)

+(void)insertSearchedStores:(id)responseObject;
+(NSArray*)getAllStores;
+(void)deleteAllItems;
@end
