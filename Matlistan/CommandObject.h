//
//  CommandObject.h
//  Matlistan
//
//  Created by Artem Bakanov on 7/27/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SuperObject.h"

typedef enum {
    INSERT = 0,
    UPDATE,
    DELETE,
    NO_ACTION
} SYNC_COMMAND;

@interface CommandObject : NSObject

@property id<SuperObject> objectToSync;
@property SYNC_COMMAND localCommand;
@property SYNC_COMMAND remoteCommand;

@end
