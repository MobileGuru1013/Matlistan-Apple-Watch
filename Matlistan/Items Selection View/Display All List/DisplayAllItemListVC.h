//
//  DisplayAllItemListVC.h
//  Matlistan
//
//  Created by Leocan on 2/26/16.
//  Copyright (c) 2016 Consumiq AB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item_list.h"
#import "Item_list+Extra.h"
#import "Item.h"
@interface DisplayAllItemListVC : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray *allListArr;
    int tbl_height;
    DataStore *dataStore;
    NSNumber *currentListId;
}
@property(strong,nonatomic) IBOutlet UITableView *table_view;
@property(strong,nonatomic) IBOutlet UIButton *cancelBtn;
@property(strong,nonatomic) NSArray *selectedItemsArr;
@property(strong,nonatomic) NSString *screenName;
@property(strong,nonatomic) Item *selectedItem;
@property(strong,nonatomic) IBOutlet UILabel *headerLbl;
-(IBAction)onclick_cancel:(id)sender;
@end
