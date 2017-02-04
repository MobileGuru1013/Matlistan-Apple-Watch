//
//  ActiveRecipeTest.m
//  MatListan
//
//  Created by Yan Zhang on 09/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FixtureHelpers.h"
#import "Active_recipe+Extra.h"
#import "DataStore.h"

@interface ActiveRecipeTest : XCTestCase

@property (nonatomic,retain)id jsonData;
@property (nonatomic, retain) NSArray * arrayOfTestEntity;
@end

@implementation ActiveRecipeTest
@synthesize jsonData,arrayOfTestEntity;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    
    jsonData = [FixtureHelpers loadFixture:@"activeRecipes.json"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [MagicalRecord cleanUp];
}

-(void)testInsertActiveRecipe{
    
    [Active_recipe insertActiveRecipeWith:@100 andPortions:@2 withIngredients:@"ingredients" forOccasion:@"middag" andNotes:@"test" inList:@111];
  
    Active_recipe *recipe = [Active_recipe MR_findFirstByAttribute:@"recipeID" withValue:@100];
    XCTAssert(recipe!=nil);

    
}
-(void)testIfInsertWorks{
    Active_recipe *recipe = [Active_recipe MR_findFirstByAttribute:@"recipeID" withValue:@100];
    XCTAssert(recipe!=nil);
    
}
-(void)testIfDeleteWork{
    NSArray *recipes = [Active_recipe MR_findByAttribute:@"recipeID" withValue:@100];
    for (Active_recipe *recipe in recipes) {
        [recipe MR_deleteEntity];
    }

    Active_recipe *recipe2 = [Active_recipe MR_findFirstByAttribute:@"recipeID" withValue:@100];
    XCTAssert(recipe2 ==nil);
    
}
-(void)testChangeSyncStatusForRecipeWithObjID{
    Active_recipe *recipe = [Active_recipe MR_findFirstByAttribute:@"recipeID" withValue:@100];
    [Active_recipe changeSyncStatus:Synced forObjectID:recipe.objectID];
    XCTAssert([recipe.syncStatus intValue] == Synced);
    
}
- (void)testDeleteItems
{
    [Active_recipe deleteAllRecipes];
    NSArray *items = [Active_recipe MR_findAll];
    XCTAssertEqual(items.count, 0);
}
- (void)testImportOfMultipleEntities
{
    [Active_recipe insertItems:jsonData];
    
    arrayOfTestEntity = [Active_recipe MR_findAll];
    XCTAssertNotNil(self.arrayOfTestEntity, @"arrayOfTestEntity should not be nil");
    XCTAssert(self.arrayOfTestEntity.count >= 5, @"arrayOfTestEntity should have at least 5 entities");
    int countOfActiveRecipes = arrayOfTestEntity.count;

    Active_recipe *recipe = [Active_recipe MR_findFirstByAttribute:@"active_recipeID" withValue:@883];
    XCTAssertEqualObjects(recipe.ingredients, @"Dressing:,1/2 vitl U00f6ksklyfta,5 sardellfil U00e9er,1  U00e4ggula,1 dl riven parmesanost,1 1/2 tsk f U00e4rskpressad citronjuice,ca 3/4 dl neutral olja,1 krm salt,Sallad:,k U00f6tt fr U00e5n kycklingklubba,romansallad,knaperstekt bacon,hyvlad parmesanost,br U00f6dkrutonger eller vitl U00f6ksbr U00f6d");
    XCTAssertEqualObjects(recipe.ingredientsMarkup, @"<h>Dressing:</h>n1/2 <ki>vitl U00f6ksklyfta</ki>n5 <ki>sardellfil U00e9er</ki>n1 <ki> U00e4ggula</ki>");
    XCTAssertEqualObjects(recipe.isPurchased, @0);
    XCTAssertEqualObjects(recipe.notes, @"note");
    XCTAssertEqualObjects(recipe.occasion, @"dinner");
    XCTAssertEqualObjects(recipe.recipeID, @1237);
    
    [Active_recipe fakeDeleteById:recipe.active_recipeID];
    
    XCTAssertEqual([recipe.syncStatus intValue], Deleted);
    
    [Active_recipe realDelete];
    NSArray *array = [Active_recipe getAllActiveRecipes];
                      
    XCTAssert(array.count == countOfActiveRecipes - 1);
   
    
}


@end
