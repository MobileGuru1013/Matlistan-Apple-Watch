//
//  AddNewRecipeViewVC.m
//  Matlistan
//
//  Created by Leocan on 2/16/16.
//  Copyright (c) 2016 Flame Soft. All rights reserved.
//

#import "AddNewRecipeViewVC.h"
#import "Recipebox+Extra.h"
#import "AppDelegate.h"

@interface AddNewRecipeViewVC () {
    BOOL userSetRecipeImage;
}

@end

@implementation AddNewRecipeViewVC
NSInteger tag;
const float movementduration=0.3f;


- (void)viewDidLoad {
    [super viewDidLoad];
    userSetRecipeImage = NO;
     max_height=30;
    if(IS_IPHONE)
    {
        max_height=30;
    }
    else
    {
        max_height=40;
    }
    flag=true;
    screen_width=SCREEN_WIDTH;
    screen_height=SCREEN_HEIGHT;

    [self keyboardGeneration];
    
    [self.user_recipe_switch addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
    
    is_iphone6=false;

    //Add Save recipe button in navigation bar
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SaveRecipe"] style:UIBarButtonItemStylePlain target:self action:@selector(saveRecipe:)];
    self.navigationItem.rightBarButtonItems = @[done];
    self.title =NSLocalizedString(@"New recipe", nil);
    if([self.screenName isEqualToString:@"Edit"])
    {
        self.title =NSLocalizedString(@"Edit recipe", nil);
        recipe_id=self.editRecipe.recipeboxID;
    }
    else{
        self.title =NSLocalizedString(@"New recipe", nil);
    }
 
      is_next_prevClick=false;
//    [self.scroll_view setScrollEnabled:YES];
//    self.automaticallyAdjustsScrollViewInsets=NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myNotificationMethod:)
                                             name:UIKeyboardWillShowNotification
                                             object:nil];
}

- (void)viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    if(flag)
    {
        flag=false;
        [self AssignRecipeValueToTextfield];
    }
}

#pragma mark-Assign Recipe Value To Textfield
-(void)AssignRecipeValueToTextfield
{
//    NSLog(@"Edit recipe object :%@",self.editRecipe);
    if([self.screenName isEqualToString:@"Edit"])
    {
        NSString *tagsText=@"";
        if (self.editRecipe.relatedTags.count > 0) {
            for (Recipebox_tag *tag in self.editRecipe.relatedTags) {
                NSString *htmlSubString = [NSString stringWithFormat:@"%@",tag.text];
                tagsText = [NSString stringWithFormat:@"%@, %@",tagsText,htmlSubString];
            }
            if(tagsText.length>0)
            {
                if(![tagsText isEqualToString:@", "])
                {
                    tagsText=[tagsText substringFromIndex:2];
                    self.tagsTxt.text=tagsText;
                }
            }
        }
        
       
        UIImage *img;
        if(self.editRecipe.imageFileName){
            img = [Utility loadLocalRecipeImage:self.editRecipe.recipeboxID];
        }
        if (img) {
            self.recipeImg.image = img;
        }
        else
        {
            NSString *newUrl = [Utility getCorrectURLFromJson: self.editRecipe.imageUrl];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                NSURL *url =[NSURL URLWithString:newUrl];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                __unsafe_unretained typeof(self) weakSelf = self;
                [self.recipeImg setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    NSString *fileName = [NSString stringWithFormat:@"%@.png",weakSelf.editRecipe.recipeboxID];
                    [Utility saveImage:[Utility imageWithImage:image scaledToMaxWidth:150 maxHeight:150] withFileName:fileName];
                    
                    [Recipebox fillImageFileName:fileName forId:weakSelf.editRecipe.recipeboxID];
                    weakSelf.editRecipe.imageFileName = fileName;
                    weakSelf.recipeImg.image = image;
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    DLog(@"Can't download recipe image from %@", newUrl);
                }];
                
            });
        }
        self.titleTxt.text=self.editRecipe.title;
        
        //Source text assign to source field #110(1.1)
        NSString *source = @"";

        if ([Utility isStringEmpty:self.editRecipe.source_text]) {
            if (![Utility isStringEmpty:self.editRecipe.source_url]) {
                source = self.editRecipe.source_url;
            }
        }
        else{
            source = self.editRecipe.source_text;
        }
        if (![Utility isStringEmpty:source]) {
            self.sourceTxt.text=source;

        }
        // source end
        
        self.yieldTxt.text=[NSString stringWithFormat:@"%@",self.editRecipe.portions];
        self.portionsTxt.text=self.editRecipe.portionType;
        
        //Cooking time text assign to Cooking time field #111(1.1)
        if(self.editRecipe.cookTime!=nil)
        {
            self.cookingtimeTxt.text=[NSString stringWithFormat:@"%@",self.editRecipe.cookTime];
        }
        //End cookin timer
        
        
        self.descTxt.text= [self.editRecipe.descriptionText  stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        self.ingredientsTxt.text=[self.editRecipe.ingredients stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        self.instructionTxt.text=[self.editRecipe.instructions stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        self.adviceTxt.text=[self.editRecipe.advice stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        self.yourNotesTxt.text=[self.editRecipe.notes stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        NSLog(@"recipe object:%@",self.editRecipe);
        NSNumber *is_public=self.editRecipe.isPublic;
        if([is_public isEqual:@1])
        {
            [self.user_recipe_switch setOn:YES animated:YES];
        }
        else
        {
            [self.user_recipe_switch setOn:NO animated:YES];
            
        }
        //        self.user_recipe_switch se
        
//        [self getContentSize:self.descTxt];
//        [self getContentSize:self.ingredientsTxt];
//        [self getContentSize:self.instructionTxt];
//        [self getContentSize:self.adviceTxt];
//        [self getContentSize:self.yourNotesTxt];
    }
    [self getContentSize:self.descTxt];
    [self getContentSize:self.ingredientsTxt];
    [self getContentSize:self.instructionTxt];
    [self getContentSize:self.adviceTxt];
    [self getContentSize:self.yourNotesTxt];
    
    //Set form design
    [self setFormDesign];
    [self setscollview_Y];

}
#pragma mark- calulate time
+(NSString*)getCookTimeStringFromRecipe:(Recipebox*)recipe{
    NSString *timeString = @"";
    if (recipe.cookTime != nil && [recipe.cookTime intValue]!= 0) {
        timeString = [NSString stringWithFormat:@"%@ min", [recipe.cookTime stringValue]];
    }
    else {
        if (recipe.originalCookTime != nil && [recipe.originalCookTime intValue] != 0) {
            if ([recipe.originalCookTimeSpanLower intValue] > 0){
                timeString = [NSString stringWithFormat:@"%@ - %@ min",[recipe.originalCookTimeSpanLower stringValue], [recipe.originalCookTime stringValue]];
            }
            else{
                timeString = [NSString stringWithFormat:@"< %@ min",[recipe.originalCookTime stringValue]];
            }
        }
        else{
            if ([recipe.originalCookTimeSpanLower intValue] > 0) {
                timeString = [NSString stringWithFormat:@"%@+ min",[recipe.originalCookTimeSpanLower stringValue]];
            }
        }
    }
    return timeString;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
     [SyncManager sharedManager].syncManagerDelegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }
//   [self.navigationController setNavigationBarHidden:YES animated:YES];
}
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self resignKeyboard:nil];
//    [self getContentSize:self.descTxt];

    
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    screen_width=SCREEN_WIDTH;
    screen_height=SCREEN_HEIGHT;
    

    if(self.descTxt.text.length>0 )
    {
        [self getContentSize:self.descTxt];
    }
    if(self.ingredientsTxt.text.length>0 )
    {
        [self getContentSize:self.ingredientsTxt];
    }
    if(self.instructionTxt.text.length>0)
    {
        [self getContentSize:self.instructionTxt];
    }
    if(self.adviceTxt.text.length>0)
    {
        [self getContentSize:self.adviceTxt];
    }
    if(self.yourNotesTxt.text.length>0)
    {
        [self getContentSize:self.yourNotesTxt];
    }
   [self setFormDesign];
   [self setscollview_Y];
    
}

#pragma mark -Keyboard Frame
- (void)myNotificationMethod:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    keyboardFrame=[keyboardFrameBegin CGRectValue];
    CGFloat height = CGRectGetMaxY(self.yourNotesTxt.frame);
    if(IS_IPAD_PRO)
    {
        self.scroll_view.contentSize = CGSizeMake(screen_width, height+[keyboardFrameBegin CGRectValue].size.height-self.bannerView.frame.size.height+150);
    }
    else
    {
        self.scroll_view.contentSize = CGSizeMake(screen_width, height+[keyboardFrameBegin CGRectValue].size.height-self.bannerView.frame.size.height+20);
    }
}

#pragma mark -Keyboard Managemnet
-(IBAction)keyboardGeneration
{
    if(self.tbKeyboard==nil)
    {
        self.tbKeyboard=[[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 38.0f)];
        self.tbKeyboard.barStyle=UIBarStyleBlack;
        UIBarButtonItem *prevBarItem=[[UIBarButtonItem alloc]initWithTitle:@"Previous" style:UIBarButtonItemStylePlain target:self action:@selector(previousTF:)];
        
        UIBarButtonItem *nextBarItem=[[UIBarButtonItem alloc]initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextTF:)];
        
        UIBarButtonItem *spaceBarItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *doneBarItem=[[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(resignKeyboard:)];
        
        [prevBarItem setTintColor:[UIColor whiteColor]];
        [nextBarItem setTintColor:[UIColor whiteColor]];
        [doneBarItem setTintColor:[UIColor whiteColor]];
        
        [self.tbKeyboard setItems:[NSArray arrayWithObjects:prevBarItem,nextBarItem,spaceBarItem,doneBarItem, nil]];
        
        [self.titleTxt setInputAccessoryView:self.tbKeyboard];
        [self.sourceTxt setInputAccessoryView:self.tbKeyboard];
        [self.tagsTxt setInputAccessoryView:self.tbKeyboard];
        [self.yieldTxt setInputAccessoryView:self.tbKeyboard];
        [self.portionsTxt setInputAccessoryView:self.tbKeyboard];
        [self.cookingtimeTxt setInputAccessoryView:self.tbKeyboard];
        [self.descTxt setInputAccessoryView:self.tbKeyboard];
        [self.ingredientsTxt setInputAccessoryView:self.tbKeyboard];
        [self.instructionTxt setInputAccessoryView:self.tbKeyboard];
        [self.adviceTxt setInputAccessoryView:self.tbKeyboard];
        [self.yourNotesTxt setInputAccessoryView:self.tbKeyboard];
    }
}

-(IBAction)previousTF:(id)sender
{
    is_next_prevClick=true;

    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:movementduration];
    
    NSLog(@"Previous:%ld",(long)tag);
    
    if(tag>1)
    {
        UITextField *tf=(UITextField *)[self.view viewWithTag:tag-1];
        [tf becomeFirstResponder];
    }
    else
    {
        [self resignKeyboard:nil];
    }
    
    [UIView commitAnimations];
}

-(IBAction)nextTF:(id)sender
{
    is_next_prevClick=true;
    
    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:movementduration];
    
    if(tag<11)
    {
        UITextField *tf=(UITextField *)[self.view viewWithTag:tag+1];
        [tf becomeFirstResponder];
    }
    else
    {
        [self resignKeyboard:nil];
    }
    
    [UIView commitAnimations];
}

-(IBAction)resignKeyboard:(id)sender
{
    is_next_prevClick=false;
    keyboardFrame=CGRectZero;
 
    
    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.5];
    
    [self.titleTxt resignFirstResponder];
    [self.sourceTxt resignFirstResponder];
    [self.tagsTxt resignFirstResponder];
    [self.yieldTxt resignFirstResponder];
    [self.portionsTxt resignFirstResponder];
    [self.cookingtimeTxt resignFirstResponder];
    [self.descTxt resignFirstResponder];
    [self.ingredientsTxt resignFirstResponder];
    [self.instructionTxt resignFirstResponder];
    [self.adviceTxt resignFirstResponder];
    [self.yourNotesTxt resignFirstResponder];

    [UIView commitAnimations];
    
}

#pragma mark- Textfield delegate method
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    tag=textField.tag;
    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:movementduration];
    int n=0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        if(IS_IPHONE)
        {
            if(iphone4)
            {
                n=textField.frame.origin.y-50;
            }
            else if(iphone5)
            {
                n=textField.frame.origin.y-150;
            }
            else if(iphone6 || iphone6Plus)
            {
                if(textField.tag>1)
                {
                    n=textField.frame.origin.y-220;
                }
                else
                {
                    n=0;
                }
            }
            
            if(is_next_prevClick)
            {
                if(tag==5||tag==6||tag==7)
                {
                    [UIView commitAnimations];
                    return;
                }
                else if(textField.tag>=1)
                {
                    [self.scroll_view setContentOffset:CGPointMake(0,n) animated:YES];
                }
            }
            else
            {
                if(textField.tag>=1)
                {
                    is_next_prevClick=true;
                    [self.scroll_view setContentOffset:CGPointMake(0, n) animated:YES];
                }
            }
        }
        else//ipad//portrait
        {
            
            if(is_next_prevClick)
            {
                if(tag==5||tag==6||tag==7)
                {
                    [UIView commitAnimations];
                    return;
                }
                else if(self.descTxt.frame.size.height>100)
                {
                    n=500;

                    if(textField.tag>=3)
                    {
                        [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                    }
                }
                else
                {
                    n=400;

                    if(textField.tag>=8)
                    {
                        [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                    }
                }
            }
            else
            {
                
                    if(self.descTxt.contentSize.height / self.descTxt.font.lineHeight>10)
                    {
                        n=500;
                        if(textField.tag>=3)
                        {
                            is_next_prevClick=true;
                            [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                        }
                    }
                    else
                    {
                        n=400;
                        if(textField.tag>=8)
                        {
                            is_next_prevClick=true;
                            [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                        }
                    }
                }
             }
    }
    else//landcap mode
    {
        if(IS_IPHONE)
        {
            if(iphone4 || iphone5)
            {
                if ([UIApplication sharedApplication].isStatusBarHidden)
                {
                    n=10;
                }
                else
                {
                    n=10-5;
                }
            }
            else if(iphone6 || iphone6Plus)
            {
                n=50;
            }
            
            if(is_next_prevClick)
            {
                if(tag==5||tag==6||tag==7)
                {
                    [UIView commitAnimations];
                    return;
                }
                else if(textField.tag>=1)
                {
                    [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                }
            }
            else
            {
                if(textField.tag>=1)
                {
                    is_next_prevClick=true;
                    [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                    
                }
            }
        }
        else//ipad//landscape
        {
            if(IS_IPAD_PRO)
            {
                NSLog(@"%f",self.descTxt.contentSize.height);
                NSLog(@"%f",self.scroll_view.contentOffset.y);
                if(is_next_prevClick)
                {
                    if(tag==5||tag==6||tag==7)
                    {
                        [UIView commitAnimations];
                        return;
                    }
                    else{
                        n=100;
                        
                        if(textField.tag>=1)
                        {
                            [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                        }
                    }
                }
                else
                {
                    n=100;
                    is_next_prevClick=true;
                    if(textField.tag>1)
                    {
//                        is_next_prevClick=true;
                        [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                    }
                }

            }
            else
            {
                if(is_next_prevClick)
                {
                    if(tag==5||tag==6||tag==7)
                    {
                        [UIView commitAnimations];
                        return;
                    }
                    else{
                        n=100;
                        
                        if(textField.tag>=1)
                        {
                            [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                        }
                    }
                }
                else
                {
                    n=100;
                        if(textField.tag>=1)
                        {
                            is_next_prevClick=true;
                            [self.scroll_view setContentOffset:CGPointMake(0, textField.frame.origin.y-n) animated:YES];
                        }
                }
            }
        }
    }
    

   
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self setScrollViewContentSize];
}

#pragma mark- Textview delegate method

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    
    previousRect=textView.frame;
    UITextPosition* pos = textView.endOfDocument;
    CGRect currentRect = [textView caretRectForPosition:pos];

    NSLog(@"contetnt offset at1 :%f",currentRect.origin.y);
//    [self.scroll_view setContentOffset:CGPointMake(0,currentRect.origin.y) animated:YES];

    

    tag=textView.tag;
    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:movementduration];
    int n=0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        if(IS_IPHONE)
        {
            if(iphone4)
            {
                if(textView.tag>=2)
                {
                    n= 90;
                }
                else
                {
                    n=0;
                }
            }
            else if(iphone5)
            {
                if(textView.tag>=2)
                {
                    n=190;
                }
                else
                {
                    n=0;
                }
            }
            else if(iphone6)
            {
                if(textView.tag>1)
                {
                    if(textView.tag == 11)
                    {
                        n=270;
                    }
                    else
                    {
                        n=230;
                    }
                }
                else
                {
                    n=0;
                }
            }
            else if(iphone6Plus)
            {
                if(textView.tag>1)
                {
                    if(textView.tag==2)
                    {
                        n=220;
                    }
                    else if(textView.tag == 11)
                    {
                        n=330;
                    }
                    else
                    {
                        n=290;
                    }
                }
                else
                {
                    n=0;
                }
            }
            [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];

        }
        else
        {
            if(IS_IPAD_PRO)
            {
                if(self.view.frame.size.height - (CGRectGetMaxY(textView.frame)+keyboardFrame.size.height)<50)
                {

                    n=750;
                    [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];
                }
                else
                {
                    NSLog(@"self.scroll_view.contentOffset.y:%f",self.descTxt.contentSize.height / self.descTxt.font.lineHeight);
                    if(textView.contentSize.height / textView.font.lineHeight>10)
                    {
                        n=750;
                        [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];
                        
                    }
                    else
                    {
                        //                n=200;
                        //                [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];
                        
                    }
                }

            }
            else
            {
                if(textView.tag>3)
                {
                    n=570;
                    [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];

                }
                else
                {
                    NSLog(@"self.scroll_view.contentOffset.y:%f",self.descTxt.contentSize.height / self.descTxt.font.lineHeight);
                    if(textView.contentSize.height / textView.font.lineHeight>10)
                    {
                        n=570;
                        [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];

                    }
                    else
                    {
        //                n=200;
        //                [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];

                    }
                }
            }
        }
    }
    else//landscape mode
    {
        if(IS_IPHONE)
        {
            if(iphone6)
            {
                if(textView.tag>=2)
                {
                    n=80;
                }
                [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];
            }
            else if (iphone6Plus)
            {
                if(textView.tag>=2)
                {
                    n=100;
                }
                [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];
            }
            else
            {
                if(textView.tag>=2)
                {
                    if ([UIApplication sharedApplication].isStatusBarHidden)
                    {
                        n=50;
                    }
                    else
                    {
                        n=50-15;
                    }
                }
                [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];
            }
            
        }
        else
        {
            if(IS_IPAD_PRO)
            {
                n=230;
                if(textView.tag>2)
                {
                    n=300;
                }
            }
            else
            {
                n=200;
                if(textView.tag>2)
                {
                    n=230;
                }
            }
            [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:NO];
        }
    }
    previousRect = currentRect;

    
    
    [UIView commitAnimations];
}
-(void)textViewDidChange:(UITextView *)textView
{
    
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth),MAX(max_height, newSize.height));
    textView.frame = newFrame;
    
    
    [self setFormDesign];
    
    UITextPosition* pos = textView.endOfDocument;
    CGRect currentRect = [textView caretRectForPosition:pos];
    
    NSLog(@"%f",CGRectGetMaxY(textView.frame));
    
    
    if(currentRect.origin.y > previousRect.origin.y)
    {
        NSLog(@"contetnt offset at :%f",currentRect.origin.y);
        int numLines = textView.contentSize.height / textView.font.lineHeight;
        NSLog(@"line:-%d", numLines);
        int n;
        if(IS_IPHONE)
        {
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            {
                if(iphone4)
                {
                     n=90;
                }
                else if(iphone5)
                {
                      n=190;
                }
                else if(iphone6)
                {
                    if(textView.tag == 11)
                    {
                        n=270;
                    }
                    else
                    {
                        n=230;
                    }
                }
                else if(iphone6Plus)
                {
                    if(textView.tag==2)
                    {
                        n=220;
                    }
                    else if(textView.tag == 11)
                    {
                        n=330;
                    }
                    else
                    {
                        n=290;
                    }
                }
            }
            else
            {
                if(iphone6)
                {
                    n=80;
                }
                else if(iphone6Plus)
                {
                    n=100;
                }
                else
                {
                    if ([UIApplication sharedApplication].isStatusBarHidden)
                    {
                        n=50;
                    }
                    else
                    {
                        n=50-15;
                    }
                }
            }
        }
        else
        {
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            {

                if(textView.contentSize.height / textView.font.lineHeight<20 && textView.tag==2)
                {
                    n=350;
                }
                else
                {
                    if(IS_IPAD_PRO)
                    {
                        n=750;
                    }
                    else
                    {
                        n=570;
                    }
                }
            }
            else
            {
                if(IS_IPAD_PRO)
                {
                    n=230;
                    if(textView.tag>2)
                    {
                        n=300;
                    }
                }
                else
                {
                    n=200;
                    if(textView.tag>2)
                    {
                        n=230;
                    }
                }
            }
        }
        [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:YES];
    }
    previousRect = currentRect;
    CGFloat height = CGRectGetMaxY(self.yourNotesTxt.frame);
    if(IS_IPAD_PRO)
    {
        self.scroll_view.contentSize = CGSizeMake(screen_width, height+[keyboardFrameBegin CGRectValue].size.height-self.bannerView.frame.size.height+150);

    }
    else
    {
        self.scroll_view.contentSize = CGSizeMake(screen_width, height+[keyboardFrameBegin CGRectValue].size.height-self.bannerView.frame.size.height+20);
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if (range.length==1 && text.length==0)
    {
        UITextPosition* pos = textView.endOfDocument;
        CGRect currentRect = [textView caretRectForPosition:pos];
        
        NSLog(@"contetnt offset at :%f",currentRect.origin.y);
        int numLines = textView.contentSize.height / textView.font.lineHeight;
        NSLog(@"line:-%d", numLines);
        int n=200;
       
        if(IS_IPHONE)
        {
          
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            {
              
                if(iphone4)
                {
                    n=90;
                }
                else if(iphone5)
                {
                    n=190;
                }
                else if(iphone6 || iphone6Plus)
                {
                    n=230;
                }
                if(textView.tag>=2)
                {
                    if(currentRect.origin.y > previousRect.origin.y)
                    {
                        [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:YES];
                    }
                    else
                    {
                        [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:YES];
                        
                    }
                }
            }
            else{
                 n=50;
                
                [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:YES];

            }

        }
        else
        {
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            {
                n=500;
                [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:YES];
                

            }
            else
            {
                n=250;
                [self.scroll_view setContentOffset:CGPointMake(0,CGRectGetMaxY(textView.frame)-n) animated:YES];

            }
        }
        
       

        
        previousRect = currentRect;
    }
    if([text isEqualToString:@"\n"])
    {
        return YES;
    }
    return YES;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    [self setScrollViewContentSize];
}

#pragma mark- calulate textview frame
-(CGRect) getContentSize:(UITextView*) textView
{
    if(IS_IPHONE)
    {
        textView.textContainerInset=UIEdgeInsetsMake(4, -5, 6, 0);
    }
    else
    {
        textView.textContainerInset=UIEdgeInsetsMake(6, -5, 8, 0);
    }
    textView.scrollEnabled = NO;
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth),MAX(max_height, newSize.height+0));
    textView.frame = newFrame;
    return textView.frame;
}

#pragma mark - Image Picker
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex ==0)
    {
        //open gallery
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.delegate = self;
//        [self presentViewController:imagePickerController animated:YES completion:nil];
        if(IS_OS_8_OR_LATER)
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                // Place image picker on the screen
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }];
        }
        else
        {
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
    }
    else if(buttonIndex ==1)
    {
        //open camera
        
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
        }
        else
        {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = YES;
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:picker animated:YES completion:NULL];
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"info%@",info);
    // self.recipeImg.image= [self croppIngimageByImageName:[info objectForKey:@"UIImagePickerControllerOriginalImage"] toRect:CGRectMake(0, 0, 2000, 2000)];
    userSetRecipeImage = YES;
     self.recipeImg.image= [AddNewRecipeViewVC imageWithImage:[info objectForKey:@"UIImagePickerControllerOriginalImage"] scaledToWidth:SCREEN_WIDTH];
    
    self.recipeImg.backgroundColor=[UIColor blackColor];
    self.recipeImg.contentMode=UIViewContentModeScaleAspectFit;
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}
+(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark- identify state of switch
- (void) switchToggled:(id)sender {
    UISwitch *mySwitch = (UISwitch *)sender;
    if ([mySwitch isOn]) {
        NSLog(@"its on!");
    } else {
        NSLog(@"its off!");
    }
}
-(void)setFormDesign
{
    if(IS_IPHONE)
    {
        distance=8;
    }
    else
    {
        distance=15;
    }
    self.lbl_titleTxt.frame=CGRectMake(self.lbl_titleTxt.frame.origin.x, self.titleTxt.frame.origin.y+self.titleTxt.frame.size.height, self.lbl_titleTxt.frame.size.width, self.lbl_titleTxt.frame.size.height);
    
    self.descTxt.frame=CGRectMake(self.descTxt.frame.origin.x, self.titleTxt.frame.origin.y+self.titleTxt.frame.size.height+distance,self.descTxt.frame.size.width, self.descTxt.frame.size.height);
    self.lbl_descTxt.frame=CGRectMake(self.lbl_descTxt.frame.origin.x, self.descTxt.frame.origin.y+self.descTxt.frame.size.height, self.lbl_descTxt.frame.size.width, self.lbl_descTxt.frame.size.height);

    self.sourceTxt.frame=CGRectMake(self.sourceTxt.frame.origin.x, self.descTxt.frame.origin.y+self.descTxt.frame.size.height+distance, self.sourceTxt.frame.size.width, self.sourceTxt.frame.size.height);
    self.lbl_sourceTxt.frame=CGRectMake(self.lbl_sourceTxt.frame.origin.x, self.sourceTxt.frame.origin.y+self.sourceTxt.frame.size.height, self.lbl_sourceTxt.frame.size.width, self.lbl_sourceTxt.frame.size.height);

    self.recipeLbl.frame=CGRectMake(self.recipeLbl.frame.origin.x,self.sourceTxt.frame.origin.y+self.sourceTxt.frame.size.height+distance, self.recipeLbl.frame.size.width, self.recipeLbl.frame.size.height);
    self.user_recipe_switch.frame=CGRectMake(self.user_recipe_switch.frame.origin.x,self.sourceTxt.frame.origin.y+self.sourceTxt.frame.size.height+distance, self.user_recipe_switch.frame.size.width, self.user_recipe_switch.frame.size.height);

    self.user_recipe_switch.frame=CGRectMake(self.user_recipe_switch.frame.origin.x,self.sourceTxt.frame.origin.y+self.sourceTxt.frame.size.height+distance, self.user_recipe_switch.frame.size.width, self.user_recipe_switch.frame.size.height);


    self.tagsTxt.frame=CGRectMake(self.tagsTxt.frame.origin.x,self.recipeLbl.frame.origin.y+self.recipeLbl.frame.size.height+distance, self.tagsTxt.frame.size.width, self.tagsTxt.frame.size.height);
    self.lbl_tagsTxt.frame=CGRectMake(self.lbl_tagsTxt.frame.origin.x,self.tagsTxt.frame.origin.y+self.tagsTxt.frame.size.height, self.lbl_tagsTxt.frame.size.width, self.lbl_tagsTxt.frame.size.height);

    
    self.yieldTxt.frame=CGRectMake(self.yieldTxt.frame.origin.x, self.tagsTxt.frame.origin.y+self.tagsTxt.frame.size.height+distance, self.yieldTxt.frame.size.width, self.yieldTxt.frame.size.height);
    self.lbl_yieldTxt.frame=CGRectMake(self.lbl_yieldTxt.frame.origin.x, self.yieldTxt.frame.origin.y+self.yieldTxt.frame.size.height, self.lbl_yieldTxt.frame.size.width, self.lbl_yieldTxt.frame.size.height);
    
    self.portionsTxt.frame=CGRectMake(self.portionsTxt.frame.origin.x, self.tagsTxt.frame.origin.y+self.tagsTxt.frame.size.height+distance, self.portionsTxt.frame.size.width, self.portionsTxt.frame.size.height);
    self.lbl_portionsTxt.frame=CGRectMake(self.lbl_portionsTxt.frame.origin.x, self.portionsTxt.frame.origin.y+self.portionsTxt.frame.size.height, self.lbl_portionsTxt.frame.size.width, self.lbl_portionsTxt.frame.size.height);

    
    self.cookingtimeTxt.frame=CGRectMake(self.cookingtimeTxt.frame.origin.x, self.tagsTxt.frame.origin.y+self.tagsTxt.frame.size.height+distance, self.cookingtimeTxt.frame.size.width, self.cookingtimeTxt.frame.size.height);
    self.lbl_cookingtimeTxt.frame=CGRectMake(self.lbl_cookingtimeTxt.frame.origin.x, self.cookingtimeTxt.frame.origin.y+self.cookingtimeTxt.frame.size.height, self.lbl_cookingtimeTxt.frame.size.width, self.lbl_cookingtimeTxt.frame.size.height);

    
    self.ingredientsTxt.frame=CGRectMake(self.ingredientsTxt.frame.origin.x, self.cookingtimeTxt.frame.origin.y+self.cookingtimeTxt.frame.size.height+distance, self.ingredientsTxt.frame.size.width, self.ingredientsTxt.frame.size.height);
    self.lbl_ingredientsTxt.frame=CGRectMake(self.lbl_ingredientsTxt.frame.origin.x, self.ingredientsTxt.frame.origin.y+self.ingredientsTxt.frame.size.height, self.lbl_ingredientsTxt.frame.size.width, self.lbl_ingredientsTxt.frame.size.height);

    self.instructionTxt.frame=CGRectMake(self.instructionTxt.frame.origin.x, self.ingredientsTxt.frame.origin.y+self.ingredientsTxt.frame.size.height+distance, self.instructionTxt.frame.size.width, self.instructionTxt.frame.size.height);
    self.lbl_instructionTxt.frame=CGRectMake(self.lbl_instructionTxt.frame.origin.x, self.instructionTxt.frame.origin.y+self.instructionTxt.frame.size.height, self.lbl_instructionTxt.frame.size.width, self.lbl_instructionTxt.frame.size.height);

    
    self.adviceTxt.frame=CGRectMake(self.adviceTxt.frame.origin.x, self.instructionTxt.frame.origin.y+self.instructionTxt.frame.size.height+distance, self.adviceTxt.frame.size.width, self.adviceTxt.frame.size.height);
    self.lbl_adviceTxt.frame=CGRectMake(self.lbl_adviceTxt.frame.origin.x, self.adviceTxt.frame.origin.y+self.adviceTxt.frame.size.height, self.lbl_adviceTxt.frame.size.width, self.lbl_adviceTxt.frame.size.height);

    self.yourNotesTxt.frame=CGRectMake(self.yourNotesTxt.frame.origin.x, self.adviceTxt.frame.origin.y+self.adviceTxt.frame.size.height+distance, self.yourNotesTxt.frame.size.width, self.yourNotesTxt.frame.size.height);
    self.lbl_yourNotesTxt.frame=CGRectMake(self.lbl_yourNotesTxt.frame.origin.x, self.yourNotesTxt.frame.origin.y+self.yourNotesTxt.frame.size.height, self.lbl_yourNotesTxt.frame.size.width, self.lbl_yourNotesTxt.frame.size.height);

    self.titleTxt.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    self.titleTxt.placeholder=NSLocalizedString(@"Title", nil);
    self.descTxt.placeholderText=NSLocalizedString(@"Description",nil);
    self.sourceTxt.placeholder=NSLocalizedString(@"Source",nil);
    self.recipeLbl.text=NSLocalizedString(@"Let others use this recipe",nil);
    self.tagsTxt.placeholder=NSLocalizedString(@"Tags_with_commas",nil);
    self.yieldTxt.placeholder=NSLocalizedString(@"Yield",nil);
    self.portionsTxt.placeholder=NSLocalizedString(@"Add Portions",nil);
    self.cookingtimeTxt.placeholder=NSLocalizedString(@"Cooking time(min)",nil);
    self.ingredientsTxt.placeholderText=NSLocalizedString(@"Ingredients",nil);
    self.instructionTxt.placeholderText=NSLocalizedString(@"EditInstructions",nil);
    self.adviceTxt.placeholderText=NSLocalizedString(@"Advice",nil);
    self.yourNotesTxt.placeholderText=NSLocalizedString(@"Your notes",nil);
    
    UIColor *place_holder_color=[UIColor colorWithRed:199.0/255.0 green:199.0/255.0 blue:205.0/255.0 alpha:1.0f];
    self.descTxt.placeholderColor=place_holder_color;
    self.ingredientsTxt.placeholderColor=place_holder_color;
    self.instructionTxt.placeholderColor=place_holder_color;
    self.adviceTxt.placeholderColor=place_holder_color;
    self.yourNotesTxt.placeholderColor=place_holder_color;
   
}
#pragma mark- Draw line
-(void)drawHalfLineBottomOfTextfield:(UITextField *)txtField frame:(CGRect)frame
{
    CALayer *border = [CALayer layer];
    border.frame =frame;
    border.backgroundColor=[UIColor lightGrayColor].CGColor;
    [self.scroll_view.layer addSublayer:border];

}

-(void)drawLineBottomOfTextfield:(UITextField *)txtField
{
    CGRect frame=CGRectMake(0, txtField.frame.origin.y+txtField.frame.size.height, SCREEN_WIDTH, 0.5);
    CALayer *border = [CALayer layer];
    border.frame =frame;
    border.backgroundColor=[UIColor lightGrayColor].CGColor;
    [self.scroll_view.layer addSublayer:border];
}
-(void)drawLineBottomOfTextview:(UITextView *)txtView
{
    CGRect frame=CGRectMake(0, txtView.frame.origin.y+txtView.frame.size.height, SCREEN_WIDTH, 0.5);
    CALayer *border = [CALayer layer];
    border.frame =frame;
    border.backgroundColor=[UIColor lightGrayColor].CGColor;
    [self.scroll_view.layer addSublayer:border];
}
#pragma mark- Button click event
-(IBAction)choosePhoto:(id)sender
{
    [self resignKeyboard:nil];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Gallery",@"Camera",nil];
    [actionSheet showInView:self.view];
}
-(IBAction)backBtn:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}
-(IBAction)saveRecipe:(id)sender
{
    if(![[MatlistanHTTPClient sharedMatlistanHTTPClient] isLoggedIn]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"internet_connection_required",nil)
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }

    NSString *tempImg;
    
    self.titleTxt.text = [self.titleTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if([self.titleTxt.text length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)  message:NSLocalizedString(@"A recipe title is required.", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:Nil, nil];
        [alert show];
    }
    else
    {
        NSMutableDictionary *json = [NSMutableDictionary new];
        
        [json setObject:self.titleTxt.text forKey:@"title"];
        [json setObject:[NSNumber numberWithBool: _user_recipe_switch.isOn] forKey:@"isPublic"];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        if([_cookingtimeTxt.text length] != 0) [json setObject:[f numberFromString:_cookingtimeTxt.text] forKey:@"cookTime"];
        if([_descTxt.text length] != 0) [json setObject:_descTxt.text forKey:@"description"];
        if([_instructionTxt.text length] != 0) [json setObject:_instructionTxt.text forKey:@"instructions"];
        if([_ingredientsTxt.text length] != 0) [json setObject:_ingredientsTxt.text forKey:@"ingredients"];
        if([_adviceTxt.text length] != 0) [json setObject:_adviceTxt.text forKey:@"advice"];
        if([_yourNotesTxt.text length] != 0) [json setObject:_yourNotesTxt.text forKey:@"notes"];
        if([_yieldTxt.text length] != 0) [json setObject:[f numberFromString:_yieldTxt.text] forKey:@"portions"];
        if([_portionsTxt.text length] != 0) [json setObject:_portionsTxt.text forKey:@"portionType"];
        if([_sourceTxt.text length] != 0) [json setObject:_sourceTxt.text forKey:@"source"];
        
        NSString *imageString = nil;
        if(userSetRecipeImage){
            imageString = [self encodeToBase64String:_recipeImg.image];
        }
        if(imageString) [json setObject:imageString forKey:@"image"];
        NSMutableArray *tagsArray = nil;
        if(_tagsTxt.text && ![_tagsTxt.text isEqualToString:@""]) {
            tagsArray = [NSMutableArray arrayWithArray:[_tagsTxt.text componentsSeparatedByString:@","]];
            [tagsArray enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
                [tagsArray replaceObjectAtIndex:idx withObject:[object stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            }];
        }
        if(tagsArray) [json setObject:tagsArray forKey:@"tags"];
        
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Please Wait",nil)] maskType:SVProgressHUDMaskTypeClear];
        MatlistanHTTPClient *client = [MatlistanHTTPClient sharedMatlistanHTTPClient];

        
        if(![self.screenName isEqualToString:@"Edit"])
        {
            [client POST:@"RecipeBox" parameters:json
                 success:
             ^(NSURLSessionDataTask *task, id responseObject){
                 (theAppDelegate).isNewRecipeAdded = YES;
                 [Recipebox createObjectWithResponseForInsert:responseObject];
                 DLog(@"Recipe saved successfully");
                 
                 __unsafe_unretained typeof(self) weakSelf = self;
                 
                 Recipebox *recipe = [Recipebox getRecipeById: responseObject[@"id"]];
                 NSString *newUrl = [Utility getCorrectURLFromJson: recipe.imageUrl];
                 
                 NSURL *url =[NSURL URLWithString:newUrl];
                 NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                 UIImage *temp_img=self.recipeImg.image;
                 [self.recipeImg setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                     NSString *fileName = [NSString stringWithFormat:@"%@.png",recipe.recipeboxID];
                     [Utility saveImage:[Utility imageWithImage:temp_img scaledToMaxWidth:150 maxHeight:150] withFileName:fileName];
                     [Recipebox fillImageFileName:fileName forId:recipe.recipeboxID];
                     recipe.imageFileName = fileName;
                     [weakSelf.navigationController popViewControllerAnimated:YES];
                     [SVProgressHUD dismiss];
                 } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                     DLog(@"Can't download recipe image from %@", newUrl);
                     [weakSelf.navigationController popViewControllerAnimated:YES];
                     [SVProgressHUD dismiss];
                 }];

             }
                 failure:
             ^(NSURLSessionDataTask *task, NSError *error){
                 [SVProgressHUD dismiss];
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)  message:NSLocalizedString(@"recipe_error", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:Nil, nil];
                 [alert show];
             }];
        }
        else {
            [client PUT:[NSString stringWithFormat:@"RecipeBox/%@", self.editRecipe.recipeboxID] parameters:json
                 success:
             ^(NSURLSessionDataTask *task, id responseObject){
                 (theAppDelegate).isNewRecipeAdded = YES;
                 [Recipebox updateObjectWithJson:responseObject];
                 DLog(@"Recipe saved successfully");
                 
                 __unsafe_unretained typeof(self) weakSelf = self;
                 
                 Recipebox *recipe = [Recipebox getRecipeById: responseObject[@"id"]];
                 NSString *newUrl = [Utility getCorrectURLFromJson: recipe.imageUrl];
                 
                 NSURL *url =[NSURL URLWithString:newUrl];
                 NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                 UIImage *temp_img=self.recipeImg.image;
                 [self.recipeImg setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                     NSString *fileName = [NSString stringWithFormat:@"%@.png",recipe.recipeboxID];
                     [Utility saveImage:[Utility imageWithImage:temp_img scaledToMaxWidth:150 maxHeight:150] withFileName:fileName];
                     [Recipebox fillImageFileName:fileName forId:recipe.recipeboxID];
                     recipe.imageFileName = fileName;
                     [weakSelf.navigationController popViewControllerAnimated:YES];
                     [SVProgressHUD dismiss];
                 } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                     DLog(@"Can't download recipe image from %@", newUrl);
                     [weakSelf.navigationController popViewControllerAnimated:YES];
                     [SVProgressHUD dismiss];
                 }];
                 
             }
                 failure:
             ^(NSURLSessionDataTask *task, NSError *error){
                 [SVProgressHUD dismiss];
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)  message:NSLocalizedString(@"recipe_error", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:Nil, nil];
                 [alert show];
             }];
        }
    }
    [self resignKeyboard:nil];

}

- (void)viewWillDisappear:(BOOL)animated {
//    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [super viewWillDisappear:animated];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"w: %f,h :%f",[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
//    if(is_iphone6==true)
//    {
//        is_iphone6=false;
//        [self AssignRecipeValueToTextfield];
//    }

//    CLS_LOG(@"Showing RecipesViewController");
    //    [[HelpDialogManager sharedHelpDialogManager] presentHelpFor:self];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
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
        self.bannerView.frame=CGRectMake(self.bannerView.frame.origin.x, self.bannerView.frame.origin.y, self.bannerView.frame.size.width, 0);
//        [self.bannerView removeConstraints:self.bannerView.constraints];
//        [self.bannerView removeFromSuperview];
//        [Utility updateConstraint:self.view toView:self.scroll_view withConstant:0];
    }
}
#pragma mark- manage Scroll " y " and content size
-(void)setscollview_Y
{
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.1f];
    if(IS_IPHONE)
    {
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            CGRect frame=self.scroll_view.frame;
            frame.origin.y=self.navigationController.navigationBar.frame.size.height+20;
            NSLog(@"%f",self.bannerView.frame.size.height);
            frame.size.height=self.view.frame.size.height-frame.origin.y-self.bannerView.frame.size.height;
            self.scroll_view.frame=frame;
        }
        else{
            CGRect frame=self.scroll_view.frame;
            if ([UIApplication sharedApplication].isStatusBarHidden)
            {
                frame.origin.y=self.navigationController.navigationBar.frame.size.height;
            }
            else
            {
                frame.origin.y=self.navigationController.navigationBar.frame.size.height+20;
            }
            frame.size.height=self.view.frame.size.height-frame.origin.y-self.bannerView.frame.size.height;
            self.scroll_view.frame=frame;
        }
        
    }
    else
    {
        CGRect frame=self.scroll_view.frame;
        frame.origin.y=self.navigationController.navigationBar.frame.size.height+20;
        frame.size.height=self.view.frame.size.height-frame.origin.y-self.bannerView.frame.size.height;
        self.scroll_view.frame=frame;
    }
    
    NSLog(@"%f",self.navigationController.navigationBar.frame.size.height);
    [UIView commitAnimations];
    [self setScrollViewContentSize];
    
    
}

-(void)setScrollViewContentSize
{
    //    scrollViewOffsetalue=self.scroll_view.contentSize.height;
    // Update the contentSize to include the new text field.
    NSLog(@"%f, %f",[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
    CGFloat height = CGRectGetMaxY(self.yourNotesTxt.frame);
    if(IS_IPHONE)
    {
        if(keyboardFrame.size.height>0)
        {
            self.scroll_view.contentSize = CGSizeMake(screen_width, height+keyboardFrame.size.height-self.bannerView.frame.size.height+20);
        }
        else{
            self.scroll_view.contentSize = CGSizeMake(screen_width, height+50);
        }
    }
    else
    {
        if(IS_IPAD_PRO)
        {
            if(keyboardFrame.size.height>0 && is_next_prevClick)
            {
                self.scroll_view.contentSize = CGSizeMake(screen_width, height+400);
            }
            else
            {
                self.scroll_view.contentSize = CGSizeMake(screen_width, height+180);
            }
            if(keyboardFrame.size.height>0)
            {
                self.scroll_view.contentSize = CGSizeMake(screen_width, height+keyboardFrame.size.height-self.bannerView.frame.size.height+150);
            }
        }
        else
        {
            if(keyboardFrame.size.height>0)
            {
                self.scroll_view.contentSize = CGSizeMake(screen_width, height+keyboardFrame.size.height-self.bannerView.frame.size.height+20);
            }
            else
            {
                self.scroll_view.contentSize = CGSizeMake(screen_width, height+180);
            }
        }
    }
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
- (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImageJPEGRepresentation(image, 1) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (UIImage *)croppIngimageByImageName:(UIImage *)imageToCrop toRect:(CGRect)rect
{
    //CGRect CropRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height+15);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropped;
}
-(void)didUpdateItems
{
    NSLog(@"save sync finished called");
    if((theAppDelegate).isNewRecipeAdded)
    {
        __unsafe_unretained typeof(self) weakSelf = self;

        Recipebox *recipe = [Recipebox getRecipeById:recipe_id];
        NSString *newUrl = [Utility getCorrectURLFromJson: recipe.imageUrl];
       
        NSURL *url =[NSURL URLWithString:newUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        UIImage *temp_img=self.recipeImg.image;
        [self.recipeImg setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                NSString *fileName = [NSString stringWithFormat:@"%@.png",recipe.recipeboxID];
                [Utility saveImage:[Utility imageWithImage:temp_img scaledToMaxWidth:150 maxHeight:150] withFileName:fileName];
                
                [Recipebox fillImageFileName:fileName forId:recipe.recipeboxID];
                recipe.imageFileName = fileName;
            [weakSelf.navigationController popViewControllerAnimated:YES];
            [SVProgressHUD dismiss];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            DLog(@"Can't download recipe image from %@", newUrl);
            [weakSelf.navigationController popViewControllerAnimated:YES];
            [SVProgressHUD dismiss];


        }];
           }
    
    
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField.tag==5 || textField.tag==7)
    {
        NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
        [nf setNumberStyle:NSNumberFormatterNoStyle];
        
        NSString * newString = [NSString stringWithFormat:@"%@%@",textField.text,string];
        NSNumber * number = [nf numberFromString:newString];
        temp_tag=(int)textField.tag;
        if (!number)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"Input must be numeric", nil)
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        return YES;
    }
    return YES;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        if(temp_tag==5)
        {
            self.yieldTxt.text=nil;
        }
        else if(temp_tag==7)
        {
            self.cookingtimeTxt.text=nil;
        }
    }
    
}


@end
