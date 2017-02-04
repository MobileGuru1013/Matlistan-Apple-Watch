//
//  MagicalRecordTests.m
//  MatListan
//
//  Created by Yan Zhang on 08/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Item+Extra.h"
#import "FixtureHelpers.h"
#import "DataStore.h"

@interface MagicalRecordTests : XCTestCase
@property (nonatomic,retain)id jsonData;
@property (nonatomic, retain) NSArray * arrayOfTestEntity;
@end

@implementation MagicalRecordTests
@synthesize jsonData,arrayOfTestEntity;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    
    jsonData = [FixtureHelpers loadFixture:@"items.json"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
	[MagicalRecord cleanUp];
}
-(void)testCombined{
    [self testDeleteItems];
    [self testImportOfMultipleEntities];
    [self testInsertResultIsCorrect];
}
- (void)testImportOfMultipleEntities
{
    [Item insertItems:jsonData];
    NSArray *allItems = [Item getAllItemsByStatus:Synced];
    XCTAssert(allItems.count > 0, @"items should have more than 1 entities");
}
- (void)testDeleteItems
{
    [Item deleteAllItemsInContext:nil];
    NSArray *items = [Item MR_findAll];
    XCTAssertEqual(items.count, 0);
}
-(void)testSumOfItems{
    NSArray *items = [Item MR_findAll];
    
    XCTAssertEqual(items.count, 2);
    
}
-(void)testInsertResultIsCorrect{
    Item *item   = [Item MR_findFirstByAttribute:@"itemID" withValue:@94252];
    
    XCTAssertEqualObjects(item.addedAt, @"2014-05-05T16:20:23.03Z");
    XCTAssertEqualObjects(item.groupedSortIndex, @33);
    XCTAssertEqualObjects(item.groupedText, @"babyspenat");
    XCTAssertEqualObjects(item.knownItemText, @"babyspenat");
    XCTAssertEqualObjects(item.listId, @1638);
    XCTAssertEqualObjects(item.matchingItemText, @"babyspenat, färsk");
    XCTAssertEqualObjects(item.text, @"70 g babyspenat");
    XCTAssertEqualObjects(item.placeCategory, @"färska grönsaker");
    
    XCTAssertEqualObjects(item.searchedText, @"babyspenat");
    
    XCTAssertEqualObjects(item.isChecked, @1);
    XCTAssertNotNil(item.addedAtTime);
    
    NSLog(@"%@\n%@",item.possibleMatches,item.addedAtTime);
    
}
-(void)testInsertItem{
    [Item insertItemWithText:@"testItem" andBarcode:@"1111" andBarcodeType:@"mycode" andListId:@65536 andAddedAt:@"2014-09-16"];
    Item *item = [Item MR_findFirstByAttribute:@"listId" withValue:@65536];
    XCTAssertEqualObjects(item.text, @"testItem");
    XCTAssertEqualObjects(item.barcode, @"1111");
    XCTAssertEqualObjects(item.barcodeType, @"mycode");
    XCTAssertEqualObjects(item.addedAt, @"2014-09-16");
    XCTAssertEqualObjects(item.syncStatus, [NSNumber numberWithInt:Created]);
    
   
}
-(void)testInsertAndFakeDeleteItems{
    
    [Item deleteAllItemsInContext:nil];
    
    [Item insertItemWithID:@65536 andText:@"f" andBarcode:@"123" andBarcodeType:@"ec4" andListId:@65535 andAddedAt:@"2014-09-28"];
    Item *item = [Item MR_findFirstByAttribute:@"itemID" withValue:@65536];
    XCTAssertEqualObjects(item.text, @"f");
    
    [Item fakeDelete:@65536];
    
    NSArray *items = [Item MR_findByAttribute:@"itemID" withValue:@65536];
    
    XCTAssertTrue(items.count == 1);
    
    [Item insertItemWithID:@65536 andText:@"f" andBarcode:@"123" andBarcodeType:@"ec4" andListId:@65535 andAddedAt:@"2014-09-28"];

    
    items = [Item MR_findByAttribute:@"itemID" withValue:@65536];
    
    NSLog(@"items %d",items.count);
    
    XCTAssertTrue(items.count == 1);
}
-(void)testFakeDelete{
    [Item fakeDelete:@0];
    Item *item = [Item MR_findFirstByAttribute:@"itemID" withValue:@0];
    NSLog(@"--------------------");
    NSLog(@"item id = %@, syncStatus = %@",item.itemID,item.syncStatus);
    NSLog(@"item: %@",item);
    XCTAssertEqualObjects(item.syncStatus, [NSNumber numberWithInt:Deleted]);
    
}
-(void)testFakeDeleteAgain{
    Item *item = [Item MR_findFirstByAttribute:@"itemID" withValue:@0];
    NSLog(@"--------------------");
    NSLog(@"item id = %@, syncStatus = %@",item.itemID,item.syncStatus);

    XCTAssertEqualObjects(item.syncStatus, [NSNumber numberWithInt:Deleted]);
    

}
-(void)testGetFakeDeleted{
    NSArray *items = [Item getAllItemsFakeDeletedInList];
    XCTAssertTrue(items.count==1);
    Item *item = items[0];
    XCTAssertTrue([item.itemID isEqualToNumber:@0]);
    
    XCTAssertTrue([item.listId isEqualToNumber:@65536]);
}
-(void)testRealDeleteItem{
    //[Item realDeleteWithPredicate:[NSPredicate predicateWithFormat:@"listId = %@",@65536]];
    
    Item *item = [Item MR_findFirstByAttribute:@"itemID" withValue:@0];
    XCTAssertNotNil(item);
    
    [Item realDelete];
     Item *item2 = [Item MR_findFirstByAttribute:@"itemID" withValue:0];

    XCTAssertNil(item2);
    
}
-(void)testUpdateItem{
    [Item updateItemWithId:@0 andText:@"testItem2" andisPermanent:[NSNumber numberWithBool:YES] andMatchingItem:@"gurka" andIsDefaultMatch:[NSNumber numberWithBool:YES]];
    
    Item *item = [Item MR_findFirstByAttribute:@"listId" withValue:@65536];
    XCTAssertEqualObjects(item.text, @"testItem2");
    XCTAssertEqualObjects(item.isPermanent, [NSNumber numberWithBool:YES] );
    XCTAssertEqualObjects(item.matchingItemText, @"gurka");
    XCTAssertEqualObjects(item.isDefaultMatch, [NSNumber numberWithBool:YES] );
    XCTAssertEqualObjects(item.syncStatus, [NSNumber numberWithInt:Updated]);
    
}
-(void)testUpdateItemAgain{
    Item *item = [Item MR_findFirstByAttribute:@"itemID" withValue:@0];
    XCTAssertEqualObjects(item.text, @"testItem2");
    XCTAssertEqualObjects(item.isPermanent, [NSNumber numberWithBool:YES] );
    XCTAssertEqualObjects(item.matchingItemText, @"gurka");
    XCTAssertEqualObjects(item.isDefaultMatch, [NSNumber numberWithBool:YES] );
    XCTAssertEqualObjects(item.syncStatus, [NSNumber numberWithInt:Updated]);
}


//
//-(void)testCheckItem{
//    [Item checkItem:@0 withCheckStatus:YES];
//    
//    Item *item = [Item MR_findFirstByAttribute:@"listId" withValue:@65536];
//    XCTAssertEqualObjects(item.isChecked, @YES);
//    XCTAssertEqualObjects(item.syncStatus, [NSNumber numberWithInt:Updated]);
//}
//-(void)testGetAllUndeletedItems{
//    NSArray *result = [Item getAllItemsExceptDeleted:STORE inList:@1638];
//    XCTAssertTrue(result.count > 0);
//}

@end
