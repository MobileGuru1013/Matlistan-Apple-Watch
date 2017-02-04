//
//  JSONResponseSerializerWithData.h
//  MatListan
//
//  Created by Yan Zhang on 22/03/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "AFURLResponseSerialization.h"

/// NSError userInfo key that will contain response data
static NSString * const JSONResponseSerializerWithDataKey = @"JSONResponseSerializerWithDataKey";

@interface JSONResponseSerializerWithData : AFJSONResponseSerializer
@end
