//
//  noLocationServiceCell.m
//  Matlistan
//
//  Created by Leocan1 on 6/1/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

#import "noLocationServiceCell.h"
#import "AppDelegate.h"
#import "ShopsTableViewController.h"

@implementation noLocationServiceCell

- (void)awakeFromNib {
    // Initialization code
    UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openSettingViewToEnableLocationService)];
    [self.reEnableLocation addGestureRecognizer:tapGesture];
}
-(void)openSettingViewToEnableLocationService
{
    (theAppDelegate).gotoSettingFromSearchShops=true;
   if(![CLLocationManager locationServicesEnabled])
   {
       [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"]];
   }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }

}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
