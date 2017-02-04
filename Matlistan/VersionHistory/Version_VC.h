//
//  Version_VC.h
//  Matlistan
//
//  Created by Leocan1 on 11/29/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HelpViewController.h"
#import "Version_VC.h"
@protocol versionHistoryDelegate;

@class HelpViewController;

@interface Version_VC : UIViewController<UITextViewDelegate,UIWebViewDelegate>
{
    HelpViewController *help;
}
@property(strong,nonatomic)IBOutlet UITextView *version_textView;
@property(strong,nonatomic)IBOutlet UIWebView *version_web;
@property BOOL hasContent;

-(IBAction)yesBtn:(id)sender;

//-(IBAction)on_CickOK:(id)sender;

@property (assign, nonatomic) id <versionHistoryDelegate>delegate;

@end

@protocol versionHistoryDelegate<NSObject>
@optional
- (void)cancelButtonClicked:(Version_VC *)secondDetailViewController;
@end