//
//  NSManagedObject+JSON.m
//
//

#import "NSManagedObject+JSON.h"

@implementation NSManagedObject (JSON)

/* Get the JSON representation of the NSManagedObject
 */
- (NSDictionary *)toJSON {
    @throw [NSException exceptionWithName:@"JSONStringToCreateObjectOnServer Not Overridden" reason:@"Must override JSONToCreateObjectOnServer on NSManagedObject class" userInfo:nil];
    return nil;
}

@end
