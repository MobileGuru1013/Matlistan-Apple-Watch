//
//  ShoppingTableViewCell.m
//  MatListan
//
//  Created by Yan Zhang on 09/02/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "ShoppingTableViewCell.h"

@interface ShoppingTableViewCell () {
    NSArray *constraintsForHiddenSuggestions;
    NSArray *constraintsForShownSuggestions;
}
@end

@implementation ShoppingTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    _buttonShowMatches.layer.cornerRadius=3;
    
    NSDictionary *viewsDictionary = @{@"label":_labelItemTitle, @"buttonMatches":_buttonShowMatches, @"buttonReason":_buttonCheckReason};
    NSArray *constraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[label]-8-[buttonMatches(40)]-8-[buttonReason]"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:viewsDictionary];
    [self addConstraints:constraint_POS_H];
    constraintsForShownSuggestions = constraint_POS_H;
    
    constraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[label]-8-[buttonReason]"
                                                               options:0
                                                               metrics:nil
                                                                 views:viewsDictionary];
    [self addConstraints:constraint_POS_H];
    constraintsForHiddenSuggestions = constraint_POS_H;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self.buttonCheckReason addTarget:self action:@selector(buttonCheckReasonClicked) forControlEvents:UIControlEventTouchUpInside];
    // Configure the view for the selected state
}
-(void)buttonCheckReasonClicked{
    DLog(@"buttonCheckReasonClicked");
    if (self.delegate && [self.delegate respondsToSelector:@selector(shoppingTableViewCellButtonPressed:)]) {
        DLog(@"shoppingTableViewCellButtonPressed");
        [self.delegate shoppingTableViewCellButtonPressed:self];
    }
}

- (IBAction)btnPossibleMatchesPressed:(UIButton *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(showPossibleMatches:withSelectedItem:)])
    {
        if (self.item != nil)
        {
            NSMutableArray *arrPossibleMatches = (NSMutableArray *)self.item.possibleMatches;
            if (arrPossibleMatches != nil && arrPossibleMatches.count > 0)
            {
                arrPossibleMatches = [[NSMutableArray alloc] initWithObjects:@"?", nil];
                [arrPossibleMatches addObjectsFromArray:self.item.possibleMatches];
                
                [self.delegate showPossibleMatches:arrPossibleMatches withSelectedItem:self.item];
            }
        }
    }
}

- (void) hideSuggestionButton {
    [_buttonShowMatches setHidden:YES];
    [NSLayoutConstraint activateConstraints:constraintsForHiddenSuggestions];
    [NSLayoutConstraint deactivateConstraints:constraintsForShownSuggestions];
}

- (void) showSuggestionButton {
    if(_canShowMatches) {
        [_buttonShowMatches setHidden:NO];
        [NSLayoutConstraint activateConstraints:constraintsForShownSuggestions];
        [NSLayoutConstraint deactivateConstraints:constraintsForHiddenSuggestions];
    }
}

@end
