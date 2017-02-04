//
//  BarcodeScannerVC.m
//  Matlistan
//
//  Created by Leocan on 12/1/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "BarcodeScannerVC.h"
#import <AudioToolbox/AudioToolbox.h>

@interface BarcodeScannerVC ()

@end

@implementation BarcodeScannerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hasScannedResult=NO;
    count=0;
    [self setBottomBorder:self.navigationView];
    
    barcodeSelectionType=[Utility getBarcodeSelection];
    if(barcodeSelectionType==nil || barcodeSelectionType.length==0)
    {
        [Utility setBarcodeSelection:@"Single"];
        barcodeSelectionType=[Utility getBarcodeSelection];
    }
    [self.SingleOrMultipleBtn setTitle: barcodeSelectionType forState: UIControlStateNormal];
    

    
    DLog(@"barcodeSelectionType:%@",barcodeSelectionType);

    self.capture = [[ZXCapture alloc] init];
    self.capture.camera = self.capture.back;
    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    self.capture.rotation = 90.0f;
    self.capture.layer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.capture.layer];
    
    [self.view bringSubviewToFront:self.scanRectView];
    [self.view bringSubviewToFront:self.decodedLabel];
    
    self.SingleOrMultipleBtn.layer.cornerRadius=5;
    self.SingleOrMultipleBtn.layer.masksToBounds=YES;
}
- (void)dealloc
{
    [self.capture.layer removeFromSuperlayer];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
   self.navigationController.navigationBarHidden=YES;
    
    self.capture.delegate = self;
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.capture.layer.frame = CGRectMake(0,64,SCREEN_WIDTH,SCREEN_HEIGHT-64);

    }
    else{
        self.capture.layer.frame = CGRectMake(0,64,SCREEN_WIDTH,SCREEN_HEIGHT-64-self.bannerView.frame.size.height);
    }
    self.scanRectView.layer.frame = self.capture.layer.frame;
    
    CGAffineTransform captureSizeTransform = CGAffineTransformMakeScale(SCREEN_WIDTH / self.view.frame.size.width, SCREEN_HEIGHT / self.view.frame.size.height);

    self.capture.scanRect = CGRectApplyAffineTransform(self.scanRectView.frame, captureSizeTransform);
    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden=NO;
}

#pragma mark - Private Methods

- (NSString *)barcodeFormatToString:(ZXBarcodeFormat)format {
    switch (format) {
        case kBarcodeFormatAztec:
            return @"Aztec";
            
        case kBarcodeFormatCodabar:
            return @"CODABAR";
            
        case kBarcodeFormatCode39:
            return @"Code 39";
            
        case kBarcodeFormatCode93:
            return @"Code 93";
            
        case kBarcodeFormatCode128:
            return @"Code 128";
            
        case kBarcodeFormatDataMatrix:
            return @"Data Matrix";
            
        case kBarcodeFormatEan8:
            return @"EAN-8";
            
        case kBarcodeFormatEan13:
            return @"EAN-13";
            
        case kBarcodeFormatITF:
            return @"ITF";
            
        case kBarcodeFormatPDF417:
            return @"PDF417";
            
        case kBarcodeFormatQRCode:
            return @"QR Code";
            
        case kBarcodeFormatRSS14:
            return @"RSS 14";
            
        case kBarcodeFormatRSSExpanded:
            return @"RSS Expanded";
            
        case kBarcodeFormatUPCA:
            return @"UPCA";
            
        case kBarcodeFormatUPCE:
            return @"UPCE";
            
        case kBarcodeFormatUPCEANExtension:
            return @"UPC/EAN extension";
            
        default:
            return @"Unknown";
    }
}

#pragma mark - ZXCaptureDelegate Methods

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result {
    DLog(@"captureResult*******  %d",self.hasScannedResult);
    if(self.hasScannedResult == NO)
    {
       
        if (!result) return;
         dataStore = [DataStore instance];
        Item_list *list = dataStore.currentList;
       
        // We got a result. Display information about the result onscreen.
        b_Format = [self barcodeFormatToString:result.barcodeFormat];
        b_Content = result.text;
        
    
        // Vibrate
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        DLog(@"b_Format %@",b_Format);
        if([b_Format isEqualToString:@"EAN-13"])
        {
            self.hasScannedResult = YES;
            if((theAppDelegate).is_scan_start)
            {
                [self checkBarcode:b_Content barcodeFormat:b_Format addedAt:[NSDate date] listId:list.item_listID];
            }
         }
        else
         {
             self.hasScannedResult = NO;
             (theAppDelegate).is_scan_start=true;
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                                message:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Invalid barcode", nil)]
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                alert.tag=1;
                [alert show];
         }
      
       DLog(@"b_Format %@",b_Format);
       DLog(@"Multiple %@",[Utility getBarcodeSelection]);
       
    }
}


#pragma mark -Add New item after Barcode
-(void)checkBarcode:(NSString*)barcode barcodeFormat:(NSString*)barcodeType addedAt:(NSDate*)addedAt listId:(NSNumber*)listId {
    
    DLog(@"checkBarcode called**********");
    (theAppDelegate).is_scan_start=false;
    NSDate *addAtTimeLocal = [NSDate date];
    NSString *addedAt1 = [Utility getStringFromDate:addAtTimeLocal];

   
    MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
   
       NSDictionary *parameters = @{@"barcode": barcode,
                                    @"barcodeType":@"EAN13",
                                    @"listId":listId,
                                    @"addedAt":addedAt1,
                                    };

    DLog(@"parameters %@",parameters);
    NSDictionary * parametersJson = [NSDictionary new];
    parametersJson=[self parseToInsertJSON:barcode barcodeFormat:@"EAN13" addedAt:addedAt1 listId:listId];
    DLog(@"parameters %@",parametersJson);
    NSString *request = [NSString stringWithFormat:@"Items"];
    
    
    [client POST:request parameters:parametersJson success:^(NSURLSessionDataTask *task, id responseObject) {
        DLog(@"Barcode scan api response %@,= %d", responseObject,count++);
        (theAppDelegate).is_scan_start=false;
        if(responseObject!=nil)
        {
            DLog(@"**********calling addNewItemAfterBarcodeScan ");

            NSString *ItemText=[responseObject objectForKey:@"text"];
            (theAppDelegate).add_success=true;
           
           
           // [items addNewItemAfterBarcodeScan:ItemText barcodeContent:barcode barcodeFormat:barcodeType];
            NSDictionary* userInfo = @{@"ItemText": ItemText,
                                       @"barcodeContent": barcode,
                                       @"barcodeType": @"EAN13",
                                       @"flag":@0
                                       };

            if ([[Utility getBarcodeSelection] isEqualToString:@"Single"]) {
                [self dismissViewControllerAnimated:YES completion:^{
                    
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"BAERCODE_ADD_SINGE_ITEM" object:self userInfo:userInfo];
                }];
            }
            else{
                NSString *barcodeItemName = [[userInfo objectForKey:@"ItemText"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                Item_list *list = dataStore.currentList;
                Item *item = [Item insertItemWithTextBarcode:barcodeItemName andBarcode:[userInfo objectForKey:@"barcodeContent"] andBarcodeType:[userInfo objectForKey:@"barcodeType"] belongToList:list withSource:@"Barcode"];
                
                NSDictionary *Info = @{@"ItemId": item.itemID,
                                       @"ItemObjectId": item.objectID,
                                       @"Item": item
                                       };
                Item_userInfo=Info;
                
                //                (theAppDelegate).barcode_itemObjectId=[item objectID];
                //                (theAppDelegate).barcode_item=item;
                //                (theAppDelegate).barcode_itemId=item.itemID;
                [self showToast:item.text];
                
            }

        }
       
        
        
       
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        (theAppDelegate).is_scan_start=false;
         DLog(@"error %@", error);
        NSData *errData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
        NSString *str = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
        DLog(@"des = %@",str);

        
        
        [self OpenBarcodeAlert];
        DLog(@"Fail to addNewItemAfterBarcodeScan");
    }];
}

#pragma mark- button click event
-(IBAction)SingleOrMultipleBtn:(id)sender
{
        (theAppDelegate).is_scan_start=true;
        if([barcodeSelectionType isEqualToString:@"Single"])
        {
            [Utility setBarcodeSelection:@"Multiple"];
        }
        else{
            [Utility setBarcodeSelection:@"Single"];
        }
        barcodeSelectionType=[Utility getBarcodeSelection];

        [self.SingleOrMultipleBtn setTitle: barcodeSelectionType forState: UIControlStateNormal];
}
-(IBAction)backBtn:(id)sender
{
   // [self.navigationController popToRootViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)hideToast
{
    self.toastLbl.hidden=YES;
    self.custom_toastView.hidden=YES;
    self.toastLine.hidden=YES;
    self.toastBtn.hidden=YES;
    if(timer != nil)
    {
        [timer invalidate];
        timer = nil;
    }
    self.hasScannedResult = NO;
    (theAppDelegate).is_scan_start=true;
//    if([[Utility getBarcodeSelection] isEqualToString:@"Multiple"])
//    {
//         self.hasScannedResult = NO;
//    }
}
-(void)showToast:(NSString *)itemName
{
    timer= [NSTimer scheduledTimerWithTimeInterval:7 target:self selector:@selector(hideToast) userInfo:nil repeats:NO];
    
    [self.custom_toastView removeFromSuperview];
    [self.toastLbl removeFromSuperview];
    [self.toastLine removeFromSuperview];
    [self.toastBtn removeFromSuperview];
    
    
    int n;
//    if(IS_IPHONE)
//    {
//        n=15;
//        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(16,SCREEN_HEIGHT-106, 288, 33)];
//        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(26, SCREEN_HEIGHT-97-3, 220, 21)];
//        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(255,SCREEN_HEIGHT-97-3, 1, 21)];
//        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(270, SCREEN_HEIGHT-97, 18, 18)];
//    }
//    else{
//        n=15;
//        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(28,SCREEN_HEIGHT-115,691 , 45)];
//        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(46, SCREEN_HEIGHT-110-15,590, 100)];
//        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(635,SCREEN_HEIGHT-110, 2, 21)];
//        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(650, SCREEN_HEIGHT-110, 70, 18)];
//    }
    
    if(IS_IPHONE)
    {
        n=15;
        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(16,SCREEN_HEIGHT-106, SCREEN_WIDTH-32, 33)];
        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(26, SCREEN_HEIGHT-97-3, SCREEN_WIDTH-100, 21)];
        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-65,SCREEN_HEIGHT-97-3, 1, 21)];
        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-50, SCREEN_HEIGHT-97, 18, 18)];
    }
    else{
        n=15;
        self.custom_toastView=[[UIView alloc]initWithFrame:CGRectMake(28,SCREEN_HEIGHT-115,SCREEN_WIDTH-77 , 45)];
        self.toastLbl=[[UILabel alloc]initWithFrame:CGRectMake(46, SCREEN_HEIGHT-110-15,SCREEN_WIDTH-178, 100)];
        self.toastLine=[[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-133,SCREEN_HEIGHT-110, 2, 21)];
        self.toastBtn=[[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-118, SCREEN_HEIGHT-110, 70, 18)];
    }

    self.custom_toastView.layer.cornerRadius=5;
    self.custom_toastView.layer.masksToBounds=YES;
    self.custom_toastView.backgroundColor=[UIColor blackColor];
    self.custom_toastView.alpha=0.5;
    
    self.toastLbl.numberOfLines=2;
    self.toastLbl.textColor=[UIColor whiteColor];
    
    self.toastLine.backgroundColor=[UIColor whiteColor];
    [self.toastBtn  setImage:[UIImage imageNamed:@"editToast"] forState:UIControlStateNormal];
    
    
    [self.view addSubview:self.custom_toastView];
    [self.view addSubview:self.toastLbl];
    [self.view addSubview:self.toastLine];
    [self.view addSubview:self.toastBtn];
    
    [self.toastBtn addTarget:self
                      action:@selector(editBarcodeItem)
            forControlEvents:UIControlEventTouchUpInside];
    
    
    self.toastLbl.hidden=NO;
    self.custom_toastView.hidden=NO;
    self.toastLine.hidden=NO;
    self.toastBtn.hidden=NO;
    
    
    self.toastLbl.text=[NSString stringWithFormat:@"%@ added",itemName];
    
    [self.toastLbl sizeToFit];
    int lbl_height=self.toastLbl.frame.size.height;
    if(IS_IPAD)
    {
        CGRect frame=self.toastLbl.frame;
        frame.size.height=lbl_height+25;
        frame.size.width=590;
        self.toastLbl.frame=frame;
    }
    
    
    int lbl_h,lbl_w;
    if(IS_IPHONE)
    {
        self.toastLbl.font=[UIFont fontWithName:@"Helvetica" size:15.0f];
        
        if(lbl_height>30)
        {
            lbl_h=50;
            lbl_w=40;
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y, self.custom_toastView.frame.size.width, lbl_height+n-5);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y, self.toastLine.frame.size.width, lbl_height);
        }
        else{
            lbl_h=35;
            lbl_w=40;
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y, self.custom_toastView.frame.size.width, lbl_height+n);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y, self.toastLine.frame.size.width, lbl_height+n-10);
        }
    }
    else{
        self.toastLbl.font=[UIFont fontWithName:@"Helvetica" size:22.0f];
        
        DLog(@"lbl height :%d",lbl_height);
        if(lbl_height>=35)
        {
            lbl_h=65;
            lbl_w=75;
            DLog(@"if called");
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y-7, self.custom_toastView.frame.size.width, lbl_height+25);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y, self.toastLine.frame.size.width, lbl_height+5);
            
            
        }
        else{
            lbl_h=40;
            lbl_w=75;
            DLog(@"else  called");
            // self.toastBtn.frame=CGRectMake(self.toastBtn.frame.origin.x-7, self.toastBtn.frame.origin.y-7,75, 35);
            self.custom_toastView.frame=CGRectMake(self.custom_toastView.frame.origin.x, self.custom_toastView.frame.origin.y-8, self.custom_toastView.frame.size.width, lbl_height+25);
            self.toastLine.frame=CGRectMake(self.toastLine.frame.origin.x, self.toastLine.frame.origin.y-5, self.toastLine.frame.size.width, lbl_height+n-5);
            
            
        }
        
        
    }
    self.toastBtn.frame=CGRectMake(self.toastBtn.frame.origin.x-7, self.toastBtn.frame.origin.y-10, lbl_w, lbl_h);

}
-(void)editBarcodeItem
{
    (theAppDelegate).multiple_edit=true;
    [self dismissViewControllerAnimated:YES completion:^{
        [self hideToast];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"editBarcodeMultipleItem" object:self userInfo:Item_userInfo];
    }];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"editBarcodeMultipleItem" object:self userInfo:Item_userInfo];
    

}

#pragma mark- set bottom border to view
-(void)setBottomBorder:(UIView*)view
{
    CALayer *BottomBorder = [CALayer layer];
    BottomBorder.frame = CGRectMake(0.0f, view.frame.size.height, SCREEN_WIDTH, 0.5f);
    BottomBorder.backgroundColor =[UIColor colorWithRed:200/255. green:199/255. blue:204/255. alpha:1].CGColor;
    [view.layer addSublayer:BottomBorder];
}

#pragma mark Orientation

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark Orientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}
-(BOOL)shouldAutorotate
{
    [super shouldAutorotate];
    return NO;
}
- (NSUInteger) supportedInterfaceOrientations {
    [super supportedInterfaceOrientations];
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskPortrait;
    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    [super preferredInterfaceOrientationForPresentation];
    // Return the orientation you'd prefer - this is what it launches to. The
    // user can still rotate. You don't have to implement this method, in which
    // case it launches in the current orientation
    return UIInterfaceOrientationPortrait;
}

- (NSDictionary *) parseToInsertJSON:(NSString*)barcode barcodeFormat:(NSString*)barcodeType addedAt:(NSString*)addedAt listId:(NSNumber*)listId
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    
    //if (self.text) [json setObject:self.text forKey:@"text"];
    [json setObject:barcode forKey:@"barcode"];
    [json setObject:barcodeType forKey:@"barcodeType"];
    [json setObject:listId forKey:@"listId"];
    [json setObject:addedAt forKey:@"addedAt"];
   // if (self.source) [json setObject:self.source forKey:@"source"];
    /*
     [json setObject:self.voiceSearchText forKey:@"voiceSearchText"];
     [json setObject:self.source forKey:@"source"];
     */
    

    return json;
}

-(void)OpenBarcodeAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unknown barcode",nil) message:NSLocalizedString(@"Barcode not in database",nil) delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:NSLocalizedString(@"Cancel", nil), nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 2;
    [alert show];
    
    UITextField *newItemTxt = [alert textFieldAtIndex:0];
    
    newItemTxt.placeholder=NSLocalizedString(@"Add new item",nil);
    newItemTxt.delegate = self;
    newItemTxt.tag = 101;

}
#pragma mark AlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 2)
    {
        if (buttonIndex == 0)
        {
            [self hideToast];
            
            NSString *itemNew = [[alertView textFieldAtIndex:0] text];
            [[alertView textFieldAtIndex:0] resignFirstResponder];
            
            NSString *barcodeItemName = [itemNew stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if(barcodeItemName.length>0)
            {
                Item_list *list = dataStore.currentList;
                [self AddBarcode:barcodeItemName barcodeFormat:b_Content addedAt:[NSDate date] listId:list.item_listID];
                
//                if([[Utility getBarcodeSelection] isEqualToString:@"Multiple"])
//                {
//                    Item_list *list = dataStore.currentList;
//                    Item *item = [Item insertItemWithText:barcodeItemName andBarcode:b_Content andBarcodeType:@"EAN13" belongToList:list withSource:@"Barcode"];
//                    
//                    [self showToast:item.text];
//                }
//                else
//                {
//                    NSDictionary* userInfo = @{@"ItemText": barcodeItemName,
//                                               @"barcodeContent": b_Content,
//                                               @"barcodeType": @"EAN13",
//                                               @"flag":@1
//                                               };
//                    [self dismissViewControllerAnimated:YES completion:^{
//                        
//                        [[NSNotificationCenter defaultCenter] postNotificationName:@"BAERCODE_ADD_SINGE_ITEM" object:self userInfo:userInfo];
//                    }];
                
                    

                //}

            }
        }
        else if (buttonIndex == 1)
        {
            DLog(@"Cancel");
            self.hasScannedResult = NO;
            (theAppDelegate).is_scan_start=true;
            [[alertView textFieldAtIndex:0] resignFirstResponder];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyDone)
    {
        [textField resignFirstResponder];
    }
    return NO;
}
#pragma mark -Add New item after Barcode
-(void)AddBarcode:(NSString*)barcode barcodeFormat:(NSString*)barcodeType addedAt:(NSDate*)addedAt listId:(NSNumber*)listId {
    
    DLog(@"AddBarcode called**********");
    (theAppDelegate).is_scan_start=false;
    NSDate *addAtTimeLocal = [NSDate date];
    NSString *addedAt1 = [Utility getStringFromDate:addAtTimeLocal];
    
    
    MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];
    
    NSDictionary *parameters = @{@"text":barcode,
                                 @"barcode": barcodeType,
                                 @"barcodeType":@"EAN13",
                                 @"listId":listId,
                                 @"addedAt":addedAt1,
                                 @"source":@"Barcode"
                                 };
    
    DLog(@"parameters %@",parameters);
//    NSDictionary * parametersJson = [NSDictionary new];
//    parametersJson=[self parseToInsertJSON:barcode barcodeFormat:@"EAN13" addedAt:addedAt1 listId:listId];
//    DLog(@"parameters %@",parametersJson);
    NSString *request = [NSString stringWithFormat:@"Items"];
    
    
    [client POST:request parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
      //  DLog(@"Barcode scan api response %@,= %d", responseObject,count++);
        (theAppDelegate).is_scan_start=false;
        if(responseObject!=nil)
        {
            DLog(@"**********calling addNewItemAfterBarcodeScan ");
            
            NSString *ItemText=[responseObject objectForKey:@"text"];
            (theAppDelegate).add_success=true;
            
            
            // [items addNewItemAfterBarcodeScan:ItemText barcodeContent:barcode barcodeFormat:barcodeType];
            NSDictionary* userInfo = @{@"ItemText": ItemText,
                                       @"barcodeContent": barcode,
                                       @"barcodeType": @"EAN13",
                                       @"flag":@0
                                       };
            
            if ([[Utility getBarcodeSelection] isEqualToString:@"Single"]) {
                [self dismissViewControllerAnimated:YES completion:^{
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"BAERCODE_ADD_SINGE_ITEM" object:self userInfo:userInfo];
                }];
            }
            else{
                NSString *barcodeItemName = [[userInfo objectForKey:@"ItemText"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                Item_list *list = dataStore.currentList;
                Item *item = [Item insertItemWithTextBarcode:barcodeItemName andBarcode:[userInfo objectForKey:@"barcodeContent"] andBarcodeType:[userInfo objectForKey:@"barcodeType"] belongToList:list withSource:@"Barcode"];
                
                NSDictionary *Info = @{@"ItemId": item.itemID,
                                       @"ItemObjectId": item.objectID,
                                       @"Item": item
                                       };
                Item_userInfo=Info;
                
                //                (theAppDelegate).barcode_itemObjectId=[item objectID];
                //                (theAppDelegate).barcode_item=item;
                //                (theAppDelegate).barcode_itemId=item.itemID;
                [self showToast:item.text];
                
            }
            
        }
        
        
        
        
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        (theAppDelegate).is_scan_start=false;
        DLog(@"error %@", error);
        NSData *errData = [error.userInfo objectForKey:@"JSONResponseSerializerWithDataKey"];
        NSString *str = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
        DLog(@"des = %@",str);
        
        
        
       // [self OpenBarcodeAlert];
        DLog(@"Fail to addNewItemAfterBarcodeScan");
    }];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
}
- (void)removeAds
{
    if (self.bannerView)
    {
        [self.bannerView removeConstraints:self.bannerView.constraints];
        [self.bannerView removeFromSuperview];
    }
}
@end
