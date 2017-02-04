//
//  MatlistanIAPHelper.m
//  MatListan
//
//  Created by Yan Zhang on 18/04/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "MatlistanIAPHelper.h"
#import "AppDelegate.h"

@implementation MatlistanIAPHelper
/*
 The sharedInstance method implements the Singleton pattern in Objective-C to return a single,
 global instance of the MatlistanIAPHelper class. It calls the superclasses initializer to pass in all
 the product identifiers that you created with iTunes Connect.
 */
+ (MatlistanIAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static MatlistanIAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        //TO DO: here it should be the product configured in App Store, the name is just an example
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      PRODUCT_IDENTIFIER,
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

@end
