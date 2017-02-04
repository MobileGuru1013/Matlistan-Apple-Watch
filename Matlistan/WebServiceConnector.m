//
//  WebServiceConnector.m
//  MatListan
//
//  Created by Yan Zhang on 18/06/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "WebServiceConnector.h"

@implementation WebServiceConnector
+(void)loginWithUser:(NSString*)user andPwd:(NSString*)pwd{
    OVCClient *client = [[OVCClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://api2.matlistan.se/"]];
    [client.requestSerializer setValue:@"application/json"
                    forHTTPHeaderField:@"Accept"];
    
    // Basic HTTP auth
    [client.requestSerializer setAuthorizationHeaderFieldWithUsername:user
                                                             password:pwd];
}
@end
