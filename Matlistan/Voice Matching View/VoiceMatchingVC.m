//
//  VoiceMatchingVC.m
//  Matlistan
//
//  Created by Leocan on 12/15/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "VoiceMatchingVC.h"
#import "AppDelegate.h"


@interface VoiceMatchingVC ()

@end

@implementation VoiceMatchingVC

- (void)viewDidLoad
{
    [super viewDidLoad];
   // DLog(@"Voice matching screen open:%@",self.matchingArr);

    self.tableview.tableFooterView = [[UIView alloc] init];

    self.headingLbl.text=NSLocalizedString(@"Select from the search results", nil);
    [self.speakAgainBtn setTitle:NSLocalizedString(@"Speak again", nil) forState: UIControlStateNormal];
    [self.cancelBtn setTitle:NSLocalizedString(@"Cancel", nil) forState: UIControlStateNormal];

   


}

#pragma mark- Tableview delegate method
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.matchingArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"SimpleData";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text=[self.matchingArr objectAtIndex:indexPath.row];
    cell.selectionStyle=NO;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    (theAppDelegate).AddViaVoice=true;
    NSString *str=[self.matchingArr objectAtIndex:indexPath.row];
  //  DLog(@"str:%@",str);
    NSDictionary* userInfo = @{@"ItemText":str,
                               @"Source":@"Voice",
                              };

    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMatchingView" object:self userInfo:userInfo];
   
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if ([self.tableview respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableview setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableview respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableview setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark- Button click event
-(IBAction)speakAgainBtn:(id)sender
{
    //DLog(@"Speak again btn click *****");
//    NSDictionary* userInfo = @{@"ItemText":@"",
//                               @"Source":@"SpeakAgain",
//                               };
   // [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMatchingView" object:self userInfo:userInfo];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(MatchingButtonClicked:)]) {
        [self.delegate MatchingButtonClicked:self];
        
    }
}
-(IBAction)cancelBtn:(id)sender
{
   // DLog(@"cancel called...");
    NSDictionary* userInfo = @{@"ItemText":@"",
                               @"Source":@"Cancel",
                               };

//    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];

   [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMatchingView" object:self userInfo:userInfo];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
