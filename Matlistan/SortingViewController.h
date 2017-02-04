//
//  SortingViewController.h
//  MatListan
//
//  Created by Yan Zhang on 10/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SortingViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@property (weak, nonatomic) IBOutlet UIButton *button3;
@property (weak, nonatomic) IBOutlet UIButton *button4;
- (IBAction)onClickButton1:(id)sender;
- (IBAction)onClickButton2:(id)sender;
- (IBAction)onClickButton3:(id)sender;

- (IBAction)onClickButton4:(id)sender;
@property (weak, nonatomic) IBOutlet UINavigationBar *navbar;

@end
