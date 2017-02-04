//
//  Environment.m
//  Matlistan
//
//  Created by Yousuf on 10/14/15.
//  Copyright © 2015 Flame Soft. All rights reserved.
//

#import "Environment.h"

@implementation Environment

static Environment *sharedInstance = nil;

- (id)init
{
    self = [super init];
    
    if (self) {
        
    }
    
    return self;
}

- (void)initializeSharedInstance
{
    NSString* configuration = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Configuration"];
    
    DLog(@"Build Configuration: %@", configuration);
    
    NSBundle* bundle = [NSBundle mainBundle];
    
    NSString* envsPListPath = [bundle pathForResource:@"Environment" ofType:@"plist"];
    
    NSDictionary* environments = [[NSDictionary alloc] initWithContentsOfFile:envsPListPath];
    NSDictionary* environment = [environments objectForKey:configuration];
    
    self.baseUrl = [environment valueForKey:@"BaseUrl"];
    self.facebookAppID = [environment valueForKey:@"FacebookAppID"];
    self.facebookDisplayName = [environment valueForKey:@"FacebookDisplayName"];
    self.urlScheme = [environment valueForKey:@"UrlScheme"];
    self.googleServerClientId = [environment valueForKey:@"GOOGLE_SERVER_CLIENT_ID"];
    self.googleClientId = [environment valueForKey:@"GOOGLE_CLIENT_ID"];

}

#pragma mark -
#pragma mark - Lifecycle Methods
#pragma mark -
+ (Environment *)sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
        {
            sharedInstance = [[self alloc] init];
            [sharedInstance initializeSharedInstance];
        }
        return sharedInstance;
    }
}

@end
