//
//  Active_recipe+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 08/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Active_recipe.h"
#import "DataStore.h"
#import "SuperObject.h"

@interface Active_recipe (Extra)<SuperObject>
+(void)insertItems:(id)responseObject;
+(void)deleteAllRecipes;

+(void)cleanDuplicatedRecipes;
+(NSArray*)getAllActiveRecipesExceptDeleted;

+(NSArray*)getAllActiveRecipesFakeDeleted;

+(NSArray*)getAllActiveRecipesByStatus:(SYNC_STATUS)status;
+(void)fakeDeleteById:(NSNumber*)activeRecipeId;
+(void)realDelete;
+(Active_recipe*)getActiveRecipeById:(NSNumber*)activeRecipeId;
+(void)boughtActiveRecipe:(NSNumber*)activeRecipeId;
+(NSArray*)getAllActiveRecipesWithPurchaseStatus:(BOOL)toBuy;

+(void)changeSyncStatus:(SYNC_STATUS)status forActiveRecipe:(Active_recipe*)activeRecipe;
+(void)insertActiveRecipeWith:(NSNumber*)recipeID andPortions:(NSString*)portions  withIngredients:(NSArray*)ingredientsJSON forOccasion:(NSString*)occasion andNotes:(NSString*)notes inList:(NSNumber*)listID;
+(NSArray*)getAllActiveRecipes;
+(BOOL)isActiveRecipe:(NSNumber*)recipeID;

+(void)changeSyncStatus:(SYNC_STATUS)status forObjectID:(NSManagedObjectID *)activeRecipeObjectID;

+ (void) setIsCooked: (NSNumber *) isCooked forActiveRecipeId: (NSNumber *) recipeboxId;

@end
