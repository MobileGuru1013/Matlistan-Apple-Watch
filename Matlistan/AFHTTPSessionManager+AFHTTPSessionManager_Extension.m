//
//  AFHTTPSessionManager+AFHTTPSessionManager_Extension.m
//  MatListan
//
//  Created by Yan Zhang on 02/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "AFHTTPSessionManager+AFHTTPSessionManager_Extension.h"

@implementation AFHTTPSessionManager (AFHTTPSessionManager_Extension)

- (NSURLSessionDataTask *)HEADWithResponse:(NSString *)URLString
                    parameters:(id)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"HEAD" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    
    __block NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(task, error);
            }
        } else {
            if (success) {
                success(task,responseObject);
            }
        }
    }];
    
    [task resume];
    
    return task;
}

@end
