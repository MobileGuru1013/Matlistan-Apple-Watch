//
//  IntroViewController.h
//  MatListan
//
//  Created by Markus Tenghamn on 07/06/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface IntroViewController : UIViewController
{
    CALayer *BottomBorder;
}
@property (weak, nonatomic) IBOutlet UIButton *contiBtn;
@property IBOutlet UILabel *intro1Label;
@property IBOutlet UITextView *intro2Label;
@property IBOutlet UIButton *readMoreButton;
@property(strong,nonatomic) IBOutlet UIView *headerView;
@property(strong,nonatomic) IBOutlet UILabel *headerTitle;
@property(strong,nonatomic) IBOutlet UIImageView *iconImg;
@property(strong,nonatomic) IBOutlet UIScrollView *scrollview;
@property(strong,nonatomic) IBOutlet UILabel *seperatorline;

- (IBAction)readMoreButtonClick:(id)sender;


@end
