//
//  StoreTest.m
//  MatListan
//
//  Created by Yan Zhang on 09/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FixtureHelpers.h"
#import "Store+Extra.h"

@interface StoreTest : XCTestCase

@property (nonatomic,retain)id jsonData;
@end

@implementation StoreTest
@synthesize jsonData;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    
    jsonData = [FixtureHelpers loadFixture:@"store.json"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [MagicalRecord cleanUp];
}

- (void)testInsert
{
    [Store deleteAllItems];
    NSArray *rows = [Store MR_findAll];
    XCTAssertTrue(rows.count == 0);
    
    [Store insertStores:jsonData];
    rows = [Store MR_findAll];
    XCTAssertTrue(rows.count == 3);
    
    Store *store = [Store MR_findFirstByAttribute:@"storeID" withValue:@2106];
    XCTAssertNotNil(store);
    XCTAssertEqualObjects(store.address, @"Kolhamnsgatan 7, 41761 Göteborg");
    XCTAssertEqualObjects(store.city, @"Göteborg");
    XCTAssertEqualObjects(store.isFavorite, @0);
    XCTAssertEqualObjects(store.itemsSortedPercent, @2);
    XCTAssertEqualObjects(store.name, @"Coop Extra Eriksberg");
    XCTAssertEqualObjects(store.postalAddress, @"Kolhamnsgatan 7");
    XCTAssertEqualObjects(store.postalCode, @41761);
    XCTAssertEqualObjects(store.title, @"Coop Extra Eriksberg, Kolhamnsgatan 7, 41761 Göteborg");
    
}

@end
