//
//  UITextField+Extended.m
//  INK'N'ART-Visitkort
//
//  Created by Yan Zhang on 12/8/13.
//  Copyright (c) 2013 Flame Soft. All rights reserved.
//

#import "UITextField+Extended.h"

#import "UITextField+Extended.h"
#import <objc/runtime.h>

static char defaultHashKey;

@implementation UITextField (Extended)


- (UITextField*) nextTextField {
    return objc_getAssociatedObject(self, &defaultHashKey);
}

- (void) setNextTextField:(UITextField *)nextTextField{
    objc_setAssociatedObject(self, &defaultHashKey, nextTextField, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
