//
//  Item.m
//  MatListan
//
//  Created by Yan Zhang on 18/02/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "Item.h"
#import "Item_list.h"
#import "ItemsCheckedStatus.h"


@implementation Item

@dynamic addedAt;
@dynamic addedAtTime;
@dynamic barcode;
@dynamic barcodeType;
@dynamic checkedAfterStart;
@dynamic groupedSortIndex;
@dynamic groupedText;
@dynamic isChecked;
@dynamic isDefaultMatch;
@dynamic isPermanent;
@dynamic isPossibleMatch;
@dynamic isTaken;
@dynamic itemID;
@dynamic knownItemText;
@dynamic listId;
@dynamic listObjectID;
@dynamic manualSortIndex;
@dynamic matchingItemText;
@dynamic mayBeDefaultMatch;
@dynamic placeCategory;
@dynamic possibleMatches;
@dynamic searchedText;
@dynamic secs_after_start;
@dynamic secs_after_start_local;
@dynamic serverIndex;
@dynamic syncStatus;
@dynamic text;
@dynamic addedAtTime_local;
@dynamic belongToList;
@dynamic itemsCheckedStatus;
@dynamic checkOrder;

// Added field to send method of adding item by user
// values can be Unknown, Voice, Manual, Favorite, Barcode, Autocomplete
// see API  https://consumiq.atlassian.net/wiki/display/API/Items for values
@dynamic source;

@end
