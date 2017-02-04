//
//  NavigationControllerViewController.h
//  MatListan
//
//  Created by Yan Zhang on 03/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
//Replaced refrosted - Markus
#import "SWRevealViewController.h"

@interface NavigationControllerViewController : UINavigationController <UIGestureRecognizerDelegate, SWRevealViewControllerDelegate>

- (void)panGestureRecognized:(UIPanGestureRecognizer *)sender;


@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@end
