//
//  RecipeCustomCell.h
//  Matlistan
//
//  Created by hemal on 02/11/15.
//  Copyright © 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecipeCustomCell : UITableViewCell
{
    
}
@property (weak, nonatomic) IBOutlet UIImageView *recipeImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic,retain) NSNumber *recipeId;
@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ratingImageView;
@property (weak, nonatomic) IBOutlet UIButton *expandbutton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) IBOutlet UIButton *planBtn;
@property (strong, nonatomic) IBOutlet UIButton *editBtn;
@property (strong, nonatomic) IBOutlet UIButton *deleteBtn;
@end
