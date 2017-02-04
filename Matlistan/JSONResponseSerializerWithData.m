//
//  JSONResponseSerializerWithData.m
//  MatListan
//  AFNetworking only returns header when error happens
//  This is to complement AFNetworking - get body information from server response.
//  Source: http://blog.gregfiumara.com/archives/239
//  Created by Yan Zhang on 22/03/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONResponseSerializerWithData.h"

@implementation JSONResponseSerializerWithData

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    id JSONObject = [super responseObjectForResponse:response data:data error:error];
    if (*error != nil) {
        NSMutableDictionary *userInfo = [(*error).userInfo mutableCopy];
        if (data == nil) {
            //			// NOTE: You might want to convert data to a string here too, up to you.
            //			userInfo[JSONResponseSerializerWithDataKey] = @"";
            userInfo[JSONResponseSerializerWithDataKey] = [NSData data];
        } else {
            //			// NOTE: You might want to convert data to a string here too, up to you.
            //			userInfo[JSONResponseSerializerWithDataKey] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            userInfo[JSONResponseSerializerWithDataKey] = data;
        }
        NSError *newError = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:userInfo];
        (*error) = newError;
    }
    
    return (JSONObject);
}

@end