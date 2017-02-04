//
//  CustomCell.h
//  RevealTableCell
//
//  Created by Shan.
//  Copyright (c) 2014 Shan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CustomCell;
@protocol CellDelegate <NSObject>
@end

@interface CustomCell : UITableViewCell
{
    
}
//@property (nonatomic, retain) UIView *optionsView; //this is your options to show when swiped
@property (nonatomic, retain) IBOutlet UIView *mainVIew; //this is your view by default present on top of options view
@property (nonatomic, retain) IBOutlet UILabel *recipeTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *recipeTimerLabel;
@property (nonatomic, retain) IBOutlet UIButton *stopTimerButton;
@property (nonatomic, retain) IBOutlet UIButton *showRecipeButton;
@property (nonatomic, retain) IBOutlet UIButton *addMinuteButton;
@property (nonatomic, retain) IBOutlet UIButton *bgButton;


@property (nonatomic, assign) id <CellDelegate> cellDelegate;
@property (nonatomic, assign) BOOL isShowingEditButtons;
@property (nonatomic, assign) UIButton *expandBtn;
@end
