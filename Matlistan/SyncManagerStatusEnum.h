//
//  SyncManagerStatusEnum.h
//  Matlistan
//
//  Created by Artem Bakanov on 9/14/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#ifndef Matlistan_SyncManagerStatusEnum_h
#define Matlistan_SyncManagerStatusEnum_h

typedef enum {
    Synchronized = 0,
    InProgress,
    Error,
    Stopped
} SYNC_MANAGER_STATUS;

#endif
