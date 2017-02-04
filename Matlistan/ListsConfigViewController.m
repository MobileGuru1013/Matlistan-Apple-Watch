//
//  ListsConfigViewController.m
//  MatListan
//
//  Created by Yan Zhang on 21/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ListsConfigViewController.h"
#import "Item_list+Extra.h"
#import "SWRevealViewController.h"

@interface ListsConfigViewController ()
{
    NSMutableArray *allLists;
    Item_list *selectedList;
    NSNumber *listID_toDelete;
    NSIndexPath *selectedIndexPath;
}
@end

@implementation ListsConfigViewController

- (void)didUpdateItems
{
    DLog(@"get updated items from server");
    allLists = [NSMutableArray arrayWithArray:[Item_list getAllLists]];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textfieldNewListName.delegate = self;
    self.txtView.layer.cornerRadius=3;
    self.buttonAdd.layer.cornerRadius=3;
    [self.textfieldNewListName sizeToFit];
    
    allLists = [NSMutableArray arrayWithArray:[Item_list getAllLists]];
    
    selectedList = [DataStore instance].currentList;
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
    
    
    //Dimple 5-10-15
    SWRevealViewController *reveal = self.revealViewController;
    reveal.panGestureRecognizer.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [SyncManager sharedManager].syncManagerDelegate = self;
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(wakeUp:) name: @"UpdateUINotification" object: nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
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
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPremiumAccountPurchased object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateUINotification" object:nil];
    
    if (self.isMovingFromParentViewController)
    {
        [DataStore instance].currentList = selectedList;
        [DataStore instance].hasListBeenShown = YES;
        [DataStore instance].sortByStoreID = selectedList.sortByStoreId;
        [DataStore instance].sortingOrder = (SORT_TYPE)[Item_list getSortType:[DataStore instance].currentList];
        
        DLog(@"list %@", selectedList.name);
    }
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI related

- (IBAction)onClickAdd:(id)sender
{
    [self TextBoxAnimationStop];
    if (self.textfieldNewListName.text.length == 0) {
        return;
    }
    [self addNewList];
}

- (void)addNewList
{
    [Item_list insertNewListWithName: self.textfieldNewListName.text];  //save in core data
    allLists = [NSMutableArray arrayWithArray:[Item_list getAllLists]];
    
    [[SyncManager sharedManager] forceSync];
    [self.tableView reloadData];
    
    self.textfieldNewListName.text = @"";
}

#pragma mark - ListAdd Animation
//Raj - 29-9-15
- (IBAction)TextBtnClick:(id)sender
{
    [self TextBoxAnimationStart];
    
}
// Raj - 29-9-15
// Animation for add item textbox
-(void)TextBoxAnimationStart
{
   // self.textBtn.hidden=YES;
    
    
    int text_frame=53,text_width=(SCREEN_WIDTH*78.75)/100;
    if(IS_IPHONE)
    {
        text_frame=53;
        text_width=(SCREEN_WIDTH*78.75)/100;
    }
    else
    {
        text_frame=65;
        text_width= (SCREEN_WIDTH * 88.54)/100;
    }
    
    self.textBtn.hidden=YES;
    [self.textfieldNewListName becomeFirstResponder];
        
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect newFrame1= self.textfieldNewListName.frame;
                         newFrame1.origin.x= 10;
                         newFrame1.size.width= text_width;
                         self.textfieldNewListName.frame = newFrame1;
                         self.textfieldNewListName.textAlignment=NSTextAlignmentLeft;
                         
                         CGRect newFrame = self.txtView.frame;
                         newFrame.size.width -= text_frame;
                         self.txtView.frame=newFrame;
                     }
                     completion:^(BOOL finished){
                     }];
    [UIView commitAnimations];
    
}
-(void)TextBoxAnimationStop
{
    
    int text_frame=53;
    if(IS_IPHONE)
    {
        text_frame=53;
    }
    else
    {
        text_frame=65;
    }
    
    [self.textfieldNewListName resignFirstResponder];
    const float movementDuration = 0.3; // tweak as needed
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    [self.tableView setContentOffset:CGPointMake(0, 0)];
    [UIView commitAnimations];
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         int textfieldForNewItem_x=(SCREEN_WIDTH * 26.88)/100;
                         CGRect newFrame1= self.textfieldNewListName.frame;
                         newFrame1.origin.x= textfieldForNewItem_x;
                         newFrame1.size.width= (SCREEN_WIDTH * 46.25)/100;
                         self.textfieldNewListName.frame = newFrame1;
                         self.textfieldNewListName.textAlignment=NSTextAlignmentCenter;
                         
                         CGRect newFrame = self.txtView.frame;
                         newFrame.size.width += text_frame;
                         self.txtView.frame=newFrame;
                         
                     }
                     completion:^(BOOL finished){
                         self.textBtn.hidden=NO;
                     }];
    [UIView commitAnimations];
    
}
#pragma mark - TableView delegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(IS_IPHONE)
    {
        return 44;
    }
    else
    {
        return 70;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return allLists.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:  (NSIndexPath *)indexPath
{
    int font_size=17;
    if(IS_IPHONE)
    {
        font_size=17;
    }
    else
    {
       font_size=25;
    }
    
    ListItemCell* cell = (ListItemCell*)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    Item_list *list = allLists[indexPath.row];
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", list.name];
    [cell.titleLabel setFont:[UIFont systemFontOfSize:font_size]];
    
    cell.button.property = list.item_listID;
    [cell.button addTarget:self action:@selector(onClickFavoriteButton:) forControlEvents:UIControlEventTouchDown];
    [self setFavoriteButtonBackground:cell.button withState:[list.isDefault boolValue]];
    
    if (![list.isDefault boolValue])
    {
        //Dimple
        cell.deleteBtn.hidden=NO;
        [cell.deleteBtn addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
        

       /*
        // Add utility buttons
        NSMutableArray *rightUtilityButtons = [NSMutableArray new];
        [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:NSLocalizedString(@"Delete",nil)];
        cell.rightUtilityButtons = rightUtilityButtons;*/
    }
    else
    {
        //Dimple
        cell.deleteBtn.hidden=YES;

        //cell.rightUtilityButtons = nil;
    }
    
    cell.listID = list.item_listID;
    cell.delegate = self;

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.textfieldNewListName isFirstResponder])
    {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self TextBoxAnimationStop];
        [self.tableView endUpdates];
        [self.textfieldNewListName resignFirstResponder];
    }
    else{
    //TODO when view is swiped to remove then this list is selected. So a default list should be selected after this is removed.
    selectedList = [allLists objectAtIndex:indexPath.row];
    
    [DataStore instance].currentList = selectedList;
    [DataStore instance].hasListBeenShown = YES;
    [DataStore instance].sortByStoreID = selectedList.sortByStoreId;
    [DataStore instance].sortingOrder = (SORT_TYPE)[Item_list getSortType:[DataStore instance].currentList];

//        [[WatchConnectivityController sharedInstance] changeShoppingList];
    
    DLog(@"list %@", selectedList.name);
    
    [self.navigationController popViewControllerAnimated:YES];  //Go back to ItemsViewcontroller
    }
}

//Dimple-10-10-2015
-(void)deleteItem:(UIButton*)sender
{
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    selectedIndexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    ListItemCell* cell = (ListItemCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
    
    ListItemCell *itemCell = (ListItemCell*)cell;
    listID_toDelete = itemCell.listID;
    
    [self.tableView reloadData];
    [self showDeleteChoice:NSLocalizedString(@"Do you want to remove the list?",nil)];
    
    
    
}
/*#pragma mark - Swipe function
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    ListItemCell *itemCell = (ListItemCell*)cell;
    listID_toDelete = itemCell.listID;
    
    switch (index) {
    
        case 0:
        {
            // Delete button is pressed
            selectedIndexPath = [self.tableView indexPathForCell:cell];
            [self showDeleteChoice:NSLocalizedString(@"Do you want to remove the list?",nil)];
            break;
        }
        default:
            break;
    }
}
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state{
    if (state == kCellStateRight) {
        
        NSArray *indxPathsArray = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indxPath in indxPathsArray) {
            
            SWTableViewCell *tmpCell = (SWTableViewCell *)[self.tableView cellForRowAtIndexPath:indxPath];
            if (tmpCell != cell) {
                [tmpCell hideUtilityButtonsAnimated:NO];
            }
        }
        if ([self.textfieldNewListName isFirstResponder]) {
            [self.textfieldNewListName resignFirstResponder];
        }
    }
}
*/
-(void)showDeleteChoice:(NSString*)msg{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil) message:msg delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // Set buttonIndex == 1 to handel "Ok"/"Yes" button response
    if (buttonIndex == 1) {
        //Fake delete in core data
        [Item_list fakeDelete:listID_toDelete];
        //Delete in the tableView
        [allLists removeObjectAtIndex:(NSUInteger) selectedIndexPath.row];
        if (allLists.count > 0) {
            [DataStore instance].currentList = allLists[0];
            selectedList = allLists[0];
            DLog(@"list %@", selectedList.name);
        }
        [[SyncManager sharedManager] forceSync];
        [self.tableView deleteRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if(buttonIndex == 0)
    {
        [self.tableView reloadData];    //to make the more/delete buttons disappear
        
    }
}

-(void)onClickFavoriteButton:(id)sender{
    //Set the list to be default list
    NSNumber *prevDefaultListID = [Item_list getDefaultListId];
    UIButton *button = (UIButton*)sender;
    NSNumber *listID = (NSNumber*)button.property;
    Item_list *clickedList = [Item_list getListById:listID];
    
    if ([clickedList.isDefault boolValue] == NO) {
        //Change to be default list and reset the one which has been defaul list
        /*
        [Item_list switchList:listID IsDefaultTo:YES];
        [Item_list switchList:prevDefaultListID IsDefaultTo:NO];
         */
        [Item_list setToDefaultList:listID unsetList:prevDefaultListID];
        allLists = [NSMutableArray arrayWithArray:[Item_list getAllLists]];
        [self.tableView reloadData];
    }
    [[SyncManager sharedManager] forceSync];
    
}

-(void)setFavoriteButtonBackground:(UIButton*)favButton withState:(BOOL)isDefault{
    if (isDefault) {
        [favButton setBackgroundImage:[UIImage imageNamed:@"starFilled"] forState:UIControlStateNormal];
    }
    else{
        [favButton setBackgroundImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
    }
}

#pragma mark - HideKeyboard

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self TextBoxAnimationStop];
    [textField resignFirstResponder];
    if (textField.text.length > 0) {
        [self addNewList];
    }
    
    return YES;
}
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    [self reloadTheseCells:[self.tableView indexPathsForVisibleRows]];
     textField.textAlignment=NSTextAlignmentLeft;
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self.textfieldNewListName resignFirstResponder];
}
#pragma mark - otherMehods
-(void)reloadTheseCells:(NSArray *)arrayIn{
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:arrayIn withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}
#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [view setAlpha:1];
    [UIView commitAnimations];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [view setAlpha:0];
    [UIView commitAnimations];
}

- (void) wakeUp: (NSNotification*)notification {
    [SyncManager sharedManager].syncManagerDelegate = self;
    [self didUpdateItems];
}
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing ListsConfigViewController");
}

@end
