//
//  ItemsSelectionViewVC.m
//  Matlistan
//
//  Created by Leocan on 2/24/16.
//  Copyright (c) 2016 Consumiq AB. All rights reserved.
//

#import "ItemsSelectionViewVC.h"


#define UNSORTED_SECTION_Vist_Store 0
#define SORTED_SECTION_Visit_Store 1
#define REMOVED_SECTION_Visit_Store 2

@interface ItemsSelectionViewVC ()

@end

@implementation ItemsSelectionViewVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self SetControlPosition];
    selectedRowsArray=[[NSMutableArray alloc]init];
    popupArr=[[NSMutableArray alloc]init];
    popupArr=[[NSMutableArray alloc]initWithObjects:@{@"menuItem":NSLocalizedString(@"Copy to", nil)},@{@"menuItem":NSLocalizedString(@"Move", nil)},@{@"menuItem":NSLocalizedString(@"Select all", nil)},nil];

    dataStore = [DataStore instance];
    client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    [SyncManager sharedManager].syncManagerDelegate = self;
    
    if (dataStore.sortingOrder == STORE)
    {
        [self getSortedItemsByStoreFromServer];
    }
    else
    {
        toBuyItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:NO]];
        [self DisplayCategorywiseColor];
        [self.table_view reloadData];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    __block Item *item=nil;
    NSIndexPath *indexPath =nil;
    
    int section=0;
    if ([DataStore instance].sortingOrder == STORE)
    {
        if(unknownItems.count>0 && sortedItems.count>0)
        {
            if([self.sectionName isEqualToString:@"UNSORTED_SECTION"])
            {
                 section=0;
            }
            else
            {
                section=1;
            }
        }
        else if(unknownItems.count>0 ||sortedItems.count>0)
        {
             section=0;
        }
        else
        {
             section=0;
        }
        
        if (unknownItems.count>0 && [self.sectionName isEqualToString:@"UNSORTED_SECTION"])
        {
//            item=[unknownItems objectAtIndex:self.scrollToIndex.row];
            [unknownItems enumerateObjectsUsingBlock:^(Item  *obj, NSUInteger idx, BOOL *found) {
                if([obj.itemID isEqualToNumber:self.item_id])
                {
                    item=obj;
                    matichingItemIndex=idx;
                    *found=YES;
                }
            }];
        }
        else if (sortedItems.count>0 && [self.sectionName isEqualToString:@"SORTED_SECTION"])
        {
//            item=[sortedItems objectAtIndex:self.scrollToIndex.row];
            [sortedItems enumerateObjectsUsingBlock:^(Item  *obj, NSUInteger idx, BOOL *found) {
                if([obj.itemID isEqualToNumber:self.item_id])
                {
                    item=obj;
                    matichingItemIndex=idx;
                    *found=YES;
                }
            }];
        }
    }
    else
    {
        if (toBuyItems.count>0)
        {
//            item=[toBuyItems objectAtIndex:self.scrollToIndex.row];
            [toBuyItems enumerateObjectsUsingBlock:^(Item  *obj, NSUInteger idx, BOOL *found) {
                if([obj.itemID isEqualToNumber:self.item_id])
                {
                    item=obj;
                    matichingItemIndex=idx;
                    *found=YES;
                }
            }];
        }
    }
    indexPath = [NSIndexPath indexPathForRow:matichingItemIndex inSection:section];
    if(item!=nil)
    {
        [selectedRowsArray addObject:item];
    }
    self.lbl_totalSelectedItems.text=[NSString stringWithFormat:@"%lu",(unsigned long)selectedRowsArray.count];
    [self.table_view reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation: UITableViewRowAnimationNone];
    
    [self.table_view scrollToRowAtIndexPath:indexPath
                           atScrollPosition:UITableViewScrollPositionMiddle
                                   animated:YES];
    


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];

    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }

}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];

}
- (void)removeAds
{
    if (self.bannerView)
    {
        [self.bannerView removeConstraints:self.bannerView.constraints];
        [self.bannerView removeFromSuperview];
        [Utility updateConstraint:self.view toView:self.table_view withConstant:0];
    }
}
#pragma mark- Tableview delegate methods
-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(tableView.tag==1)
    {
        if ([DataStore instance].sortingOrder == STORE) {
            if (section == 0)
            {
                if (unknownItems.count > 0)
                {
                    if(IS_IPHONE)
                    {
                        return 40;
                    }
                    else
                    {
                        return 60;
                    }
                }
                else
                    return 0.0f;
            }
            else if (section == 1)
            {
                if (sortedItems.count > 0)
                {
                    if(IS_IPHONE)
                    {
                        return 40;
                    }
                    else
                    {
                        return 60;
                    }
                }
                else
                    return 0.0f;
            }
            
        }
    }
    else
    {
    }
    return 0;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(tableView.tag==1)
    {
        int font_size1=17,title_lbl_y=0,header_vw_y=5.0;
        if(IS_IPHONE)
        {
            font_size1=17;
            title_lbl_y=0;
            header_vw_y=5.0;
        }
        else
        {
            font_size1=25;
            title_lbl_y=10;
            header_vw_y=10.0;
        }
        if ([DataStore instance].sortingOrder == STORE) {
            sectionNames = @[NSLocalizedString(@"Unsorted items", nil), NSLocalizedString(@"Sorted items", nil)];
            
            NSString *sectionTitle = sectionNames[(NSUInteger) section];
            
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40.0f)];
            [view setBackgroundColor:[Utility getGreenColor]];
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, title_lbl_y, tableView.frame.size.width, 40.0f)];
            [titleLabel setTextAlignment:NSTextAlignmentCenter];
            [titleLabel setTextColor:[UIColor whiteColor]];
            titleLabel.font = [UIFont systemFontOfSize:font_size1];
            titleLabel.text = sectionTitle;
            [view addSubview:titleLabel];
            
            if (section == 0) {
                if (unknownItems.count > 0) {
                    return view;
                }else{
                    [view setFrame:CGRectMake(0.0f, 0.0f, 0, 0.0f)];
                    return view;
                }
                
            }else if (section == 1){
                if (sortedItems.count > 0) {
                    sectionTitle = sectionNames[(NSUInteger) section];
                    titleLabel.text = sectionTitle;
                    return view;
                }else{
                    [view setFrame:CGRectMake(0.0f, 0.0f, 0, 0.0f)];
                    return view;
                }
            }
        }
        else
        {
            UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 5.0, tableView.bounds.size.width, 40.0)];
           
            headerView.backgroundColor = [Utility getGreenColor];
            UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10.0, header_vw_y, tableView.bounds.size.width * 0.86, 30.0)];
            
            // Header label is not center aligned
            [label setTextAlignment:NSTextAlignmentCenter];
            [label setTextColor:[UIColor whiteColor]];
            label.text = NSLocalizedString(@"Taken Items",nil);
            label.font = [UIFont systemFontOfSize:font_size1];
            [headerView addSubview:label];
            return headerView;
        }
    }
    else
    {
        
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag==1)
    {
        if(IS_IPHONE)
        {
            return 44.0f;
        }
        else
        {
            return 70;
        }
    }
    else
    {
        return 44;
    }
    return 0;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView.tag==1)
    {
        if ([DataStore instance].sortingOrder == STORE)
        {
                return 2;
        }
        else
        {
            return 1;
        }
    }
    else
    {
        return 0;
    }
    return 0;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"popupArr.count:%lu",(unsigned long)popupArr.count);
    if(tableView.tag==1)
    {
    
        if ([DataStore instance].sortingOrder == STORE)
        {
            if (section == 0)
            {
                return unknownItems.count;
            }
            else if (section == 1)
            {
                return sortedItems.count;
            }
            
        }
        else
        {
            if (section == 0)
            {
                return toBuyItems.count;
            }
           
        }
    }
    else
    {
        return popupArr.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     Item *theItem=nil;
    int font_size1=14,font_size2=17, item_size=36;
    if(IS_IPHONE)
    {
        font_size1=14;
        font_size2=17;
        item_size=36;
    }
    else
    {
        font_size1=20;
        font_size2=25;
        item_size=72;
    }
   
        ItemsSelectionCell *cell=[tableView dequeueReusableCellWithIdentifier:@"cell"];
        if(cell==nil)
        {
            cell=[[ItemsSelectionCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
            NSArray *menuarray=[[NSBundle mainBundle]loadNibNamed:@"ItemsSelectionCell" owner:self options:nil];
            cell=[menuarray objectAtIndex:0];
        }
    
        NSInteger rowNum = indexPath.row;
        NSString *color=@"";
        
        if ([DataStore instance].sortingOrder == STORE)
        {
            if (indexPath.section == UNSORTED_SECTION_Vist_Store )
            {
                if (rowNum < unknownItems.count)
                {
                    theItem = [unknownItems objectAtIndex:rowNum];
                    color=[UnSortedcolorArr objectAtIndex:indexPath.row];
                    
                }
            }
            else if (indexPath.section == SORTED_SECTION_Visit_Store )
            {
                if (rowNum < sortedItems.count)
                {
                    theItem = [sortedItems objectAtIndex:rowNum];
                    color=[SortedcolorArr objectAtIndex:indexPath.row];
                    
                }
            }
            
        }
        else
        {
            if (indexPath.section == UNSORTED_SECTION_Vist_Store)
            {
                if (rowNum < toBuyItems.count)
                {
                    theItem = [toBuyItems objectAtIndex:rowNum];
                    color=[toBuycolorArr objectAtIndex:indexPath.row];
                    
                }
            }
            
        }

        if([[Utility getSortName] isEqualToString:@"By category"])
        {
            if([color isEqualToString:@"Blue"])
            {
                cell.backgroundColor=lightblueColor;
            }
            else
            {
                cell.backgroundColor=lightgreenColor;
            }
        }
        else{
            if(indexPath.row%2==0)
            {
                cell.backgroundColor=CELL_BG_COLOR;
            }
            else
            {
                cell.backgroundColor=[UIColor whiteColor];
            }
        }

        
        UIImage *is_checked;
        if ([selectedRowsArray containsObject:theItem]) {
            is_checked = [UIImage imageNamed:@"Item_isChecked"];
        }
        else {
            is_checked = [UIImage imageNamed:@"Item_isUnChecked"];
        }
        cell.isCheckedImg.image=is_checked;
        cell.itemName.text=theItem.text;
    NSLog(@"theItem.tex:%@",theItem.text);
    if (theItem.text.length > item_size)
    {
        cell.itemName.numberOfLines = 0;
        [cell.itemName setFont:[UIFont systemFontOfSize:font_size1]];
        
        if(cell.itemName.text != nil || cell.itemName.text.length>0)
        {
            [self adjustTitleLabelForKnowText:cell.itemName withItem:theItem withFountSize:font_size1];
        }
    }
    else
    {
        cell.itemName.numberOfLines = 1;
        [cell.itemName setFont:[UIFont systemFontOfSize:font_size2]];
        if(cell.itemName.text != nil || cell.itemName.text.length>0)
        {
            [self adjustTitleLabelForKnowText:cell.itemName withItem:theItem withFountSize:font_size2];
        }
    }

        cell.selectionStyle=NO;
    
        return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(self.moreBtn.show)
    {
        [self.moreBtn backgroundTapped:nil];
    }
    [self select_deselectItems:indexPath];
}
#pragma mark- check & unchecked items
-(void)select_deselectItems:(NSIndexPath*)indexPath
{
    NSInteger rowNum = indexPath.row;
    Item *theItem;
   
    if ([DataStore instance].sortingOrder == STORE)
    {
        if (indexPath.section == UNSORTED_SECTION_Vist_Store )
        {
            if (rowNum < unknownItems.count)
            {
                theItem = [unknownItems objectAtIndex:rowNum];
                
            }
        }
        else if (indexPath.section == SORTED_SECTION_Visit_Store )
        {
            if (rowNum < sortedItems.count)
            {
                theItem = [sortedItems objectAtIndex:rowNum];
             }
        }
     }
    else
    {
        if (indexPath.section == UNSORTED_SECTION_Vist_Store)
        {
            if (rowNum < toBuyItems.count)
            {
                theItem = [toBuyItems objectAtIndex:rowNum];
            }
        }
        
    }
    
    if ([selectedRowsArray containsObject:theItem]) {
        [selectedRowsArray removeObject:theItem];
    }
    else {
        [selectedRowsArray addObject:theItem];
    }
    
    if(selectedRowsArray.count==0 || selectedRowsArray==nil)
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
    self.lbl_totalSelectedItems.text=[NSString stringWithFormat:@"%lu",selectedRowsArray.count];
    
    
    [self.table_view reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation: UITableViewRowAnimationFade];
}
- (void)adjustTitleLabelForKnowText:(UILabel *)labelIn withItem:(Item *)itemIn withFountSize:(CGFloat) fontSizeIn
{
    if (itemIn.knownItemText && itemIn.knownItemText.length != 0)
    {
        if ([labelIn respondsToSelector:@selector(setAttributedText:)])
        {
            UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSizeIn];
            UIFont *regularFont = [UIFont systemFontOfSize:fontSizeIn];
            UIColor *foregroundColor = [UIColor blackColor];
            
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName,foregroundColor, NSForegroundColorAttributeName, nil];
            NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, nil];
            
            const NSRange range = [labelIn.text rangeOfString:itemIn.knownItemText];
            
            
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:labelIn.text attributes:attrs];
            [attributedText setAttributes:subAttrs range:range];
            
            /*NSRange range = [labelIn.text rangeOfString:[NSString stringWithFormat:@" %@ ", itemIn.knownItemText]];
             if (range.location == NSNotFound)
             {
             range = [labelIn.text rangeOfString:[NSString stringWithFormat:@" %@", itemIn.knownItemText]];
             if (range.location != NSNotFound)
             {
             [attributedText setAttributes:subAttrs range:range];
             }
             else
             {
             range = [labelIn.text rangeOfString:[NSString stringWithFormat:@"%@", itemIn.knownItemText]];
             if (range.location != NSNotFound)
             {
             [attributedText setAttributes:subAttrs range:range];
             }
             }
             }
             else
             {
             [attributedText setAttributes:subAttrs range:range];
             }*/
            [labelIn setAttributedText:attributedText];
        }
    }
    else
    {
        // Adde code to fix issue # 183, /Yousuf
        if ([labelIn respondsToSelector:@selector(setAttributedText:)])
        {
            UIFont *regularFont = [UIFont systemFontOfSize:fontSizeIn];
            UIColor *foregroundColor = [UIColor blackColor];
            
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName,foregroundColor, NSForegroundColorAttributeName, nil];
            
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:labelIn.text attributes:attrs];
            [labelIn setAttributedText:attributedText];
        }
    }
}

#pragma mark- Button click event
-(IBAction)onClick_back:(id)sender
{
    if(self.moreBtn.show)
    {
        [self.moreBtn backgroundTapped:nil];
    }

    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(IBAction)onClick_delete:(id)sender
{
    if(self.moreBtn.show)
    {
        [self.moreBtn backgroundTapped:nil];
    }
    for(int i=0;i<selectedRowsArray.count;i++)
    {
        Item *item=[selectedRowsArray objectAtIndex:i];
        [Item fakeDelete:item.objectID];
        if(i==selectedRowsArray.count-1)
        {
            [self.navigationController popViewControllerAnimated:NO];
        }
        
    }
    
}

-(IBAction)onClick_copy:(id)sender
{
    
}
-(IBAction)onClick_move:(id)sender
{
    
}

#pragma mark- Display categorywise different color
-(void)DisplayCategorywiseColor
{
    SortedcolorArr=[[NSMutableArray alloc]init];
    UnSortedcolorArr=[[NSMutableArray alloc]init];
    if (unknownItems.count>0)
    {
        Item *firstItem=unknownItems[0];
        old_cat=firstItem.placeCategory;
        UnSortedcolorArr=[[NSMutableArray alloc]init];
        for (int i=0; i<unknownItems.count; i++) {
            Item *firstItem=unknownItems[i];
            new_cat=firstItem.placeCategory;
            // DLog(@"old cat1 :%@ || new cat1 :%@",old_cat,new_cat);
            if([old_cat isEqualToString:new_cat] && old_cat!=nil && new_cat!=nil)
            {
                if(colorFlag2==0)
                {
                    colorFlag=0;
                    [UnSortedcolorArr addObject:@"Blue"];
                }
                else
                {
                    colorFlag=1;
                    [UnSortedcolorArr addObject:@"Green"];
                    
                }
            }
            else{
                old_cat=new_cat;
                
                if(colorFlag==0)
                {
                    [UnSortedcolorArr addObject:@"Green"];
                    colorFlag=1;
                    colorFlag2=1;
                }
                else{
                    [UnSortedcolorArr addObject:@"Blue"];
                    colorFlag=0;
                    colorFlag2=0;
                }
            }
            
        }
    }
    if (sortedItems.count>0)
    {
        Item *firstItem=sortedItems[0];
        old_cat=firstItem.placeCategory;
        SortedcolorArr=[[NSMutableArray alloc]init];
        for (int i=0; i<sortedItems.count; i++) {
            Item *firstItem=sortedItems[i];
            new_cat=firstItem.placeCategory;
            // DLog(@"old cat1 :%@ || new cat1 :%@",old_cat,new_cat);
            if([old_cat isEqualToString:new_cat] && old_cat!=nil && new_cat!=nil)
            {
                if(sortedItems.count>0 && unknownItems.count==0)
                {
                    if(colorFlag2==0)
                    {
                        colorFlag=0;
                        [SortedcolorArr addObject:@"Blue"];
                    }
                    else
                    {
                        colorFlag=1;
                        [SortedcolorArr addObject:@"Green"];
                        
                    }
                }
                else{
                    if(colorFlag2==0)
                    {
                        colorFlag=0;
                        [SortedcolorArr addObject:@"Green"];
                    }
                    else
                    {
                        colorFlag=1;
                        [SortedcolorArr addObject:@"Blue"];
                        
                    }
                    
                }
            }
            else{
                old_cat=new_cat;
                if(sortedItems.count>0 && unknownItems.count==0)
                {
                    if(colorFlag==0)
                    {
                        [SortedcolorArr addObject:@"Green"];
                        colorFlag=1;
                        colorFlag2=1;
                    }
                    else{
                        [SortedcolorArr addObject:@"Blue"];
                        colorFlag=0;
                        colorFlag2=0;
                    }
                }
                else{
                    if(colorFlag==0)
                    {
                        [SortedcolorArr addObject:@"Blue"];
                        colorFlag=1;
                        colorFlag2=1;
                    }
                    else{
                        [SortedcolorArr addObject:@"Green"];
                        colorFlag=0;
                        colorFlag2=0;
                    }
                }
            }
            
        }
    }
    
    
    if (toBuyItems.count>0)
    {
        Item *firstItem=toBuyItems[0];
        old_cat=firstItem.placeCategory;
        toBuycolorArr=[[NSMutableArray alloc]init];
        for (int i=0; i<toBuyItems.count; i++) {
            Item *firstItem=toBuyItems[i];
            new_cat=firstItem.placeCategory;
            // DLog(@"old cat1 :%@ || new cat1 :%@",old_cat,new_cat);
            if([old_cat isEqualToString:new_cat] && old_cat!=nil && new_cat!=nil)
            {
                if(colorFlag2==0)
                {
                    colorFlag=0;
                    [toBuycolorArr addObject:@"Blue"];
                }
                else
                {
                    colorFlag=1;
                    [toBuycolorArr addObject:@"Green"];
                    
                }
            }
            else{
                old_cat=new_cat;
                
                if(colorFlag==0)
                {
                    [toBuycolorArr addObject:@"Green"];
                    colorFlag=1;
                    colorFlag2=1;
                }
                else{
                    [toBuycolorArr addObject:@"Blue"];
                    colorFlag=0;
                    colorFlag2=0;
                }
            }
            
        }
    }

    
}
-(NSMutableArray*)getItemsWithIDs:(NSArray* )itemIDs{
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for (NSString* itemID in itemIDs) {
        Item *item = [Item getItemInList:dataStore.currentList.item_listID withItemID:[NSNumber numberWithInteger:[itemID integerValue]]];
        if (item != nil) {
            [array addObject:item];
        }
    }
    return array;
}
- (void)getSortedItemsByStoreFromServer
{
    [DataStore instance].sortByStoreID = [DataStore instance].currentList.sortByStoreId;
    if([DataStore instance].sortByStoreID == nil || [[DataStore instance].sortByStoreID intValue] == 0)
    {
        return;
    }
    
    ItemListsSorting *sorting = [ItemListsSorting getSortingForItemListId:[DataStore instance].currentList.item_listID andShopId:[DataStore instance].sortByStoreID];
   
    sortedItems = [self getItemsWithIDs:sorting.sortedItems];
        unknownItems = [self getItemsWithIDs:sorting.unknownItems];
    
        NSMutableArray *unknownItemsTemp = [NSMutableArray arrayWithArray:unknownItems];
        
        NSMutableArray *arrIds = [[NSMutableArray alloc] init];
        for (Item *item in sortedItems)
        {
            [arrIds addObject:item.itemID];
        }
        for (Item *item in unknownItems)
        {
            [arrIds addObject:item.itemID];
        }
        
        NSArray *arrWithIdZero = [Item getAllItemsInList:[DataStore instance].currentList.item_listID exceptItemIds:arrIds];
        int index = 0;
        for (Item *item in arrWithIdZero)
        {
            if (![unknownItems containsObject:item])
            {
                [unknownItemsTemp insertObject:item atIndex:index];
                index++;
            }
        }
        unknownItems = unknownItemsTemp;
    
        sortedItems = [sortedItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isChecked == %@",[NSNumber numberWithBool:NO]]];
        unknownItems = [unknownItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isChecked == %@",[NSNumber numberWithBool:NO]]];
        
        unknownItemsMUT  = [[NSMutableArray alloc]init];
        unknownItemsMUT = [unknownItems mutableCopy];
        
        sortedItemsMUT  = [[NSMutableArray alloc]init];
        sortedItemsMUT = [sortedItems mutableCopy];
    
    [Utility SetSortName:@"By category"];
    [self DisplayCategorywiseColor];
    
    [self.table_view reloadData];
}
#pragma mark - Selection tableview Delegate method
- (NSInteger)numberOfColumnsInMenu:(DOPDropDownMenu *)menu {
    return 1;
}

- (NSInteger)menu:(DOPDropDownMenu *)menu numberOfRowsInColumn:(NSInteger)column {
    return popupArr.count;
}
- (NSDictionary *)menu:(DOPDropDownMenu *)menu titleForRowAtIndexPath:(DOPIndexPath *)indexPath
{
   return [popupArr objectAtIndex:indexPath.row];
}
- (void)menu:(DOPDropDownMenu *)menu didSelectRowAtIndexPath:(DOPIndexPath *)indexPath
{
    if(indexPath.row==0)//Copy to
    {
        [self gotoListView:@"Copy Items"];
    }
    else if(indexPath.row==1)//Moved
    {
        [self gotoListView:@"Move Items"];
    }
    else if(indexPath.row==2) //Select all
    {
        selectedRowsArray=[[NSMutableArray alloc]init];
        if ([DataStore instance].sortingOrder == STORE)
        {
            if (unknownItems.count>0)
            {
                [selectedRowsArray addObjectsFromArray:unknownItems];
            }
            if (sortedItems.count>0)
            {
                [selectedRowsArray addObjectsFromArray:sortedItems];

            }
        }
        else{
                if (toBuyItems.count>0)
                {
                    [selectedRowsArray addObjectsFromArray:toBuyItems];
                }
        }
        self.lbl_totalSelectedItems.text=[NSString stringWithFormat:@"%lu",selectedRowsArray.count];
        [self.table_view reloadData];

    }

    
    if(self.moreBtn.show)
    {
        [self.moreBtn backgroundTapped:nil];
    }
}
#pragma mrak- open  list view
-(void)gotoListView:(NSString*)screen_name
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPopupList:) name:@"dismissListView" object: nil];

  //  NSLog(@"selected array %@",selectedRowsArray);
   // NSLog(@"screen_name %@",screen_name);
    
    DisplayAllItemListVC *nav=[[DisplayAllItemListVC alloc]initWithNibName:@"DisplayAllItemListVC" bundle:nil];
    nav.selectedItemsArr=selectedRowsArray;
    nav.screenName=screen_name;
    [self presentPopupViewController:nav animationType:MJPopupViewAnimationFade];
}
-(void)dismissPopupList:(NSNotification *)noti
{
   // NSLog(@"noti %@",noti);
    NSDictionary* userInfo = noti.userInfo;
    if([[userInfo objectForKey:@"Option"] isEqualToString:@"Move Items"])
    {
        for(int i=0;i<selectedRowsArray.count;i++)
        {
            Item *SelItem=[selectedRowsArray objectAtIndex:i];
            //[Item fakeDelete:SelItem.objectID];
            
            Item_list *list=[userInfo objectForKey:@"SelectedList"];
            //[Item insertItemWithText:SelItem.text andBarcode:@"" andBarcodeType:@"" belongToList:list withSource:@"Manual"];
            [SelItem updateItemWithItemListId:list.item_listID];
            // NSLog(@"item text %@",SelItem.text);
        }
        [[SyncManager sharedManager] forceSync];
        
        
    }
    else if([[userInfo objectForKey:@"Option"] isEqualToString:@"Copy Items"])
    {
        for(int i=0;i<selectedRowsArray.count;i++)
        {
            Item *SelItem=[selectedRowsArray objectAtIndex:i];
            Item_list *list=[userInfo objectForKey:@"SelectedList"];
            [Item insertItemWithText:SelItem.text andBarcode:@"" andBarcodeType:@"" belongToList:list withSource:@"Manual"];
           // NSLog(@"item text %@",SelItem.text);
        }
        [[SyncManager sharedManager] forceSync];
        
        
    }

    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"dismissListView" object:nil];
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    [self.navigationController popToRootViewControllerAnimated:NO];
}
#pragma mark- Scrollview delegate Method
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if(self.moreBtn.show)
    {
        [self.moreBtn backgroundTapped:nil];
    }
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.moreBtn removeFromSuperview];
    
    [self SetControlPosition];
    
    
}
#pragma mark- Set all controls position in both orientation
-(void)SetControlPosition
{
    int screen_height,screen_width,nav_height,nav_controls_y,nav_controls_h,tbl_height,line_height;
    screen_height=SCREEN_HEIGHT;
    screen_width=SCREEN_WIDTH;
    
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(IS_IPHONE)
    {
        line_height=0.5;
        if (orientation == UIInterfaceOrientationPortrait || orientation ==UIInterfaceOrientationPortraitUpsideDown)
        {
            nav_height=64;
            nav_controls_y=20;
            nav_controls_h=44;
        }
        else
        {
            if ([UIApplication sharedApplication].isStatusBarHidden) {
                nav_height=32;
                nav_controls_y=0;
                nav_controls_h=32;
            }
            else
            {
                nav_height=52;
                nav_controls_y=20;
                nav_controls_h=32;
            }
        }
    }
    else
    {
        line_height=1;

        nav_height=64;
        nav_controls_y=20;
        nav_controls_h=44;
     }
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        tbl_height=screen_height-nav_height;
    }
    else
    {
        tbl_height=screen_height-nav_height-self.bannerView.frame.size.height;
     }
    
    CGRect frame1=self.headerView.frame;
    frame1.size.height=nav_height;
    self.headerView.frame=frame1;
    
    self.navigationLine.frame=CGRectMake(self.navigationLine.frame.origin.x, self.headerView.frame.origin.y+self.headerView.frame.size.height-line_height, self.headerView.frame.size.width,line_height);
    
    CGRect frame=self.table_view.frame;
    frame.origin.y=self.headerView.frame.origin.y+self.headerView.frame.size.height;
    frame.size.height=tbl_height;
    self.table_view.frame=frame;
    
    self.backBtn.frame=CGRectMake(self.backBtn.frame.origin.x, nav_controls_y, self.backBtn.frame.size.width, nav_controls_h);
    self.lbl_totalSelectedItems.frame=CGRectMake(self.lbl_totalSelectedItems.frame.origin.x, nav_controls_y, self.lbl_totalSelectedItems.frame.size.width, nav_controls_h);
    self.delBtn.frame=CGRectMake(self.delBtn.frame.origin.x, nav_controls_y, self.delBtn.frame.size.width, nav_controls_h);
    self.moreImgBtn.frame=CGRectMake(self.moreImgBtn.frame.origin.x, nav_controls_y, self.moreImgBtn.frame.size.width, nav_controls_h);
    
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height+20;
       
            x=SCREEN_WIDTH-42;
            w=40;
            h=44;
    }
    else
    {
        //Landscape mode
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height;
        x=SCREEN_WIDTH-42;
        w=40;
        if(IS_IPHONE)
        {
            if ([UIApplication sharedApplication].isStatusBarHidden) {
                h=32;
            }
            else
            {
                h=44;
            }
         }
        else
        {
            h=44;
        }
    }
    
    my_screenwidth=SCREEN_WIDTH;
    self.moreBtn = [[DOPDropDownMenu alloc] initWithOrigin:CGPointMake(SCREEN_WIDTH-105, 0) andX:x andY:self.table_view.frame.origin.y-h-1 andWidth:w andHeight:h];
    self.moreBtn.dataSource = self;
    self.moreBtn.delegate = self;
    self.moreBtn.screenname=@"itemsSelection";
    [self.view addSubview:self.moreBtn];
    

}
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(self.moreBtn.show)
    {
        [self.moreBtn backgroundTapped:nil];
    }
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    
    
    [self.table_view reloadData];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(void)didUpdateItems
{
   
}
@end
