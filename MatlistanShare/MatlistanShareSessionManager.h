//
//  MatlistanShareSessionManager.h
//  Matlistan
//
//  Created by Artem Bakanov on 12/15/15.
//  Copyright © 2015 Consumiq AB. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "ShareViewController.h"

@interface MatlistanShareSessionManager : AFHTTPSessionManager

@property (nonatomic,retain) NSString* ticket;
@property (nonatomic,retain) NSString* accountId;
@property ShareViewController *shareViewDelegate;

+(MatlistanShareSessionManager *) sharedManager;
- (void) login;
- (void) loginWithUserName:(NSString *)userName andPassword:(NSString *)password;
- (void) sendRecipeURL: (NSString *) recipeURL;

@end
