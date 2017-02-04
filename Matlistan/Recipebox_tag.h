//
//  Recipebox_tag.h
//  MatListan
//
//  Created by Yan Zhang on 09/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Recipebox;

@interface Recipebox_tag : NSManagedObject

@property (nonatomic, retain) NSNumber * recipeID;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) Recipebox *forRecipe;
@property (nonatomic, retain) NSString * recipeObjectID;

@end
