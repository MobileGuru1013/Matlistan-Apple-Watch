//
//  ActiveRecipeSWCell.h
//  MatListan
//
//  Created by Yan Zhang on 23/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActiveRecipeSWCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *recipeImageView;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDetail;
@property (nonatomic,retain) NSNumber *activeRecipeId;
@property (nonatomic,retain) NSNumber *recipeId;

// Dimple 8-10-15
@property (weak, nonatomic) IBOutlet UIButton *expandViewBtn;
@property (weak, nonatomic) IBOutlet UIButton *boughtBtn;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIButton *cookedBtn;

@property (weak, nonatomic) IBOutlet UIImageView *boughtImg;
@property (weak, nonatomic) IBOutlet UIImageView *editImg;
@property (weak, nonatomic) IBOutlet UIImageView *deleteImg;
@property (weak, nonatomic) IBOutlet UIImageView *cookedImg;

@property (weak, nonatomic) IBOutlet UILabel *boughtLbl;
@property (weak, nonatomic) IBOutlet UILabel *editLbl;
@property (weak, nonatomic) IBOutlet UILabel *deleteLbl;
@property (weak, nonatomic) IBOutlet UILabel *cookedLbl;

@property (weak, nonatomic) IBOutlet UILabel *Occasion_label;
@property (strong,nonatomic)IBOutlet UIView *expanded_view;
@end
