//
//  ItemListTest.m
//  MatListan
//
//  Created by Yan Zhang on 09/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FixtureHelpers.h"
#import "Item_list+Extra.h"

@interface ItemListTest : XCTestCase

@property (nonatomic,retain)id jsonData;
@end

@implementation ItemListTest
@synthesize jsonData;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    
    jsonData = [FixtureHelpers loadFixture:@"itemlist.json"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [MagicalRecord cleanUp];
}

- (void)testInsert
{
    [Item_list deleteAllItemsInContext:nil];
    NSArray *rows = [Item_list MR_findAll];
    XCTAssertTrue(rows.count == 0);
    
    [Item_list insertItems:jsonData];
    rows = [Item_list MR_findAll];
    XCTAssertTrue(rows.count == 2);
    
    Item_list *list = [Item_list MR_findFirstByAttribute:@"item_listID" withValue:@1638];
    XCTAssertNotNil(list);
    XCTAssertEqualObjects(list.isDefault, @1);
    XCTAssertEqualObjects(list.manualSortOrderIsGrouped, @0);
    XCTAssertEqualObjects(list.name, @"Min inköpslista");
    XCTAssertEqualObjects(list.sortByStoreId, @2106);
    XCTAssertEqualObjects(list.sortOrder, @"Store");
    
}
-(void)testDefaultId{
    NSNumber *listId = [Item_list getDefaultListId];
    XCTAssert(listId!=nil);
    XCTAssert(listId.intValue != 0);
}

@end
