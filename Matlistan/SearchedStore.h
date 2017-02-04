//
//  SearchedStore.h
//  MatListan
//
//  Created by Yan Zhang on 21/03/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SearchedStore : NSManagedObject

@property (nonatomic, retain) NSString * postalAddress;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSNumber * postalCode;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) NSNumber * itemsSortedPercent;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) NSNumber * searchedStoreID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * address;

@end
