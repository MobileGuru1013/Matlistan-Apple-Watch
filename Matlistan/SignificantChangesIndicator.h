//
//  SignificantChangesIndicator.h
//  Matlistan
//
//  Created by Artem Bakanov on 8/7/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SignificantChangesIndicator : NSObject

@property BOOL itemsChanged;
@property BOOL itemsListChanged;
@property BOOL itemsSortingChanged;
@property BOOL currentItemListChanged;
@property BOOL recipeChanged;
@property BOOL activeRecipeChanged;
@property BOOL activeRecipeAdded;

+(SignificantChangesIndicator *) sharedIndicator;

- (void) resetData;

@end
