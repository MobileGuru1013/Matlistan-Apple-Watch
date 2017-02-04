//
//  ItemCustomCell.h
//  Matlistan
//
//  Created by hemal on 28/10/15.
//  Copyright © 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item.h"
@class ItemCustomCell;
@protocol PossibleMatchesCellDelegate <NSObject>

@optional

- (void)showPossibleMatches:(NSMutableArray *)arrPossibleMatches withSelectedItem:(id)selectedItem;

@end

@interface ItemCustomCell : UITableViewCell
{
}
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *btnPossibleMatches;
@property (weak, nonatomic) IBOutlet UIButton *btnAddSuggestion;
@property (weak, nonatomic) IBOutlet UIImageView *pinImage;
@property (strong, nonatomic) IBOutlet UIButton *editBtn;
@property (strong, nonatomic) IBOutlet UIButton *deleteBtn;
@property (strong, nonatomic) IBOutlet UIButton *moveBtn;
@property (strong, nonatomic) IBOutlet UIButton *copytoBtn;

@property (nonatomic,retain) NSNumber *itemId;
@property (nonatomic,retain) NSManagedObjectID *itemObjectId;

@property (nonatomic, strong) Item *cellItem;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pinImageTrailingConstraint;



@property (weak, nonatomic) IBOutlet UIView *expandedView;

@property (nonatomic, weak) id <PossibleMatchesCellDelegate> delegate;
- (IBAction)btnPossibleMatches_Pressed:(UIButton *)sender;
@end
