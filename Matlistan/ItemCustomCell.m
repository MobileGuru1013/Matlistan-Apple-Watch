//
//  ItemCustomCell.m
//  Matlistan
//
//  Created by hemal on 28/10/15.
//  Copyright © 2015 Flame Soft. All rights reserved.
//

#import "ItemCustomCell.h"


@implementation ItemCustomCell

- (void)awakeFromNib {
    // Initialization code
    //
    
    CALayer *sub = [CALayer new];
    if(IS_IPHONE) {
        sub.frame = CGRectInset(self.btnAddSuggestion.bounds, 8, 6);
    }
    else {
        sub.frame = CGRectInset(self.btnAddSuggestion.bounds, 13, 8);
    }
    sub.backgroundColor = [Utility getGreenColor].CGColor;
    sub.cornerRadius=3;
    [self.btnAddSuggestion.layer addSublayer:sub];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
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
