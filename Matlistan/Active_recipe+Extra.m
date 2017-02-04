//
//  Active_recipe+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 08/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Active_recipe+Extra.h"
#import "Ingredient+Extra.h"
#import "SignificantChangesIndicator.h"
#import "SyncManager.h"


@implementation Active_recipe (Extra)
+(void)insertItems:(id)responseObject{
    NSDictionary *allItems = (NSDictionary*)responseObject;
    
    NSArray *itemArray = [allItems objectForKey:@"list"];

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
             [Active_recipe MR_importFromArray:itemArray inContext:localContext];
    }completion:^(BOOL success, NSError *error) {
    }];

}

+(void)deleteAllRecipes{
    NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_context];
    [Active_recipe MR_truncateAll];

    [localContext MR_saveToPersistentStoreAndWait];
}
+(NSArray*)getAllActiveRecipesExceptDeleted{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Deleted]];
    NSArray *resultArray = [Active_recipe MR_findAllWithPredicate:predicate];
    return resultArray;
}

+(NSArray*)getAllActiveRecipes{
    NSArray *resultArray = [Active_recipe MR_findAll];
    return resultArray;
}

+(void)cleanDuplicatedRecipes{
  
  NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(active_recipeID = 0) AND (syncStatus = %@)",[NSNumber numberWithInt:Synced]];
  NSArray *syncedRecipes = [Active_recipe MR_findAllWithPredicate:predicate];
  
  NSPredicate *predicate2 =[NSPredicate predicateWithFormat:@"active_recipeID != 0"];
  NSArray *allRecipesWithIDs = [Active_recipe MR_findAllWithPredicate:predicate2];
  
  
    for (Active_recipe* syncedRecipe in syncedRecipes) {
        for (Active_recipe* recipe in allRecipesWithIDs) {
            DLog(@"%@ , %@", recipe.recipeID, syncedRecipe.recipeID);
            if ([recipe.recipeID intValue] == [syncedRecipe.recipeID intValue]) {
        
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            [syncedRecipe MR_deleteEntityInContext:localContext];   //sometimes crash here. No idea about the reason
            //syncedRecipe.syncStatus = @(Deleted);
            DLog(@"Clean duplicated recipe %@", recipe.recipeID);
        }];

      }
    }
  }
  
}
/*Get activeRecipes to buy or to cook
 * 
 */
+(NSArray*)getAllActiveRecipesWithPurchaseStatus:(BOOL)toBuy{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(isPurchased== %@) AND (syncStatus != %@) AND (isCooked != %@)",[NSNumber numberWithBool:toBuy], [NSNumber numberWithInt:Deleted], @1];
    NSArray *resultArray = [Active_recipe MR_findAllSortedBy:@"itemOrder" ascending:YES withPredicate:predicate];
    return resultArray;
}

+(NSArray*)getAllActiveRecipesFakeDeleted{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus = %@", [NSNumber numberWithInt:Deleted]];
    NSArray *resultArray = [Active_recipe MR_findAllWithPredicate:predicate];
    return resultArray;
}

+(NSArray*)getAllActiveRecipesByStatus:(SYNC_STATUS)status{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus = %@", [NSNumber numberWithInt:status]];
    NSArray *resultArray = [Active_recipe MR_findAllWithPredicate:predicate];
    return resultArray;
}

+(BOOL)isActiveRecipe:(NSNumber*)recipeID{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"recipeID = %@", recipeID];
    Active_recipe *activeRecipe = [Active_recipe MR_findFirstWithPredicate:predicate];
    
    return (activeRecipe != nil);
}

+(void)changeSyncStatus:(SYNC_STATUS)status forActiveRecipe:(Active_recipe*)activeRecipe{
    NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_context];
    activeRecipe.syncStatus = [NSNumber numberWithInt:status];
    [localContext MR_saveToPersistentStoreAndWait];
}

+(Active_recipe*)getActiveRecipeById:(NSNumber*)activeRecipeId{
    NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_context];
    Active_recipe *recipe = [Active_recipe MR_findFirstByAttribute:@"active_recipeID" withValue:activeRecipeId];
    [localContext MR_saveToPersistentStoreAndWait];
    return recipe;
}

+(void)boughtActiveRecipe:(NSNumber*)activeRecipeId{
    CLS_LOG(@"Bought active recipe with id: %@", activeRecipeId);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Active_recipe *recipe = [Active_recipe MR_findFirstByAttribute:@"active_recipeID" withValue:activeRecipeId inContext:localContext];
        recipe.isPurchased = [NSNumber numberWithBool:YES];
        if([recipe.syncStatus intValue] == Synced){
            recipe.syncStatus = [NSNumber numberWithInt:Updated];
        }
    }];
}

+(void)fakeDeleteById:(NSNumber*)activeRecipeId{
    CLS_LOG(@"Deleting active recipe with id: %@", activeRecipeId);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Active_recipe *recipe = [Active_recipe MR_findFirstByAttribute:@"active_recipeID" withValue:activeRecipeId inContext:localContext];
        recipe.syncStatus = [NSNumber numberWithInt:Deleted];
    }];
}

+(void)realDelete{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus == %@",[NSNumber numberWithInt:Deleted]];
        NSArray *recipes = [Active_recipe MR_findAllWithPredicate:predicate inContext:localContext];
        if (recipes.count > 0) {
            for (Active_recipe *item in recipes){
                NSManagedObject *localObject = [item MR_inContext:localContext];
                [localObject MR_deleteEntityInContext:localContext];
            }
        }
    }];
}

+(void)insertActiveRecipeWith:(NSNumber*)recipeID andPortions:(NSString*)portions  withIngredients:(NSArray*) ingredientsJSON forOccasion:(NSString*)occasion andNotes:(NSString*)notes inList:(NSNumber*)listID{
    CLS_LOG(@"Insert active recipe.\nRecipe id: %@\nPortions: %@\nIngredients: %@\nOccasion: %@\nNotes: %@\nList id: %@", recipeID, portions, ingredientsJSON, occasion, notes, listID);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Active_recipe *item = [Active_recipe MR_createEntityInContext:localContext];
        item.recipeID = recipeID;
        item.portionsStr = portions;
        item.occasion = occasion;
        item.notes = notes;
        item.ingredientsJSONArray = [NSKeyedArchiver archivedDataWithRootObject:ingredientsJSON];
        item.listID = listID;
        item.syncStatus = [NSNumber numberWithInt:Created];
    }];
}

+(void)changeSyncStatus:(SYNC_STATUS)status forObjectID:(NSManagedObjectID *)activeRecipeObjectID{

    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_context];
    [localContext performBlock:^{
        Active_recipe *recipe = (Active_recipe *)[localContext objectWithID:activeRecipeObjectID];
        if (nil != recipe)
        {
            recipe.syncStatus = [NSNumber numberWithInt:status];
            [localContext MR_saveToPersistentStoreAndWait];
        }
    }];

}

+ (void) setIsCooked: (NSNumber *) isCooked forActiveRecipeId: (NSNumber *) activeRecipeId {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"active_recipeID == %@", activeRecipeId];
        Active_recipe *currentActiveRecipe = [Active_recipe MR_findFirstWithPredicate:predicate inContext:localContext];
        currentActiveRecipe.isCooked = isCooked;
        if ([currentActiveRecipe.syncStatus intValue] == Synced) {
            currentActiveRecipe.syncStatus = [NSNumber numberWithInt: Updated];
        }
    }];
}

//SuperObject methods
- (void) updateObject {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Active_recipe *aRecipe = [self MR_inContext:localContext];
        aRecipe.syncStatus = [NSNumber numberWithInt:Synced];
    }];
}

- (NSNumber *)getId {
    return self.active_recipeID;
}

- (void) deleteObjectWithChildren {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSManagedObject *localObject = [self MR_inContext:localContext];
        [localObject MR_deleteEntityInContext:localContext];
    }];
}

- (BOOL) parentSyncedCheck{
    NSPredicate *recipePredicate =[NSPredicate predicateWithFormat:@"recipeboxID == %@ AND syncStatus != %@", self.recipeID, [NSNumber numberWithInt:Created]];
    BOOL recipesSynced = [[Recipebox MR_numberOfEntitiesWithPredicate:recipePredicate] intValue] > 0;
    
    BOOL itemListsSynced;
    if(self.listID && [self.listID intValue] != 0) {
        NSPredicate *listPredicate =[NSPredicate predicateWithFormat:@"item_listID == %@ AND syncStatus != %@", self.listID, [NSNumber numberWithInt:Created]];
        itemListsSynced = [[Item_list MR_numberOfEntitiesWithPredicate:listPredicate] intValue] > 0;
    }
    else {
        itemListsSynced = YES;
    }
    return recipesSynced && itemListsSynced;
}

+ (BOOL) isInDatabase: (NSNumber *) objectId {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"active_recipeID == %@", objectId];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSString *) getObjectURL {
    return @"ActiveRecipes";
}

+ (NSArray *) getNotSyncedObjects {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    NSArray *itemArray = [Active_recipe MR_findAllWithPredicate:predicate];
    return itemArray;
}

+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds {
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat: @"syncStatus == %@ AND NOT (active_recipeID IN %@)", [NSNumber numberWithInt:Synced], objectIds];
    NSArray *itemArray = [self MR_findAllWithPredicate:predicate];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        for (Active_recipe *item in itemArray){
            NSManagedObject *localObject = [item MR_inContext:localContext];
            [localObject MR_deleteEntityInContext:localContext];
            [SignificantChangesIndicator sharedIndicator].activeRecipeChanged = YES;
        }
    }];
}


- (void) updateObjectWithResponseForInsert: (id) response{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Active_recipe *aRecipe = [self MR_inContext:localContext];
        aRecipe.active_recipeID = [response objectForKey:@"id"];
        aRecipe.recipeID =  [response objectForKey:@"recipeId"];
        aRecipe.isPurchased = [response objectForKey:@"isPurchased"];
        aRecipe.occasion = [response objectForKey:@"occasion"];
        aRecipe.notes = [response objectForKey:@"notes"];
        aRecipe.portions = [response objectForKey:@"portions"];
        aRecipe.portionsStr = [response objectForKey:@"portions2"];
        aRecipe.ingredients = [response objectForKey:@"ingredients"];
        aRecipe.ingredientsMarkup = [response objectForKey:@"ingredientsMarkup"];
        aRecipe.syncStatus = [NSNumber numberWithInt:Synced];
        [SignificantChangesIndicator sharedIndicator].activeRecipeChanged = YES;
        
        [[SyncManager sharedManager] forceSync];
    }];
}

+ (BOOL) needsUpdate {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject{
    NSMutableDictionary *objectsAndIds = [NSMutableDictionary new];
    int i = 0;
    for (NSDictionary * objectJSON in [jsonResposeObject objectForKey:@"list"]){
        NSMutableDictionary *zzz = [NSMutableDictionary dictionaryWithDictionary:objectJSON];
        [zzz setObject:[NSNumber numberWithInt:i] forKey:@"itemOrder"];
        [objectsAndIds setObject:zzz forKey:[objectJSON valueForKey:@"id"]];
        i++;
    }
    return objectsAndIds;
}

+ (void)insertObjectWithParentCheckAndJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Active_recipe *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt: Synced];
        item.itemOrder = [objectJson valueForKey:@"itemOrder"];
        [SignificantChangesIndicator sharedIndicator].activeRecipeChanged = YES;
    }];
}
+ (void) updateObjectWithJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Active_recipe *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt: Synced];
        item.itemOrder = [objectJson valueForKey:@"itemOrder"];
        [SignificantChangesIndicator sharedIndicator].activeRecipeChanged = YES;
    }];
}

+(BOOL) parentsExistForResponse: (id) json {
    NSPredicate *recipePredicate =[NSPredicate predicateWithFormat:@"recipeboxID == %@ AND syncStatus != %@", [json objectForKey:@"recipeId"] , [NSNumber numberWithInt:Deleted]];
    BOOL recipesSynced = [[Recipebox MR_numberOfEntitiesWithPredicate:recipePredicate] intValue] > 0;

    return recipesSynced;

}

- (NSString *) getUpdateURL{
    return [NSString stringWithFormat:@"%@/%@", [[self class] getObjectURL], [self getId]];
}
- (NSString *) getInsertURL{
    return [[self class] getObjectURL];
}

+ (REQUEST_TYPE) getGetRequestType {
    return REQUEST_GET;
}
+ (REQUEST_TYPE) getInsertRequestType {
    return REQUEST_POST;
}
+ (REQUEST_TYPE) getUpdateRequestType {
    return REQUEST_PATCH;
}
+ (REQUEST_TYPE) getDeleteRequestType {
    return REQUEST_DELETE;
}

- (NSDictionary *) parseToInsertJSON {
    NSArray *ingredients = [NSKeyedUnarchiver unarchiveObjectWithData:self.ingredientsJSONArray];
/*
    NSMutableArray *ingredientList = [[NSMutableArray alloc]init];
    for (Ingredient *ingredient in ingredients) {
        NSString *matchText = ingredient.possibleMatchText == nil? ingredient.text:ingredient.possibleMatchText;
        if (ingredient.isSelected != nil && [ingredient.isSelected boolValue] == YES) {
            
            NSDictionary *dict = @{@"text":ingredient.text,
                                   @"isSelected":ingredient.isSelected,
                                   @"possibleMatchText":matchText
                                   };
            
            [ingredientList addObject:dict];
        }
    }
*/
    NSMutableDictionary *json = [NSMutableDictionary new];

    if (self.recipeID) [json setObject:self.recipeID forKey:@"recipeId"];
    //if (self.portions) [json setObject:self.portions forKey:@"portions"];
    if (self.portionsStr) [json setObject:self.portionsStr forKey:@"portions"];
    if (self.listID) [json setObject:self.listID forKey:@"itemListId"];
    if (ingredients && ingredients.count > 0) [json setObject:ingredients forKey:@"ingredients"];
    if (self.occasion) [json setObject:self.occasion forKey:@"occasion"];
    if (self.notes) [json setObject:self.notes forKey:@"notes"];
    
    [[SyncManager sharedManager] forceSync];

    return json;
}
- (NSDictionary *) parseToUpdateJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    if([self.isCooked boolValue]) {
        [json setObject:self.isCooked forKey:@"isCooked"];
    }
    else {
        [json setObject:self.isPurchased forKey:@"isPurchased"];
    }
    
    return json;
}

+ (BOOL)isHeavyObject {
    return NO;
}

- (NSString *) getDeleteURL {
    return [NSString stringWithFormat:@"%@/%@", [[self class] getObjectURL], [self getId]];
}

- (void)updateObjectWithResponseForUpdate:(id)response {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Active_recipe *aRecipe = [self MR_inContext:localContext];
        aRecipe.active_recipeID = [response objectForKey:@"id"];
        aRecipe.recipeID = [response objectForKey:@"recipeId"];
        aRecipe.isPurchased = [response objectForKey:@"isPurchased"];
        aRecipe.occasion = [response objectForKey:@"occasion"];
        aRecipe.notes = [response objectForKey:@"notes"];
        aRecipe.portions = [response objectForKey:@"portions"];
        aRecipe.portionsStr = [response objectForKey:@"portions2"];
        aRecipe.ingredients = [response objectForKey:@"ingredients"];
        aRecipe.ingredientsMarkup = [response objectForKey:@"ingredientsMarkup"];
        aRecipe.syncStatus = [NSNumber numberWithInt:Synced];
        [SignificantChangesIndicator sharedIndicator].activeRecipeChanged = YES;
    }];
}

@end
