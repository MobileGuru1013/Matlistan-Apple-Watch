//
//  ItemCell.h
//  MatListan
//
//  Created by Yan Zhang on 30/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "SWTableViewCell.h"
#import "Item.h"

@interface ItemCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *btnPossibleMatches;
@property (weak, nonatomic) IBOutlet UIImageView *pinImage;

@property (nonatomic,retain) NSNumber *itemId;
@property (nonatomic,retain) NSManagedObjectID *itemObjectId;

@property (nonatomic, strong) Item *cellItem;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pinImageTrailingConstraint;

- (IBAction)btnPossibleMatches_Pressed:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UIView *expandedView;

@end
