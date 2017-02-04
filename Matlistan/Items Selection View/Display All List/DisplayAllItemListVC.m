//
//  DisplayAllItemListVC.m
//  Matlistan
//
//  Created by Leocan on 2/26/16.
//  Copyright (c) 2016 Consumiq AB. All rights reserved.
//

#import "DisplayAllItemListVC.h"

@interface DisplayAllItemListVC ()

@end

@implementation DisplayAllItemListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.cancelBtn setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    self.headerLbl.text=NSLocalizedString(@"Select item list", nil);
    
    NSLog(@"selectedItemsArr:%@",self.selectedItemsArr);
    
    dataStore = [DataStore instance];
    allListArr=[[NSMutableArray alloc]init];
    allListArr = [NSMutableArray arrayWithArray:[Item_list getAllLists]];

    if([self.screenName isEqualToString:@"Move Items"] && self.screenName!=nil)
    {
        if (dataStore.currentList == nil)
        {
             dataStore.currentList = [Item_list getDefaultList];
        }
        
        Item_list *list=dataStore.currentList;
        if([allListArr containsObject:list])
        {
            [allListArr removeObject:list];
       }
    }
}

#pragma mark- tableview delegate methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return allListArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if(IS_IPHONE)
    {
        cell.textLabel.font=[UIFont fontWithName:@"Helvetica" size:14.0f];
    }
    else
    {
        cell.textLabel.font=[UIFont fontWithName:@"Helvetica" size:18.0f];

    }

    Item_list *list = allListArr[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", list.name];
    cell.selectionStyle=NO;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item_list *list = allListArr[indexPath.row];
    NSNumber *listid=list.item_listID;
    NSLog(@"listid:%@",listid);
    
    NSDictionary* userInfo = @{@"SelectedList": list,
                               @"Option": self.screenName,
                               @"SelectedItemText":self.selectedItem.text==nil?@"":self.selectedItem.text,
                               @"SelectItem":self.selectedItem==nil?@"":self.selectedItem
                               };

   [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissListView" object:self userInfo:userInfo];
}
#pragma mark- Button click event
-(IBAction)onclick_cancel:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissListView" object:nil];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
