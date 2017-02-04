//
//  Ingredient+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 09/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Ingredient+Extra.h"
#import "DataStore.h"
#import "Recipebox+Extra.h"
#import "Mixpanel.h"

@implementation Ingredient (Extra)

+(void)deleteIngredients:(NSNumber *)recipeboxID inContext:(NSManagedObjectContext*)context{
    NSManagedObjectContext *localContext    = context;
    
    NSArray *items = [Ingredient MR_findByAttribute:@"recipeID" withValue:recipeboxID];
    
    if (items.count > 0) {
        for (Ingredient *item in items){

            NSManagedObject *localObject = [item MR_inContext:localContext];
            [localObject MR_deleteEntityInContext:localContext];
            
        }
        //[localContext MR_saveToPersistentStoreAndWait];
    }
}

+(void)insertIngredients:(NSArray*)itemArray forRecipe:(NSNumber*)recipeboxID{
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSArray *items = [Ingredient MR_importFromArray:itemArray inContext:localContext];
        for (Ingredient *item in items) {
            item.recipeID = recipeboxID;
        }
    }];
}

+(void)updateIngredientsForRecipe:(Recipebox*)recipe withInput:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context{
    [self deleteIngredients:recipe.recipeboxID inContext:context];
    [self insertIngredientsForRecipe:recipe withInput:itemArray inContext:context];
}
/*
 *Used to add a new active recipe
 */
+(void)updateIngredient:(Ingredient*)ingredient WithSelectedStatus:(NSNumber*)selected ForRecipe:(Recipebox*)recipe{
    DLog(@"%@ %@", ingredient.text, ingredient.isSelected);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Ingredient *localIngr = [ingredient MR_inContext:localContext];
        localIngr.isSelected = selected;
        if([localIngr.syncStatus intValue] == Synced){
            localIngr.syncStatus = [NSNumber numberWithInt:Updated];
        }
    }];
    
}

+(void)insertIngredientsForRecipe:(Recipebox*)recipe withInput:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context{
    NSArray *items = [Ingredient MR_importFromArray:itemArray inContext:context];
    for (Ingredient *item in items) {
        item.recipeID = recipe.recipeboxID;
    }
    //[context MR_saveToPersistentStoreAndWait];
}

+(NSArray*)getIngredientsOfRecipeID:(NSNumber*)recipeID{
     NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(recipeID == %@) AND (syncStatus != %@)",recipeID, [NSNumber numberWithInt:Deleted]];
    NSArray *ingredients = [Ingredient MR_findAllWithPredicate:predicate];
    return ingredients;
}

-(NSDictionary *) getJSONforActiveRecipe {
    NSMutableDictionary *result = [NSMutableDictionary new];
    [result setObject:self.text forKey:@"text"];
    [result setObject:self.isSelected forKey:@"isSelected"];
    if(self.possibleMatchText) [result setObject:self.possibleMatchText forKey:@"possibleMatchText"];
    return  result;
}


@end
