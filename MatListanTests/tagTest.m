//
//  tagTest.m
//  MatListan
//
//  Created by Yan Zhang on 09/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FixtureHelpers.h"
#import "Recipebox_tag+Extra.h"

@interface tagTest : XCTestCase

@property (nonatomic,retain)id jsonData;
@property (nonatomic,retain)NSNumber *recipeId;
@end

@implementation tagTest
@synthesize jsonData,recipeId;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    
    jsonData = [FixtureHelpers loadFixture:@"tags.json"];
    recipeId = @65536;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
	[MagicalRecord cleanUp];
}

-(void)testDelete{
    [Recipebox_tag deleteTags:recipeId];
    NSArray *result = [Recipebox_tag MR_findByAttribute:@"recipeID" withValue:recipeId];
    XCTAssertEqual(result.count, 0);
}
-(void)testInsert{
    NSArray *input = (NSArray*)jsonData;
    [Recipebox_tag insertTags:input forRecipe:recipeId];
    NSArray *result = [Recipebox_tag MR_findByAttribute:@"recipeID" withValue:recipeId];
    for (Recipebox_tag *tag in result) {
        NSLog(@"%@ | %@",tag.text,tag.recipeID);
    }
    XCTAssertTrue(result.count==5);
}
-(void)testUpdate{
    NSArray *input = (NSArray*)jsonData;
    [Recipebox_tag updateTags:input forRecipe:recipeId];
    NSArray *result = [Recipebox_tag MR_findByAttribute:@"recipeID" withValue:recipeId];
    for (Recipebox_tag *tag in result) {
        NSLog(@"%@ | %@",tag.text,tag.recipeID);
    }
    XCTAssertTrue(result.count==5);
}

@end
