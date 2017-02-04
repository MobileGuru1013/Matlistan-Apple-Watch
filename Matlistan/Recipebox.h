//
//  Recipebox.h
//  MatListan
//
//  Created by Yan Zhang on 29/03/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Active_recipe, Ingredient, Recipebox_tag;

@interface Recipebox : NSManagedObject

@property (nonatomic, retain) NSString * advice;
@property (nonatomic, retain) NSNumber * cookCount;
@property (nonatomic, retain) NSNumber * cookTime;
@property (nonatomic, retain) NSNumber * cooktime_sorting;
@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSString * imageFileName;
@property (nonatomic, retain) NSString * imageUrl;
@property (nonatomic, retain) NSString * ingredients;
@property (nonatomic, retain) NSString * ingredientsMarkup;
@property (nonatomic, retain) NSString * instructions;
@property (nonatomic, retain) NSString * instructionsMarkup;
@property (nonatomic, retain) NSNumber * isPublic;
@property (nonatomic, retain) NSString * lastCookedAt;
@property (nonatomic, retain) NSDate * lastCookedAtTime;
@property (nonatomic, retain) NSString * lastViewedAt;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSNumber * originalCookTime;
@property (nonatomic, retain) NSNumber * originalCookTimeSpanLower;
@property (nonatomic, retain) NSNumber * portions;
@property (nonatomic, retain) NSNumber * portions_span_lower;
@property (nonatomic, retain) NSString * portionType;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSNumber * recipeboxID;
@property (nonatomic, retain) NSString * sel_portions;
@property (nonatomic, retain) NSString * source_original_text;
@property (nonatomic, retain) NSString * source_text;
@property (nonatomic, retain) NSString * source_url;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * updatedAt;
@property (nonatomic, retain) NSSet *containIngredients;
@property (nonatomic, retain) Active_recipe *relatedActiveRecipe;
@property (nonatomic, retain) NSSet *relatedTags;
@property (nonatomic, retain) NSString *image;
@property (nonatomic, retain) NSNumber *imageUpdated;
@property (nonatomic, retain) NSNumber * manuallyUpdated;

@end

@interface Recipebox (CoreDataGeneratedAccessors)

- (void)addContainIngredientsObject:(Ingredient *)value;
- (void)removeContainIngredientsObject:(Ingredient *)value;
- (void)addContainIngredients:(NSSet *)values;
- (void)removeContainIngredients:(NSSet *)values;

- (void)addRelatedTagsObject:(Recipebox_tag *)value;
- (void)removeRelatedTagsObject:(Recipebox_tag *)value;
- (void)addRelatedTags:(NSSet *)values;
- (void)removeRelatedTags:(NSSet *)values;

@end
