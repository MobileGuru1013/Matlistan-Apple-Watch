//
//  RootViewController.m
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "RootViewController.h"
#import "DataStore.h"

@interface RootViewController ()

@property(strong) MatlistanHTTPClient *client;
@end

@implementation RootViewController

@synthesize client;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)awakeFromNib
{
    [super awakeFromNib];
    self.frontViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"contentController"];
    self.rearViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"menuController"];
    //self.contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"contentController"];
    //self.menuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"menuController"];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    //[self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
