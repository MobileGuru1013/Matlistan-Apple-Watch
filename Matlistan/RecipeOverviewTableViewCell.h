//
//  RecipeOverviewTableViewCell.h
//  MatListan
//
//  Created by Yan Zhang on 19/06/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecipeOverviewTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *recipeImageView;
@property (weak, nonatomic) IBOutlet UILabel *labelSource;
@property (weak, nonatomic) IBOutlet UIButton *buttonSource;
@property (weak, nonatomic) IBOutlet UILabel *labelPortionTime;
@property (weak, nonatomic) IBOutlet UILabel *labelTag;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@end
