//
//  Store.h
//  MatListan
//
//  Created by Yan Zhang on 18/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item_list;

@interface Store : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) NSNumber * itemsSortedPercent;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * postalAddress;
@property (nonatomic, retain) NSNumber * postalCode;
@property (nonatomic, retain) NSNumber * serverid;
@property (nonatomic, retain) NSNumber * storeID;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) Item_list *relatedItemsList;

@end
