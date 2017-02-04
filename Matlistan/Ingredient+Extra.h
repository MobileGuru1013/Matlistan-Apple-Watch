//
//  Ingredient+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 09/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Ingredient.h"
#import "Recipebox.h"

@interface Ingredient (Extra)


+(void)insertIngredients:(NSArray*)itemArray forRecipe:(NSNumber*)recipeboxID;

+(void)deleteIngredients:(NSNumber *)recipeboxID inContext:(NSManagedObjectContext*)context;

+(void)insertIngredientsForRecipe:(Recipebox*)recipe withInput:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context;

+(void)updateIngredientsForRecipe:(Recipebox*)recipe withInput:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context;
+(NSArray*)getIngredientsOfRecipeID:(NSNumber*)recipeID;
+(void)updateIngredient:(Ingredient*)ingredient WithSelectedStatus:(NSNumber*)selected ForRecipe:(Recipebox*)recipe;

-(NSDictionary *) getJSONforActiveRecipe;
@end
