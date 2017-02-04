//
//  EndpointHashTest.m
//  MatListan
//
//  Created by Yan Zhang on 10/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FixtureHelpers.h"
#import "EndpointHash+Extra.h"

@interface EndpointHashTest : XCTestCase

@property (nonatomic,retain)id jsonData;
@end

@implementation EndpointHashTest
@synthesize jsonData;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    
    jsonData = [FixtureHelpers loadFixture:@"hash.json"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [MagicalRecord cleanUp];
}

- (void)testTable
{
    [EndpointHash deleteAllItemsInContext:nil];
    NSArray *rows = [EndpointHash MR_findAll];
    XCTAssertEqual(rows.count,0);
    
    [EndpointHash insertItems:jsonData];
    rows = [EndpointHash MR_findAll];
    
    XCTAssertEqual(rows.count,1);
    
    for (EndpointHash *end in rows) {
        
        NSNumber *activeRecipeHash = [NSNumber numberWithLong:-280690556];
        NSNumber *storesHash = [NSNumber numberWithLong:-335835015];
        
        XCTAssertEqualObjects(end.favoriteItemsHash, @1635633965);
        XCTAssertEqualObjects(end.itemListsHash, @1852334263);
        XCTAssertEqualObjects(end.itemsHash, @1052219737);
        XCTAssertEqualObjects(end.recipeCount, @9);
        XCTAssertEqualObjects(end.recipeUpdatedAt, @"2014-07-14T20:40:55.47Z");
        XCTAssertEqualObjects(end.activeRecipesHash, activeRecipeHash);
        XCTAssertEqualObjects(end.storesHash, storesHash);
        
                                             
                       
        NSLog(@"%@",end);
    }
    
}
-(void)testDelete{
    
    [EndpointHash deleteAllItemsInContext:nil];
    NSArray *rows = [EndpointHash MR_findAll];
    XCTAssertEqual(rows.count,0);
}

@end
