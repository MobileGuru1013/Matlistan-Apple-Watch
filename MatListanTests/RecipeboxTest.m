//
//  RecipeboxTest.m
//  MatListan
//
//  Created by Yan Zhang on 09/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FixtureHelpers.h"
#import "Recipebox+Extra.h"
#import "Recipebox_tag+Extra.h"
#import "Ingredient.h"
#import "DataStore.h"
#import "Active_recipe+Extra.h"

@interface RecipeboxTest : XCTestCase
@property (nonatomic,retain)id jsonData;


@end

@implementation RecipeboxTest
@synthesize jsonData;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    
    jsonData = [FixtureHelpers loadFixture:@"recipe.json"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
	[MagicalRecord cleanUp];
}
//Allinone test- combine all the tests in the correct order and test them all
-(void)testCombined{
    [self testDeleteItems];
    [self testImportRecipe];
    [self testInsertRelatedIngredientsCorrect];
    [self testInsertRelatedTagsCorrect];
    
}
- (void)testDeleteItems
{
    [Recipebox deleteAllRecipes];

    NSArray *items = [Recipebox MR_findAll];
    NSArray *tags = [Recipebox_tag MR_findAll];
    NSArray *ingredients = [Ingredient MR_findAll];
    
    XCTAssertEqual(items.count, 0);
    XCTAssertEqual(tags.count, 0);
    XCTAssertEqual(ingredients.count, 0);
}
- (void)testImportRecipe
{
    [Recipebox insertItems:jsonData];
    Recipebox *recipe = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:@65536];
    XCTAssertNotNil(recipe, @"Recipe is nil");
    Recipebox *item   = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:@65536];
    
    XCTAssertEqualObjects(item.advice,@"För alla: noga ingrediensförteckningen på korven.\n glutenfri: använd glutenfri pasta.laktosfri");
    
    XCTAssertEqualObjects(item.cookCount,@1);
    
    XCTAssertEqualObjects(item.createdAt,@"2014-05-08T15:14:46.313Z");
    
    XCTAssertEqualObjects(item.descriptionText,@"Falukorvsf paprika och majs blir");
    
    XCTAssertEqualObjects(item.imageUrl,@"http://sss.se");
    
    XCTAssertEqualObjects(item.ingredients,@"550 g falukorv");
    
    XCTAssertEqualObjects(item.ingredientsMarkup,@"550 g <ki>falukorv</ki>\n1/2 <ki>purjolök</ki>\n1 röd <ki>paprika</ki>\n1 tsk <ki>olivolja</ki>n1 tsk <ki>paprikapulver</ki>\n340 g <ki>majs</ki>\n<ki>salt</ki> och peppar");
    XCTAssertEqualObjects(item.instructions,@"1. 2.");
    
    XCTAssertEqualObjects(item.isPublic,@1);
    
    XCTAssertEqualObjects(item.lastCookedAt,@"2014-07-14T20:40:55.47Z");
    
    XCTAssertEqualObjects(item.lastViewedAt,@"2014-05-08T15:14:48.22Z");
    
    XCTAssertEqualObjects(item.originalCookTime,@40);
    
    XCTAssertEqualObjects(item.originalCookTimeSpanLower,@20);
    XCTAssertEqualObjects(item.portionType,@"portioner");
    XCTAssertEqualObjects(item.portions,@4);
    
    XCTAssertEqualObjects(item.rating,@3);
    
    XCTAssertEqualObjects(item.source_text,@"ica.se");
    
    XCTAssertEqualObjects(item.source_url,@"http://www.ica.se/recept/falukorvsfras-med-pasta-716655/");
    
    XCTAssertEqualObjects(item.title,@"Falukorvsfrö med pasta");
    XCTAssertEqualObjects(item.updatedAt, @"2014-07-14T20:40:55.47Z");
    
}
-(void)testInsertRelatedTagsCorrect{

    Recipebox *item   = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:@65536];
    NSArray *tags = [ item.relatedTags allObjects];
    XCTAssertNotNil(tags);
    XCTAssertEqual(tags.count,6);
    
    for (Recipebox_tag *tag in tags) {
        XCTAssertTrue([tag.text length] > 0);
        NSLog(@"text: %@", tag.text);
    }
}
-(void)testInsertRelatedIngredientsCorrect{
    
    Recipebox *item   = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:@65536];
    NSArray *ingredients = [ item.containIngredients allObjects];
    XCTAssertNotNil(ingredients);
    XCTAssertEqual(ingredients.count,7);
    
    for (Ingredient *ingredient in ingredients) {
        XCTAssertTrue([ingredient.text length] > 0);
        NSLog(@"%@ | %@ | %@ | %@ |%@ | %@ |%@", ingredient.isCategory,ingredient.isProbablyNeeded,ingredient.knownItemText,ingredient.quantityText,ingredient.sortableText,ingredient.text,ingredient.unitText);
    }
}
-(void)testGetAllExceptDeleted{
    NSArray *results = [Recipebox getAllRecipesExceptDeleted];
    
    for (Recipebox *recipe in results) {
        XCTAssertNotEqualObjects(recipe.syncStatus, [NSNumber numberWithInt:Deleted], @"%@ - Not deleted",recipe.recipeboxID);
    }
}
-(void)testFakeDelete{
    [Recipebox fakeDeleteById:@65536];
    Recipebox *item = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:@65536];
    NSArray* items = [Recipebox MR_findByAttribute:@"recipeboxID" withValue:@65536];
    XCTAssertTrue(items.count == 1);
    
    XCTAssertEqualObjects(item.syncStatus, [NSNumber numberWithInt:Deleted]);
    NSLog(@"item syncStatus %@",item.syncStatus);
}

-(void)testRealDelete{
    Recipebox *item = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:@65536];
    XCTAssertNotNil(item);
    
    Active_recipe *activeItem = [Active_recipe MR_findFirstByAttribute:@"active_recipeID" withValue:@65536];
    XCTAssertNil(activeItem);
    
    [Recipebox realDelete];
    Recipebox *item2 = [Recipebox MR_findFirstByAttribute:@"recipeboxID" withValue:@65536];
    XCTAssertNil(item2);

}
-(void)testAgainRealDelete{
    NSArray* items = [Recipebox MR_findByAttribute:@"recipeboxID" withValue:@65536];
    XCTAssertTrue(items.count == 0);
}

@end
