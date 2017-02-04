//
//  ItemListsSortOrder.h
//  Matlistan
//
//  Created by Artem Bakanov on 7/30/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SuperObject.h"

@interface ItemListsSortOrder : NSObject<SuperObject>

@property NSNumber *itemListId;
@property NSString *sortOrder;
@property NSNumber *storeId;
@property NSNumber *syncStatus;

@end
