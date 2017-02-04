//
//  Recipebox_tag+Extra.m
//  MatListan
//
//  Created by Yan Zhang on 06/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Recipebox_tag+Extra.h"


@implementation Recipebox_tag (Extra)

//not used
+(void)deleteTags:(NSNumber *)recipeboxID{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NSArray *tags = [Recipebox_tag MR_findByAttribute:@"recipeID" withValue:recipeboxID];
        
        if (tags.count > 0) {
            for (Recipebox_tag *tag in tags){
                
                NSManagedObject *localObject = [tag MR_inContext:localContext];
                [localObject MR_deleteEntityInContext:localContext];
                
            }
            [localContext MR_saveToPersistentStoreAndWait];
        }
    }completion:^(BOOL success, NSError *error) {
    }];
}

//not used
+(void)deleteTags:(NSNumber *)recipeboxID inContext:(NSManagedObjectContext*)context{
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        
        NSArray *tags = [Recipebox_tag MR_findByAttribute:@"recipeID" withValue:recipeboxID];
        
        if (tags.count > 0) {
            for (Recipebox_tag *tag in tags){

                NSManagedObject *localObject = [tag MR_inContext:localContext];
                [localObject MR_deleteEntityInContext:localContext];
                
            }
            
        }
    }];
}


//Not used
+(void)insertTags:(NSArray*)itemArray forRecipe:(NSNumber*)recipeboxID{
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSArray *recipeTags = [Recipebox_tag MR_importFromArray:itemArray inContext:localContext];
        for (Recipebox_tag *tag in recipeTags) {
            tag.recipeID = recipeboxID;
        }
    }];
}

//Not used
+(void)updateTags:(NSArray*)itemArray forRecipe:(NSNumber*)recipeboxID{
    [self deleteTags:recipeboxID];
    [self insertTags:itemArray forRecipe:recipeboxID];
}

/*Update tags
  MR_importFromArray cannot update tags directly.
  [self deleteTags:recipe.recipeboxID inContext:context];   //cause missing delete propagation for to-many relationship
 */
+(void)updateTagsForRecipe:(Recipebox*)recipe withInput:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context{
    
    //NSPredicate *predicate =[NSPredicate predicateWithFormat:@"(NOT recipeID=0 AND recipeID=%@) OR (recipeID=0 AND recipeObjectID == %@)",recipe.recipeboxID, [[recipe.objectID URIRepresentation]absoluteString]];
    //NSArray *tags = [Recipebox_tag MR_findAllWithPredicate:predicate];
    NSArray *tags = [recipe.relatedTags allObjects];
    NSMutableArray *newTags = [[NSMutableArray alloc]init];
   
    if (tags != nil && tags.count > 0) {
         //Find new tags and only add them
        for (int i = 0; i < itemArray.count; i++) {
            NSString *tagText = [[itemArray objectAtIndex:i] objectForKey:@"text"];
            if (![Recipebox_tag doesTagExist:tagText inArray:tags]) {
                [newTags addObject:[itemArray objectAtIndex:i]];
            }
        }
        if (newTags.count > 0) {
            [self insertTagsForRecipe:recipe withInput:newTags inContext:context];
        }
    }
    else{
        [self insertTagsForRecipe:recipe withInput:itemArray inContext:context];
    }
   
}

+(BOOL)doesTagExist:(NSString*)tagText inArray:(NSArray*)tags{
    for (Recipebox_tag *tag in tags) {
        if ([tag.text isEqualToString:tagText]) {
            return YES;
        }
    }
    return NO;
}

+(void)insertTagsForRecipe:(Recipebox*)recipe withInput:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context{
    
    NSArray *recipeTags = [Recipebox_tag MR_importFromArray:itemArray inContext:context];
    for (Recipebox_tag *tag in recipeTags) {
        tag.recipeID = recipe.recipeboxID;
        tag.recipeObjectID = [[recipe.objectID URIRepresentation]absoluteString];
        [tag setForRecipe:recipe];  //add relationship to RecipeBox
    }

    //[context MR_saveToPersistentStoreAndWait];
}

+(void)insertTagsForRecipe:(Recipebox*)recipe withStrings:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context {
    for(NSString *tagText in itemArray) {
        Recipebox_tag *tag = [Recipebox_tag MR_createEntityInContext:context];
        tag.text = tagText;
        tag.recipeID = recipe.recipeboxID;
        tag.recipeObjectID = [[recipe.objectID URIRepresentation]absoluteString];
        [tag setForRecipe:recipe];
        [context MR_saveToPersistentStoreAndWait];
    }
}
@end
