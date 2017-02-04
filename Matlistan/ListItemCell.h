//
//  listItemCell.h
//  MatListan
//
//  Created by Yan Zhang on 07/12/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "SWTableViewCell.h"

@interface ListItemCell : SWTableViewCell

@property (weak,nonatomic) IBOutlet UILabel *titleLabel;
@property (weak,nonatomic) IBOutlet UIButton *button;
@property (nonatomic,retain) NSNumber *listID;


//Dimple
@property(strong,nonatomic) IBOutlet UIButton *deleteBtn;

@end
