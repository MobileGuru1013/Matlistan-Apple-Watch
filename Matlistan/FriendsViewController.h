//
//  LinkAccountViewController.h
//  Matlistan
//
//  Created by Muhammad Yousuf Saif on 9/2/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FriendsViewController : UIViewController

@property (nonatomic, strong) NSArray *arrFBFriends;

@property (nonatomic, weak) IBOutlet UITableView *friendsTableView;

@end
