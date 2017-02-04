//
//  RecipeCellView.h
//  MatListan
//
//  Created by Yan Zhang on 13/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+AFNetworking.h"

@interface RecipeCellView : UIView

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *button;
@property (strong, nonatomic) IBOutlet UIButton *manButton;
@property (nonatomic)BOOL didSetupConstraints;
@end
