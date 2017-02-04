//
//  NetHelper.m
//  MatListan
//
//  Created by Yan Zhang on 28/08/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "NetHelper.h"
#import <AFHTTPSessionManager.h>
@implementation NetHelper

static NSString * const BaseURLString = @"http://www.raywenderlich.com/demos/weather_sample/";

-(void)DownloadDataFromLink:(NSString*)urlString andSection:(NSString*)section{
    
    NSDictionary *result = [[NSDictionary alloc]init];
    
    NSURL *baseURL = [NSURL URLWithString:urlString];
    NSDictionary *parameters = @{@"format":@"json"};
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithBaseURL:baseURL];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager GET:section parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {


    } failure:^(NSURLSessionDataTask *task, NSError *error) {

    }];
    
    

}
@end
