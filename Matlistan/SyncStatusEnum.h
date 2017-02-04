//
//  SyncStatusEnum.h
//  Matlistan
//
//  Created by Artem Bakanov on 7/27/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#ifndef Matlistan_SyncStatusEnum_h
#define Matlistan_SyncStatusEnum_h

typedef enum {
    Synced = 0,
    Created,
    Updated,
    Deleted,
    UpdatedAgain //Used for checked status.
} SYNC_STATUS;

#endif
