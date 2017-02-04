//
//  ShoppingTableViewCell.h
//  MatListan
//
//  Created by Yan Zhang on 09/02/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item.h"
@class ShoppingTableViewCell;
@protocol ShoppingTableViewCellProtocol <NSObject>

- (void)shoppingTableViewCellButtonPressed:(ShoppingTableViewCell *)shoppingCell;
- (void)showPossibleMatches:(NSMutableArray *)arrPossibleMatches withSelectedItem:(id)selectedItem;

@end

@interface ShoppingTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelItemTitle;
@property (weak, nonatomic) IBOutlet UIButton *buttonCheckReason;
@property (weak, nonatomic) IBOutlet UIButton *buttonShowMatches;
@property (nonatomic,retain) Item *item;
@property (nonatomic, retain) UIColor *nonCheckedBackgroundColor;
@property BOOL canShowMatches;

- (IBAction)btnPossibleMatchesPressed:(UIButton *)sender;

@property (nonatomic,assign) id <ShoppingTableViewCellProtocol> delegate;

- (void) hideSuggestionButton;
- (void) showSuggestionButton;

@end
