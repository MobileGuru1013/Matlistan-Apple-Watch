//
//  LinkedAccountsViewController.h
//  Matlistan
//
//  Created by Muhammad Yousuf Saif on 9/1/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MatlistanHTTPClient.h"

@interface LinkedAccountsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MatlistanHTTPClientDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *addAccountButton;

@property (nonatomic, weak) IBOutlet UITableView *accountsTable;

@property (nonatomic, strong) NSMutableArray *arrLinkedAccounts;

@end
