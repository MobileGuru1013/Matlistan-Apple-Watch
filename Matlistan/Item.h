//
//  Item.h
//  MatListan
//
//  Created by Yan Zhang on 18/02/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item_list, ItemsCheckedStatus;

@interface Item : NSManagedObject

@property (nonatomic, retain) NSString * addedAt;
@property (nonatomic, retain) NSDate * addedAtTime;
@property (nonatomic, retain) NSString * barcode;
@property (nonatomic, retain) NSString * barcodeType;
@property (nonatomic, retain) NSNumber * checkedAfterStart;
@property (nonatomic, retain) NSNumber * groupedSortIndex;
@property (nonatomic, retain) NSString * groupedText;
@property (nonatomic, retain) NSNumber * isChecked;
@property (nonatomic, retain) NSNumber * isDefaultMatch;
@property (nonatomic, retain) NSNumber * isPermanent;
@property (nonatomic, retain) NSNumber * isPossibleMatch;
@property (nonatomic, retain) NSNumber * isTaken;
@property (nonatomic, retain) NSNumber * itemID;
@property (nonatomic, retain) NSString * knownItemText;
@property (nonatomic, retain) NSNumber * listId;
@property (nonatomic, retain) NSString * listObjectID;
@property (nonatomic, retain) NSNumber * manualSortIndex;
@property (nonatomic, retain) NSString * matchingItemText;
@property (nonatomic, retain) NSNumber * mayBeDefaultMatch;
@property (nonatomic, retain) NSString * placeCategory;
@property (nonatomic, retain) id possibleMatches;
@property (nonatomic, retain) NSString * searchedText;
@property (nonatomic, retain) NSNumber * secs_after_start;
@property (nonatomic, retain) NSNumber * secs_after_start_local;
@property (nonatomic, retain) NSNumber * serverIndex;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * addedAtTime_local;
@property (nonatomic, retain) Item_list *belongToList;
@property (nonatomic, retain) ItemsCheckedStatus *itemsCheckedStatus;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSNumber * checkOrder;

@end
