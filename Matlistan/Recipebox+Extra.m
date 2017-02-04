//
//  Recipebox+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 06/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Recipebox+Extra.h"
#import "Ingredient+Extra.h"
#import "Recipebox_tag+Extra.h"
#import "Active_recipe+Extra.h"
#import "SignificantChangesIndicator.h"
#import "Mixpanel.h"

@implementation Recipebox (Extra)
/*
+(void) createRecipeWithTitle: (NSString*) title isPublic: (BOOL) isPublic cookTime: (NSNumber*) cookTime description: (NSString*) description instructions:(NSString*) instructions ingredients: (NSString*) ingredients advice: (NSString*) advice notes:(NSString*) notes portions: (NSNumber*) portions portionType:(NSString*) portionType source: (NSString*) source tags: (NSArray*) tags image:(NSString*) image {
    CLS_LOG(@"Insert Recipe.\nTitle: %@", title);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Recipebox *recipe = [Recipebox MR_createEntityInContext:localContext];
        recipe.title = title;
        recipe.isPublic = [NSNumber numberWithBool:isPublic];
        recipe.cookTime = cookTime;
        recipe.descriptionText = description;
        recipe.instructions = instructions;
        recipe.ingredients = ingredients;
        recipe.advice = advice;
        recipe.notes = notes;
        recipe.portions = portions;
        recipe.portionType = portionType;
        recipe.source_text = source;
        recipe.image = image;
        recipe.syncStatus = [NSNumber numberWithInt:Created];
        
        [Recipebox_tag insertTagsForRecipe:recipe withStrings:tags inContext:localContext];
    }];

}
 */

+ (void) createObjectWithResponseForInsert: (id) response{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Recipebox *recipe = [Recipebox MR_createEntityInContext:localContext];
        recipe.recipeboxID = [response objectForKey:@"id"];
        recipe.title = [response objectForKey:@"title"];
        recipe.createdAt = [response objectForKey:@"createdAt"];
        recipe.isPublic = [response objectForKey:@"isPublic"];
        recipe.lastViewedAt = [response objectForKey:@"lastViewedAt"];
        recipe.rating = [response objectForKey:@"rating"];
        recipe.cookTime = [response objectForKey:@"cookTime"];
        recipe.originalCookTime = [response objectForKey:@"originalCookTime"];
        recipe.originalCookTimeSpanLower = [response objectForKey:@"originalCookTimeSpanLower"];
        NSArray *imageUrls = [response objectForKey:@"imageUrls"];
        if(imageUrls && imageUrls.count > 0){
            recipe.imageUrl = [imageUrls[0] objectForKey:@"url"];
        }
        recipe.descriptionText = [response objectForKey:@"description"];
        recipe.instructions = [response objectForKey:@"instructions"];
        recipe.instructionsMarkup = [response objectForKey:@"instructionsMarkup"];
        recipe.ingredients = [response objectForKey:@"ingredients"];
        recipe.ingredientsMarkup = [response objectForKey:@"ingredientsMarkup"];
        recipe.advice = [response objectForKey:@"advice"];
        recipe.notes = [response objectForKey:@"notes"];
        recipe.portions = [response objectForKey:@"portions"];
        recipe.portions_span_lower = [response objectForKey:@"portionsSpanLower"];
        if(response[@"selectedPortions"]) recipe.sel_portions = [response objectForKey:@"selectedPortions"];
        recipe.portionType = [response objectForKey:@"portionType"];
        recipe.source_original_text = [[response objectForKey:@"source"] objectForKey:@"originalText"];
        recipe.source_text = [[response objectForKey:@"source"] objectForKey:@"text"];
        recipe.source_url = [[response objectForKey:@"source"] objectForKey:@"url"];
        recipe.lastCookedAt = [response objectForKey:@"lastCookedAt"];
        recipe.cookCount = [response objectForKey:@"cookCount"];
        recipe.updatedAt = [response objectForKey:@"updatedAt"];
        recipe.syncStatus = [NSNumber numberWithInt:Synced];
        recipe.lastCookedAtTime = [Utility getDateFromString:recipe.lastCookedAt];
        
        recipe.manuallyUpdated = @NO;
        recipe.imageUpdated = @NO;
        //import tags
        NSArray *tags = response[@"tags"];
        [Recipebox_tag updateTagsForRecipe:recipe withInput:tags inContext:localContext];
        
        //import parsed ingredients
        NSDictionary *parsedIngredients = response[@"parsedIngredients"];
        
        NSArray *ingredientsArray = [parsedIngredients objectForKey:@"list"];
        
        [Ingredient updateIngredientsForRecipe:recipe withInput:ingredientsArray inContext:localContext];
        [SignificantChangesIndicator sharedIndicator].recipeChanged = YES;
    }];
}
/*
-(void) updateRecipeWithTitle: (NSString*) title isPublic: (BOOL) isPublic cookTime: (NSNumber*) cookTime description: (NSString*) description instructions:(NSString*) instructions ingredients: (NSString*) ingredients advice: (NSString*) advice notes:(NSString*) notes portions: (NSNumber*) portions portionType:(NSString*) portionType source: (NSString*) source tags: (NSArray*) tags image:(NSString*) image {
    
    self.title = title;
    self.isPublic = [NSNumber numberWithBool:isPublic];
    self.cookTime = cookTime;
    self.descriptionText = description;
    self.instructions = instructions;
    self.ingredients = ingredients;
    self.advice = advice;
    self.notes = notes;
    self.portions = portions;
    self.portionType = portionType;
    self.source_text = source;
    if(image){
        self.image = image;
        self.imageUpdated = @YES;
    }
    self.syncStatus = [NSNumber numberWithInt:Updated];
    self.manuallyUpdated = @YES;
    [[self managedObjectContext] MR_saveToPersistentStoreAndWait];
}
 */

+(void)importRecipe:(NSArray*)recipeDetails{

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [Recipebox MR_importFromArray:recipeDetails];
    }completion:^(BOOL success, NSError *error) {
    }];
    
}
+(void)deleteAllRecipes{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *recipes = [Recipebox MR_findAll];
        if (recipes.count > 0) {
            for (Recipebox *recipe in recipes) {
                NSManagedObject *localObject = [recipe MR_inContext:localContext];
                [localObject MR_deleteEntityInContext:localContext];
            }
            [localContext MR_saveToPersistentStoreAndWait];
        }
    }completion:^(BOOL success, NSError *error) {
    }];
}

+(void)changePortionsWith:(NSString*)count forRecipe:(Recipebox*)recipe{
    CLS_LOG(@"Change portions for recipe:\nRecipe id: %@\nPortions count: %@", recipe.recipeboxID, count);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Recipebox *localObject = [recipe MR_inContext:localContext];
        localObject.sel_portions = count;
        if([localObject.syncStatus intValue] == Synced) {
            localObject.syncStatus = [NSNumber numberWithInt:Updated];
        }
    }];
}


+(void)changeCookingTimeWith:(NSNumber*)cookingTime andRating:(NSNumber*)rating forRecipe:(Recipebox*)recipe{
    CLS_LOG(@"Update recipe:\nRecipe id: %@\nCooking time: %@\nRating: %@", recipe.recipeboxID, cookingTime, rating);
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        recipe.cookTime = cookingTime;
        recipe.rating = rating;
        if([recipe.syncStatus intValue] == Synced) {
            recipe.syncStatus = [NSNumber numberWithInt:Updated];
        }
        
    }completion:^(BOOL success, NSError *error) {}];
}

+(BOOL)fakeDeleteById:(NSNumber*)recipeId{
    CLS_LOG(@"Delete recipe with id: %@", recipeId);
    Active_recipe *activeRecipe = [Active_recipe MR_findFirstByAttribute:@"recipeID" withValue:recipeId];
    if (activeRecipe != nil) {
        return NO;
    }
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Recipebox *recipe = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:recipeId inContext:localContext];
        recipe.syncStatus = [NSNumber numberWithInt:Deleted];
        [[DataStore instance].viewedRecipes removeObject:recipeId];
        [Utility saveInDefaultsWithObject:[DataStore instance].viewedRecipes andKey:@"viewedRecipes"];
    }];
    return YES;

}

+(Active_recipe*)getActiveRecipeByRecipeId:(NSNumber*)recipeId{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recipeID == %@", recipeId];
    NSArray *activeRecipes = [Active_recipe MR_findAllWithPredicate:predicate];
    if(activeRecipes.count == 0) {
        return nil;
    }
    Active_recipe *activeRecipe = activeRecipes[0];
    for (Active_recipe* ar in activeRecipes) {
        if([ar.active_recipeID longValue] > [activeRecipe.active_recipeID longValue]) {
            activeRecipe = ar;
        }
    }
    return activeRecipe;
}

+(void)fillImageFileName:(NSString*)fileName forId:(NSNumber*)recipeId{
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Recipebox *recipe = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:recipeId];
        if (recipe != nil) {
            recipe.imageFileName = fileName;
            [localContext MR_saveToPersistentStoreAndWait];
        }
    }completion:^(BOOL success, NSError *error) {
        DLog(@"Saved image for recipe.");
    }];
    
}

+(void)realDelete{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus = %@", [NSNumber numberWithInt:Deleted]];
        
        NSArray *recipes = [Recipebox MR_findAllWithPredicate:predicate inContext:localContext];
        if (recipes.count > 0) {
            for (Recipebox *item in recipes){
                NSManagedObject *localObject = [item MR_inContext:localContext];
                [localObject MR_deleteEntityInContext:localContext];
            }
        }
    }completion:^(BOOL success, NSError *error) {
    }];
}

+(NSArray*)getAllRecipesExceptDeleted{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Deleted]];
    NSArray *resultArray = [Recipebox MR_findAllWithPredicate:predicate];
    return resultArray;
}

+ (NSArray*)getAllRecipesExceptDeletedOrderBy:(SORT_TYPE_RECIPE)type
{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Deleted]];
    NSArray *resultArray = [Recipebox MR_findAllWithPredicate:predicate];
  
    // Added this code to sort array when Alphabetical sort is selected
    // Modified by: Yousuf
    if (type == ALPHABETICALLY)
    {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"sv"];
        
        return [resultArray sortedArrayUsingComparator:^(Recipebox *first, Recipebox *second) {
            return [first.title compare:second.title options:0 range:NSMakeRange(0, [first.title length]) locale:locale];
        }];
    }
    //Dimple- 6-11-2015 bug no. #343
    if (type == EARLEST_COOKED)
    {
        NSPredicate *predicate1 =[NSPredicate predicateWithFormat:@"lastCookedAtTime !=%@",nil];
        NSArray *pred_arr1 = [resultArray filteredArrayUsingPredicate:predicate1];
        NSSortDescriptor *sort1= [[NSSortDescriptor alloc] initWithKey:@"lastCookedAtTime" ascending:YES];
        NSArray *final_sortedArr1= [pred_arr1 sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort1]];
        NSMutableArray *arr1=(NSMutableArray *)final_sortedArr1;
        
        
        
        NSPredicate *predicate2 =[NSPredicate predicateWithFormat:@"lastCookedAtTime =%@", nil];
        NSArray *pred_arr2 = [resultArray filteredArrayUsingPredicate:predicate2];
        NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"lastCookedAtTime" ascending:NO];
        NSArray *final_sortedArr2= [pred_arr2 sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort2]];
        NSMutableArray *arr2=(NSMutableArray*)final_sortedArr2;
        
        
        NSPredicate *predicate3 =[NSPredicate predicateWithFormat:@"recipeboxID !=%@", nil];
        NSArray *pred_arr3 = [arr2 filteredArrayUsingPredicate:predicate3];
        NSSortDescriptor *sort3 = [[NSSortDescriptor alloc] initWithKey:@"recipeboxID" ascending:YES];
        NSArray *final_sortedArr3= [pred_arr3 sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort3]];
        NSMutableArray *arr3=(NSMutableArray*)final_sortedArr3;
        
        
        
        resultArray = [[arr1 arrayByAddingObjectsFromArray:arr3] mutableCopy];
        resultArray=(NSArray*)resultArray;
       
        return resultArray;
        
    }
    else if(type == SHORTEST_TIME) {
        return [resultArray sortedArrayUsingComparator:^NSComparisonResult(Recipebox *first, Recipebox *second) {
            NSNumber *firstCookTime = first.cookTime;
            NSNumber *secondCookTime = second.cookTime;
            
            if(firstCookTime == nil || [firstCookTime intValue] == 0) {
                NSNumber *firstOriginalCookTime = first.originalCookTime;
                NSNumber *firstActualCookTime = first.originalCookTimeSpanLower;
                if(firstActualCookTime == nil || [firstActualCookTime intValue] == 0) {
                    firstActualCookTime = firstOriginalCookTime;
                }
                else if(firstOriginalCookTime != nil && [firstOriginalCookTime intValue] != 0) {
                    firstActualCookTime = @(([firstActualCookTime floatValue] + [firstOriginalCookTime floatValue])/2);
                }
                firstCookTime = firstActualCookTime;
            }
            
            if(secondCookTime == nil || [secondCookTime intValue] == 0) {
                NSNumber *secondOriginalCookTime = second.originalCookTime;
                NSNumber *secondActualCookTime = second.originalCookTimeSpanLower;
                if(secondActualCookTime == nil || [secondActualCookTime intValue] == 0) {
                    secondActualCookTime = secondOriginalCookTime;
                }
                else if(secondOriginalCookTime != nil && [secondOriginalCookTime intValue] != 0) {
                    secondActualCookTime = @(([secondActualCookTime floatValue] + [secondOriginalCookTime floatValue])/2);
                }
                secondCookTime = secondActualCookTime;
            }

            if((firstCookTime == nil || [firstCookTime intValue] == 0) && (secondCookTime == nil || [secondCookTime intValue] == 0)) {
                return NSOrderedSame;
            }
            else if(firstCookTime == nil || [firstCookTime intValue] == 0) {
                return NSOrderedDescending;
            }
            else if(secondCookTime == nil || [secondCookTime intValue] == 0) {
                return NSOrderedAscending;
            }
            else
                return [firstCookTime compare:secondCookTime];

        }];
    }
    else {
        return [resultArray sortedArrayUsingDescriptors:[self getSortDescriptor:type]];
    }
}

+ (NSArray*)getSortDescriptor:(SORT_TYPE_RECIPE)type
{
    NSArray *sortDescriptors;
    //NSSortDescriptor *sort = [[NSSortDescriptor alloc]init];
    switch (type) {
        case NEWEST:
        {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
            sortDescriptors = @[sort];
            break;
        }
        case ALPHABETICALLY:
        {
            // This is not being used for Alphabetical Sort
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
            sortDescriptors = @[sort];
            break;
        }
        case MOST_COOKED:
        {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"cookCount" ascending:NO];
            NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"rating" ascending:NO];
            sortDescriptors = @[sort, sort1];
            break;
        }
        case LEAST_COOKED:
        {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"cookCount" ascending:YES];
            NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"rating" ascending:NO];
            sortDescriptors = @[sort, sort1];
        }
            break;
        case LATEST_COOKED:
        {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastCookedAtTime" ascending:NO];
            sortDescriptors = @[sort];
            break;
        }
        case EARLEST_COOKED:
        {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastCookedAtTime" ascending:YES];
            sortDescriptors = @[sort];
            break;
        }
        case SHORTEST_TIME:
        {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"cookTime" ascending:YES comparator:^(id first, id second){
                DLog(@"cookTime - %@:%@", first, second);
                int number1 = [first intValue];
                int number2 = [second intValue];
                if(first == nil && second == nil) {
                    return NSOrderedSame;
                }
                else if(first == nil) {
                    return NSOrderedAscending;
                }
                else if(second == nil) {
                    return NSOrderedDescending;
                }
                else if(number1 == number2) {
                    return NSOrderedSame;
                }
                else if (number1 == 0) {
                    return NSOrderedDescending;
                }
                else if (number2 == 0) {
                    return NSOrderedAscending;
                }
                else if (number1 < number2)
                    return NSOrderedAscending;
                else if (number2 < number1)
                    return NSOrderedDescending;
                else
                    return NSOrderedSame;
            }];
            NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"originalCookTime" ascending:YES comparator:^(id first, id second){
                DLog(@"originalCookTime - %@:%@", first, second);

                int number1 = [first intValue];
                int number2 = [second intValue];
                
                if(first == nil && second == nil) {
                    return NSOrderedSame;
                }
                else if(first == nil) {
                    return NSOrderedAscending;
                }
                else if(second == nil) {
                    return NSOrderedDescending;
                }
                else if(number1 == number2) {
                    return NSOrderedSame;
                }
                else if (number1 == 0) {
                    return NSOrderedDescending;
                }
                else if (number2 == 0) {
                    return NSOrderedAscending;
                }
                else if (number1 < number2)
                    return NSOrderedAscending;
                else if (number2 < number1)
                    return NSOrderedDescending;
                else
                    return NSOrderedSame;
            }];
            sortDescriptors = @[sort, sort1];
            break;
        }
        case HIGHEST_CREDIT:
        {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"rating" ascending:NO];
            NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"cookCount" ascending:NO];
            sortDescriptors = @[sort, sort1];
            break;
        }
        default:
        {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
            sortDescriptors = @[sort];
            break;
        }
    }
    
    return sortDescriptors;
    
}

+(NSArray*)getAllRecipesFakeDeleted{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus = %@", [NSNumber numberWithInt:Deleted]];
    NSArray *resultArray = [Recipebox MR_findAllWithPredicate:predicate];
    return resultArray;
}

+(NSArray*)getAllRecipesByStatus:(SYNC_STATUS)status{
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus = %@", [NSNumber numberWithInt:status]];
    NSArray *resultArray = [Recipebox MR_findAllWithPredicate:predicate];
    return resultArray;
}

+(Recipebox*)getRecipeById:(NSNumber*)recipeId{
    Recipebox *recipe = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:recipeId];
    return recipe;
}

+(void)insertItems:(id)responseObject{
    NSDictionary *allItems = (NSDictionary*)responseObject;
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Recipebox *recipeInTable = [Recipebox MR_importFromObject:allItems inContext:localContext];
        
        //import tags
        NSArray *tags = allItems[@"tags"];
        [Recipebox_tag updateTagsForRecipe:recipeInTable withInput:tags inContext:localContext];
        
        //import parsed ingredients
        NSDictionary *parsedIngredients = allItems[@"parsedIngredients"];
        
        NSArray *ingredientsArray = [parsedIngredients objectForKey:@"list"];
        
        [Ingredient updateIngredientsForRecipe:recipeInTable withInput:ingredientsArray inContext:localContext];

    }completion:^(BOOL success, NSError *error) {
    }];
}

+(void)changeSyncStatus:(SYNC_STATUS)status forObjectID:(NSManagedObjectID *)recipeObjectID
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_context];
    [localContext performBlock:^{
        Recipebox *recipe = (Recipebox *)[localContext objectWithID:recipeObjectID];
        if (nil != recipe)
        {
            recipe.syncStatus = [NSNumber numberWithInt:status];
            [localContext MR_saveToPersistentStoreAndWait];
        }
    }];

}

+(NSString*)getCookTimeStringFromRecipe:(Recipebox*)recipe{
    NSString *timeString = @"";
    if (recipe.cookTime != nil && [recipe.cookTime intValue]!= 0) {
        timeString = [NSString stringWithFormat:@"%@ min", [recipe.cookTime stringValue]];
    }
    else {
        if (recipe.originalCookTime != nil && [recipe.originalCookTime intValue] != 0) {
            if ([recipe.originalCookTimeSpanLower intValue] > 0){
                timeString = [NSString stringWithFormat:@"%@ - %@ min",[recipe.originalCookTimeSpanLower stringValue], [recipe.originalCookTime stringValue]];
            }
            else{
                timeString = [NSString stringWithFormat:@"< %@ min",[recipe.originalCookTime stringValue]];
            }
        }
        else{
            if ([recipe.originalCookTimeSpanLower intValue] > 0) {
                timeString = [NSString stringWithFormat:@"%@+ min",[recipe.originalCookTimeSpanLower stringValue]];
            }
        }
    }
    return timeString;
}

//SuperObject methods

- (NSNumber *)getId {
    return self.recipeboxID;
}

- (void) deleteObjectWithChildren {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSManagedObject *localObject = [self MR_inContext:localContext];
        [localObject MR_deleteEntityInContext:localContext];
    }];
}

- (BOOL) parentSyncedCheck{
    return YES;
}

+ (BOOL) isInDatabase: (NSNumber *) objectId {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"recipeboxID == %@", objectId];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSString *) getObjectURL {
    return @"RecipeBox";
}

+ (NSArray *) getNotSyncedObjects {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    NSArray *itemArray = [Recipebox MR_findAllWithPredicate:predicate];
    return itemArray;
}

+ (void) deleteSyncedObjectsExceptIds: (NSArray *) objectIds {
    NSPredicate *predicate =[NSPredicate predicateWithFormat: @"syncStatus == %@ AND NOT (recipeboxID IN %@)", [NSNumber numberWithInt:Synced], objectIds];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSArray *itemArray = [self MR_findAllWithPredicate:predicate inContext:localContext];
        for (Recipebox *item in itemArray){
            NSManagedObject *localObject = [item MR_inContext:localContext];
            [[DataStore instance].viewedRecipes removeObject:item.recipeboxID];
            [Utility saveInDefaultsWithObject:[DataStore instance].viewedRecipes andKey:@"viewedRecipes"];
            [localObject MR_deleteEntityInContext:localContext];
            [SignificantChangesIndicator sharedIndicator].recipeChanged = YES;
        }
    }];
}

- (void) updateObjectWithResponseForInsert: (id) response{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Recipebox *recipe = [self MR_inContext:localContext];
        recipe.recipeboxID = [response objectForKey:@"id"];
        recipe.title = [response objectForKey:@"title"];
        recipe.createdAt = [response objectForKey:@"createdAt"];
        recipe.isPublic = [response objectForKey:@"isPublic"];
        recipe.lastViewedAt = [response objectForKey:@"lastViewedAt"];
        recipe.rating = [response objectForKey:@"rating"];
        recipe.cookTime = [response objectForKey:@"cookTime"];
        recipe.originalCookTime = [response objectForKey:@"originalCookTime"];
        recipe.originalCookTimeSpanLower = [response objectForKey:@"originalCookTimeSpanLower"];
        NSArray *imageUrls = [response objectForKey:@"imageUrls"];
        if(imageUrls && imageUrls.count > 0){
            recipe.imageUrl = [imageUrls[0] objectForKey:@"url"];
        }
        recipe.descriptionText = [response objectForKey:@"description"];
        recipe.instructions = [response objectForKey:@"instructions"];
        recipe.instructionsMarkup = [response objectForKey:@"instructionsMarkup"];
        recipe.ingredients = [response objectForKey:@"ingredients"];
        recipe.ingredientsMarkup = [response objectForKey:@"ingredientsMarkup"];
        recipe.advice = [response objectForKey:@"advice"];
        recipe.notes = [response objectForKey:@"notes"];
        recipe.portions = [response objectForKey:@"portions"];
        recipe.portions_span_lower = [response objectForKey:@"portionsSpanLower"];
        if(response[@"selectedPortions"]) recipe.sel_portions = [response objectForKey:@"selectedPortions"];
        recipe.portionType = [response objectForKey:@"portionType"];
        recipe.source_original_text = [[response objectForKey:@"source"] objectForKey:@"originalText"];
        recipe.source_text = [[response objectForKey:@"source"] objectForKey:@"text"];
        recipe.source_url = [[response objectForKey:@"source"] objectForKey:@"url"];
        recipe.lastCookedAt = [response objectForKey:@"lastCookedAt"];
        recipe.cookCount = [response objectForKey:@"cookCount"];
        recipe.updatedAt = [response objectForKey:@"updatedAt"];
        recipe.syncStatus = [NSNumber numberWithInt:Synced];
        recipe.lastCookedAtTime = [Utility getDateFromString:recipe.lastCookedAt];
        
        recipe.manuallyUpdated = @NO;
        recipe.imageUpdated = @NO;
        //import tags
        NSArray *tags = response[@"tags"];
        [Recipebox_tag updateTagsForRecipe:recipe withInput:tags inContext:localContext];
        
        //import parsed ingredients
        NSDictionary *parsedIngredients = response[@"parsedIngredients"];
        
        NSArray *ingredientsArray = [parsedIngredients objectForKey:@"list"];
        
        [Ingredient updateIngredientsForRecipe:recipe withInput:ingredientsArray inContext:localContext];
        [SignificantChangesIndicator sharedIndicator].recipeChanged = YES;
    }];
}

+ (BOOL) needsUpdate {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus != %@", [NSNumber numberWithInt:Synced]];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] > 0;
}

+ (NSDictionary *) getIdsAndObjectFromResponse: (id) jsonResposeObject{
    NSMutableDictionary *objectsAndIds = [NSMutableDictionary new];
    for (NSDictionary * objectJSON in [jsonResposeObject objectForKey:@"list"]){
        [objectsAndIds setObject:@{@"updatedAt":[objectJSON valueForKey:@"updatedAt"]} forKey:[objectJSON valueForKey:@"id"]];
    }
    return objectsAndIds;
}

+ (NSDictionary *) removeIdsNotNeededToUpdate: (NSDictionary *) remoteObjectsIdsAndObjects {
    NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:remoteObjectsIdsAndObjects];
    for (NSNumber *item_id in [remoteObjectsIdsAndObjects allKeys]) {
        if(![self needsUpdateWithId:item_id andDate:temp[item_id][@"updatedAt"]]) {
            [temp removeObjectForKey:item_id];
        }
    }
    return temp;
}

+ (BOOL) needsUpdateWithId: (NSNumber *) recipeboxID andDate: (NSDate *) date {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"syncStatus == %@ AND recipeboxID == %@ AND updatedAt == %@", [NSNumber numberWithInt:Synced], recipeboxID, date];
    return [[self MR_numberOfEntitiesWithPredicate:predicate] intValue] == 0;
}

+ (void)insertObjectWithParentCheckAndJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Recipebox *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.lastCookedAtTime = [Utility getDateFromString:item.lastCookedAt];
        item.syncStatus = [NSNumber numberWithInt: Synced];
        //import tags
        NSArray *tags = objectJson[@"tags"];
        [Recipebox_tag updateTagsForRecipe:item withInput:tags inContext:localContext];
        
        //import parsed ingredients
        NSDictionary *parsedIngredients = objectJson[@"parsedIngredients"];
        
        NSArray *ingredientsArray = [parsedIngredients objectForKey:@"list"];
        
        [Ingredient updateIngredientsForRecipe:item withInput:ingredientsArray inContext:localContext];
        [SignificantChangesIndicator sharedIndicator].recipeChanged = YES;
    }];
}
+ (void) updateObjectWithJson: (id) objectJson{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Recipebox *item = [self MR_importFromObject:objectJson inContext:localContext];
        item.syncStatus = [NSNumber numberWithInt: Synced];
        item.lastCookedAtTime = [Utility getDateFromString:item.lastCookedAt];
        
        //import tags
        NSArray *tags = objectJson[@"tags"];
        [Recipebox_tag updateTagsForRecipe:item withInput:tags inContext:localContext];
        
        //import parsed ingredients
        NSDictionary *parsedIngredients = objectJson[@"parsedIngredients"];
        
        NSArray *ingredientsArray = [parsedIngredients objectForKey:@"list"];
        
        [Ingredient updateIngredientsForRecipe:item withInput:ingredientsArray inContext:localContext];
        [SignificantChangesIndicator sharedIndicator].recipeChanged = YES;
    }];
}
- (void) updateObject {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Recipebox *recipe = [self MR_inContext:localContext];
        recipe.syncStatus = [NSNumber numberWithInt:Synced];
    }];
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
    return REQUEST_PUT;
}
+ (REQUEST_TYPE) getDeleteRequestType {
    return REQUEST_DELETE;
}

- (NSDictionary *) parseToInsertJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];
    if(self.title == nil || [self.title isEqualToString: @""]) {
        if(self.source_url) [json setObject:self.source_url forKey:@"url"];
    }
    else {
        if(self.title) [json setObject:self.title forKey:@"title"];
        if(self.isPublic) [json setObject:self.isPublic forKey:@"isPublic"];
        if(self.cookTime) [json setObject:self.cookTime forKey:@"cookTime"];
        if(self.descriptionText) [json setObject:self.descriptionText forKey:@"description"];
        if(self.instructions) [json setObject:self.instructions forKey:@"instructions"];
        if(self.ingredients) [json setObject:self.ingredients forKey:@"ingredients"];
        if(self.advice) [json setObject:self.advice forKey:@"advice"];
        if(self.notes) [json setObject:self.notes forKey:@"notes"];
        if(self.portions) [json setObject:self.portions forKey:@"portions"];
        if(self.portionType) [json setObject:self.portionType forKey:@"portionType"];
        if(self.source_text) [json setObject:self.source_text forKey:@"source"];
        if(self.image) [json setObject:self.image forKey:@"image"];
        NSMutableArray *tags = [NSMutableArray new];
        for(Recipebox_tag *tag in self.relatedTags) {
            [tags addObject:tag.text];
        }
        if(tags.count > 0) [json setObject:tags forKey:@"tags"];
    }
    
    return json;
}

- (NSDictionary *) parseToUpdateJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];

    //DLog(@"selected portions %@",self.portions);
    
    if(self.rating != nil) [json setObject:self.rating forKey:@"rating"];
    if(self.cookTime != nil) [json setObject:self.cookTime forKey:@"cookTime"];
    if(self.sel_portions != nil) [json setObject:self.sel_portions forKey:@"selectedPortions"];
    if([self.manuallyUpdated boolValue]) {
        if(self.title) [json setObject:self.title forKey:@"title"];
        if(self.isPublic) [json setObject:self.isPublic forKey:@"isPublic"];
        if(self.descriptionText) [json setObject:self.descriptionText forKey:@"description"];
        if(self.instructions) [json setObject:self.instructions forKey:@"instructions"];
        if(self.ingredients) [json setObject:self.ingredients forKey:@"ingredients"];
        if(self.advice) [json setObject:self.advice forKey:@"advice"];
        if(self.notes) [json setObject:self.notes forKey:@"notes"];
        if(self.portions) [json setObject:self.portions forKey:@"portions"];
        if(self.portionType) [json setObject:self.portionType forKey:@"portionType"];
        if(self.source_text) [json setObject:self.source_text forKey:@"source"];
        if(self.image && [self.imageUpdated boolValue]) [json setObject:self.image forKey:@"image"];
        NSMutableArray *tags = [NSMutableArray new];
        for(Recipebox_tag *tag in self.relatedTags) {
            [tags addObject:tag.text];
        }
        if(tags.count > 0) [json setObject:tags forKey:@"tags"];

    }
    
    return json;
}

+ (BOOL)isHeavyObject {
    return YES;
}

- (NSString *) getDeleteURL {
    return [NSString stringWithFormat:@"%@/%@", [[self class] getObjectURL], [self getId]];
}

+ (NSString*) heavyObjectURL: (NSNumber *) objectId{
    return [NSString stringWithFormat:@"%@/%@", [[self class] getObjectURL], objectId];
}
+ (REQUEST_TYPE) heavyObjectGetRequestType{
    return REQUEST_GET;
}

+ (NSDictionary *) getHeavyParameters{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"format"] = @"json";
    return parameters;
}

+ (BOOL) parentsExistForResponse:(id)responseJSON {
    return YES;
}

- (void)updateObjectWithResponseForUpdate:(id)response {
    [self updateObjectWithResponseForInsert:response];
}


@end
