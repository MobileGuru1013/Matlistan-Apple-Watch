
//
//  ShoppingModeTableViewController.m
//  MatListan
//
//  Created by Yan Zhang on 10/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ShoppingModeTableViewController.h"
#import "SortTableViewController.h"


#define UNSORTED_SECTION_Vist_Store 0
#define SORTED_SECTION_Visit_Store 1
#define REMOVED_SECTION_Visit_Store 2



#import "DataStore.h"
#import "Item+Extra.h"
#import "Item_list+Extra.h"
#import "ItemsCheckedStatus+Extra.h"

#import "Store+Extra.h"
#import "MatlistanHTTPClient.h"

#import "ALToastView.h"

#import "SignificantChangesIndicator.h"
#import <AudioToolbox/AudioServices.h>

#import "ItemListsSorting+Extra.h"
#import "AppDelegate.h"
#import "ShopsTableViewController.h"

@import SystemConfiguration.CaptiveNetwork;

@interface ShoppingModeTableViewController ()
{
    NSString *currentRowText;
    NSInteger sectionSum;
    //NSMutableArray *allItems;
    NSMutableArray *toBuyItems;
    NSMutableArray *checkedItems;
    CLLocationManager *locationManager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    CLLocation *currentLocation;
    NSManagedObjectID *listObjectId;
    MatlistanHTTPClient *client;
    NSArray *reasons ;
    DataStore *dataStore;
    
    NSIndexPath *selectedIndxPath;
    
    NSArray *sortedItems;    //used for sorting by STORE
    NSArray *unknownItems;   //used for sorting by STORE
    NSMutableArray *sortedItemsMUT;    //used for sorting by STORE
    NSMutableArray *unknownItemsMUT;   //used for sorting by STORE
    NSArray *sectionNames;
    
    //Overlay Objects
    UIActivityIndicatorView * spinner;
    UIImageView * bgimage;
    UILabel * loadingLabel;
    NSArray *myCustomCheckedArr;
    
    //Dimple-16-09-2015 Fixed #383
    BOOL refreshFlag,Location_update;
    int x,w,h,navigationBarHeight,y1;
    NSMutableArray *Final_visted_store_Arr;
    CGRect floatingButtonRect;
    CGRect hiddenFloatingButtonRect;
    
    int more_x,more_w,more_h,more_y1;
    NSMutableArray *popupArr;
    
    CustomPickerView *customPickerView;
    NSMutableArray *storeHistory;
}

@end

@implementation UINavigationController (Orientation)
-(NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

-(BOOL)shouldAutorotate
{
    return YES;
}
@end


@implementation ShoppingModeTableViewController


- (void)viewDidLoad
{
    CLS_LOG(@"viewdidload method called in shoppingmodetableviewcontroller");

    [super viewDidLoad];
    
    
    is_autoSortAlert=false;
    popupArr=[[NSMutableArray alloc]init];
    popupArr=[[NSMutableArray alloc]initWithObjects:@{@"menuItem":NSLocalizedString(@"Manual sorting", nil)},@{@"menuItem":NSLocalizedString(@"Only Help", nil)},nil];
    
    refreshFlag=false;
    Location_update=true;
    self.navigationController.navigationBar.hidden=YES;
    CALayer *TopBorder = [CALayer layer];
    TopBorder.frame = CGRectMake(0.0f,self.custView.frame.size.height-1, SCREEN_WIDTH, 1.0f);
    TopBorder.backgroundColor = [UIColor colorWithRed:200/255. green:199/255. blue:204/255. alpha:1].CGColor;
    [self.custView.layer addSublayer:TopBorder];
    self.titleLbl.text=NSLocalizedString(@"In the store", nil);
    [self.backButton setTitle:NSLocalizedString(@"Back",nil) forState: UIControlStateNormal];
   
    
    //[[SyncManager sharedManager] stopSync];
    //[Visit cleanOldVisits]; //remove visits older than 2hr
    Final_visted_store_Arr=[[NSMutableArray alloc] init];
    self.tableView.sectionHeaderHeight = 0.0;
    self.tableView.sectionFooterHeight = 0.0;
    self.tableView.tableHeaderView=[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
    self.tableView.tableFooterView=[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
    
    reasons = @[@"Taken",@"OutOfOrder",@"Moved",@"SoldOut",@"NotInThisStore",@"NotThisTime",@"Remove",@"Unknown"];
    dataStore = [DataStore instance];
    locationManager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    
    client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
   
    
    sectionSum = 1;
    self.navigationItem.title = NSLocalizedString(@"In the store", nil);
    self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Back", nil);
    
    checkedItems = [[NSMutableArray alloc]init];
    toBuyItems = [[NSMutableArray alloc]init];

    if (dataStore.sortingOrder == STORE) {
        [self getSortedItemsByStoreFromServer:false];
    }
    
    toBuyItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:NO]];
    checkedItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:YES]];
    [self DisplayCategorywiseColor];
    
    
    /////////////floating button////////////////////////
    int floating_X,floating_Y,floating_W,floating_H;
    int floating_distance=0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height+20;
        if(IS_IPHONE)
        {
            floating_W=44;
            floating_H=44;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=30;
        }
        else
        {
            floating_W=66;
            floating_H=66;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=45;
        }
    }
    else
    {
        //Landscape mode
        navigationBarHeight=self.navigationController.navigationBar.frame.size.height;
        if(IS_IPHONE)
        {
            floating_W=44;
            floating_H=44;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=30;
            
        }
        else
        {
            floating_W=66;
            floating_H=66;
            floating_X=(SCREEN_WIDTH/2)-floating_W/2;
            floating_distance=45;
            
        }
    }
    floating_Y=SCREEN_HEIGHT-floating_distance-floating_H;

    floatingButtonRect = CGRectMake(floating_X, floating_Y, floating_W, floating_H);
    hiddenFloatingButtonRect = CGRectMake(floating_X, floating_Y, 0, 0);
    self.refreshButton = [[VCFloatingActionButton alloc]initWithFrame:floatingButtonRect normalImage:[UIImage imageNamed:@"refresh_floating"] andPressedImage:[UIImage imageNamed:@"refresh_floating_sel"] withScrollview:self.tableView];
    
    self.refreshButton.hideWhileScrolling = NO;
    self.refreshButton.delegate = self;
    self.refreshButton.tintColor=LIGHT_BROWN_COLOR;
    self.refreshButton.hidden = YES;
    [self.view addSubview:self.refreshButton];
    ///////////////////////////////////////////////////////////////////////////////////
    
    
    DLog(@"sorting type: %d", dataStore.sortingOrder);
    if(IS_IPHONE)
    {
        x=80;
        w=180;
        h=43;
        y1=21;
    }
    else
    {
        x=123;
        w=522;
        h=68;
        y1=-5;
    }
    navigationBarHeight=self.navigationController.navigationBar.frame.size.height;
    self.menu = [[DOPDropDownMenu alloc] initWithOrigin:CGPointMake(0, 0) andX:x andY:y1 andWidth:w andHeight:h];
    self.menu.dataSource = self;
    self.menu.delegate = self;
    self.menu.tag=1;
    self.menu.screenname=@"instoremode";
    [self.view addSubview:self.menu];
    
    more_x=SCREEN_WIDTH-42;
    more_w=40;
    more_h=44;
    
    self.moreBtn = [[DOPDropDownMenu alloc] initWithOrigin:CGPointMake(SCREEN_WIDTH-105, 0) andX:more_x andY:self.tableView.frame.origin.y-1-more_h andWidth:more_w andHeight:more_h];
    self.moreBtn.dataSource = self;
    self.moreBtn.delegate = self;
    self.moreBtn.screenname=@"instoremode_more";
    self.moreBtn.tag=2;
    [self.view addSubview:self.moreBtn];
    
    //[self LoadStoreHistory];
   //[self getVisitedStoreFromServer:dataStore.currentList.item_listID];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing ShoppingModeTableViewController");
    [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self];
}

- (void)getSortedItemsByStoreFromServer:(BOOL)hasAutomaticSortData
{
    CLS_LOG(@"getSortedItemsByStoreFromServer method called in shoppingmodetableviewcontroller");

    is_autoSortAlert=false;
    [DataStore instance].sortByStoreID = [DataStore instance].currentList.sortByStoreId;
    if([DataStore instance].sortByStoreID == nil || [[DataStore instance].sortByStoreID intValue] == 0)
    {
        return;
    }
    
    ItemListsSorting *sorting = [ItemListsSorting getSortingForItemListId:[DataStore instance].currentList.item_listID andShopId:[DataStore instance].sortByStoreID];
    //NSLog(@"sorting %@",sorting);
    NSLog(@"sorting1  %@",[DataStore instance].sortByStoreID);
    if (sorting) {
        sortedItems = [self getItemsWithIDs:sorting.sortedItems];
        unknownItems = [self getItemsWithIDs:sorting.unknownItems];
        
        /////////Adding newly added items (where id = 0)
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
        ///////////
        
        
        NSArray *ar1 = [sortedItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isChecked == %@",[NSNumber numberWithBool:YES]]];
        NSArray *ar2 = [unknownItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isChecked == %@",[NSNumber numberWithBool:YES]]];
        
        checkedItems = [ar1 mutableCopy];
        [checkedItems addObjectsFromArray:ar2];
        
        sortedItems = [sortedItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isChecked == %@",[NSNumber numberWithBool:NO]]];
        unknownItems = [unknownItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isChecked == %@",[NSNumber numberWithBool:NO]]];
        
        unknownItemsMUT  = [[NSMutableArray alloc]init];
        unknownItemsMUT = [unknownItems mutableCopy];
        
        sortedItemsMUT  = [[NSMutableArray alloc]init];
        sortedItemsMUT = [sortedItems mutableCopy];
    }
    else {
         [dataStore setPreviousSortingOrder];
        // DLog(@"hasAutomaticSortData %d",hasAutomaticSortData);
         if(hasAutomaticSortData)
         {
            is_autoSortAlert=true;
            [[SortingSyncManager sharedSortingSyncManager] forceSync];
            Store *store = [Store getStoreByID:[NSNumber numberWithInt:[self.selectd_store_id intValue]]];
             DLog(@"selected store id %@",[NSNumber numberWithInt:[self.selectd_store_id intValue]]);
             DLog(@"store %@",store);
             
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Sort items for",nil), self.selectd_store_name] maskType:SVProgressHUDMaskTypeClear];
         }
       
    }
    [Utility SetSortName:@"By category"];
    [self DisplayCategorywiseColor];
    [self.tableView reloadData];
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - location

- (void)getCurrentLocation {
    CLS_LOG(@"getCurrentLocation method called in shoppingmodetableviewcontroller");

    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [locationManager requestWhenInUseAuthorization];
    }
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    currentLocation = [locations lastObject];
    
    if(Location_update)
    {
        [self getVisitedStoreFromServer:dataStore.currentList.item_listID];
    }
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"didFailWithError: %@", error);
    [self LoadStoreHistory];
    [locationManager stopUpdatingLocation];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if([CLLocationManager locationServicesEnabled])
    {
        locationManager=nil;
    }

}


#pragma mark- Actionsheet

-(void)popover:(id)sender
{
    if(self.moreBtn.show)
    {
        [self.moreBtn backgroundTapped:nil];
    }
    //set current row for later usage - set strike on
    UIButton *button = (UIButton*)sender;
    currentRowText = [button titleForState:UIControlStateDisabled];
    UIActionSheet *popup = nil;
    
    popup = [[UIActionSheet alloc] initWithTitle:@"Status" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Taken", nil), NSLocalizedString(@"Caught at wrong place", nil),NSLocalizedString(@"Taken, item has a new location", nil), NSLocalizedString(@"Out", nil), NSLocalizedString(@"Not in the collection", nil), NSLocalizedString(@"Shop next time", nil), NSLocalizedString(@"Remove", nil), nil];
    
    if (IS_IPHONE)
    {
        [popup showInView:[UIApplication sharedApplication].keyWindow];
    }
    else{
        //[popup showFromRect:button.frame inView:self.view animated:YES];
        CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
        ShoppingTableViewCell *cell = (ShoppingTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
        CGRect aRect = CGRectMake(button.frame.origin.x, cell.frame.origin.y, button.frame.size.width, button.frame.size.height);
        [popup showFromRect:aRect inView:self.view animated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 7)
    {
        return; //when clicking cancel button
    }
    
    [self vibrateDevice:nil];
    
    ShoppingTableViewCell *sCell = (ShoppingTableViewCell *)[self.tableView cellForRowAtIndexPath:selectedIndxPath];
    Item *theItem = sCell.item;
    if(buttonIndex==6)
    {
        BOOL originalCheck = [theItem.isChecked boolValue];
        [self checkItemInCoreData:theItem WithStatus:((CHECK_REASON)buttonIndex) andChecked:originalCheck andTaken:originalCheck];
    }
    else
    {
        BOOL originalCheck = [theItem.isChecked boolValue];
        theItem.isChecked = [NSNumber numberWithBool:!originalCheck];
        theItem.isTaken = [NSNumber numberWithBool:!originalCheck];
        [self checkItemInCoreData:theItem WithStatus:((CHECK_REASON)buttonIndex) andChecked:!originalCheck andTaken:!originalCheck];
        
        ShoppingTableViewCell *shopCell = (ShoppingTableViewCell *)[self.tableView cellForRowAtIndexPath:selectedIndxPath];
        [self configureCell:shopCell atIndexPath:selectedIndxPath forItem:theItem];
        [self showRefreshButton];
        self.refreshButton.tintColor=DARK_GREEN_COLOR;
        
    }
    
    [[SyncManager sharedManager] forceSync];
}

-(int)getIndexByText:(NSString*)text{
    int index = -1;
    
    if (selectedIndxPath.section == 0)
    {
        for (int i = 0; i < toBuyItems.count; i++)
        {
            Item *theItem = [toBuyItems objectAtIndex:i];
            NSString *objectText = theItem.text;
            if([objectText isEqualToString:text])
            {
                return i;
            }
        }
    }
    
    if (selectedIndxPath.section == 1)
    {
        for (int i=0; i< checkedItems.count; i++)
        {
            Item *theItem = [checkedItems objectAtIndex:i];
            NSString *objectText = theItem.text;
            if([objectText isEqualToString:text])
            {
                return i;
            }
        }
    }
    return index;
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(IS_IPHONE)
    {
        return 44.0f;
    }
    else
    {
        return 70;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if ([DataStore instance].sortingOrder == STORE)
    {
        if (checkedItems.count == 0)
        {
            return 2;
        }
        else
        {
            return 3;
        }
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
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
        else
        {
            return checkedItems.count;
        }
    }
    else
    {
        if (section == 0)
        {
            return toBuyItems.count;
        }
        else
        {
            return checkedItems.count;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.moreBtn.show)
    {
        [self.moreBtn backgroundTapped:nil];
    }

    ShoppingTableViewCell *cell = (ShoppingTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    
    Item *item = cell.item;
    
    if (item == nil) {
        return;
    }
    
    BOOL originalCheck = [item.isChecked boolValue];
    
    item.isChecked = [NSNumber numberWithBool:!originalCheck];
    item.isTaken = [NSNumber numberWithBool:!originalCheck];
    currentRowText = item.text;
    
    CHECK_REASON reason = !originalCheck? TAKEN:NOT_THIS_TIME;
    
    [self vibrateDevice:nil];
    
    [self checkItemInCoreData:item WithStatus:reason andChecked:!originalCheck andTaken:!originalCheck];
    
    [self configureCell:cell atIndexPath:indexPath forItem:item];
    
    [self showRefreshButton];
    self.refreshButton.tintColor=DARK_GREEN_COLOR;
    if([item.isChecked boolValue]) {
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell hideSuggestionButton];
    }
    else {
        [cell setBackgroundColor: cell.nonCheckedBackgroundColor];
        [cell showSuggestionButton];
    }
    [[SyncManager sharedManager] forceSync];
}

- (void)configureCell:(ShoppingTableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath forItem:(Item*)item
{
    UILabel *label = cell.labelItemTitle;
    UIButton *button = cell.buttonCheckReason;
    NSString *text = currentRowText;
    BOOL isChecked = [item.isChecked boolValue];
    
    label.text = currentRowText;
    [button setTitle:text forState:UIControlStateDisabled];
    
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
    if (text.length > item_size) {
        [self adjustTitleLabelForKnowText:label withItem:item withFountSize:font_size1 withIsChecked:isChecked withButton:button withNumberOfLines:0];
    }
    else{
        [self adjustTitleLabelForKnowText:label withItem:item withFountSize:font_size2 withIsChecked:isChecked withButton:button withNumberOfLines:1];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLS_LOG(@"start cellForRowAtIndexPath method called in shoppingmodetableviewcontroller");

    BOOL makeWhite = NO;
    BOOL hideSuggestionsBtn = YES;
    ShoppingTableViewCell *cell = (ShoppingTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    UILabel *label = cell.labelItemTitle;
    UIButton *button = cell.buttonCheckReason;
    Item *theItem;
    
    // Configure the cell...
    NSInteger rowNum = indexPath.row;
    NSString *color=@"";
    //Dimple-16-09-2015 Fixed #383
    if(refreshFlag)
    {
        checkedItems=[NSMutableArray arrayWithArray: myCustomCheckedArr];
    }
    if ([DataStore instance].sortingOrder == STORE)
    {
        if (indexPath.section == UNSORTED_SECTION_Vist_Store )
        {
            if (rowNum < unknownItems.count)
            {
                theItem = [unknownItems objectAtIndex:rowNum];
                [self makeChangesInItemCell:theItem withLabel:label withCell:cell withButton:button];
                color=[UnSortedcolorArr objectAtIndex:indexPath.row];

            }
        }
        else if (indexPath.section == SORTED_SECTION_Visit_Store )
        {
            if (rowNum < sortedItems.count)
            {
                theItem = [sortedItems objectAtIndex:rowNum];
                [self makeChangesInItemCell:theItem withLabel:label withCell:cell withButton:button];
                color=[SortedcolorArr objectAtIndex:indexPath.row];

            }
        }
        else if (indexPath.section == REMOVED_SECTION_Visit_Store )
        {
            if (rowNum < checkedItems.count) {
                theItem = [checkedItems objectAtIndex:rowNum];
                [self makeChangesInItemCell:theItem withLabel:label withCell:cell withButton:button];
                color=[toCheckedcolorArr objectAtIndex:indexPath.row];
                makeWhite = YES;
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
                [self makeChangesInItemCell:theItem withLabel:label withCell:cell withButton:button];
                color=[toBuycolorArr objectAtIndex:indexPath.row];

            }
        }
        else
        {
            if (rowNum < checkedItems.count) {
                theItem = [checkedItems objectAtIndex:rowNum];
                DLog(@"%@", theItem.checkedAfterStart);
                [self makeChangesInItemCell:theItem withLabel:label withCell:cell withButton:button];
                color=[toCheckedcolorArr objectAtIndex:indexPath.row];
                makeWhite = YES;
            }
        }
    }
    if(makeWhite || [theItem.isChecked boolValue]) {
        cell.backgroundColor=[UIColor whiteColor];
    }
    else if([[Utility getSortName] isEqualToString:@"By category"])
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
    cell.nonCheckedBackgroundColor = cell.backgroundColor;
    
    if([DataStore instance].sortingOrder == STORE || [DataStore instance].sortingOrder == GROUPED  || [DataStore instance].sortingOrder == DEFAULT)
    {
        NSArray *arrPossibleMatches = (NSArray *)theItem.possibleMatches;
        
        if (arrPossibleMatches && arrPossibleMatches.count > 0)
        {
            if ([theItem.isPossibleMatch isEqualToNumber:[NSNumber numberWithBool:false]])
            {
                hideSuggestionsBtn = NO;
            }
        }
    }
    cell.canShowMatches = !hideSuggestionsBtn;
    
    if(hideSuggestionsBtn || makeWhite) {
        [cell hideSuggestionButton];
        cell.canShowMatches = NO;
    }
    else {
        [cell showSuggestionButton];
    }
    CLS_LOG(@"end cellForRowAtIndexPath method called in shoppingmodetableviewcontroller");

    return cell;
}



-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
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
        else if (section == 2)
        {
            if (checkedItems.count > 0)
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
    else
    {
        if (checkedItems.count == 0)
        {
            return 0.0;
        }
        if (section == 1)
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
    }
    return 0;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
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
        sectionNames = @[NSLocalizedString(@"Unsorted items", nil), NSLocalizedString(@"Sorting", nil),NSLocalizedString(@"Removed Items",nil)];
        
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
                sectionTitle = [sectionTitle stringByAppendingString:@": "];
                titleLabel.text = [sectionTitle stringByAppendingString:[Store getStoreByID:[DataStore instance].sortByStoreID].name];
                return view;
            }else{
                [view setFrame:CGRectMake(0.0f, 0.0f, 0, 0.0f)];
                return view;
            }
        }else if (section == 2){
            if (checkedItems.count > 0) {
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
        if (checkedItems.count == 0)
        {
            return [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, tableView.bounds.size.width, 0.0)];
        }
        headerView.backgroundColor = [Utility getGreenColor];
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10.0, header_vw_y, tableView.bounds.size.width * 0.86, 30.0)];
        // Header label is not center aligned /Yousuf
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setTextColor:[UIColor whiteColor]];
        label.text = NSLocalizedString(@"Removed Items",nil);
        label.font = [UIFont systemFontOfSize:font_size1];
        [headerView addSubview:label];
        return headerView;
    }
    return nil;
}

#pragma mark- data handling
/**
 Save checked status in core data
 TAKEN, - tagen
 OUT_OF_ORDER, - tagen på fel plats (fel ordning, går inte att använda för att räkna ut sorteringen)
 SOLD_OUT,- tillfälligt slut
 NOT_IN_STORE,- Finns inte i sortiment
 NOT_THIS_TIME, -Handla nästa gång
 REMOVE, - Ta bort
 UNKNOWN_REASON - ej tagen
 
 */
- (void)checkItemInCoreData:(Item*)theItem WithStatus:(CHECK_REASON)reason andChecked:(BOOL)isChecked andTaken:(BOOL)isTaken
{
    CLS_LOG(@"checkItemInCoreData method called in shoppingmodetableviewcontroller");

    [Utility saveInDefaultsWithObject:[NSDate new] andKey:@"lastCheckingActivity"];
    //DLog(@"\n\n\nCheck item: %@\nIs checked: %@ \nwith reason %d\n\n\n",theItem.text, isChecked? @"YES" : @"NO", reason);
    // Add info in ItemsCheckedStatus
    
    int deviceId = [DataStore instance].randomDeviceID;
    
    //long secAfterStart = [self getSecondsAfterStart];
    
    if (reason == REMOVE)
    {
        //Remove this item from the table view
        
        
        for (int i=0; i< toBuyItems.count; i++)
        {
            Item *item = [toBuyItems objectAtIndex:i];
            
            // DLog(@"Item.itemID %@ & name %@",item.itemID,item.text);
            // DLog(@"theItem.itemID %@",theItem.itemID);
            if([item.objectID isEqual:theItem.objectID])
            {
                [toBuyItems removeObjectAtIndex:i];
                
                if ([DataStore instance].sortingOrder == STORE) {
                    
                    for(int j=0;j<unknownItemsMUT.count;j++)
                    {
                        Item *item = [unknownItemsMUT objectAtIndex:j];
                        if([item.objectID isEqual:theItem.objectID])
                        {
                            [unknownItemsMUT removeObjectAtIndex:j];
                            unknownItems=[[NSArray alloc] initWithArray:unknownItemsMUT];
                            break;
                        }
                    }
                    for(int k=0;k<sortedItemsMUT.count;k++)
                    {
                        Item *item = [sortedItemsMUT objectAtIndex:k];
                        if([item.objectID isEqual:theItem.objectID])
                        {
                            [sortedItemsMUT removeObjectAtIndex:k];
                            sortedItems=[[NSArray alloc] initWithArray:sortedItemsMUT];
                            break;
                        }
                    }
                    
                    
                }
                
                [self.tableView reloadData];
                [Item fakeDelete:theItem.objectID];
                
                return;
            }
        }
        //for removed item section
        if([checkedItems containsObject:theItem])
        {
            [checkedItems removeObject:theItem];
            myCustomCheckedArr=[NSArray arrayWithArray:(NSArray*)checkedItems];
            [Item fakeDelete:theItem.objectID];
            [self.tableView reloadData];
            return;
            
        }
        
        
        DLog(@"Remove the item in core data");
        //Remove this item from core data
        
    }
    else {
        // Update core data if any change is made
        [Item checkItem:theItem.objectID withCheckStatus:isChecked andReason:reason];
    }
    //Apple does not allow developers direct access to the low-level wireless API functions. So leave the networks to be empty
    NSMutableArray *networks = [[NSMutableArray alloc]initWithArray:@[[NSNull null]]];
    
    
    if([DataStore instance].sortingOrder==STORE)
    {
        [ItemsCheckedStatus updateItemCheckedStatus:isChecked andTaken:isTaken forItemObjectId:theItem.objectID forItemId:theItem.itemID inList:theItem.listId andDeviceId:deviceId andCheckedReason:reasons[reason] andLat:currentLocation.coordinate.latitude andLon:currentLocation.coordinate.longitude andAccuracy:(int)currentLocation.horizontalAccuracy andNetworks:networks andSelectedStoreId:[DataStore instance].currentList.sortByStoreId];
    }
    else
    {
        if(self.selectd_store_id==nil)
        {
            [ItemsCheckedStatus updateItemCheckedStatus:isChecked andTaken:isTaken forItemObjectId:theItem.objectID forItemId:theItem.itemID inList:theItem.listId andDeviceId:deviceId andCheckedReason:reasons[reason] andLat:currentLocation.coordinate.latitude andLon:currentLocation.coordinate.longitude andAccuracy:(int)currentLocation.horizontalAccuracy andNetworks:networks andSelectedStoreId:0];

        }
        else
        {
            [ItemsCheckedStatus updateItemCheckedStatus:isChecked andTaken:isTaken forItemObjectId:theItem.objectID forItemId:theItem.itemID inList:theItem.listId andDeviceId:deviceId andCheckedReason:reasons[reason] andLat:currentLocation.coordinate.latitude andLon:currentLocation.coordinate.longitude andAccuracy:(int)currentLocation.horizontalAccuracy andNetworks:networks andSelectedStoreId:[DataStore instance].currentList.sortByStoreId];

        }
    }
}

/*
- (long)getSecondsAfterStart
{
    Visit *visit = [Visit getVisitByList:[DataStore instance].currentList.item_listID];
    long currentTime = (long)[Utility getTimeStamp];
    if (visit == nil) {
        //create a new visit: startedAt = updatedAt = now() time_diff=int.minvalue
        DLog(@"create a new visit");
        [Visit insertVisitWithStarted:[NSNumber numberWithLong:currentTime] andUpdated:[NSNumber numberWithLong:currentTime] andTimeDiff:[NSNumber numberWithLong:INT32_MIN] forListID:[DataStore instance].currentList.item_listID];
        return 0;
    }
    else
    {
        DLog(@"DB time diff %ld",[visit.time_diff longValue]);
        //update visit's updated_at column
        [Visit updateVisitUpdatedAt:[DataStore instance].currentList.item_listID];
        long secondsAfterStart = (currentTime - [visit.started_at longValue]);
        DLog(@"sec after start : %ld",secondsAfterStart);
        return secondsAfterStart;
    }
}
 */

/**
 * Directly get visits from server
 */
-(void)getVisitsFromServer:(NSNumber*)listId{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"format"] = @"json";
    NSString *request = [NSString stringWithFormat:@"Visits/Current/%@", listId];
    [client GET:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        DLog(@"Get visit from server %@",responseObject);
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to getVisitsFromServer");
    }];
}


#pragma mark - UI related

- (IBAction)onClickClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:Nil];
    //[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClickRefresh:(id)sender {
    CLS_LOG(@"onClickRefresh method called in shoppingmodetableviewcontroller");

    //[[SyncManager sharedManager] syncOnce];
    [self hideRefreshButton];
    [self refreshData];
    
    if (dataStore.sortingOrder == STORE) {
        [self getSortedItemsByStoreFromServer:false];
    }
    
    toBuyItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:NO]];
    checkedItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:YES]];
    [self DisplayCategorywiseColor];
    [self.tableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateUINotification" object:nil];
    self.navigationController.navigationBar.hidden=NO;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    if([SortingSyncManager sharedSortingSyncManager].sortingSyncManagerDelegate == self)
    {
        [SortingSyncManager sharedSortingSyncManager].sortingSyncManagerDelegate = nil;
    }
    [locationManager stopUpdatingLocation];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    self.navigationController.navigationBar.hidden=YES;
    [SyncManager sharedManager].syncManagerDelegate = self;
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(wakeUp:) name: @"UpdateUINotification" object: nil];
    [SortingSyncManager sharedSortingSyncManager].sortingSyncManagerDelegate = self;
   
    
//    if (dataStore.sortingOrder == STORE) {
//        [self getSortedItemsByStoreFromServer:false];
//    }
    
    if((theAppDelegate).storeDict!=nil)
    {
        //DLog(@"StoreDict %@",(theAppDelegate).storeDict);
        //dataStore.currentList.item_listID
        self.selectd_store_id=[NSString stringWithFormat:@"%@",[DataStore instance].sortByStoreID];
        [self CheckOtherStoreSortedAutomatically:dataStore.currentList.item_listID storeId:[DataStore instance].sortByStoreID storeName:[(theAppDelegate).storeDict objectForKey:@"name"]];
        
        if(Final_visted_store_Arr != nil)
        {
            NSMutableDictionary *dic1T=[[NSMutableDictionary alloc] init];
            [dic1T setObject:(theAppDelegate).storeDict forKey:@"store"];
            if(Final_visted_store_Arr.count > 0)
            {
                [Final_visted_store_Arr insertObject:dic1T atIndex:Final_visted_store_Arr.count-1];
            }
            else
            {
                [Final_visted_store_Arr insertObject:dic1T atIndex:Final_visted_store_Arr.count];
            }
            [self setStoreTitle:[(theAppDelegate).storeDict objectForKey:@"name"]];
            
            [self.menu.tableView reloadData];
        }
        

    }
    
    [self onClickRefresh:nil];
}
-(void)CheckOtherStoreSortedAutomatically:(NSNumber*)listId storeId:(NSNumber*)storeId storeName:(NSString*)storeName{
    NSString *request = [NSString stringWithFormat:@"ItemLists/%@/SortedByStore/%@", listId,storeId];
    [client GET:request parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *dict = (NSDictionary*)responseObject;
        NSLog(@"CheckOtherStoreSortedAutomatically %@",dict);
        NSArray *sortedItemsArr=[dict objectForKey:@"sortedItems"];
        int ItemSortCount=(int)(dataStore.sorteditemsList.count+checkedItems.count);
        
        if(sortedItemsArr !=nil && sortedItemsArr.count>0 && sortedItemsArr.count>=(ItemSortCount/2))
        {
           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Vist_store_alert_Title", nil) message:[NSString stringWithFormat:@"%@%@.%@",NSLocalizedString(@"Vist_store_alert_msg1", nil),storeName,NSLocalizedString(@"Vist_store_alert_msg2", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:NSLocalizedString(@"Cancel", nil), nil];
            alert.tag=1;
            [alert show];
        }
        
        
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to get other store error");
    }];
    
}
/*
 Refresh checked and tobuy items according to the UI change
 */
-(void)refreshData{
    /*
    //Dimple-16-09-2015 Fixed #383
    refreshFlag=true;
    
    NSMutableArray *newCheckedItems = [[NSMutableArray alloc]init];
    NSMutableArray *newToBuyItems = [[NSMutableArray alloc]init];
    for (int i=0; i<toBuyItems.count;i++) {
        Item *object = [toBuyItems objectAtIndex:i];
        BOOL isChecked = [object.isChecked boolValue];
        if (isChecked) {
            [newCheckedItems addObject:object];
        }
    }
    
    //Dimple-16-09-2015 Fixed #383
    checkedItems=[[[checkedItems reverseObjectEnumerator]allObjects]mutableCopy];
    for (int i=0; i<checkedItems.count;i++) {
        Item *object = [checkedItems objectAtIndex:i];
        BOOL isChecked = [object.isChecked boolValue];
        if (!isChecked) {
            [newToBuyItems addObject:object];
            
        }
    }
    
    if ([DataStore instance].sortingOrder == STORE) {
        unknownItems = [unknownItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isChecked == %@",[NSNumber numberWithBool:NO]]];
        sortedItems = [sortedItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isChecked == %@",[NSNumber numberWithBool:NO]]];
    }
    
    [checkedItems removeObjectsInArray:newToBuyItems];
    [checkedItems addObjectsFromArray:newCheckedItems];
    
    //Dimple-16-09-2015 Fixed #383
    
    NSArray* reversedCheckedItems = [[[checkedItems reverseObjectEnumerator] allObjects] mutableCopy];   //do this because newest added item should be on the top
    
    checkedItems = [NSMutableArray arrayWithArray:reversedCheckedItems];
    
    //Dimple-16-09-2015 Fixed #383
    myCustomCheckedArr=[NSArray arrayWithArray:(NSArray*)checkedItems];
*/
    /*
    myCustomCheckedArr = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:YES]];
     */
    checkedItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:YES]];
    toBuyItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:NO]];
    
}
#pragma mark - other Methods
-(void)makeChangesInItemCell:(Item *)itemIn withLabel:(UILabel *)labelIn withCell:(ShoppingTableViewCell*)cellIn withButton:(UIButton*)buttonIn{
    CLS_LOG(@"makeChangesInItemCell method called in shoppingmodetableviewcontroller");

    //labelIn.text = [NSString stringWithFormat:@"%@ - %@ - %@", itemIn.text, itemIn.checkOrder, itemIn.checkedAfterStart];
    labelIn.text = itemIn.text;
    cellIn.item = itemIn;
    NSString *text = itemIn.text;
    BOOL isChecked = [itemIn.isChecked boolValue];
    
    DLog(@"%@ taken:%@, check:%@", itemIn.text, itemIn.isTaken, itemIn.isChecked);
    
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
    
    [buttonIn setTitle:text forState:UIControlStateDisabled];
    if (text.length > item_size) {
        [self adjustTitleLabelForKnowText:labelIn withItem:itemIn withFountSize:font_size1 withIsChecked:isChecked withButton:buttonIn withNumberOfLines:0];
    }
    else{
        [self adjustTitleLabelForKnowText:labelIn withItem:itemIn withFountSize:font_size2 withIsChecked:isChecked withButton:buttonIn withNumberOfLines:1];
    }
}
-(void)adjustTitleLabelForKnowText:(UILabel *)labelIn withItem:(Item *)itemIn withFountSize:(CGFloat) fontSizeIn withIsChecked:(BOOL)isChecked withButton:(UIButton *)buttonIn withNumberOfLines:(NSInteger)nomOfLines{
    CLS_LOG(@"adjustTitleLabelForKnowText function is called in ShoppingModeTableviewController");
    CLS_LOG(@"label name :%@,itemname :%@, numberof line :%ld",labelIn.text,itemIn.knownItemText,(long)nomOfLines);

    if (isChecked)
        [buttonIn setHidden:YES];
    else [buttonIn setHidden:NO];
    
    [labelIn setNumberOfLines:nomOfLines];
    
    if ([labelIn respondsToSelector:@selector(setAttributedText:)]) {
        UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSizeIn];
        UIFont *regularFont = [UIFont systemFontOfSize:fontSizeIn];
        UIColor *foregroundColor;
        if (isChecked) {
            foregroundColor = [UIColor grayColor];
        }
        else {
           foregroundColor = [UIColor blackColor];
        }
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName,foregroundColor, NSForegroundColorAttributeName, nil];
        
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:labelIn.text attributes:attrs];
        CLS_LOG(@"adjustTitleLabelForKnowText attributedText :%@",attributedText);

        if (itemIn.knownItemText && itemIn.knownItemText.length != 0 && !isChecked) {
            NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, nil];
            const NSRange range = [labelIn.text rangeOfString:itemIn.knownItemText];
            CLS_LOG(@"adjustTitleLabelForKnowText subAttrs :%@",subAttrs);

            CLS_LOG(@"adjustTitleLabelForKnowText range location :%lu  range length :%lu",(unsigned long)range.location,(unsigned long)range.length);

            [attributedText setAttributes:subAttrs range:range];
        }
        if (isChecked) {
            const NSRange range2 = NSMakeRange(0, labelIn.text.length);
            CLS_LOG(@"adjustTitleLabelForKnowText range2 location :%lu  range2 length :%lu",(unsigned long)range2.location,(unsigned long)range2.length);

            [attributedText addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:range2];
        }
        [labelIn setAttributedText:attributedText];
    }
}
- (void)vibrateDevice: (id) sender {
    if ([Utility getDefaultBoolAtKey:@"vibrateOnPickDropItemBool"] && IS_IPHONE) {
        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    }
}

-(void)showToastMessage:(NSString*)message{
    [ALToastView toastInView:self.view withText:message];
}

# pragma mark ShoppinTableViewProtocol
-(void)shoppingTableViewCellButtonPressed:(ShoppingTableViewCell *)shoppingCell{
    CLS_LOG(@"shoppingTableViewCellButtonPressed method called in shoppingmodetableviewcontroller");

    selectedIndxPath = [self.tableView indexPathForCell:shoppingCell];
    currentRowText = shoppingCell.labelItemTitle.text;
    [self popover:shoppingCell.buttonCheckReason];
}

#pragma mark - SyncEngineDelegate
-(void) didUpdateItems{
    DLog(@"SyncEngine didUpdateItems");
    if([SignificantChangesIndicator sharedIndicator].itemsChanged){
        [self showRefreshButton];
        [[SignificantChangesIndicator sharedIndicator] resetData];
    }
}

#pragma mark - showSpinner

-(void)createWaitOverlay:(NSString*)message
{
    CLS_LOG(@"createWaitOverlay method called in shoppingmodetableviewcontroller");

    //waitOverlayHasBeenShown = YES;
    // fade the overlay in
    if (loadingLabel != nil) {
        return;
    }
    if (message.length > 14) {
        loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 75,self.view.bounds.size.height/2 - 30,210.0, 50.0)];
    }
    else{
        loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 -100,self.view.bounds.size.height/2 - 30,210.0, 20.0)];
    }
    loadingLabel.text = message;
    loadingLabel.numberOfLines = 0;
    loadingLabel.textColor = [UIColor whiteColor];
    bgimage = [[UIImageView alloc] initWithFrame:self.view.frame];
    bgimage.image = [UIImage imageNamed:@"waitOverLay.png"];
    [self.view addSubview:bgimage];
    bgimage.alpha = 0;
    [bgimage addSubview:loadingLabel];
    loadingLabel.alpha = 0;
    
    
    [UIView beginAnimations: @"Fade In" context:nil];
    [UIView setAnimationDelay:0];
    [UIView setAnimationDuration:.5];
    bgimage.alpha = 1;
    loadingLabel.alpha = 1;
    [UIView commitAnimations];
    
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.hidden = FALSE;
    spinner.frame = CGRectMake(self.view.bounds.size.width/2 - 25,self.view.bounds.size.height/2 - 75, 50, 50);
    [spinner setHidesWhenStopped:YES];
    [self.view addSubview:spinner];
    [self.view bringSubviewToFront:spinner];
    [spinner startAnimating];
}

-(void)removeWaitOverlay {
    CLS_LOG(@"removeWaitOverlay method called in shoppingmodetableviewcontroller");

    [UIView beginAnimations: @"Fade Out" context:nil];
    [UIView setAnimationDelay:0];
    [UIView setAnimationDuration:.5];
    bgimage.alpha = 0;
    loadingLabel.alpha = 0;
    [UIView commitAnimations];
    [spinner stopAnimating];
    
    if (loadingLabel != nil) {
        [bgimage removeFromSuperview];
        [loadingLabel removeFromSuperview];
        [spinner removeFromSuperview];
        bgimage = nil;
        loadingLabel = nil;
        spinner = nil;
    }
}
//Raj-21-10-2015
-(void)sortingSyncFinished:(BOOL)withError
{
    CLS_LOG(@"sortingSyncFinished method called in shoppingmodetableviewcontroller");

    if(!is_autoSortAlert)
    {
        [self showRefreshButton];
        self.refreshButton.tintColor=DARK_GREEN_COLOR;
    }
    [SVProgressHUD dismiss];
    if (dataStore.sortingOrder == STORE) {
        [self getSortedItemsByStoreFromServer:true];
    }

    
}
//-(void)sortingSyncFinished {
//    self.refreshButton.enabled = YES;
//}

#pragma mark - rotation
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableView reloadData];
    //this is to redraw the section header so that it suits the width of the tableView
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
}

//Dimple 16-09-2015 //Fixed #382
#pragma mark Orientation
-(BOOL)shouldAutorotate
{
    [super shouldAutorotate];
    return NO;
}
-(NSUInteger) supportedInterfaceOrientations {
    [super supportedInterfaceOrientations];
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskPortrait;
    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    [super preferredInterfaceOrientationForPresentation];
    // Return the orientation you'd prefer - this is what it launches to. The
    // user can still rotate. You don't have to implement this method, in which
    // case it launches in the current orientation
    return UIInterfaceOrientationPortrait;
}

#pragma mark - VISTED STORE API
//Get Visites Store from server
-(void)getVisitedStoreFromServer:(NSNumber*)listId{
    CLS_LOG(@"getVisitedStoreFromServer method called in shoppingmodetableviewcontroller");

    //NSMutableArray *networks = [[NSMutableArray alloc]initWithArray:@[[NSNull null]]];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
//    parameters[@"lat"] = @"57.6788843530097";
//    parameters[@"long"] = @"12.0055747814669";
    
    parameters[@"lat"] = [NSNumber numberWithDouble:currentLocation.coordinate.latitude];
    parameters[@"long"] = [NSNumber numberWithDouble:currentLocation.coordinate.longitude];
    
    //parameters[@"positionAccuracy"] =[NSNumber numberWithInt:(int)currentLocation.horizontalAccuracy];
    //parameters[@"networks"] = networks;
     Location_update=false;
    NSString *request = [NSString stringWithFormat:@"ItemLists/%@/VisitedStores",listId];
    [client POST:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *dict = (NSDictionary*)responseObject;
        DLog(@"dic %@",dict);
        [self loadDataInDropdown:dict];
        
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to getVisitedStore");
       // DLog(@"lat %@",[NSNumber numberWithDouble:currentLocation.coordinate.latitude]);
       // DLog(@"long %@",[NSNumber numberWithDouble:currentLocation.coordinate.longitude]);
        Location_update=false;
        [self LoadStoreHistory];
    }];
}
-(void)loadDataInDropdown:(NSDictionary *)dict
{
    CLS_LOG(@"loadDataInDropdown method called in shoppingmodetableviewcontroller");

    DLog(@"selected store id in Shopping %@",[DataStore instance].sortByStoreID);
    Final_visted_store_Arr=[NSMutableArray arrayWithArray:[dict objectForKey:@"list"]];
    if(Final_visted_store_Arr!=nil && Final_visted_store_Arr.count>0)
    {
        NSMutableDictionary *dicT=[[NSMutableDictionary alloc] init];
        [dicT setObject:[NSString stringWithFormat:@"%@...",NSLocalizedString(@"In the store", nil)] forKey:@"name"];
        
        NSMutableDictionary *dic1T=[[NSMutableDictionary alloc] init];
        [dic1T setObject:dicT forKey:@"store"];
        
        NSMutableDictionary *dicB=[[NSMutableDictionary alloc] init];
        [dicB setObject:[NSString stringWithFormat:@"%@...",NSLocalizedString(@"Other store", nil)] forKey:@"name"];
        
        NSMutableDictionary *dic1B=[[NSMutableDictionary alloc] init];
        [dic1B setObject:dicB forKey:@"store"];
        
        [Final_visted_store_Arr insertObject:dic1T atIndex:0];
        
        [Final_visted_store_Arr addObject:dic1B];
        
        NSLog(@"Final_visted_store_Arr %@",Final_visted_store_Arr);
        [self.menu.tableView reloadData];
        Location_update=false;
        
        if([[dict objectForKey:@"firstIsProbable"] intValue]==1)
        {
            NSDictionary *main_dic=[Final_visted_store_Arr objectAtIndex:1];
            NSDictionary *fav_dic=[main_dic objectForKey:@"store"];
            [self setStoreTitle:[fav_dic objectForKey:@"name"]];
        }
        else
        {
            [self setStoreTitle:NSLocalizedString(@"In the store", nil)];
        }
    }
    else
    {
        self.titleLbl.text=NSLocalizedString(@"In the store", nil);
        [self LoadStoreHistory];
    }

}
-(void)setStoreTitle:(NSString *)store_title
{
    CLS_LOG(@"setStoreTitle method called in shoppingmodetableviewcontroller");

    int nav_title_char=15,title_font_size=17;
    if(IS_IPHONE)
    {
        nav_title_char=18;
        title_font_size=17;
    }
    else
    {
        nav_title_char=30;
        title_font_size=20;
    }
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed:@"backimg"];
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    NSMutableAttributedString *myString=nil;
    if(store_title.length<=nav_title_char)
    {
        myString= [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",store_title]];
    }
    else
    {
        myString= [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",[store_title substringWithRange:NSMakeRange(0, nav_title_char)]]];
    }
    [myString appendAttributedString:attachmentString];
    
    self.titleLbl.attributedText = myString;
    self.titleLbl.textAlignment=NSTextAlignmentCenter;
    [self.titleLbl setFont:[UIFont systemFontOfSize:title_font_size]];
    
    
}
-(void)showStoreList
{
    CLS_LOG(@"showStoreList method called in shoppingmodetableviewcontroller");

    //spinneer up down code
    DLog(@"Store list click event");
    
}

#pragma mark - Visited store Dropdown Delegate mathod
- (NSInteger)numberOfColumnsInMenu:(DOPDropDownMenu *)menu {
    return 1;
}

- (NSInteger)menu:(DOPDropDownMenu *)menu numberOfRowsInColumn:(NSInteger)column {
    if(menu.tag==1)
    {
        if(Final_visted_store_Arr.count>0)
        {
            return Final_visted_store_Arr.count;
        }
        else
        {
            return storeHistory.count;
        }
        
    }
    else
    {
        return popupArr.count;
    }
}
- (NSDictionary *)menu:(DOPDropDownMenu *)menu titleForRowAtIndexPath:(DOPIndexPath *)indexPath {
    if(menu.tag==1)
    {
        if(self.moreBtn.show)
        {
            [self.moreBtn backgroundTapped:nil];
        }
        if(Final_visted_store_Arr.count>0)
        {
            NSDictionary *main_dic=[Final_visted_store_Arr objectAtIndex:indexPath.row];
            NSDictionary *fav_dic=[main_dic objectForKey:@"store"];
           // DLog(@"Fav dic %@",fav_dic);
           // DLog(@"Fav dic %@",main_dic);
            return fav_dic;
        }
        else if(Final_visted_store_Arr.count==0)
        {
            if(indexPath.row>0 && indexPath.row<(storeHistory.count-1))
            {
                Store *store = storeHistory[indexPath.row];
                NSLog(@"History store %@",store);
                NSMutableDictionary *dic=[[NSMutableDictionary alloc] init];
                [dic setValue:store.address forKey:@"address"];
                [dic setValue:store.city forKey:@"city"];
                [dic setValue:store.distance forKey:@"distance"];
                [dic setValue:store.isFavorite forKey:@"isFavorite"];
                [dic setValue:store.storeID forKey:@"id"];
                [dic setValue:store.itemsSortedPercent forKey:@"itemsSortedPercent"];
                [dic setValue:store.name forKey:@"name"];
                [dic setValue:store.postalAddress forKey:@"postalAddress"];
                [dic setValue:store.postalCode forKey:@"postalCode"];
                [dic setValue:store.title forKey:@"title"];
                NSLog(@"history store name %@", store.name);
                NSDictionary *fav_dic=[[NSDictionary alloc] initWithDictionary:dic];
                return fav_dic;

            }
            else
            {
                NSDictionary *main_dic=[storeHistory objectAtIndex:indexPath.row];
                NSDictionary *fav_dic=[main_dic objectForKey:@"store"];
                return fav_dic;

            }
            
        }
        return 0;
    }
    else
    {
        if(self.menu.show)
        {
            [self.menu backgroundTapped:nil];
        }
        return [popupArr objectAtIndex:indexPath.row];
    }
}
- (void)menu:(DOPDropDownMenu *)menu didSelectRowAtIndexPath:(DOPIndexPath *)indexPath
{
    CLS_LOG(@"didSelectRowAtIndexPath method called in shoppingmodetableviewcontroller");

    if(menu.tag==1)
    {
        is_autoSortAlert=true;
        if(indexPath.row==0)
        {
            [self setStoreTitle:NSLocalizedString(@"In the store", nil)];
    //        self.titleLbl.text=NSLocalizedString(@"In the store", nil);
    //        [self.menu removeFromSuperview];
            
        }
        else if(indexPath.row == Final_visted_store_Arr.count-1 || indexPath.row == storeHistory.count-1)
        {
            (theAppDelegate).storeDict=[[NSMutableDictionary alloc] init];
            (theAppDelegate).storeDict=nil;
             [self performSegueWithIdentifier:@"ShoppingToShop" sender:self];
        }
        else
        {
            if(indexPath.row>0)
            {
                if(Final_visted_store_Arr.count==0) //store history
                {
                    Store *store = storeHistory[indexPath.row];
                    self.selectd_store_id=[NSString stringWithFormat:@"%@",store.storeID];
                     [self setStoreTitle:store.name];
                    [self CheckOtherStoreSortedAutomatically:dataStore.currentList.item_listID storeId:store.storeID storeName:store.name];
                }
                else
                {
                        NSDictionary *main_dic=[Final_visted_store_Arr objectAtIndex:indexPath.row];
                        NSDictionary *store_dic=[main_dic objectForKey:@"store"];
                        [self setStoreTitle:[store_dic objectForKey:@"name"]];
                        self.selectd_store_name=[store_dic objectForKey:@"name"];
                        self.selectd_store_id=[store_dic objectForKey:@"id"];

                        //add selected store in coredata
                        NSNumber *store_id= [NSNumber numberWithInt:[self.selectd_store_id intValue]];
                        if ([Store getStoreByID:store_id] == nil)
                        {
                            
                            Store* inserted_store=  [Store insertSearchedStore:[store_dic objectForKey:@"title"] storeCity:[store_dic objectForKey:@"city"] postalAddress:[store_dic objectForKey:@"postalAddress"] postalCode:[NSNumber numberWithInt:[[store_dic objectForKey:@"postalCode"] intValue]] name:[store_dic objectForKey:@"name"] distance:[NSNumber numberWithInt:[[store_dic objectForKey:@"distance"] intValue]] isFavorite:[NSNumber numberWithInt:[[store_dic objectForKey:@"isFavorite"] intValue]] itemsSortedPercent:[NSNumber numberWithInt:[[store_dic objectForKey:@"itemsSortedPercent"] intValue]] storeID:[NSNumber numberWithInt:[[store_dic objectForKey:@"id"] intValue]] address:[store_dic objectForKey:@"address"]];
                            
                                [DataStore instance].sortByStoreID = inserted_store.storeID;
                                [DataStore instance].currentList.sortByStoreId= inserted_store.storeID;
                                //[Item_list changeList:[DataStore instance].currentList byNewOrder:STORE andStoreID:inserted_store.storeID];  //up

                        }
                        else
                        {
                            [DataStore instance].sortByStoreID = store_id;
                            [DataStore instance].currentList.sortByStoreId = store_id;
                           //[Item_list changeList:[DataStore instance].currentList byNewOrder:STORE andStoreID:store_id];  //up
                        }
                        
                        // check for hasAutomaticSortData
                        if([[main_dic objectForKey:@"hasAutomaticSortData"] intValue]==1)
                        {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Vist_store_alert_Title", nil) message:[NSString stringWithFormat:@"%@%@.%@",NSLocalizedString(@"Vist_store_alert_msg1", nil),self.selectd_store_name,NSLocalizedString(@"Vist_store_alert_msg2", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:NSLocalizedString(@"Cancel", nil), nil];
                            alert.tag=1;
                            [alert show];

                        }
                }// eof else
            }
        }
    }
    else
    {
        if(indexPath.row==0)//Manual sorting
        {
            [self performSegueWithIdentifier:@"shoppingToSort" sender:self];
        }
        else if(indexPath.row==1)//Help
        {
            [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self force:YES];
        }
        
        if(self.moreBtn.show)
        {
            [self.moreBtn backgroundTapped:nil];
        }
    }
}
#pragma mark AlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    CLS_LOG(@"alertview clickedButtonAtIndex delegate method called in shoppingmodetableviewcontroller");

    if (alertView.tag == 1)
    {
        if (buttonIndex == 0)
        {
            DLog(@"OK");
            is_autoSortAlert=true;
            [DataStore instance].sortingOrder = STORE;
            [DataStore instance].sortByStoreID = [NSNumber numberWithInt:[self.selectd_store_id intValue]];
            [DataStore instance].currentList.sortByStoreId= [NSNumber numberWithInt:[self.selectd_store_id intValue]];
            
            [Item_list changeList:[DataStore instance].currentList byNewOrder:STORE andStoreID: [DataStore instance].currentList.sortByStoreId];  //update database
            
            [[SortingSyncManager sharedSortingSyncManager] forceSync];
            Store *store = [Store getStoreByID:[NSNumber numberWithInt:[self.selectd_store_id intValue]]];
            DLog(@"selected store id %@",[NSNumber numberWithInt:[self.selectd_store_id intValue]]);
            DLog(@"store %@",store);
            
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Sort items for",nil), store.name] maskType:SVProgressHUDMaskTypeClear];

            
            
        }
        else if (buttonIndex == 1)
        {
            DLog(@"Cancel");
        }
    }
}

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    CLS_LOG(@"prepareForSegue method called in shoppingmodetableviewcontroller");

    if ([segue.identifier isEqualToString:@"ShoppingToShop"])
    {
        ShopsTableViewController *controller = (ShopsTableViewController*)segue.destinationViewController;
        controller.is_comming_from_items=NO;
    }
    else if([segue.identifier isEqualToString:@"shoppingToSort"])
    {
        SortTableViewController *controller = (SortTableViewController*)segue.destinationViewController;
        [self refreshData];
        
        if (dataStore.sortingOrder == STORE) {
            [self getSortedItemsByStoreFromServer:false];
        }
        if(dataStore.sortingOrder == STORE) {
            NSMutableArray *items = [NSMutableArray new];
            [items addObjectsFromArray: unknownItems];
            [items addObjectsFromArray:sortedItems];
            controller.itemsList = items;
        }
        else {
            toBuyItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:NO]];
            checkedItems = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeletedFromList:dataStore.currentList withId:dataStore.currentList.item_listID andSortInOrder:dataStore.sortingOrder andIsChecked:YES]];
            
            controller.itemsList = toBuyItems;
        }
        controller.is_sorttype= dataStore.sortingOrder == GROUPED || dataStore.sortingOrder == STORE || dataStore.sortingOrder == MANUAL;
    }
}

- (void) wakeUp: (NSNotification*)notification {
    [SyncManager sharedManager].syncManagerDelegate = self;
    [self didUpdateItems];
}
#pragma mark- Display categorywise different color
-(void)DisplayCategorywiseColor
{
    CLS_LOG(@"DisplayCategorywiseColor method called in shoppingmodetableviewcontroller");

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
    if (checkedItems.count>0)
    {
        Item *firstItem=checkedItems[0];
        old_cat=firstItem.placeCategory;
        toCheckedcolorArr=[[NSMutableArray alloc]init];
        for (int i=0; i<checkedItems.count; i++) {
            Item *firstItem=checkedItems[i];
            new_cat=firstItem.placeCategory;
            // DLog(@"old cat1 :%@ || new cat1 :%@",old_cat,new_cat);
            if([old_cat isEqualToString:new_cat] && old_cat!=nil && new_cat!=nil)
            {
                if(checkedItems.count>0 && toBuyItems.count==0)
                {
                    if(colorFlag2==0)
                    {
                        colorFlag=0;
                        [toCheckedcolorArr addObject:@"Blue"];
                    }
                    else
                    {
                        colorFlag=1;
                        [toCheckedcolorArr addObject:@"Green"];
                        
                    }
                }
                else{
                    if(colorFlag2==0)
                    {
                        colorFlag=0;
                        [toCheckedcolorArr addObject:@"Green"];
                    }
                    else
                    {
                        colorFlag=1;
                        [toCheckedcolorArr addObject:@"Blue"];
                        
                    }
                    
                }
            }
            else{
                old_cat=new_cat;
                if(sortedItems.count>0 && unknownItems.count==0)
                {
                    if(colorFlag==0)
                    {
                        [toCheckedcolorArr addObject:@"Green"];
                        colorFlag=1;
                        colorFlag2=1;
                    }
                    else{
                        [toCheckedcolorArr addObject:@"Blue"];
                        colorFlag=0;
                        colorFlag2=0;
                    }
                }
                else{
                    if(colorFlag==0)
                    {
                        [toCheckedcolorArr addObject:@"Blue"];
                        colorFlag=1;
                        colorFlag2=1;
                    }
                    else{
                        [toCheckedcolorArr addObject:@"Green"];
                        colorFlag=0;
                        colorFlag2=0;
                    }
                }
            }
            
        }
    }
    
}

-(void) FloatingBtnTap:(id)sender {
    [self onClickRefresh:nil];
}

- (void) showRefreshButton {
    [self fadeInAnimation:self.refreshButton];
    self.refreshButton.hidden = NO;
}

- (void) hideRefreshButton {
    [self fadeInAnimation:self.refreshButton];
    self.refreshButton.hidden = YES;

}

-(void)fadeInAnimation:(UIView *)aView {
    
    CATransition *transition = [CATransition animation];
    transition.type =kCATransitionFade;
    transition.duration = 0.2f;
    transition.delegate = self;
    [aView.layer addAnimation:transition forKey:nil];
}
#pragma mark- Scrollview delegate Method
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    CLS_LOG(@"scrollViewWillBeginDragging method called in shoppingmodetableviewcontroller");

    if(self.moreBtn.show)
    {
        [self.moreBtn backgroundTapped:nil];
    }
}

-(void) helpDialogDismissed {
    [self getCurrentLocation];
}

- (void)showPossibleMatches:(NSMutableArray *)arrPossibleMatches withSelectedItem:(id)selectedItem1
{
    if(!customPickerView) {
        CLS_LOG(@"showPossibleMatches method called in shoppingmodetableviewcontroller");

        [self showPickerView:@"possibleMatches" withArray:arrPossibleMatches withItem:(Item *)selectedItem1];
    }
}

- (void)showPickerView:(NSString *)type withArray:(NSMutableArray *)array withItem:(Item *)item
{
    CLS_LOG(@"showPickerView method called in shoppingmodetableviewcontroller");

    customPickerView = [CustomPickerView createViewWithItems:array pickerType:type];
    customPickerView.delegate = self;
    customPickerView.selectedItem = item;
    /*
     CGRect frame = self.customPickerView.frame;
     //frame.size.height = 260;
     frame.size.width = self.view.frame.size.width;
     
     self.customPickerView.frame = frame;
     */
    customPickerView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height + 300);
    
    [self.view addSubview:customPickerView];
    
    [UIView animateWithDuration:0.5 animations:^{
        customPickerView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height - 80);
    }completion:^(BOOL finished) {
        customPickerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *viewsDictionary = @{@"pickerView":customPickerView};
        NSArray *constraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[pickerView]-0-|"
                                                                            options:0
                                                                            metrics:nil
                                                                              views:viewsDictionary];
        [self.view addConstraints:constraint_POS_H];
        NSArray *constraint_POS_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[pickerView]-|"
                                                                            options:0
                                                                            metrics:nil
                                                                              views:viewsDictionary];
        [self.view addConstraints:constraint_POS_V];
        
    }];
}

- (void)CancelTapped
{
    CLS_LOG(@"CancelTapped method called in shoppingmodetableviewcontroller");

    //Dimple-21-10-2015
    [UIView animateWithDuration:0.5 animations:^{
        customPickerView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height + 200);
    }completion:^(BOOL finished) {
        [customPickerView removeFromSuperview];
        customPickerView = nil;
    }];
}
- (void)pickerView:(CustomPickerView *)pickerView withSelectedOption:(NSInteger)optionIndex
{
    CLS_LOG(@"picker view >> withSelectedOption method called in shoppingmodetableviewcontroller");

    NSString *matchingItem = [pickerView.items objectAtIndex:optionIndex];
    if (![matchingItem isEqualToString:@"?"])
    {
        [pickerView.selectedItem updateItemWithMatchingText:matchingItem andIsPossibleMatch:[NSNumber numberWithBool:true]];
        
        [[SyncManager sharedManager] forceSync];
        [self.tableView reloadData];
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        customPickerView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height + 200);
    }completion:^(BOOL finished) {
        [customPickerView removeFromSuperview];
        customPickerView = nil;
    }];
}
-(void)LoadStoreHistory
{
    storeHistory=[[NSMutableArray alloc] init];
    storeHistory=[NSMutableArray arrayWithArray:[Store getAllStores]];
    
    if(storeHistory.count>0 && storeHistory != nil)
    {
        NSMutableDictionary *dicT=[[NSMutableDictionary alloc] init];
        [dicT setObject:[NSString stringWithFormat:@"%@...",NSLocalizedString(@"In the store", nil)] forKey:@"name"];
        [self setStoreTitle:NSLocalizedString(@"In the store", nil)];
        NSMutableDictionary *dic1T=[[NSMutableDictionary alloc] init];
        [dic1T setObject:dicT forKey:@"store"];
        
        NSMutableDictionary *dicB=[[NSMutableDictionary alloc] init];
        [dicB setObject:[NSString stringWithFormat:@"%@...",NSLocalizedString(@"Other store", nil)] forKey:@"name"];
        
        NSMutableDictionary *dic1B=[[NSMutableDictionary alloc] init];
        [dic1B setObject:dicB forKey:@"store"];
        
        [storeHistory insertObject:dic1T atIndex:0];
        
        [storeHistory addObject:dic1B];
        
        
        
        [self.menu.tableView reloadData];
    }

}
@end
