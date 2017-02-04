//
//  VoiceDetectionVC.h
//  Matlistan
//
//  Created by Leocan on 12/18/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpeechKit/SpeechKit.h>
#import "VoiceMatchingVC.h"
#import "UIViewController+MJPopupViewController.h"

@protocol MJSecondPopupDelegate;

@interface VoiceDetectionVC : UIViewController<SKRecognizerDelegate,SpeechKitDelegate>
{
    BOOL is_recording;
}
@property(strong,nonatomic) IBOutlet UIButton *cancelBtn;
@property(strong,nonatomic) IBOutlet UILabel *speakNowLbl;
@property (strong,nonatomic)   SKRecognizer *recognizer1;
@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;
-(IBAction)cancelBtn:(id)sender;


@end

@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)cancelButtonClicked:(VoiceDetectionVC*)secondDetailViewController;
- (void)FinishWithErrorButtonClicked:(VoiceDetectionVC*)secondDetailViewController;
@end