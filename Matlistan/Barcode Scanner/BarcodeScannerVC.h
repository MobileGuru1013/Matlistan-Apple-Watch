//
//  BarcodeScannerVC.h
//  Matlistan
//
//  Created by Leocan on 12/1/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZXingObjC/ZXingObjC.h>
#import "MatlistanHTTPClient.h"
#import "Item_list.h"
#import "DataStore.h"
#import "Item.h"
#import "Mixpanel.h"
#import "ItemsViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "AppDelegate.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface BarcodeScannerVC : UIViewController<ZXCaptureDelegate,UITextFieldDelegate,GADBannerViewDelegate>
{
    DataStore *dataStore;
    NSString *barcodeSelectionType;
    
    NSString *b_Content,*b_Format;
    NSTimer *timer;
    int count;
    
    Item *selectedItem;
    NSManagedObjectID *selectedItemObjectId;
    NSNumber *selectedItemId;
    
    NSDictionary* Item_userInfo;
}
@property (nonatomic, strong) ZXCapture *capture;
@property (nonatomic, weak) IBOutlet UIView *scanRectView;
@property (nonatomic, weak) IBOutlet UILabel *decodedLabel;
@property (strong, nonatomic) IBOutlet UIButton *SingleOrMultipleBtn;
@property (nonatomic, weak) IBOutlet UIView *navigationView;
@property (nonatomic, assign) BOOL hasScannedResult;


@property(strong,nonatomic) IBOutlet UIView* custom_toastView;
@property(strong,nonatomic) IBOutlet UILabel* toastLbl;
@property(strong,nonatomic) IBOutlet UILabel* toastLine;
@property(strong,nonatomic) IBOutlet UIButton* toastBtn;

@property (strong, nonatomic) IBOutlet GADBannerView *bannerView;

-(IBAction)SingleOrMultipleBtn:(id)sender;
@end
