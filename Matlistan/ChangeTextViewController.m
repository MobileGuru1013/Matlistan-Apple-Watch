//
//  ChangeTextViewController.m
//  MatListan
//
//  Created by Yan Zhang on 30/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "ChangeTextViewController.h"
#import "Item+Extra.h"

#import "SyncManager.h"
#import "SignificantChangesIndicator.h"

@interface ChangeTextViewController ()
{
    NSMutableArray *possibleMatches;
    NSInteger selectedMatchIndex;
    
    // Added to fix issue # 236, /Yousuf
    BOOL isItemChanged,is_open,scroll_flag;
    UINavigationBar *headerView;
    
    //To add lists in Edit screen
    NSArray *lists;
    NSInteger selectedListIndex;
    NSString *currentListName;
    NSNumber *currentListID;
    BOOL isOpen_list;
    NSString *current_list_name;
}
@end

@implementation ChangeTextViewController

@synthesize itemId, item, itemObjectId;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    scroll_flag=true;
    //Dimple 26-10-2015
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        [self addTitleBar:64 width:SCREEN_WIDTH];
    }
    else
    {
        if(IS_IPHONE)
        {
            int header;
            if(IS_OS_8_OR_LATER)
            {
                header=44;
            }
            else{
                header=52;
            }
            if(IS_IPHONE)
            {
                if(!IS_OS_8_OR_LATER)
                {
                    if(iphone4)
                    {
                        [self addTitleBar:header width:480];
                    }
                    else
                    {
                        [self addTitleBar:header width:568];
                        
                    }
                }
                else{
                    [self addTitleBar:header width:SCREEN_WIDTH];
                    
                }
            }
        }
        else
        {
            [self addTitleBar:64 width:1024];
            
        }
    }
    
    //Dimple -30-10-2015
    is_open=true;
    self.picker.hidden=YES;
    self.picker_main_view.frame=CGRectMake(self.picker_main_view.frame.origin.x, self.picker_main_view.frame.origin.y, self.picker_main_view.frame.size.width, 0);
    self.picker_main_view.translatesAutoresizingMaskIntoConstraints=YES;
    
    //7-12-15
    
    isOpen_list=true;
    self.list_picker.hidden=YES;
    self.picker_view_list.frame=CGRectMake(self.picker_view_list.frame.origin.x, self.picker_view_list.frame.origin.y, self.picker_view_list.frame.size.width, 0);
    self.picker_view_list.translatesAutoresizingMaskIntoConstraints=YES;
    
    
    
    [self.segbutton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:font_name size:segment_title_font], NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    //Dimple-29-10-2015 set font and size
    
    self.textFieldItem.font=[UIFont fontWithName:font_name size:segment_title_font];
    
    self.labelMatchItem.font=[UIFont fontWithName:font_name size:textField_font];
    self.labelAfterShopping.font=[UIFont fontWithName:font_name size:textField_font];
    self.edititemLabel.font=[UIFont fontWithName:font_name size:textField_font];
    
    self.textFieldItem.delegate = self;
    
    self.textFieldItem.placeholder = NSLocalizedString(@"Item text", nil);
    self.labelMatchItem.text =[NSString stringWithFormat:@"%@: %@ " ,NSLocalizedString(@"Matching item", nil),@"?"];
    self.labelAfterShopping.text = NSLocalizedString(@"after purchasing", nil);
    
    
    [self.segbutton setTitle:NSLocalizedString(@"item is not permanent", nil) forSegmentAtIndex:0];
    [self.segbutton setTitle:NSLocalizedString(@"item is permanent", nil) forSegmentAtIndex:1];
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
    
    //7-12-15
    lists = [Item_list getAllLists];
    current_list_name=[[Item_list getListById:[item listId]]name];
    self.listlbl.text=[NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"List", nil),current_list_name];
    
     self.headerLbl.text=NSLocalizedString(@"Item name", nil);
    NSInteger index = 0;
    for (int i=0; i<[lists count]; i++)
    {
        if([[[lists objectAtIndex:i]name]isEqualToString:current_list_name])
        {
            index=i;
        }
    }
    [self.list_picker selectRow:index inComponent:0 animated:YES];
    
    
    currentListID = item.listId;
    
}
#pragma mark-Fixed headerview
- (void)addTitleBar:(int)height width:(int)width
{
    //Creating the plain Navigation Bar
    headerView = [[UINavigationBar alloc] init];
    const CGFloat mainHeaderHeight = height;
    [headerView setFrame:CGRectMake(0, 0, width, mainHeaderHeight)];
    
    //The UINavigationItem is neede as a "box" that holds the Buttons or other elements
    UINavigationItem *buttonCarrier = [[UINavigationItem alloc]initWithTitle:[NSString stringWithFormat:@"%@",NSLocalizedString(@"Edit item",nil)]];
    
    //The NavigationBar accepts those "Carrier" (UINavigationItem) inside an Array
    NSArray *barItemArray = [[NSArray alloc]initWithObjects:buttonCarrier,nil];
    
    // Attaching the Array to the NavigationBar
    [headerView setItems:barItemArray];
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor blackColor],
                                               NSForegroundColorAttributeName,
                                               [UIFont fontWithName:font_name size:header_font_size],
                                               NSFontAttributeName,
                                               nil];
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    
    UIImage *imageBack = [UIImage imageNamed:@"backimg1"];
    UIBarButtonItem *cancelbutton = [[UIBarButtonItem alloc] initWithImage:imageBack style:UIBarButtonItemStylePlain target:self action:@selector(onClickCancel:)];
    
    UIImage *imageOk = [UIImage imageNamed:@"nav_ok"];
    UIBarButtonItem *okbutton = [[UIBarButtonItem alloc] initWithImage:imageOk style:UIBarButtonItemStylePlain target:self action:@selector(onClickSave:)];
    
    UIImage *imageDel = [UIImage imageNamed:@"nav_rem"];
    UIBarButtonItem *Deletebutton = [[UIBarButtonItem alloc] initWithImage:imageDel style:UIBarButtonItemStylePlain target:self action:@selector(delete_click:)];
    
    buttonCarrier.leftBarButtonItem = cancelbutton;
    buttonCarrier.rightBarButtonItems = @[okbutton,Deletebutton];
    
    
    [self.view addSubview:headerView];
    
    if(IS_IPHONE)
    {
        if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
        {
            self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 275);
        }
        else
        {
            if(!iphone4)
            {
                self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 420);
            }
        }
    }
}

-(void)scrollViewDidScroll: (UIScrollView*)scrollView
{
    if(IS_IPHONE)
    {
        float scrollViewHeight = scrollView.frame.size.height;
        float scrollContentSizeHeight = scrollView.contentSize.height;
        float scrollOffset = scrollView.contentOffset.y;
        
        if (scrollOffset == 0)
        {
            scroll_flag=true;
            // then we are at the top
        }
        else if (scrollOffset + scrollViewHeight == scrollContentSizeHeight)
        {
            if(is_open)
            {
                scroll_flag=true;
                
            }
            else{
                scroll_flag=false;
            }
            // then we are at the end
        }
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //item = [Item getItemByObjectId:itemObjectId];
    
    self.textFieldItem.text = item.text;
    
    self.segbutton.selectedSegmentIndex = [item.isPermanent boolValue] ? 1 : 0;
    
    //possibleMatches = (NSArray*)item.possibleMatches;
    //orignalItemText = item.text;
    possibleMatches = [[NSMutableArray alloc] initWithArray:(NSArray*)item.possibleMatches];
    
    if (possibleMatches.count == 0)
    {
        
        //Dimple-31-10-2015
        self.labelMatchItem.hidden = YES;
        self.pickerImage.hidden=YES;
        self.openPickerBtn.hidden=YES;
    }
    else
    {
        self.listlbl.hidden = YES;
        self.pickerImage_list.hidden=YES;
        self.openPickerBtn_list.hidden=YES;
        self.openPickerBtn_list.userInteractionEnabled=NO;
        
        //Dimple-31-10-2015
        self.labelMatchItem.hidden = NO;
        self.pickerImage.hidden=NO;
        self.openPickerBtn.hidden=NO;
        
        
        [possibleMatches insertObject:@"?" atIndex:0];
        
        // Added to fix issue # 204, /Yousuf
        NSInteger numberOfRowsInPickerView = [self.picker numberOfRowsInComponent:0];
        if (item.matchingItemText && ![item.matchingItemText isEqualToString:item.text])
        {
            NSInteger selectedRow = [possibleMatches indexOfObject:item.matchingItemText];
            if (selectedRow >= 0 && selectedRow < numberOfRowsInPickerView)
            {
                selectedMatchIndex = selectedRow;
                self.labelMatchItem.text =[NSString stringWithFormat:@"%@: %@ " ,NSLocalizedString(@"Matching item", nil),item.matchingItemText];
                [self.picker selectRow:selectedRow inComponent:0 animated:NO];
            }
        }
        [self setlist_pickerframe];
        
    }
    if(IS_IPHONE)
    {
        self.picker_main_view.frame=CGRectMake(24,212,272, 0);
        self.picker.frame=CGRectMake(0,0,272,0);
    }
    else{
        self.picker_main_view.frame=CGRectMake(24,230,720, 0);
        self.picker.frame=CGRectMake(0,0,720,0);
    }
    self.picker_main_view.hidden=YES;
    self.picker.hidden=YES;
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_TO_REMOVE_ADS * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                       {
                           [self removeAds];
                       });
    }
    
}

-(void)setlist_pickerframe
{
    
    if(IS_IPHONE)
    {
        self.listlbl.translatesAutoresizingMaskIntoConstraints=YES;
        self.listlbl.frame=CGRectMake(24, 231, 240, 21);
        self.pickerImage_list.translatesAutoresizingMaskIntoConstraints=YES;
        self.pickerImage_list.frame=CGRectMake(276, 239, 20, 11);
        self.openPickerBtn_list.translatesAutoresizingMaskIntoConstraints=YES;
        self.openPickerBtn_list.frame=CGRectMake(0,224,320,36);
        self.picker_view_list.frame=CGRectMake(24,263,272, 0);
        self.list_picker.frame=CGRectMake(0,0,272,0);
    }
    else{
        self.listlbl.translatesAutoresizingMaskIntoConstraints=YES;
        self.listlbl.frame=CGRectMake(24, 231, 680, 21);
        self.pickerImage_list.translatesAutoresizingMaskIntoConstraints=YES;
        self.pickerImage_list.frame=CGRectMake(724, 239, 20, 11);
        self.openPickerBtn_list.translatesAutoresizingMaskIntoConstraints=YES;
        self.openPickerBtn_list.frame=CGRectMake(24,224,720,36);
        self.picker_view_list.frame=CGRectMake(24,263,720, 0);
        self.list_picker.frame=CGRectMake(0,0,720,0);
        
    }
    
    self.listlbl.hidden=NO;
    self.pickerImage_list.hidden=NO;
    self.openPickerBtn_list.hidden=NO;
    self.openPickerBtn_list.userInteractionEnabled=YES;
    self.picker_view_list.hidden=YES;
    self.list_picker.hidden=YES;
    
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPremiumAccountPurchased object:nil];
}

/**
 Remove ads if user has purchased premium
 @ModifiedDate: October 7 , 2015
 @Version:1.14
 @Author: Yousuf
 */
- (void)removeAds
{
    if (self.bannerView)
    {
        [self.bannerView removeConstraints:self.bannerView.constraints];
        [self.bannerView removeFromSuperview];
        
        
        [Utility updateConstraint:self.view toView:headerView withConstant:10];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- UI event

- (IBAction)onClickSave:(id)sender
{
    NSString *knowItemText = item.knownItemText;
    NSString *text = self.textFieldItem.text;
    NSNumber *isPermanent = [NSNumber numberWithInteger: self.segbutton.selectedSegmentIndex];
    
    NSString *matchingItem = item.matchingItemText;
    NSNumber *isDefaultMatch = item.isDefaultMatch; //not used even in android app.
    if (possibleMatches.count > 0)
    {
        matchingItem = [possibleMatches objectAtIndex:selectedMatchIndex];
        if ([matchingItem isEqualToString:@"?"])
        {
            matchingItem = @"";
        }
        
        // Added to fix issue # 236, /Yousuf
        if (![matchingItem isEqualToString:item.matchingItemText])
        {
            isItemChanged = YES;
        }
    }
    
    // Added to fix issue # 236, /Yousuf
    if (item.isPermanent != nil && isPermanent != nil && ![isPermanent isEqualToNumber:item.isPermanent])
    {
        isItemChanged = YES;
    }
    if (item.isDefaultMatch != nil && isDefaultMatch != nil && ![isDefaultMatch isEqualToNumber:item.isDefaultMatch])
    {
        isItemChanged = YES;
    }
    if (![text isEqualToString:item.text])
    {
        knowItemText = @"";
        isItemChanged = YES;
    }
    if([item.listId longValue] != [currentListID longValue])
    {
        isItemChanged=YES;
    }
    // Added to fix issue # 236, /Yousuf
    if (isItemChanged)
    {
        [item updateItemWithText:text andisPermanent:isPermanent andMatchingItem:matchingItem andIsDefaultMatch:isDefaultMatch withKnownItemText:knowItemText andItemListId:currentListID];
        [SignificantChangesIndicator sharedIndicator].itemsChanged = YES;
        [[SyncManager sharedManager] forceSync];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onClickCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark- Populating The UIPickerView

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(pickerView.tag==1)
    {
        return possibleMatches.count;
    }
    if(pickerView.tag==2)
    {
        return lists.count;
    }
    return 0;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(pickerView.tag==1)
    {
        self.labelMatchItem.text=[NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Matching item", nil),[possibleMatches objectAtIndex:row]];
        
        selectedMatchIndex = row;
    }
    if (pickerView.tag==2)
    {
        selectedListIndex = row;
        Item_list *list = (Item_list*)lists[row];
        if (self.listlbl !=nil)
        {
            currentListName = list.name;
            self.listlbl.text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"List", nil),currentListName];
            currentListID = list.item_listID;
        }
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *returnStr = @"";
    
    if(pickerView.tag==1)
    {
        returnStr = [possibleMatches objectAtIndex:row];
    }
    if(pickerView.tag==2)
    {
        returnStr=[[lists objectAtIndex:row]name];
    }
    return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return pickerView.frame.size.width;
}

#pragma HideKeyboard

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self.textFieldItem resignFirstResponder];
}

#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [view setAlpha:1];
    [UIView commitAnimations];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [view setAlpha:0];
    [UIView commitAnimations];
}
//Dimple-27-10-2015
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    if(pickerView.tag==1)
    {
        UILabel* tView = (UILabel*)view;
        if (!tView)
        {
            tView = [[UILabel alloc] init];
            
            [tView setFont:[UIFont fontWithName:font_name size:pickerview_font]];
            
            //       [tView setTextAlignment:UITextAlignmentLeft];
            
            tView.textAlignment=NSTextAlignmentCenter;
        }
        // Fill the label text here
        tView.text=[possibleMatches objectAtIndex:row];
        return tView;
    }
    if(pickerView.tag==2)
    {
        UILabel* tView = (UILabel*)view;
        if (!tView)
        {
            tView = [[UILabel alloc] init];
            
            [tView setFont:[UIFont fontWithName:font_name size:pickerview_font]];
            
            //       [tView setTextAlignment:UITextAlignmentLeft];
            
            tView.textAlignment=NSTextAlignmentCenter;
        }
        // Fill the label text here
        tView.text=[[lists objectAtIndex:row]name];
        return tView;
    }
    return 0;
}
#pragma mark- Open and Close Picker
-(void)openPickerBtn:(id)sender
{
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if(isOpen_list==false)
                         {
                             [self closedPicker_list];
                         }
                         
                         if(is_open)
                         {
                             [self openPicker];
                         }
                         else{
                             [self closedPicker];
                         }
                         
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
    [UIView commitAnimations];
}
-(void)openPicker
{
    self.picker_main_view.translatesAutoresizingMaskIntoConstraints=YES;
    self.pickerImage.image=[UIImage imageNamed:@"upimg"];
    self.picker_main_view.hidden=NO;
    
    if(IS_IPHONE)
    {
        self.picker.frame=CGRectMake(0,0,260,216);
        self.picker_main_view.frame=CGRectMake(24, 212, 272,180);
        self.listlbl.frame=CGRectMake(24, 394, 240, 21);
        self.pickerImage_list.frame=CGRectMake(276, 399, 20, 11);
        self.openPickerBtn_list.frame=CGRectMake(0,384,320,36);
        self.picker_view_list.frame=CGRectMake(24,423,272, 0);
        self.list_picker.frame=CGRectMake(0,0,272,0);
    }
    else{
        
        self.picker.frame=CGRectMake(0,0,720,216);
        self.picker_main_view.frame=CGRectMake(24, 212, 720,180);
        self.listlbl.frame=CGRectMake(24, 394, 680, 21);
        self.pickerImage_list.frame=CGRectMake(724, 399, 20, 11);
        self.openPickerBtn_list.frame=CGRectMake(24,384,720,36);
        self.picker_view_list.frame=CGRectMake(24,423,720, 0);
        self.list_picker.frame=CGRectMake(0,0,720,0);
        
    }
    
    is_open=false;
    
    [UIView animateWithDuration:0.5
                          delay:20
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
                         {
                             if(IS_IPHONE)
                             {
                                 if(scroll_flag)
                                 {
                                     if(IS_OS_8_OR_LATER)
                                     {
                                         [self.scrollview setContentOffset: CGPointMake(0, [Utility getScreenHeight]-145) animated:YES];
                                     }
                                     else{
                                         [self.scrollview setContentOffset: CGPointMake(0, 185) animated:YES];
                                         
                                     }
                                 }
                                 self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 460);
                             }
                         }
                         else{
                             if (IS_IPHONE) {
                                 if (iphone4) {
                                     self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 460);
                                     
                                 }
                                 
                             }
                         }
                         self.picker.hidden=NO;
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
    
}
-(void)closedPicker
{
    self.picker_main_view.translatesAutoresizingMaskIntoConstraints=YES;
    self.pickerImage.image=[UIImage imageNamed:@"backimg"];
    
    is_open=true;
    
    
    if(IS_IPHONE)
    {
        self.picker_main_view.frame=CGRectMake(24,212,272, 0);
        self.picker.frame=CGRectMake(0,0,272,0);
        // self.listlbl.translatesAutoresizingMaskIntoConstraints=YES;
        
        self.listlbl.frame=CGRectMake(24, 231, 240, 21);
        // self.pickerImage_list.translatesAutoresizingMaskIntoConstraints=YES;
        self.pickerImage_list.frame=CGRectMake(276, 239, 20, 11);
        //  self.openPickerBtn_list.translatesAutoresizingMaskIntoConstraints=YES;
        self.openPickerBtn_list.frame=CGRectMake(0,224,320,36);
        self.picker_view_list.frame=CGRectMake(24,263,272, 0);
        self.list_picker.frame=CGRectMake(0,0,272,0);
    }
    else{
        
        self.picker_main_view.frame=CGRectMake(24,212,720, 0);
        self.picker.frame=CGRectMake(0,0,720,0);
        //  self.listlbl.translatesAutoresizingMaskIntoConstraints=YES;
        self.listlbl.frame=CGRectMake(24, 231, 240, 21);
        //  self.pickerImage_list.translatesAutoresizingMaskIntoConstraints=YES;
        self.pickerImage_list.frame=CGRectMake(724, 239, 20, 11);
        //  self.openPickerBtn_list.translatesAutoresizingMaskIntoConstraints=YES;
        self.openPickerBtn_list.frame=CGRectMake(24,224,720,36);
        self.picker_view_list.frame=CGRectMake(24,230,720, 0);
        self.picker.frame=CGRectMake(0,0,720,0);
        
    }
    self.picker.hidden=YES;
    
}

#pragma mark- Chnage orientation
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(IS_IPHONE)
    {
        if(!is_open)
        {
            self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 460);
        }
        else
        {
            self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 275);
        }
        if(!isOpen_list)
        {
            self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 500);
        }
        else
        {
            self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 300);
        }
    }
    
    
}
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [headerView removeFromSuperview];
    [self closedPicker_list];
    [self closedPicker];
    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight||interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        if(IS_IPHONE)
        {
            int header;
            if(IS_OS_8_OR_LATER)
            {
                header=44;
            }
            else{
                header=52;
            }
            
            if (iphone4)
            {
                [self addTitleBar:header width:480];
            }
            else
            {
                [self addTitleBar:header width:568];
            }
        }
        else
        {
            [self addTitleBar:64 width:1024];
        }
    }
    else
    {
        if(IS_IPHONE)
        {
            [self addTitleBar:64 width:320];
        }
        else{
            [self addTitleBar:64 width:768];
            
        }
        
    }
}
-(IBAction)delete_click:(id)sender
{
    DLog(@"item Deleted:");
    [Item fakeDelete:itemObjectId];
    
    //Raj-7-1-16
    NSDictionary* userInfo = @{@"ItemText": self.textFieldItem.text};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UndoItemToast" object:self userInfo:userInfo];

    [self dismissViewControllerAnimated:YES completion:nil];
    
}
#pragma mark-open and close picker for list picker
-(void)openPickerBtn_list:(id)sender
{
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if(isOpen_list)
                         {
                             if(is_open==false)
                             {
                              [self closedPicker];
                             }
                             

                             [self openPicker_list];
                         }
                         else{
                             [self closedPicker_list];
                         }
                         
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
    [UIView commitAnimations];
}
-(void)openPicker_list
{
    
    self.picker_view_list.translatesAutoresizingMaskIntoConstraints=YES;
    self.pickerImage_list.image=[UIImage imageNamed:@"upimg"];
    self.picker_view_list.hidden=NO;
    if(IS_IPHONE)
    {
        if([possibleMatches count]>0)
        {
            self.list_picker.frame=CGRectMake(0,0,260,216);
            self.picker_view_list.frame=CGRectMake(24, 257, 272,180);
        }
        else
        {
            self.list_picker.frame=CGRectMake(0,0,260,216);
            self.picker_view_list.frame=CGRectMake(24, 212, 272,180);
        }
    }
    else{
        
        if([possibleMatches count]>0)
        {
            self.list_picker.frame=CGRectMake(0,0,720,216);
            self.picker_view_list.frame=CGRectMake(24, 257, 720,180);
        }
        else
        {
            self.list_picker.frame=CGRectMake(0,0,720, 216);
            self.picker_view_list.frame=CGRectMake(24,230,720,180);
        }
    }
    
    
    isOpen_list=false;
    
    [UIView animateWithDuration:0.5
                          delay:20
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
                         {
                             if(IS_IPHONE)
                             {
                                 if(scroll_flag)
                                 {
                                     if(IS_OS_8_OR_LATER)
                                     {
                                         [self.scrollview setContentOffset: CGPointMake(0, [Utility getScreenHeight]-145) animated:YES];
                                     }
                                     else{
                                         [self.scrollview setContentOffset: CGPointMake(0, 185) animated:YES];
                                         
                                     }
                                 }
                                 self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 460);
                             }
                         }
                         else{
                             if (IS_IPHONE) {
                                 if (iphone4) {
                                     self.scrollview.contentSize=CGSizeMake(SCREEN_WIDTH, 460);
                                     
                                 }
                                 
                             }
                         }
                         self.list_picker.hidden=NO;
                     }
                     completion:^(BOOL finished){
                         
                         
                     }];
    
}

-(void)closedPicker_list
{
    self.picker_view_list.translatesAutoresizingMaskIntoConstraints=YES;
    self.pickerImage_list.image=[UIImage imageNamed:@"backimg"];
    
    isOpen_list=true;
    
    
    if(IS_IPHONE)
    {
        if([possibleMatches count]>0)
        {
            self.picker_view_list.frame=CGRectMake(24,257,272, 0);
            self.list_picker.frame=CGRectMake(0,0,272,0);
        }
        else
        {
            self.picker_view_list.frame=CGRectMake(24,212,272, 0);
            self.list_picker.frame=CGRectMake(0,0,272,0);
        }
    }
    else{
        if([possibleMatches count]>0)
        {
            self.picker_view_list.frame=CGRectMake(24,257,720, 0);
            self.list_picker.frame=CGRectMake(0,0,720,0);
        }
        else
        {
            self.picker_view_list.frame=CGRectMake(24,230,720, 0);
            self.list_picker.frame=CGRectMake(0,0,720,0);
        }
    }
    self.list_picker.hidden=YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing ChangeTextViewController");
}

@end
