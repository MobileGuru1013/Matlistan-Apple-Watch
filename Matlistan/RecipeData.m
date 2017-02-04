//
//  RecipeData.m
//  MatListan
//
//  Created by Yan Zhang on 13/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "RecipeData.h"

@implementation RecipeData
-(id)init{
    self = [super init];
    if(self){
        self.recipe = [[Recipebox alloc]init];
        self.image = [[UIImage alloc]init];
    }
    return self;
}
-(id)initWithRecipe:(Recipebox *)recipe{
    self = [super init];
    if(self){
        self.recipe = recipe;
        self.image = [[UIImage alloc]init];
    }
    return self;
}

@end
