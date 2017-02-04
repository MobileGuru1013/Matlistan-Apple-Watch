//
//  ReceptViewController.h
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>

//Replaced refrosted - Markus
#import "SWRevealViewController.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ReceptViewController : UIViewController<GADBannerViewDelegate>
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
- (IBAction)showMenu;
@end
