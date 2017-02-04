//
//  HelpViewController.h
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
//Replaced refrosted - Markus
#import "SWRevealViewController.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "Version_VC.h"


@interface HelpViewController : UIViewController<GADBannerViewDelegate,SWRevealViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *buttonQuestion;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
- (IBAction)showMenu;
@property (weak, nonatomic) IBOutlet UIButton *buttonContactUs;

@property (weak, nonatomic) IBOutlet UIButton *buttonRate;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property(weak,nonatomic)IBOutlet UIButton *btn_Verionhistory;

- (IBAction)onClickQuestion:(id)sender;
- (IBAction)onClickContactUs:(id)sender;
- (IBAction)onClickFacebook:(id)sender;

- (IBAction)onClickRate:(id)sender;
-(IBAction)onClickVersionHistory:(id)sender;


@end
