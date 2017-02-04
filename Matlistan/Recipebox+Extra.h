//
//  Recipebox+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 06/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Recipebox.h"
#import "DataStore.h"
#import "Active_recipe+Extra.h"
#import "SuperObject.h"

@interface Recipebox (Extra)<SuperObject>

+(void)importRecipe:(NSArray*)recipeDetails;
+(void)deleteAllRecipes;
+(void)insertItems:(id)responseObject;
+(NSArray*)getAllRecipesExceptDeleted;
+(BOOL)fakeDeleteById:(NSNumber*)recipeId;
+(void)realDelete;
+(NSArray*)getAllRecipesFakeDeleted;
+(NSArray*)getAllRecipesByStatus:(SYNC_STATUS)status;
+(Recipebox*)getRecipeById:(NSNumber*)recipeId;
+(void)changePortionsWith:(NSString*)count forRecipe:(Recipebox*)recipe;
+(void)changeCookingTimeWith:(NSNumber*)cookingTime andRating:(NSNumber*)rating forRecipe:(Recipebox*)recipe;
+(void)changeSyncStatus:(SYNC_STATUS)status forObjectID:(NSManagedObjectID *)recipeObjectID;
+(void)fillImageFileName:(NSString*)fileName forId:(NSNumber*)recipeId;
+(Active_recipe*)getActiveRecipeByRecipeId:(NSNumber*)recipeId;
+(NSArray*)getSortDescriptor:(SORT_TYPE_RECIPE)type;
+(NSArray*)getAllRecipesExceptDeletedOrderBy:(SORT_TYPE_RECIPE)type;
+(NSString*)getCookTimeStringFromRecipe:(Recipebox*)recipe;
//+(void) createRecipeWithTitle: (NSString*) title isPublic: (BOOL) isPublic cookTime: (NSNumber*) cookTime description: (NSString*) description instructions:(NSString*) instructions ingredients: (NSString*) ingredients advice: (NSString*) advice notes:(NSString*) notes portions: (NSNumber*) portions portionType:(NSString*) portionType source: (NSString*) source tags: (NSArray*) tags image:(NSString*) image;

//-(void) updateRecipeWithTitle: (NSString*) title isPublic: (BOOL) isPublic cookTime: (NSNumber*) cookTime description: (NSString*) description instructions:(NSString*) instructions ingredients: (NSString*) ingredients advice: (NSString*) advice notes:(NSString*) notes portions: (NSNumber*) portions portionType:(NSString*) portionType source: (NSString*) source tags: (NSArray*) tags image:(NSString*) image;
+ (void) createObjectWithResponseForInsert: (id) response;
@end
