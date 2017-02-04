//
//  ItemsCheckedStatus.h
//  MatListan
//
//  Created by Yan Zhang on 14/02/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item;

@interface ItemsCheckedStatus : NSManagedObject

@property (nonatomic, retain) NSString * checkedReason;
@property (nonatomic, retain) NSNumber * deviceId;
@property (nonatomic, retain) NSNumber * isChecked;
@property (nonatomic, retain) NSNumber * itemID;
@property (nonatomic, retain) NSString * itemObjectID;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * listID;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) id networks;
@property (nonatomic, retain) NSNumber * positionAccuracy;
@property (nonatomic, retain) NSNumber * secondsAfterStart;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSNumber * isTaken;
@property (nonatomic, retain) Item *item;
@property (nonatomic, retain) NSNumber *selectedStoreId;
@property (nonatomic, retain) NSDate *dateChecked_local;

@end
