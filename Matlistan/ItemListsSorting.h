//
//  ItemListsSorting.h
//  Matlistan
//
//  Created by Artem Bakanov on 9/11/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface ItemListsSorting : NSManagedObject

@property (nonatomic, retain) NSNumber * item_listID;
@property (nonatomic, retain) NSNumber * shopID;
@property (nonatomic, retain) id unknownItems;
@property (nonatomic, retain) id sortedItems;
@property (nonatomic, retain) NSNumber *sortingHashCode;

@end
