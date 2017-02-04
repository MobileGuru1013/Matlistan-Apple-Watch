//
//  Active_recipe.h
//  MatListan
//
//  Created by Yan Zhang on 29/03/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Active_recipe : NSManagedObject

@property (nonatomic, retain) NSNumber * active_recipeID;
@property (nonatomic, retain) NSString * ingredients;
@property (nonatomic, retain) NSString * ingredientsMarkup;
@property (nonatomic, retain) NSNumber * isPurchased;
@property (nonatomic, retain) NSNumber * isCooked;
@property (nonatomic, retain) NSNumber * itemOrder;
@property (nonatomic, retain) NSNumber * listID;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * occasion;
@property (nonatomic, retain) NSNumber * portions;
@property (nonatomic, retain) NSNumber * portions2; //Never use this! Use portionsStr instead
@property (nonatomic, retain) NSString * portionsStr;
@property (nonatomic, retain) NSNumber * recipeID;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSData * ingredientsJSONArray;

@end
