//
//  ShoppingListsTableViewController.m
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ShoppingListsTableViewController.h"
#import "DataStore.h"
#import "Communicator.h"
#import "Utility.h"
#import "ShoppingModeTableViewController.h"
#import "SortingViewController.h"
#import <MTLJSONAdapter.h>
#import "Item+Extra.h"
#import "Item_list+Extra.h"
#import "ItemCell.h"
#import "ChangeTextViewController.h"
#import "Store+Extra.h"
#import "MatlistanHTTPClient.h"

@interface ShoppingListsTableViewController ()
{
    NSMutableArray *itemsList;
    NSMutableArray *sortedItems;
    NSMutableArray *unknownItems;
    NSNumber *defaultListId;
    UITextField *newItemTextField;
    NSString *cookie;
    NSNumber *selectedItemId;
    NSIndexPath *selectedIndexPath;
    NSString *favoriteStoreName;
    Store *favoriteStore;
    
}
@property(strong) MatlistanHTTPClient *httpClient;
@property(strong) SyncEngine *engine;
@end

@implementation ShoppingListsTableViewController
@synthesize httpClient,engine;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Get sorting type from NSDefaults
    
  //  [DataStore instance].sortingOrder = (SORT_TYPE)[[NSUserDefaults standardUserDefaults] integerForKey:SORT_KEY];
    
    httpClient = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    httpClient.delegate = self;
    
    engine = [SyncEngine sharedEngine];
    engine.delegate = self;
    
    if ([DataStore instance].tagByURL.length > 0) {
        [self performSegueWithIdentifier:@"listToRecipes" sender:self];
    }
    
    itemsList = [[NSMutableArray alloc]init];
    unknownItems = [[NSMutableArray alloc]init];
    sortedItems = [[NSMutableArray alloc]init];
    
    [self loadRecordsFromCoreData]; //read data from local core data
    
    newItemTextField.delegate = self;
    
    UIImage *imageVagn = [UIImage imageNamed:@"vagn"];
    UIImage *imageSort = [UIImage imageNamed:@"sort"];
    UIImage *imageMenu = [UIImage imageNamed:@"menu"];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:imageMenu style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
    
     UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithImage:imageSort style:UIBarButtonItemStylePlain target:self action:@selector(showSortingView)];
    
    UIBarButtonItem *storeButton = [[UIBarButtonItem alloc]
                               initWithImage:imageVagn style:UIBarButtonItemStylePlain target:self action:@selector(switchToStore)];
    
    
    NSArray *arrBtns = [[NSArray alloc]initWithObjects:menuButton,sortButton,storeButton, nil];
    self.navigationItem.leftBarButtonItems = arrBtns;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
   //  self.navigationItem.rightBarButtonItem = self.editButtonItem;

    //For sorting manually
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self.tableView addGestureRecognizer:longPress];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSorting:) name:@"SortingChanged" object:nil];
   
}
- (IBAction)longPressGestureRecognized:(id)sender {
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    CGPoint location = [longPress locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    static UIView       *snapshot = nil;        ///< A snapshot of the row user is moving.
    static NSIndexPath  *sourceIndexPath = nil; ///< Initial index path, where gesture begins.
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                sourceIndexPath = indexPath;
                
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                // Take a snapshot of the selected row using helper method.
                snapshot = [self customSnapshotFromView:cell];
                
                // Add the snapshot as subview, centered at cell's center...
                __block CGPoint center = cell.center;
                snapshot.center = center;
                snapshot.alpha = 0.0;
                [self.tableView addSubview:snapshot];
                [UIView animateWithDuration:0.25 animations:^{
                    
                    // Offset for gesture location.
                    center.y = location.y;
                    snapshot.center = center;
                    snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
                    snapshot.alpha = 0.98;
                    
                    // Fade out.
                    cell.alpha = 0.0;
                    
                } completion:^(BOOL finished) {
                    
                    cell.hidden = YES;
                    
                }];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint center = snapshot.center;
            center.y = location.y;
            snapshot.center = center;
            
            // Is destination valid and is it different from source?
            if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
                
                // ... update data source.
                [itemsList exchangeObjectAtIndex:indexPath.row withObjectAtIndex:sourceIndexPath.row];
                
                [self updateAllItemsManualIndex];  // update all index in core data
                // ... move the rows.
                [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                
                // ... and update source so it is in sync with UI changes.
                sourceIndexPath = indexPath;
            }
            break;
        }
        default: {
            // Clean up.
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
            cell.hidden = NO;
            cell.alpha = 0.0;
            [UIView animateWithDuration:0.25 animations:^{
                
                snapshot.center = cell.center;
                snapshot.transform = CGAffineTransformIdentity;
                snapshot.alpha = 0.0;
                
                // Undo fade out.
                cell.alpha = 1.0;
                
            } completion:^(BOOL finished) {
                
                sourceIndexPath = nil;
                [snapshot removeFromSuperview];
                snapshot = nil;
                
            }];
            break;
        }
       
    }
}
-(void)updateAllItemsManualIndex{
   
    for (int i=0; i<itemsList.count; i++) {
        Item *item = [itemsList objectAtIndex:i];
        [Item updateItem:item.itemID WithManualIndex:i];
    }
}
-(void)loadRecordsFromCoreData{
    defaultListId = [Item_list getDefaultListId];
    if ([DataStore instance].sortingOrder == STORE) {
        [self getSortedStoresFromServer];
    }
    else{
        itemsList = [NSMutableArray arrayWithArray:[Item getAllItemsExceptDeleted:[DataStore instance].sortingOrder inList:defaultListId]];
    }
    [self.tableView reloadData];
}
//GET /ItemLists/{id}/SortedByStore/{storeId}
-(void)getSortedStoresFromServer{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc]init];
    NSString *request = [NSString stringWithFormat:@"ItemLists/%@/SortedByStore/%@", defaultListId, [DataStore instance].sortByStoreID];
    SyncEngine *httpClient = [SyncEngine sharedEngine];
    [httpClient GET:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *dict = (NSDictionary*)responseObject;
        sortedItems = [dict objectForKey:@"sortedItems"];
        unknownItems = [dict objectForKey:@"unknownItems"];
        DLog(@"Get sorted stores");
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Fail to get sorted stores");
    }];
    
}
#pragma SyncEngineDelegate
-(void)SyncEngine:(SyncEngine *)engine didUpdateItems:(id)allItems{
    DLog(@"get updated items from server");
    [self loadRecordsFromCoreData];
    //[self.tableView reloadData];
}
#pragma MatlistanHTTPClientDelegate

-(void)matlistanHTTPClient:(MatlistanHTTPClient *)client didLogin:(id)cookie{

 //Create sync thread
    dispatch_queue_t queue = dispatch_queue_create("com.matlistan.sync", NULL);
    
    dispatch_async(queue, ^{
        [[SyncEngine sharedEngine] startSync];
    });
    
}
-(void)matlistanHTTPClient:(MatlistanHTTPClient *)client didFailWithError:(NSError *)error{
    NSLog(@"table - fail login");
}

#pragma view
-(void)viewWillAppear:(BOOL)animated{
    newItemTextField.text = [DataStore instance].ingredientByURL;
    DLog(@"Sort by storeID %@",[DataStore instance].sortByStoreID);
    [self loadRecordsFromCoreData]; //read data from local core data
    
}
/*
 *Show the sorting types in action sheet
 * Senast överst, Alfabetiskt, Per kategori, Sortera efter butik ... 
 * Senast överst, Alfabetiskt, Per kategori, Egen sortering(this is manual sorting), butik namn, Annan butik
 
 "Latest first"="Latest first";
 "Alphabetically"="Alphabetically";
 "By category"="By category";
 "Own sorting"="Own sorting";
 "Another store"="Another store";
 "Sort by store"="Sort by store";
 */
-(void)showSortingView{
    [DataStore instance].shops = [Store getStoresCloseby];
    favoriteStoreName = @"";
    UIActionSheet *popup = nil;
    if ([DataStore instance].shops.count > 0) {
        favoriteStore = [Store getFavoriteStore];
        if (favoriteStore != nil) {
            favoriteStoreName = favoriteStore.name;
        }
        popup = [[UIActionSheet alloc] initWithTitle:@"Sortering" delegate:self cancelButtonTitle:@"Avbryt" destructiveButtonTitle:nil otherButtonTitles:@"Senast överst", @"Alfabetiskt", @"Per kategori", @"Egen sortering", favoriteStoreName, @"Annan butik ...",nil];

    }
    else{
        popup = [[UIActionSheet alloc] initWithTitle:@"Sortering" delegate:self cancelButtonTitle:@"Avbryt" destructiveButtonTitle:nil otherButtonTitles:@"Senast överst", @"Alfabetiskt", @"Per kategori", @"Sortera efter butik ...",
                 nil];
    }
    popup.tag = 1;
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}


#pragma Actionsheet
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
                    [DataStore instance].sortingOrder = DATE;
                    DLog(@"Click Senast överst");
                    break;
                case 1:
                    [DataStore instance].sortingOrder = DEFAULT;
                     DLog(@"Click Alfabetiskt");
                    break;
                case 2:
                    [DataStore instance].sortingOrder = GROUPED;
                    DLog(@"Click per kategori");
                    break;
                case 3:
                    [DataStore instance].sortingOrder = MANUAL;
                    DLog(@"Click egen sortering");
                    break;
                case 4:
                {
                    [DataStore instance].sortingOrder = STORE;
                    DLog(@"Click store");
                    if (favoriteStoreName.length == 0) {
                        [self showStores];
                    }
                    else{
                        [DataStore instance].sortByStoreID = favoriteStore.storeID;
                    }
                    break;
                }
                case 5:
                    [DataStore instance].sortingOrder = STORE;
                    [self showStores];
                    break;
                default:
                    break;
            }
            break;
        }

        default:
            break;
    }
    DLog(@"sort type: %d",[DataStore instance].sortingOrder );
    [self.tableView reloadData];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];

    [self loadRecordsFromCoreData];
}
/*
 *This is called when click "Annan butik..." or "Sortera efter butik ... "
 */
-(void)showStores{
    [self performSegueWithIdentifier:@"ListToStores" sender:self];
}

-(void)switchToStore{
     [self performSegueWithIdentifier:@"ListToShoppingMode" sender:self];
}
-(void)showMenu{
    [self.frostedViewController presentMenuViewController];

}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ListToShoppingMode"]) {
        [DataStore instance].sorteditemsList = itemsList;
    }
    else if([segue.identifier isEqualToString:@"toChangeItem"]){
        ChangeTextViewController *controller = (ChangeTextViewController*)segue.destinationViewController;
        controller.itemId = selectedItemId;
    }
}
#pragma notification way
- (void)dealloc {
    
    // we are no longer interested in these notifications:
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SortingChanged" object:nil];
    
}
-(void)changeSorting:(NSNotification *)notif{
    //resort list
    SORT_TYPE type = [DataStore instance].sortingOrder;
    DLog(@"sorting by %d",type);
    [self loadRecordsFromCoreData];
    //[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
   // Return the number of sections.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowSum = 0;
    switch (section) {
        case 0:
            rowSum = 0;
            break;
        case 1:
            rowSum = [DataStore instance].sortingOrder == STORE? unknownItems.count : itemsList.count;
            DLog(@"sortingOrder %d, section %d, row sum %d",[DataStore instance].sortingOrder,section,rowSum);
            break;
        case 2:
            rowSum  = [DataStore instance].sortingOrder == STORE? sortedItems.count : 0;
            DLog(@"sortingOrder %d, section %d, row sum %d",[DataStore instance].sortingOrder,section,rowSum);
            break;
        default:
            break;
    }
    return rowSum; // Return the number of rows in the section.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ItemCell *cell = (ItemCell*)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    Item *item = nil;
    DLog(@"Index section %d",indexPath.section);
    // Configure the cell...
    if([DataStore instance].sortingOrder == STORE){
        NSNumber *itemId = nil;
        if(indexPath.section == 1) {
            if (unknownItems!= nil && unknownItems.count > 0) {
               itemId = unknownItems[indexPath.row];
            }
        }
        else if(indexPath.section ==2){
            if (sortedItems != nil && sortedItems.count > 0) {
                itemId = sortedItems[indexPath.row];
            }
        }
        item = [Item getItemInList:defaultListId withItemID:itemId];
    }
    else{
        item = [itemsList objectAtIndex:indexPath.row];
    }
    
    // Add utility buttons
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:NSLocalizedString(@"Change",nil)];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:NSLocalizedString(@"Delete",nil)];
    
    cell.rightUtilityButtons = rightUtilityButtons;
    cell.delegate = self;
    
    if (item!=nil) {
        cell.itemId = item.itemID;
        cell.titleLabel.text = item.text;
        if (item.text.length > 36) {
            cell.titleLabel.numberOfLines = 0;
            [cell.titleLabel setFont:[UIFont systemFontOfSize:14]];
        }
        else{
            cell.titleLabel.numberOfLines = 1;
            [cell.titleLabel setFont:[UIFont systemFontOfSize:17]];
        }

    }

    return cell;
}
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    
    ItemCell *itemCell = (ItemCell*)cell;
    selectedItemId = itemCell.itemId;
    
    switch (index) {
        case 0:
        {
            // Change button is pressed
            // show change view
            [self performSegueWithIdentifier:@"toChangeItem" sender:self];
            [cell hideUtilityButtonsAnimated:YES];
            break;
        }
        case 1:
        {
            // Delete button is pressed
            selectedIndexPath = [self.tableView indexPathForCell:cell];
            [self showDeleteChoice:@"Do you want to remove the recipe?"];
            break;
        }
        default:
            break;
    }
}
-(void)showDeleteChoice:(NSString*)msg{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil) message:msg delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // Set buttonIndex == 1 to handel "Ok"/"Yes" button response
    if (buttonIndex == 1) {
        //Fake delete in core data
        [Item fakeDelete:selectedItemId];
        //Delete in the tableView
        [itemsList removeObjectAtIndex:selectedIndexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
    else if(buttonIndex == 0)
    {
        [self.tableView reloadData];    //to make the more/delete buttons disappear
        
    }
}
-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 40.0;
    }
    else{
        return 0.0;
    }
}
- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 5.0, tableView.bounds.size.width, 40.0)];

    headerView.backgroundColor = [UIColor greenColor]; //whiteColor];
    newItemTextField = [[UITextField alloc]initWithFrame:CGRectMake(10.0, 5.0, tableView.bounds.size.width * 0.86, 30.0)];
    newItemTextField.delegate = self;
    newItemTextField.placeholder = NSLocalizedString(@"Add new item", nil);
    newItemTextField.layer.borderColor = [[Utility getGreenColor]CGColor];
    newItemTextField.layer.borderWidth = 1.0;
    newItemTextField.layer.cornerRadius = 5.0;
    
    [headerView addSubview:newItemTextField];
    newItemTextField.text = [DataStore instance].ingredientByURL;
    
    UIButton *addButton = [[UIButton alloc]initWithFrame:CGRectMake(tableView.bounds.size.width * 0.86 + 10.0, 5.0, 32.0, 32.0)];
    UIImage *buttonImg = [UIImage imageNamed:@"new"];
    [addButton setImage:buttonImg forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(addNewItem) forControlEvents:UIControlEventTouchDown];
    [headerView addSubview:addButton];
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(10.0, 5.0, tableView.bounds.size.width * 0.86, 30.0)];
    switch (section) {
        case 0:
            titleLabel.text = @"";
            break;
        case 1:
            titleLabel.text = ([DataStore instance].sortingOrder == STORE)? NSLocalizedString(@"Unsorted items", nil):@"";
            break;
        case 2:
            titleLabel.text = ([DataStore instance].sortingOrder == STORE)? NSLocalizedString(@"Sorted items", nil):@"";
            break;
        default:
            break;
    }
    [headerView addSubview:titleLabel];

    
    
    return headerView;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //segue to the ChangeTextViewController
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    ItemCell *itemCell = (ItemCell*)cell;
    selectedItemId = itemCell.itemId;
    
    [self performSegueWithIdentifier:@"toChangeItem" sender:self];
    
}
-(void)addNewItem{
    //Add new item to sortedlist
    if ([Utility isStringEmpty:newItemTextField.text]) {
        return;
    }
    [Item insertItemWithText:newItemTextField.text andBarcode:@"" andBarcodeType:@"" andListId:defaultListId andAddedAt:[Utility getStringFromDate:[NSDate date]]];
    
    [self loadRecordsFromCoreData];
    //[self.tableView reloadData];
    
}
#pragma HideKeyboard
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self addNewItem];
    return YES;
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [newItemTextField resignFirstResponder];
}


#pragma iAd
-(void)bannerViewDidLoadAd:(ADBannerView *)banner{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1];
    [banner setAlpha:1];
    [UIView commitAnimations];
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1];
    [banner setAlpha:0];
    [UIView commitAnimations];
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

@end
