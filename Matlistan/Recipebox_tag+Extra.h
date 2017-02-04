//
//  Recipebox_tag+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 06/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Recipebox_tag.h"
#import "Recipebox.h"

@interface Recipebox_tag (Extra)


+(void)updateTagsForRecipe:(Recipebox*)recipe withInput:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context;
+(void)insertTagsForRecipe:(Recipebox*)recipe withInput:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context;
+(void)insertTagsForRecipe:(Recipebox*)recipe withStrings:(NSArray*)itemArray inContext:(NSManagedObjectContext*)context;


//Not used
+(void)updateTags:(NSArray*)itemArray forRecipe:(NSNumber*)recipeboxID;
+(void)insertTags:(NSArray*)itemArray forRecipe:(NSNumber*)recipeboxID;
+(void)deleteTags:(NSNumber *)recipeboxID;
+(void)deleteTags:(NSNumber *)recipeboxID inContext:(NSManagedObjectContext*)context;
@end
