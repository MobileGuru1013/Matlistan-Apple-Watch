//
//  AdsRemovalViewController.h
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
//Replaced REFrosted with SW... Not sure if this is needed - Markus
#import "SWRevealViewController.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface AdsRemovalViewController : UIViewController<GADBannerViewDelegate,SWRevealViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblDescription;
@property (nonatomic, weak) IBOutlet UIButton *btnBuySubcription;

- (IBAction)showMenu;
- (IBAction)btnBuySubscription_Pressed:(UIButton *)sender;

@end
