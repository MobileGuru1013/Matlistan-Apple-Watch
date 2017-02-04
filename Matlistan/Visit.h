//
//  Visit.h
//  MatListan
//
//  Created by Yan Zhang on 09/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Visit : NSManagedObject

@property (nonatomic, retain) NSNumber * visitID;
@property (nonatomic, retain) NSNumber * list;
@property (nonatomic, retain) NSNumber * started_at;
@property (nonatomic, retain) NSNumber * syncStatus; //sync status is used to decide if an object should be synced or not synced.
@property (nonatomic, retain) NSNumber * time_diff;
@property (nonatomic, retain) NSNumber * updated_at;

@end
