//
//  FixtureHelpers.h
//  Magical Record
//

#import <XCTest/XCTest.h>

@interface FixtureHelpers : NSObject

+(id)loadFixture:(NSString *)name;
+ (id) dataFromPListFixtureNamed:(NSString *)fixtureName;

@end

@interface XCTest (FixtureHelpers)



@end
