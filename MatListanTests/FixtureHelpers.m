//
//  FixtureHelpers.m
//  Magical Record

#import "FixtureHelpers.h"

@implementation FixtureHelpers

+(id)loadFixture:(NSString *)name
{
    NSBundle *unitTestBundle = [NSBundle bundleForClass:[self class]];
    NSString *pathForFile    = [unitTestBundle pathForResource:name ofType:nil];
    NSData   *data           = [[NSData alloc] initWithContentsOfFile:pathForFile];
    
    
    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    id response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:NULL];
    
   // NSLog(@"JSON DIct: %@", response);
    return response;
    
}
+ (id) dataFromPListFixtureNamed:(NSString *)fixtureName
{
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *resource = [testBundle pathForResource:fixtureName ofType:@"plist"];
    NSData *plistData = [NSData dataWithContentsOfFile:resource];
    
    return [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:nil error:nil];
}


@end

@implementation XCTest (FixtureHelpers)


@end
