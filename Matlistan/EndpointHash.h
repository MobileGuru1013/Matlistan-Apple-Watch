//
//  EndpointHash.h
//  MatListan
//
//  Created by Yan Zhang on 10/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EndpointHash : NSManagedObject

@property (nonatomic, retain) NSNumber * activeRecipesHash;
@property (nonatomic, retain) NSNumber * itemsHash;
@property (nonatomic, retain) NSNumber * itemListsHash;
@property (nonatomic, retain) NSString * recipeUpdatedAt;
@property (nonatomic, retain) NSNumber * favoriteItemsHash;
@property (nonatomic, retain) NSNumber * recipeCount;
@property (nonatomic, retain) NSNumber * storesHash;
@property (nonatomic, retain) NSNumber * totalHash;

@end
