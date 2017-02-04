//
//  SignificantChangesIndicator.m
//  Matlistan
//
//  Created by Artem Bakanov on 8/7/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "SignificantChangesIndicator.h"

@implementation SignificantChangesIndicator

+ (SignificantChangesIndicator *)sharedIndicator {
    static SignificantChangesIndicator *sharedIndicator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedIndicator = [self new];
        sharedIndicator.itemsChanged = NO;
        sharedIndicator.itemsListChanged = NO;
        sharedIndicator.currentItemListChanged = NO;
        sharedIndicator.recipeChanged = NO;
        sharedIndicator.activeRecipeChanged = NO;
        sharedIndicator.activeRecipeAdded = NO;
    });
    
    return sharedIndicator;
}

- (void) resetData {
    _itemsChanged = NO;
    _itemsListChanged = NO;
    _currentItemListChanged = NO;
    _recipeChanged = NO;
    _activeRecipeChanged = NO;
    _activeRecipeAdded = NO;
}

@end