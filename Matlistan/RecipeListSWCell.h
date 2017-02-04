//
//  RecipeListSWCell.h
//  MatListan
//
//  Created by Yan Zhang on 25/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecipeListSWCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *recipeImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic,retain) NSNumber *recipeId;
@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ratingImageView;
@property (weak, nonatomic) IBOutlet UIButton *expandbutton;

@end
