//
//  AFHTTPSessionManager+AFHTTPSessionManager_Extension.h
//  MatListan
//
//  Created by Yan Zhang on 02/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface AFHTTPSessionManager (AFHTTPSessionManager_Extension)
- (NSURLSessionDataTask *)HEADWithResponse:(NSString *)URLString
                    parameters:(id)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;
@end
