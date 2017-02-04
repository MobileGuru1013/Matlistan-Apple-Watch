//
//  SortTableViewController.h
//  MatListan
//
//  Created by Yan Zhang on 10/02/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item+Extra.h"
#import "Item_list+Extra.h"
#import "DataStore.h"
#import "MatlistanHTTPClient.h"
#import "ItemCell.h"
#import "SyncManager.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface SortTableViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,GADBannerViewDelegate,SyncManagerDelegate>
{
    int gesture_rcgn;
}
@property (nonatomic,retain)  NSMutableArray *itemsList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;

-(void)adjustTitleLabelForKnowText:(UILabel *)labelIn withItem:(Item *)itemIn withFountSize:(CGFloat) fontSizeIn;


//Dimple 17-11-2015
@property BOOL is_sorttype;

- (IBAction)showHelp:(id)sender;


@end
