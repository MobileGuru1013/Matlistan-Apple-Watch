//
//  ShoppingListsTableViewController.h
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "MatlistanHTTPClient.h"
#import "SyncEngine.h"
#import "SWTableViewCell.h"

@interface ShoppingListsTableViewController : UITableViewController<ADBannerViewDelegate,UITextFieldDelegate,MatlistanHTTPClientDelegate,SyncEngineDelegate,SWTableViewCellDelegate>
//@property (strong, nonatomic, getter=theNewItemName) NSString *newItemNameFromRecipe; //this is added from active and all Recipe view controllers."new" is not allowed to use as a variable name in obj-C
-(UIView *)customSnapshotFromView:(UIView *)inputView;
@end
