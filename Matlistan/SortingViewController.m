//
//  SortingViewController.m
//  MatListan
//
//  Created by Yan Zhang on 10/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "SortingViewController.h"
#import "DataStore.h"
@interface SortingViewController ()

@end

@implementation SortingViewController
@synthesize button1,button2,button3,button4;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navbar.topItem.title = NSLocalizedString(@"Choose sorting order", nil);
    [button1 setTitle:NSLocalizedString(@"Latest Top", nil) forState:UIControlStateNormal];
    [button2 setTitle:NSLocalizedString(@"Alphabetically", nil) forState:UIControlStateNormal];
    [button3 setTitle:NSLocalizedString(@"By Category", nil) forState:UIControlStateNormal];
    [button4 setTitle:NSLocalizedString(@"Sort By Store", nil) forState:UIControlStateNormal];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onClickButton1:(id)sender {
    [self setSortingOrder:DATE];
}

- (IBAction)onClickButton2:(id)sender {
    [self setSortingOrder:DEFAULT];
}

- (IBAction)onClickButton3:(id)sender {
    [self setSortingOrder:GROUPED];
}

- (IBAction)onClickButton4:(id)sender {
    [self setSortingOrder:STORE];
   
}
-(void)setSortingOrder:(SORT_TYPE)type{
    [DataStore instance].sortingOrder = type;
    [self dismissViewControllerAnimated:YES completion:Nil];
}

@end
