//
//  ItemTableViewViewController.h
//  Matlistan
//
//  Created by hemal on 28/10/15.
//  Copyright © 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemCustomCell.h"
#import "SWRevealViewController.h"

@interface ItemTableViewViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    ItemCustomCell *cell;
}
-(IBAction)Backbtn:(id)sender;
@end
