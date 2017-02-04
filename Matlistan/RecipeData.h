//
//  RecipeData.h
//  MatListan
//
//  Created by Yan Zhang on 13/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "UserRecipe.h"
#import "Recipebox+Extra.h"

@interface RecipeData : NSObject
//@property (nonatomic,retain)UserRecipe *recipe;
@property (nonatomic,retain)Recipebox *recipe;
@property (nonatomic,retain)UIImage *image;
-(id)initWithRecipe:(Recipebox *)recipe;
@end
