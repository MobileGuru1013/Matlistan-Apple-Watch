//
//  Ingredient.h
//  MatListan
//
//  Created by Yan Zhang on 24/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Recipebox;

@interface Ingredient : NSManagedObject

@property (nonatomic, retain) NSNumber * isCategory;
@property (nonatomic, retain) NSNumber * isProbablyNeeded;
@property (nonatomic, retain) NSString * knownItemText;
@property (nonatomic, retain) NSString * quantityText;
@property (nonatomic, retain) NSNumber * recipeID;
@property (nonatomic, retain) NSString * sortableText;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * unitText;
@property (nonatomic, retain) NSNumber * isSelected;
@property (nonatomic, retain) NSString * possibleMatchText;
@property (nonatomic, retain) Recipebox *belongToRecipe;

@end
