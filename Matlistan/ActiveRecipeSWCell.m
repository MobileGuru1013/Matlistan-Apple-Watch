//
//  ActiveRecipeSWCell.m
//  MatListan
//
//  Created by Yan Zhang on 23/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ActiveRecipeSWCell.h"

@implementation ActiveRecipeSWCell

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

@end
