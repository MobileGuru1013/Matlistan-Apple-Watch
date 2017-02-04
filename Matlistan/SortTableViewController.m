//
//  SortTableViewController.m
//  MatListan
//
//  Created by Yan Zhang on 10/02/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "SortTableViewController.h"
#import "HelpDialogManager.h"

#define ANIMATION_DURATION 0.1

@interface SortTableViewController ()
{
    NSNumber *currentListId;
    NSMutableArray *groupByCategotyArr,*finalArr;
    NSString *grouped_itemTitle,*old_cat,*new_cat;
    Item *itemByCategoty;


}
@end

@implementation SortTableViewController
@synthesize  itemsList;

#pragma mark- Category wise create grouped
-(void)getItemsByCategory
{
  
    for(int i=0;i<itemsList.count;i++)
    {
        Item *item1=itemsList[i];
        old_cat=item1.placeCategory;

        if(item1.groupedText.length>0 && item1.groupedText!=nil && ![item1.groupedText isEqualToString:@""])
        {
            grouped_itemTitle=item1.groupedText;
        }
        else
        {
            grouped_itemTitle=item1.text;
        }
        if(old_cat==nil)
        {
            old_cat=@"";
        }
        if([old_cat isEqualToString:@""])
        {
            //add into dictionary
            NSDictionary *paramsDic=[[NSDictionary alloc] initWithObjectsAndKeys:
                                     grouped_itemTitle, @"item_text",
                                     old_cat, @"item_cat",
                                     item1.itemID, @"item_id",
                                     nil
                                     ];
            [groupByCategotyArr addObject:paramsDic];
            grouped_itemTitle=@"";
        }
        else
        {
            if(i==itemsList.count-1)
            {
              NSDictionary *paramsDic=[[NSDictionary alloc] initWithObjectsAndKeys:
                           grouped_itemTitle, @"item_text",
                           old_cat, @"item_cat",
                           item1.itemID, @"item_id",
                           nil
                           ];
                 [groupByCategotyArr addObject:paramsDic];
            }
            else
            {
                for(int j=i+1;j<itemsList.count;j++)
                {
                    Item *item2=itemsList[j];
                    new_cat=item2.placeCategory;
                    int flag=0;
                   
                    if([old_cat isEqualToString:new_cat])
                    {
                        //add item title into comma sep string
                        grouped_itemTitle=[NSString stringWithFormat:@"%@,%@",grouped_itemTitle,item2.groupedText];
                        flag=1;
                        i++;
                        if(i==itemsList.count-1)
                        {
                            NSDictionary *paramsDic=[[NSDictionary alloc] initWithObjectsAndKeys:
                                       grouped_itemTitle, @"item_text",
                                       old_cat, @"item_cat",
                                       item2.itemID, @"item_id",
                                       nil
                                       ];
                            [groupByCategotyArr addObject:paramsDic];
 
                        }
                    }
                    else
                    {
                        NSDictionary *paramsDic;
                        if(flag==0)
                        {
                            paramsDic=[[NSDictionary alloc] initWithObjectsAndKeys:
                                                     grouped_itemTitle, @"item_text",
                                                     old_cat, @"item_cat",
                                                     item1.itemID, @"item_id",
                                                     nil
                                                     ];
                        }
                        else
                        {
                            paramsDic=[[NSDictionary alloc] initWithObjectsAndKeys:
                                                 grouped_itemTitle, @"item_text",
                                                 old_cat, @"item_cat",
                                                 item2.itemID, @"item_id",
                                                 nil
                                                 ];
                           
                        }
                        [groupByCategotyArr addObject:paramsDic];
                        break;
                    }
                    
                }
            }
        }
        
    }

}

- (void)viewDidLoad {
    [super viewDidLoad];
    groupByCategotyArr=[[NSMutableArray alloc]init];
    finalArr=[[NSMutableArray alloc]init];

    [self getItemsByCategory];
    gesture_rcgn=0;
    [SyncManager sharedManager].syncManagerDelegate = self;
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(wakeUp:) name: @"UpdateUINotification" object: nil];
    
    currentListId = [DataStore instance].currentList.item_listID;
  //  [self.tableView setEditing:YES animated:YES];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
    if(IS_IPHONE)
    {
        self.tableView.estimatedRowHeight = 40.0;
    }
    else
    {
        self.tableView.estimatedRowHeight = 90.0;
    }
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing SortTableViewController");
    [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        //[self removeAds];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_TO_REMOVE_ADS * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                       {
                           [self removeAds];
                       });
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if(gesture_rcgn==1)
    {
        //Dimple :19-10-2015
        [self updateAllItemsManualIndex];
    }
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPremiumAccountPurchased object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateUINotification" object:nil];
}

/**
 Remove ads if user has purchased premium
 @ModifiedDate: October 7 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)removeAds
{
    if (self.bannerView)
    {
        [self.bannerView removeConstraints:self.bannerView.constraints];
        [self.bannerView removeFromSuperview];
        
        [Utility updateConstraint:self.view toView:self.tableView withConstant:0];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if(IS_IPHONE)
//    {
//        return UITableViewAutomaticDimension;
//    }
//    else
//    {
//        return 70;
//    }
//}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    // To "clear" the footer view
    return [UIView new];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    if(self.is_sorttype)
    {
        return groupByCategotyArr.count;
    }
    else
    {
        return itemsList.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell...
    ItemCell *cell = (ItemCell*)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
     UILabel *label = (UILabel *) [cell viewWithTag:1];
    Item *item;
    if(self.is_sorttype)
    {
        NSDictionary *final_dic=[groupByCategotyArr objectAtIndex:indexPath.row];
        NSString *main_string=[final_dic objectForKey:@"item_text"];
        NSString *displyText=[self itemSeperatorByComma:main_string];
        label.text =displyText;
    }
    else
    {
        if ([itemsList count] > indexPath.row) {
            item = [itemsList objectAtIndex:indexPath.row];
            if (item != nil) {
                cell.itemId = item.itemID;
                cell.itemObjectId = item.objectID;
                label.text = [NSString stringWithFormat:@"%@", item.text];
                
            }
        }
    }
    if(IS_IPHONE)
    {
        [self adjustTitleLabelForKnowText:label withItem:item withFountSize:14.0f];
    }
    else
    {
        [self adjustTitleLabelForKnowText:label withItem:item withFountSize:20.0f];
    }
    if(indexPath.row%2==0)
    {
        cell.backgroundColor=CELL_BG_COLOR;
    }
    else
    {
        cell.backgroundColor=[UIColor whiteColor];
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    gesture_rcgn=1;
    if(self.is_sorttype)
    {
        id object = [groupByCategotyArr objectAtIndex:fromIndexPath.row];
        [groupByCategotyArr removeObjectAtIndex:fromIndexPath.row];
        [groupByCategotyArr insertObject:object atIndex:toIndexPath.row];
    }
    else
    {
        id object = [self.itemsList objectAtIndex:fromIndexPath.row];
        [itemsList removeObjectAtIndex:fromIndexPath.row];
        [itemsList insertObject:object atIndex:toIndexPath.row];
    }
}
//- (IBAction)longPressGestureRecognized:(id)sender {
//    
//    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
//    UIGestureRecognizerState state = longPress.state;
//    
//    CGPoint location = [longPress locationInView:self.tableView];
//    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
//    
//    static UIView       *snapshot = nil;        ///< A snapshot of the row user is moving.
//    static NSIndexPath  *sourceIndexPath = nil; ///< Initial index path, where gesture begins.
//    
//    switch (state) {
//        case UIGestureRecognizerStateBegan: {
//            if (indexPath) {
//                sourceIndexPath = indexPath;
//                
//                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//                
//                // Take a snapshot of the selected row using helper method.
//                snapshot = [self customSnapshotFromView:cell];
//                
//                // Add the snapshot as subview, centered at cell's center...
//                __block CGPoint center = cell.center;
//                snapshot.center = center;
//                snapshot.alpha = 0.0;
//                [self.tableView addSubview:snapshot];
//                [UIView animateWithDuration:ANIMATION_DURATION animations:^{
//                    
//                    // Offset for gesture location.
//                    center.y = location.y;
//                    snapshot.center = center;
//                    snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
//                    snapshot.alpha = 0.98;
//                    
//                } completion:^(BOOL finished) {
//                    
//                }];
//            }
//            break;
//        }
//        case UIGestureRecognizerStateChanged: {
//            CGPoint center = snapshot.center;
//            center.y = location.y;
//            snapshot.center = center;
//            
//            // Is destination valid and is it different from source?
//            if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
//                DLog(@"Gesture: destination is valid, update core data");
//                // update data source.
//                if(self.is_sorttype)
//                {
//                    //[Utility SetSortName:nil];
//                    [groupByCategotyArr exchangeObjectAtIndex:indexPath.row withObjectAtIndex:sourceIndexPath.row];
//                }
//                else
//                {
//                    [itemsList exchangeObjectAtIndex:indexPath.row withObjectAtIndex:sourceIndexPath.row];
//                }
//                
//                //Dimple :19-10-2015
//                gesture_rcgn=1;
//                //[self updateAllItemsManualIndex];  // update all index in core data and sync with server
//                // move the rows.
//                [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
//                
//                // and update source so it is in sync with UI changes.
//                sourceIndexPath = indexPath;
//            }
//            break;
//        }
//        default: {
//            // Clean up
//            DLog(@"Gesture: default");
//            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
//            cell.hidden = NO;
//            cell.alpha = 0.0;
//            //NOTICE: the animation duration must be small enough so that the snapshot completion is not shown. Otherwise, a cell can be thrown away if move fast
//            [UIView animateWithDuration:ANIMATION_DURATION animations:^{
//                
//                snapshot.center = cell.center;
//                snapshot.transform = CGAffineTransformIdentity;
//                snapshot.alpha = 0.0;
//                
//                // Undo fade out.
//                cell.alpha = 1.0;
//                
//            } completion:^(BOOL finished) {
//                
//                sourceIndexPath = nil;
//                [snapshot removeFromSuperview];
//                snapshot = nil;
//                
//            }];
//            break;
//        }
//            
//    }
//}

-(void)updateAllItemsManualIndex{
   
   [DataStore instance].sortingOrder = MANUAL;
    
    [Item_list changeList:[DataStore instance].currentList byNewOrder:MANUAL andStoreID:@0];  //update database
    NSMutableArray *sortedIDs = [[NSMutableArray alloc]init];

    if(self.is_sorttype)
    {
        int index=0;
        for(int i=0;i<groupByCategotyArr.count;i++)
        {
            
            NSDictionary *dic1=groupByCategotyArr[i];
            NSString *cat1=[dic1 objectForKey:@"item_cat"];
           // NSNumber* id1=[dic1 objectForKey:@"item_id"];
            NSString* id1=[dic1 objectForKey:@"item_id"];
            
            int flag=0;
            if([cat1 isEqualToString:@""])
            {
                //NSNumber* id2;
                NSString* id2;
                for(int j=0;j<itemsList.count; j++)
                {
                    Item *item2=itemsList[j];
                    id2=[NSString stringWithFormat:@"%@",item2.itemID];

                    if([id1 intValue]==[id2 intValue])
                    {
                        Item *item = [itemsList objectAtIndex:j];
                        if (item.itemID != nil && [item.itemID intValue] != 0) {
                            [Item updateItem:item.itemID WithManualIndex:index];
                            index++;
                            [sortedIDs addObject:item.itemID];
                            break;
                        }
                        
                    } //EOF IF
                    
                } //EOF For j
                
            }
            else
            {
                for(int j=0;j<itemsList.count; j++)
                {
                    Item *item2=itemsList[j];
                    NSString * cat2= item2.placeCategory;

                    if([cat1 isEqualToString:cat2] && ![cat1 isEqualToString:@""] && cat2 !=nil)
                    {
                        Item *item = [itemsList objectAtIndex:j];
                        if (item.itemID != nil && [item.itemID intValue] != 0) {
                            [Item updateItem:item.itemID WithManualIndex:index];
                            flag=1;
                            index++;
                            [sortedIDs addObject:item.itemID];
                        }
                        
                    } //EOF IF
                    else
                    {
                        // Category not blank and not same
                        
                   
                            if(flag==0)
                            {
                                for(int k=0;k<itemsList.count; k++)
                                {
                                    Item *item2=itemsList[k];
                                   
                                    NSString* id2= [NSString stringWithFormat:@"%@",item2.itemID];
                                    if([id1 intValue]==[id2 intValue])
                                    {
                                        Item *item = [itemsList objectAtIndex:k];
                                        if (item.itemID != nil && [item.itemID intValue] != 0) {
                                            [Item updateItem:item.itemID WithManualIndex:index];
                                            index++;
                                            [sortedIDs addObject:item.itemID];
                                            break;  // K loop break
                                        }
                                        
                                    } //EOF IF
                                    
                                } //EOF For k
                            }
                       // break;  // J loop break
                        
                    } // inner else
                    
                } //EOF For j
            }// EOF Else
            
            
            
        } // EOF For i

    }
    else
    {
        for (int i=0; i<itemsList.count; i++)
        {
            
            Item *item = [itemsList objectAtIndex:i];
            if (item.itemID != nil && [item.itemID intValue] != 0) {
                [Item updateItem:item.itemID WithManualIndex:i];
                [sortedIDs addObject:item.itemID];
            }
        }
    }
    [Item_list setManualSortOrderSyncStatusFor:[DataStore instance].currentList to:Created];
    [[SyncManager sharedManager] forceSync];

}

//TO DO: test this with network, resend if failed and when there is network

-(void)sendManualSortingToServer:(NSMutableArray*)sortedIDs{
    /*
    NSString *request = @"Items/ManualSort";
    NSDictionary *parameters = @{@"listId":currentListId,
                                 @"sortedIds": sortedIDs,
                                 @"basedOnSortOrder": @"Manual"
                                 };
    MatlistanHTTPClient *httpClient = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    [httpClient PUT:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        DLog(@"Sent manual sortedIDs for list %@",currentListId);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to send manual sortedIDs for list %@",currentListId);
    }];
    */
}

#pragma mark - Helper methods

/** @brief Returns a customized snapshot of a given view. */
- (UIView *)customSnapshotFromView:(UIView *)inputView {
    
    UIView *snapshot = [inputView snapshotViewAfterScreenUpdates:YES];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
}
#pragma mark - other Methods
-(void)adjustTitleLabelForKnowText:(UILabel *)labelIn withItem:(Item *)itemIn withFountSize:(CGFloat) fontSizeIn {
    if ([labelIn respondsToSelector:@selector(setAttributedText:)]) {
        UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSizeIn];
        UIFont *regularFont = [UIFont systemFontOfSize:fontSizeIn];
        UIColor *foregroundColor = [UIColor blackColor];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName,foregroundColor, NSForegroundColorAttributeName, nil];
        NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, nil];

        if (labelIn.text != nil && itemIn.knownItemText != nil) {
            const NSRange range = [labelIn.text rangeOfString:itemIn.knownItemText];

            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:labelIn.text attributes:attrs];
            [attributedText setAttributes:subAttrs range:range];

            [labelIn setAttributedText:attributedText];
        }
    }
}
#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [self.bannerView setAlpha:1];
    [UIView commitAnimations];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [self.bannerView setAlpha:0];
    [UIView commitAnimations];
}
-(void)didUpdateItems
{
    //DLog(@"get updated items from server");
    NSMutableArray *allItems = [NSMutableArray arrayWithArray:[Item getItemsToBuyFromList:[DataStore instance].currentList.item_listID andList:[DataStore instance].currentList andSortInOrder:[DataStore instance].sortingOrder]];
    itemsList=allItems;
    
//        for(int i=0;i<itemsList.count;i++)
//        {
//            Item *item = [itemsList objectAtIndex:i];
//            DLog(@"Sorted Item %@",item.text);
//        }
    [self.tableView reloadData];
    
}

- (void) wakeUp: (NSNotification*)notification {
    [SyncManager sharedManager].syncManagerDelegate = self;
    [self didUpdateItems];
}

- (IBAction)showHelp:(id)sender {
    [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self force:YES];
}
#pragma mark- Remove Duplicate  items
-(NSString*)itemSeperatorByComma:(NSString*)main_str
{
    NSString *seperated_str=@"";
    NSString *old_str,*new_str;
    
    if([main_str rangeOfString:@","].location!=NSNotFound)
    {
        NSArray *splitArr = [main_str componentsSeparatedByString:@","];
        for(int i=0;i<splitArr.count;i++)
        {
            NSString *trimmedString = [splitArr[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            new_str=trimmedString;
            if(![old_str isEqualToString:new_str])
            {
                seperated_str=[NSString stringWithFormat:@"%@, %@",seperated_str,new_str];
                old_str=splitArr[i];
            }
            else if([seperated_str rangeOfString:@","].location!=NSNotFound)
            {
                if([seperated_str rangeOfString:[NSString stringWithFormat:@", %@",new_str]].location==NSNotFound)
                {
                    seperated_str=[NSString stringWithFormat:@"%@, %@",seperated_str,new_str];
                    old_str=splitArr[i];
                }
            }
        }
    }
    else
    {
        seperated_str=main_str;
    }
    if([[seperated_str substringFromIndex:0] rangeOfString:@","].location!=NSNotFound)
    {
        seperated_str =[seperated_str substringFromIndex:1];
        seperated_str = [seperated_str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
    }
    return seperated_str;
}

@end
