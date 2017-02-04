//
//  ItemCell.m
//  MatListan
//
//  Created by Yan Zhang on 30/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ItemCell.h"

@implementation ItemCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

/**
 This methods will be called when user will press '?' button when there are possibleMatches available
 @ModifiedDate: September 8 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (IBAction)btnPossibleMatches_Pressed:(UIButton *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(showPossibleMatches:withSelectedItem:)])
    {
        if (self.cellItem != nil)
        {
            NSMutableArray *arrPossibleMatches = (NSMutableArray *)self.cellItem.possibleMatches;
            if (arrPossibleMatches != nil && arrPossibleMatches.count > 0)
            {
                arrPossibleMatches = [[NSMutableArray alloc] initWithObjects:@"?", nil];
                [arrPossibleMatches addObjectsFromArray:self.cellItem.possibleMatches];
                
                [self.delegate showPossibleMatches:arrPossibleMatches withSelectedItem:self.cellItem];
            }
        }
    }
}


@end
