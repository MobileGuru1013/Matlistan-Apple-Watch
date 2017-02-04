//
//  ItemTableViewViewController.m
//  Matlistan
//
//  Created by hemal on 28/10/15.
//  Copyright © 2015 Flame Soft. All rights reserved.
//

#import "ItemTableViewViewController.h"

@interface ItemTableViewViewController ()

@end

@implementation ItemTableViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    SWRevealViewController *reveal = self.revealViewController;
    reveal.panGestureRecognizer.enabled = YES;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
    //    if(IS_IPHONE)
    //    {
    //        return ITEMS_VIEW_ROW_HEIGHT;
    //    }
    //    else
    //    {
    //        return ITEMS_VIEW_IPAD_ROW_HEIGHT;
    //    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:  (NSIndexPath *)indexPath
{
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
       cell=[tableView dequeueReusableCellWithIdentifier:@"cell"];
       if(cell==nil)
        {
            cell=[[ItemCustomCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
            NSArray *menuarray=[[NSBundle mainBundle]loadNibNamed:@"ItemCustomCell" owner:self options:nil];
            cell=[menuarray objectAtIndex:0];
       }
    cell.clipsToBounds = YES;

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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(IBAction)Backbtn:(id)sender
{
     [self.revealViewController revealToggle:self];
}
@end
