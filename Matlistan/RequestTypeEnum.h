//
//  RequestTypeEnum.h
//  Matlistan
//
//  Created by Artem Bakanov on 7/29/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#ifndef Matlistan_RequestTypeEnum_h
#define Matlistan_RequestTypeEnum_h

typedef enum {
    REQUEST_GET = 0,
    REQUEST_POST,
    REQUEST_PUT,
    REQUEST_DELETE,
    REQUEST_PATCH,
    REQUEST_NONE
} REQUEST_TYPE;

#endif
