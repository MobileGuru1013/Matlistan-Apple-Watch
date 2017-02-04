//
//  VoiceMatchingVC.h
//  Matlistan
//
//  Created by Leocan on 12/15/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+MJPopupViewController.h"

@protocol MJMatchingPopupDelegate;
@interface VoiceMatchingVC : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    
}
@property(strong,nonatomic) IBOutlet UILabel *headingLbl;
@property(strong,nonatomic) IBOutlet UIButton *speakAgainBtn;
@property(strong,nonatomic) IBOutlet UIButton *cancelBtn;

@property(strong,nonatomic) IBOutlet UITableView *tableview;
@property(strong,nonatomic)  NSArray *matchingArr;
@property (assign, nonatomic) id <MJMatchingPopupDelegate>delegate;

-(IBAction)speakAgainBtn:(id)sender;
-(IBAction)cancelBtn:(id)sender;




@end

@protocol MJMatchingPopupDelegate<NSObject>
@optional
- (void)MatchingButtonClicked:(VoiceMatchingVC*)voiceMatchingVC;
@end