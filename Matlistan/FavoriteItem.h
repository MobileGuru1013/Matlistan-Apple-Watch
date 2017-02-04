//
//  FavoriteItems.h
//  Matlistan
//
//  Created by Artem Bakanov on 12/8/15.
//  Copyright © 2015 Consumiq AB. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface FavoriteItem : NSManagedObject

@property (nonatomic, retain) NSString * matchingItem;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * sortOrder;

@end
