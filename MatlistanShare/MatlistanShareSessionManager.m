//
//  MatlistanShareSessionManager.m
//  Matlistan
//
//  Created by Artem Bakanov on 12/15/15.
//  Copyright © 2015 Consumiq AB. All rights reserved.
//

#import "MatlistanShareSessionManager.h"

#define GROUP_BUNDLE_ID @"group.com.consumiq.matlistan.test"
//#define GROUP_BUNDLE_ID @"group.com.consumiq.matlistan.testmtpl"

@implementation MatlistanShareSessionManager

typedef enum{
    LoginTypeEmail,
    LoginTypeAnonymous,
    LoginTypeFacebook,
    LoginTypeUnknown,
    LoginTypeGoogle
} LoginType;

+(MatlistanShareSessionManager *) sharedManager {
    static MatlistanShareSessionManager *_sharedClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:GROUP_BUNDLE_ID];
        _sharedClient = [[self alloc]initWithBaseURL:[NSURL URLWithString:[defaults objectForKey:@"serverURL"]]];
        _sharedClient.responseSerializer = [AFJSONResponseSerializer serializer];
    });
    return _sharedClient;
}

- (void)loginWithUserName:(NSString *)userName andPassword:(NSString *)password
{
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"email"] = userName;
    parameters[@"password"] = password;
    
    void (^successBlock)(NSURLSessionDataTask *task, id responseObject) =
    ^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *dict = (NSDictionary*)responseObject;
        
        self.ticket = dict[@"ticket"];
        self.accountId = dict[@"accountId"];
        
        [_shareViewDelegate didLogin:YES];
       
    };
    void (^failureBlock)(NSURLSessionDataTask *task, NSError *error) =
    ^(NSURLSessionDataTask *task, NSError *error) {
        [_shareViewDelegate didLogin:NO];
    };
    
    [self POST:@"Sessions" parameters:parameters success:successBlock failure: failureBlock];
}

-(void)loginAsAnonymousWithUserName:(NSString *)anonymousId andPassword:(NSString *)anonymousPassword{
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"anonymousUid"] = anonymousId;
    parameters[@"password"] = anonymousPassword;
    
    [self POST:@"Sessions" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject){
        
        NSDictionary *dict = (NSDictionary*)responseObject;
        
        self.ticket = dict[@"ticket"];
        self.accountId = dict[@"accountId"];

        [_shareViewDelegate didLogin:YES];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        [_shareViewDelegate didLogin:NO];
    }];
}


- (void) sendRecipeURL: (NSString *) recipeURL {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"url"] = recipeURL;
    
    void (^successBlock)(NSURLSessionDataTask *task, id responseObject) =
    ^(NSURLSessionDataTask *task, id responseObject) {
        [_shareViewDelegate didUploadRecipe:YES];
        
    };
    void (^failureBlock)(NSURLSessionDataTask *task, NSError *error) =
    ^(NSURLSessionDataTask *task, NSError *error) {
        [_shareViewDelegate didUploadRecipe:NO withMessage:NSLocalizedString(@"not_a_recipe", nil)];
    };
    
    [self POST:@"RecipeBox" parameters:parameters success:successBlock failure: failureBlock];
}

- (void) login {
    if ([self getCurrentLoginType] == LoginTypeEmail) {
        [self loginWithUserName: [self getObjectFromDefaults:@"userName"] andPassword: [self getObjectFromDefaults:@"password"]];
    }
    else if ([self getCurrentLoginType] == LoginTypeAnonymous) {
        [self loginAsAnonymousWithUserName: [self getObjectFromDefaults:@"userName"] andPassword: [self getObjectFromDefaults:@"password"]];
    }
    
     else if ([self getCurrentLoginType] == LoginTypeFacebook){
        if ([self getObjectFromDefaults:@"FacebookTokenRetrieved"]) {
            [self loginWithFacebookToken:[self getObjectFromDefaults:@"FacebookTokenRetrieved"]];
        }
         else {
             [_shareViewDelegate didLogin:NO];
         }
    }
    else if ([self getCurrentLoginType] == LoginTypeGoogle) {
        NSString *gidToken = [self getObjectFromDefaults:@"GoogleIdTokenRetrieved"];
        NSString *gauthToken = [self getObjectFromDefaults:@"GoogleAccessTokenRetrieved"];
        if(gidToken && gauthToken) {
            [self loginWithGoogleIdToken:gidToken andAccessToken:gauthToken];
        }
        else {
            [_shareViewDelegate didLogin:NO];
        }
    }
}

- (void) loginWithGoogleIdToken:(NSString *)idToken andAccessToken: (NSString *) accessToken {
    NSDate *expDate = [self getObjectFromDefaults:@"GoogleAccessTokenExpirationDate"];
    NSDate *todayDate = [NSDate date];
    if ([todayDate compare: expDate] == NSOrderedDescending) {
        [_shareViewDelegate didLogin:NO];
    }
    else {
        NSDictionary *parameters = @{@"gIdToken": idToken, @"gAccessToken": accessToken};
       
        [self POST:@"Sessions" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject){
            NSDictionary *dict = (NSDictionary*)responseObject;
            
            if ([[responseObject objectForKey:@"success"]boolValue]) {
                self.ticket = dict[@"ticket"];
                self.accountId = dict[@"accountId"];
                [_shareViewDelegate didLogin:YES];
            }
            else {
                [_shareViewDelegate didLogin:NO];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error){
            [_shareViewDelegate didLogin:NO];
        }];
    }
}

-(void)loginWithFacebookToken:(NSString *)fbTokenIn{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"fbAccessToken"] = fbTokenIn;
    
    [self POST:@"Sessions" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject){
        NSDictionary *dict = (NSDictionary*)responseObject;
        if ([[responseObject objectForKey:@"success"]boolValue]) {
            
            self.ticket = dict[@"ticket"];
            self.accountId = dict[@"accountId"];
            [_shareViewDelegate didLogin:YES];
        }
        else {
            [_shareViewDelegate didLogin:NO];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        [_shareViewDelegate didLogin:NO];
    }];
}

- (LoginType) getCurrentLoginType{
    return (LoginType)[self getDefaultIntAtKey:@"LoginType"];
}

- (NSInteger)getDefaultIntAtKey:(NSString*)key{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:GROUP_BUNDLE_ID];
    return [defaults integerForKey:key];
}

- (id)getObjectFromDefaults:(NSString*)key{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:GROUP_BUNDLE_ID];
    id obj = [defaults objectForKey:key];
    return obj;
}

@end
