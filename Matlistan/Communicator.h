//
//  Communicator.h
//  MatListan
//
//  Created by Yan Zhang on 08/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataStore.h"

typedef enum APIType
{
    GET_SHOPPING_LIST,
    GET_RECIPE,
    GET_ACTIVE_RECIPE,
    GET_RECIPE_IDS,
    GET_LISTS

} APIType;

@interface Communicator : NSObject<NSURLConnectionDelegate>
{
 //   NSURLConnection *currentConnection;
  //  NSString *cookie;
    APIType apiType;
}
+ (Communicator *) instance;
@property (retain,nonatomic)NSMutableData *apiReturnedData;
@property (retain,nonatomic)NSURLConnection *currentConnection;
@property (retain,nonatomic)NSString *cookie;
//---functions---
-(void)login;
-(void)getListItems;
-(void)getRecipesIDs;
-(void)getRecipeByID:(long)recipeID;
-(void)getRecipes;
-(void)getActiveRecipes;
@end
