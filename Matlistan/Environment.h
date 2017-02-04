//
//  Environment.h
//  Matlistan
//
//  Created by Yousuf on 10/14/15.
//  Copyright © 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Environment : NSObject

@property (nonatomic , copy) NSString *baseUrl;
@property (nonatomic , copy) NSString *facebookAppID;
@property (nonatomic , copy) NSString *facebookDisplayName;
@property (nonatomic , copy) NSString *urlScheme;
@property (nonatomic , copy) NSString *googleServerClientId;
@property (nonatomic , copy) NSString *googleClientId;

+ (Environment *)sharedInstance;

@end
