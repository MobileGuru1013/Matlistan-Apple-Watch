//
//  UISwitch+Property.m
//  MatListan
//
//  Created by Yan Zhang on 24/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "UISwitch+Property.h"
#import <objc/runtime.h>

@implementation UISwitch (Property)


static char UIS_PROPERTY_KEY;

@dynamic property;

-(void)setProperty:(NSObject *)property
{
    objc_setAssociatedObject(self, &UIS_PROPERTY_KEY, property, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSObject*)property
{
    return (NSObject*)objc_getAssociatedObject(self, &UIS_PROPERTY_KEY);
}


@end
