//
//  MatlistanHTTPClient.h
//  MatListan
//
//  Created by Yan Zhang on 28/08/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "AFHTTPRequestOperationManager.h"
#import <Google/SignIn.h>

typedef NS_ENUM(NSInteger, RequestType)
{
    RequestGetLinkedAccounts,
    RequestLinkNewAccount,
    RequestDeleteLinkedAccount
};

@protocol MatlistanHTTPClientDelegate;

@interface MatlistanHTTPClient : AFHTTPSessionManager<UIActionSheetDelegate, GIDSignInDelegate>

@property (nonatomic,weak)id<MatlistanHTTPClientDelegate>delegate;

@property (nonatomic,retain) NSString* ticket;
//@property (nonatomic,retain) NSString* userName;
//@property (nonatomic,retain) NSString* password;
@property (nonatomic) BOOL isLoggedIn;

@property (nonatomic,retain) NSString *anonymousUserId;
@property (nonatomic,retain) NSString *anonymousPassword;
@property (nonatomic,retain) NSDictionary* googleTokenSaved;

@property (nonatomic,retain) NSString* accountId;

@property BOOL googleLoginTriedAgain;
@property BOOL facebookLoginTriedAgain;

+(MatlistanHTTPClient *)sharedMatlistanHTTPClient;
-(instancetype)initWithBaseURL:(NSURL *)url;
-(void)loginWithUserName:(NSString*)userName andPassword:(NSString*)password;
-(void)loginAsAnonymousWithUserName:(NSString *)anonymousId andPassword:(NSString *)anonymousPassword;
-(void)retryLogin;
-(void)registerAsAnonymous;
-(void)loginWithFacebook;
- (void) loginWithGoogleIdToken:(NSString *)idToken andAccessToken: (NSString *) accessToken;
- (void)resetPasswordWithEmail:(NSString*)email;
- (void)getLinkedAccounts;
- (void)linkAccount:(NSString *)email withFbId:(NSString *)fbId;
- (void)deleteAccount:(int)accountId;

- (void)loginWithPostSession;

- (void)getMe;

- (void) didLogin:(id)cookie;
//- (void) didFailWithError:(NSError *)error;

@end

@protocol MatlistanHTTPClientDelegate <NSObject>

@optional

-(void)matlistanHTTPClient:(MatlistanHTTPClient*)client didFailWithError:(NSError*)error;
-(void)matlistanHTTPClient:(MatlistanHTTPClient*)client didFailWithError:(NSError*)error andCode: (long) code;
-(void)matlistanHTTPClient:(MatlistanHTTPClient*)client didLogin:(id)cookie;

- (void)matlistanHTTPClient:(MatlistanHTTPClient*)client didResetFailWithError:(NSError*)error;
- (void)matlistanHTTPClient:(MatlistanHTTPClient*)client didResetPasswordSuccessful:(id)response;

- (void)matlistanHTTPClient:(MatlistanHTTPClient*)client didRequestSuccessful:(id)response withType:(RequestType)requestType;

@end
