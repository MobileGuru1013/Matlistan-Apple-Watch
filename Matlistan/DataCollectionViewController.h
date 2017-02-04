//
//  DataCollectionViewController.h
//  Matlistan
//
//  Created by Yousuf on 10/20/15.
//  Copyright © 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataCollectionViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *dataCollectionTable;

@end
