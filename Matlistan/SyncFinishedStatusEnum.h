//
//  SyncFinishedStatusEnum.h
//  Matlistan
//
//  Created by Artem Bakanov on 7/31/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#ifndef Matlistan_SyncFinishedStatusEnum_h
#define Matlistan_SyncFinishedStatusEnum_h

typedef enum {
    SYNC_FINISHED_OK = 0,
    SYNC_FINISHED_GET_ERROR,
    SYNC_FINISHED_REMOTE_ERROR,
    SYNC_FINISHED_LOCAL_ERROR
} SYNC_FINISHED_STATUS;

#endif
