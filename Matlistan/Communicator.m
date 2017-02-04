//
//  Communicator.m
//  MatListan
//
//  Created by Yan Zhang on 08/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Communicator.h"
#import "RecipeData.h"
#import <MTLJSONAdapter.h>
#import "ActiveRecipe.h"
#import "UserRecipe.h"
#import "Item.h"

@implementation Communicator

@synthesize currentConnection,cookie;

static Communicator *instance=nil;
+(Communicator*)instance{
    @synchronized(self){
        if (instance == nil) {
            instance = [[Communicator alloc]init];
        }
    }
    return instance;
}
-(void)login{
    NSString *user = @"emma2740@yahoo.com";
    NSString *pwd = @"12080000";
    NSString *restCallString = [NSString stringWithFormat:@"http://api2.matlistan.se/Sessions?email=%@&password=%@", user, pwd ];
    //Create the URL to make the REST call
    NSURL *restURL = [NSURL URLWithString:restCallString];
    NSURLRequest *restRequest = [NSURLRequest requestWithURL:restURL];
    if(currentConnection)
    {
        [currentConnection cancel];
        currentConnection = nil;
        self.apiReturnedData = nil;
    }
    currentConnection = [[NSURLConnection alloc]initWithRequest:restRequest delegate:self];
    //if the connection was successful, receive the xml data that will be returned by the API call
    self.apiReturnedData =[NSMutableData data];
}
//this function is called when there is return data. It may be called multiple times for a connection
//so you should reset the data if it is not empty
-(void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response{
    
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    NSDictionary *fields = [HTTPResponse allHeaderFields];
    cookie = [fields valueForKey:@"Set-Cookie"]; // It is your cookie
    NSLog(@"Cookie: %@",cookie);
    if (cookie.length > 0) {
        [DataStore instance].cookie = cookie; //remember cookie

    }
    
    [self.apiReturnedData setLength:0];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoggedIn" object:self];
    
    
}
//this function is called when some or all of the data from the API call is returned
-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)data{
    [self.apiReturnedData appendData:data];
}
-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError *)error{
    NSLog(@"URL connection failed");
    currentConnection = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FailedConnection" object:self];
}

//this is called when the call is complete and all the data has been received.
-(void)connectionDidFinishLoading :(NSURLConnection*)connection
{
    //create xml parser with the return data from the connection
    int recipeSum = 0;
    currentConnection = nil;
    NSString* string = [[NSString alloc] initWithData:self.apiReturnedData
                                             encoding:NSUTF8StringEncoding];
    DataStore *store = [DataStore instance];
    //   string=[string stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    
    
    NSError *error;
    NSMutableDictionary *allItems = [NSJSONSerialization
                                     JSONObjectWithData:self.apiReturnedData
                                     options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves
                                     error:&error];
    if (apiType == GET_SHOPPING_LIST) {
        [DataStore instance].allItemsForAList = allItems;
        
        NSArray *resultArray = [self deserializeFromJSON:[allItems objectForKey:@"list"] forClass:[Item class]];
        store.items = [resultArray copy];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ItemsDownloaded" object:self]; //inform that items are downloaded now
    }
    else if(apiType == GET_ACTIVE_RECIPE){
        //store.activeRecipes = [allItems objectForKey:@"list"];
        NSArray *resultArray = [self deserializeActiveRecipesFromJSON:[allItems objectForKey:@"list"]];
        store.activeRecipes = [resultArray copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ActiveRecipesDownloaded" object:self];
    }
    else if(apiType == GET_RECIPE_IDS){

        NSArray *keys = [allItems allKeys];
        id aKey = [keys objectAtIndex:0];
        [DataStore instance].recipeIDs = [allItems objectForKey:aKey];
        DLog(@"recipe sum %d",[DataStore instance].recipeIDs.count );
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RecipeIDsDownloaded" object:self]; //inform that ids are downloaded
     
    }
    else if(apiType == GET_RECIPE){
        
        //NSMutableDictionary *theRecipe = allItems;
        
        UserRecipe *theRecipe = (UserRecipe*)[self deserializeDictionaryFromJSON:allItems forClass:[UserRecipe class]];
        
        [[DataStore instance].recipeList addObject:theRecipe];
        
        RecipeData *recipeData = [[RecipeData alloc]initWithRecipe:theRecipe];
        [[DataStore instance].recipeWithImageList addObject:recipeData];
        NSLog(@"imagelist count %d",[DataStore instance].recipeWithImageList.count );
        
        NSMutableArray *array = [DataStore instance].recipeList; //test
        
        if ([DataStore instance].recipeList.count == [DataStore instance].recipeIDs.count) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RecipesDownloaded" object:self]; //inform that all recipes are downloaded
            
        }
        else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GetNextRecipe" object:self]; //inform that one recipe has been downloaded
        }

    }
    
}
-(NSDictionary*)deserializeDictionaryFromJSON:(NSDictionary*)jsonData forClass:(Class)className{
    NSError *error = nil;
    NSDictionary *outputDict = [MTLJSONAdapter modelOfClass:className fromJSONDictionary:jsonData error:&error];
    if (error) {
        DLog(@"Couldn't convert JSON dict: %@", error);
        return nil;
    }
    return outputDict;
}
-(NSArray*)deserializeFromJSON:(NSArray*)jsonData forClass:(Class)className{
    NSError *error = nil;
    NSArray *outputArray = [MTLJSONAdapter modelsOfClass:className fromJSONArray:jsonData error:&error];
    if (error) {
        DLog(@"Couldn't convert JSON: %@", error);
        return nil;
    }
    return outputArray;
}
- (NSArray *)deserializeActiveRecipesFromJSON:(NSArray *)activeRecipesJSON
{
    NSError *error;
    NSArray *activeRecipes = [MTLJSONAdapter modelsOfClass:[ActiveRecipe class] fromJSONArray:activeRecipesJSON error:&error];
    if (error) {
        DLog(@"Couldn't convert JSON to active recipe: %@", error);
        return nil;
    }
    
    return activeRecipes;
}
-(void)getListItems{
    apiType = GET_SHOPPING_LIST;
    [self getItems:@"Items"];
    
}
-(void)getLists{
    apiType = GET_LISTS;
    [self getItems:@"ItemLists"];
    
}
-(void)getRecipesIDs{
    apiType = GET_RECIPE_IDS;
    [self getItems:@"RecipeBox"];
}
-(void)getRecipeByID:(long)recipeID{
    apiType = GET_RECIPE;
    NSString *apiName = [NSString stringWithFormat:@"RecipeBox/%ld",recipeID];
    [self getItems:apiName];
}
-(void)getRecipes{
    apiType = GET_RECIPE;
    for(NSMutableDictionary *object in [DataStore instance].recipeIDs){
        long recipeID = [[object valueForKey:@"id"] longValue];

        DLog(@"Get recipe id: %ld",recipeID);
        [self getRecipeByID:recipeID];
    }
}
-(void)getActiveRecipes{
    apiType = GET_ACTIVE_RECIPE;
    [self getItems:@"ActiveRecipes"];

}
-(void)getItems:(NSString *)api{
    if(currentConnection)
    {
        [currentConnection cancel];
        currentConnection = nil;
        self.apiReturnedData = nil;
    }
    NSString *url = [NSString stringWithFormat:@"http://api2.matlistan.se/%@",api];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];

    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData]; //add caching policy for omitting  ERROR: unable to get the receiver data from the DB
    
    //NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api2.matlistan.se/Items"]];
    // NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api2.matlistan.se/RecipeBox"]];
    //NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api2.matlistan.se/RecipeBox/777"]];
   // DLog(@"public cookie: %@\n private cookie:%@\n",[DataStore instance].cookie,cookie);
    [request addValue:[DataStore instance].cookie forHTTPHeaderField:@"Cookie"]; //cookie
    
    currentConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    //if the connection was successful, receive the xml data that will be returned by the API call
    self.apiReturnedData =[NSMutableData data];
}

@end
