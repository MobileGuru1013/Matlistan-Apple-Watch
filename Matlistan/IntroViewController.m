//
//  IntroViewController.m
//  MatListan
//
//  Created by Markus Tenghamn on 07/06/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "IntroViewController.h"
#import "Mixpanel.h"

@interface IntroViewController ()
{
    __weak IBOutlet UIButton *privacyPolicyButton;
    __weak IBOutlet UIButton *termsButton;
}
@end

@implementation IntroViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    //abc test merge to main
    [Utility saveInDefaultsWithBool:YES andKey:@"vibrateOnPickDropItemBool"];
    [Utility saveInDefaultsWithBool:YES andKey:@"sendBugReport"];
    
    [termsButton setTitle:NSLocalizedString(@"Terms of Service", nil) forState:UIControlStateNormal];
    [privacyPolicyButton setTitle:NSLocalizedString(@"Privacy Policy", nil) forState:UIControlStateNormal];
    _intro1Label.text = NSLocalizedString(@"intro1", nil);
    _intro2Label.text = NSLocalizedString(@"intro2", nil);
    [_contiBtn setTitle:NSLocalizedString(@"continue", nil) forState:UIControlStateNormal];
    [_readMoreButton setTitle:NSLocalizedString(@"read_more", nil) forState:UIControlStateNormal];
    
    self.contiBtn.layer.cornerRadius=3;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
   [termsButton setTitle:NSLocalizedString(@"Terms of Service", nil) forState:UIControlStateNormal];

   [privacyPolicyButton setTitle:NSLocalizedString(@"Privacy Policy", nil) forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
//- (NSUInteger) supportedInterfaceOrientations {
//    [super supportedInterfaceOrientations];
//    // Return a bitmask of supported orientations. If you need more,
//    // use bitwise or (see the commented return).
//    return UIInterfaceOrientationMaskPortrait;
//    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
//}
//
//- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
//    [super preferredInterfaceOrientationForPresentation];
//    // Return the orientation you'd prefer - this is what it launches to. The
//    // user can still rotate. You don't have to implement this method, in which
//    // case it launches in the current orientation
//    return UIInterfaceOrientationPortrait;
//}

- (IBAction)readMoreButtonClick:(id)sender
{
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Intro: Read more clicked"];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://matlistan.se/help"]];
}

- (IBAction)termsButtonClick:(id)sender
{
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Intro: Terms of Service clicked"];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://matlistan.se/Home/Terms"]];
}

- (IBAction)PrivacyPolicyButtonClick:(id)sender
{
    if ([Utility getDefaultBoolAtKey:@"sendAnalyticsReport"])
    {
        [[Mixpanel sharedInstance] track:@"Intro: Privacy Policy clicked"];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://matlistan.se/Home/Privacy"]];
}

/*
#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [self.bannerView setAlpha:1];
    [UIView commitAnimations];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [self.bannerView setAlpha:0];
    [UIView commitAnimations];
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [Utility saveInDefaultsWithBool:YES andKey:@"firstLaunchComplete"];
}
-(void)setControlsForiPhone
{
    [BottomBorder removeFromSuperlayer];

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    int nav_h=32,img_w_h=35,img_y=24,header_title_y=0;

    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        nav_h=64;
        img_w_h=35;
        img_y=24;
        header_title_y=10;
    }
    else
    {
        if ([UIApplication sharedApplication].isStatusBarHidden) {
            nav_h=32;
            img_w_h=28;
            img_y=2;
        }
        else{
            nav_h=32+20;
            img_w_h=35;
            img_y=24;
        }
        header_title_y=0;
    }
    
    self.scrollview.translatesAutoresizingMaskIntoConstraints=YES;
    self.headerView.translatesAutoresizingMaskIntoConstraints=YES;
    self.headerTitle.translatesAutoresizingMaskIntoConstraints=YES;
    self.iconImg.translatesAutoresizingMaskIntoConstraints=YES;
    self.intro2Label.translatesAutoresizingMaskIntoConstraints=YES;
    self.readMoreButton.translatesAutoresizingMaskIntoConstraints=YES;
    self.contiBtn.translatesAutoresizingMaskIntoConstraints=YES;
    
    self.scrollview.scrollEnabled=NO;
    self.scrollview.frame=CGRectMake(0, nav_h, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.headerView.frame=CGRectMake(0, 0, SCREEN_WIDTH, nav_h);
    self.headerTitle.frame=CGRectMake(0, header_title_y, SCREEN_WIDTH, nav_h-header_title_y);
    self.iconImg.frame=CGRectMake(6,img_y, img_w_h, img_w_h);
   
    BottomBorder = [CALayer layer];
    BottomBorder.frame = CGRectMake(0.0f,self.headerView.frame.origin.y+ self.headerView.frame.size.height, SCREEN_WIDTH, 0.5f);
    BottomBorder.backgroundColor =[UIColor colorWithRed:200/255. green:199/255. blue:204/255. alpha:1].CGColor;
    
    [self.headerView.layer addSublayer:BottomBorder];
    
    int intro1_x=36,intro1_h=50,distance=8;
    int intro2_h=102;
    int btn_h=40,cont_btn=30;

    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        if(IS_IPHONE)
        {
            if(iphone4 || iphone5)
            {
                intro2_h=102;
                intro1_h=50;
            }
            else if(iphone6 || iphone6Plus)
            {
                intro2_h=90;
                intro1_h=50;
            }
        }
    }
    else
    {
        if(IS_IPHONE)
        {
            if(iphone4 || iphone5)
            {
                intro2_h=50;
                intro1_h=40;
            }
            else if(iphone6 || iphone6Plus)
            {
                intro2_h=50;
                intro1_h=20;
            }
        }
    }
    self.intro1Label.frame=CGRectMake(intro1_x, distance, SCREEN_WIDTH-intro1_x*2, intro1_h);
    self.intro2Label.frame=CGRectMake(intro1_x, self.intro1Label.frame.origin.y+self.intro1Label.frame.size.height+distance, SCREEN_WIDTH-intro1_x*2, intro2_h);
    
    self.readMoreButton.frame=CGRectMake(intro1_x, self.intro2Label.frame.origin.y+self.intro2Label.frame.size.height, SCREEN_WIDTH-intro1_x*2, btn_h);

    
    self.contiBtn.frame=CGRectMake(intro1_x, self.readMoreButton.frame.origin.y+self.readMoreButton.frame.size.height+distance, SCREEN_WIDTH-intro1_x*2, cont_btn);
    termsButton.frame=CGRectMake(intro1_x, self.contiBtn.frame.origin.y+self.contiBtn.frame.size.height+distance, self.contiBtn.frame.size.width/2-distance, btn_h);
    privacyPolicyButton.frame=CGRectMake(intro1_x+termsButton.frame.size.width+distance+1, self.contiBtn.frame.origin.y+self.contiBtn.frame.size.height+distance, self.contiBtn.frame.size.width/2-distance, btn_h);
}
-(void)setControlsForiPad
{
    self.intro1Label.translatesAutoresizingMaskIntoConstraints=YES;
    
    self.intro2Label.translatesAutoresizingMaskIntoConstraints=YES;
    self.readMoreButton.translatesAutoresizingMaskIntoConstraints=YES;
    self.contiBtn.translatesAutoresizingMaskIntoConstraints=YES;
    termsButton.translatesAutoresizingMaskIntoConstraints=YES;
    privacyPolicyButton.translatesAutoresizingMaskIntoConstraints=YES;
    self.seperatorline.translatesAutoresizingMaskIntoConstraints=YES;
    
    int distance=20,btn_h=45,intro2_h=55,intro2_y=155,intro1_h=70;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        if([UIScreen mainScreen].bounds.size.height == 1366 || [UIScreen mainScreen].bounds.size.width == 1366)
        {
            btn_h=45,intro2_h=50,intro2_y=155,intro1_h=50;
        }
        else
        {
            btn_h=45,intro2_h=84,intro2_y=155,intro1_h=77;
        }
    }
    else
    {
        btn_h=45,intro2_h=55,intro2_y=155,intro1_h=30;
    }
    CGRect frame11=self.intro1Label.frame;
    frame11.size.height=intro1_h;
    frame11.size.width=SCREEN_WIDTH-frame11.origin.x*2;
    self.intro1Label.frame=frame11;
    
    
    CGRect frame=self.intro2Label.frame;
    frame.origin.y=self.intro1Label.frame.origin.y+self.intro1Label.frame.size.height+distance;
    frame.size.height=intro2_h;
    frame.size.width=SCREEN_WIDTH-frame.origin.x*2;
    self.intro2Label.frame=frame;
    
    CGRect frame1=self.readMoreButton.frame;
    frame1.origin.y=self.intro2Label.frame.origin.y+self.intro2Label.frame.size.height+distance;
    frame1.size.height=btn_h;
    frame1.size.width=SCREEN_WIDTH-frame1.origin.x*2;
    self.readMoreButton.frame=frame1;
    
    CGRect frame2=self.contiBtn.frame;
    frame2.origin.y=self.readMoreButton.frame.origin.y+self.readMoreButton.frame.size.height+distance;
    frame2.size.height=btn_h;
    frame2.size.width=SCREEN_WIDTH-frame2.origin.x*2;
    self.contiBtn.frame=frame2;
    
    self.seperatorline.frame=CGRectMake(SCREEN_WIDTH/2-1, self.contiBtn.frame.origin.y+self.contiBtn.frame.size.height+distance+12, 1, 21);
    
    CGRect frame3=termsButton.frame;
    frame3.origin.x=self.seperatorline.frame.origin.x-161;
    frame3.origin.y=self.contiBtn.frame.origin.y+self.contiBtn.frame.size.height+distance;
    
    frame3.origin.y=self.contiBtn.frame.origin.y+self.contiBtn.frame.size.height+distance;
    frame3.size.height=btn_h;
    frame3.size.width=151;
    termsButton.frame=frame3;
    
    CGRect frame4=privacyPolicyButton.frame;
    frame4.origin.x=self.seperatorline.frame.origin.x+161;

    frame4.origin.y=self.contiBtn.frame.origin.y+self.contiBtn.frame.size.height+distance;
    frame4.origin.x=self.seperatorline.frame.origin.x+self.seperatorline.frame.size.width+10;
    frame4.size.height=btn_h;
    frame4.size.width=151;

    privacyPolicyButton.frame=frame4;
}
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(IS_IPHONE)
    {
        [self setControlsForiPhone];
    }
    else
    {
        [self setControlsForiPad];
    }
    CLS_LOG(@"Showing IntroViewController");
}
#pragma mark- override method for orientation
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
    if(IS_IPHONE)
    {
        [self setControlsForiPhone];
    }
    else
    {
        [self setControlsForiPad];
    }
}
@end
