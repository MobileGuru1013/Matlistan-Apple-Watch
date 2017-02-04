//
//  NavigationControllerViewController.m
//  MatListan
//
//  Created by Yan Zhang on 03/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "NavigationControllerViewController.h"
//Replaced refrosted - Markus
#import "SWRevealViewController.h"

@interface NavigationControllerViewController ()


@end

@implementation NavigationControllerViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.revealViewController action:@selector(rightRevealToggle:)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer.enabled = NO;
    
    SWRevealViewController *revealController = self.revealViewController;
    revealController.delegate = self;
    
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    
    //[self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)]];

}

#pragma mark -Gesture recognizer

- (void)panGestureRecognized:(UIPanGestureRecognizer *)sender
{
    //TODO this is not being used
    //[self.frostedViewController panGestureRecognized:sender];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SWRevealViewController Delegate Methods

- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position
{
    if (position == FrontViewPositionRight) {               // Menu will get revealed
        self.tapGestureRecognizer.enabled = YES;                 // Enable the tap gesture Recognizer
        self.interactivePopGestureRecognizer.enabled = NO;        // Prevents the iOS7's pan gesture
        self.topViewController.view.userInteractionEnabled = NO;       // Disable the topViewController's interaction
    }
    else if (position == FrontViewPositionLeft){      // Menu will close
        self.tapGestureRecognizer.enabled = NO;
        self.interactivePopGestureRecognizer.enabled = YES;
        self.topViewController.view.userInteractionEnabled = YES;
    }
}
@end
