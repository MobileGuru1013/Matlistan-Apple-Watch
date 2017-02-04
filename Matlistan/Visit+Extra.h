//
//  Visit+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 26/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Visit.h"
#import "DataStore.h"
#import "SuperObject.h"

@interface Visit (Extra)<SuperObject>
//Seems that we don't need it anymore
/*
+(NSArray*)getAllVisits;
+(void)insertVisitWithStarted:(NSNumber*)startedAt andUpdated:(NSNumber*)updatedAt andTimeDiff:(NSNumber*)timeDiff forListID:(NSNumber*)listID;
+(Visit*)getVisitByList:(NSNumber*)listID;
+(void)cleanOldVisits;
+(void)updateVisitUpdatedAt:(NSNumber*)listId;
+(void)updateVisitTimeDiff:(NSNumber*)timeDiff forList:(NSNumber*)listId;
 */
@end
