//
//  AfterCookViewController.m
//  MatListan
//
//  Created by Yan Zhang on 23/11/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "AfterCookViewController.h"
#import "DataStore.h"
#import "Active_recipe+Extra.h"
#import "MatlistanHTTPClient.h"

#import "RootViewController.h"
#import "NavigationControllerViewController.h"
#import "AppDelegate.h"
#import "SyncManager.h"

@interface AfterCookViewController ()
{
    int rating;
    UIImage *image;
}
@end

@implementation AfterCookViewController
@synthesize buttonStart1,buttonStart2,buttonStart3,buttonStart4,buttonStart5,labelTitle, recipe;

- (void)viewDidLoad {
    [super viewDidLoad];
    movementduration=0.3f;
    [self keyboardGeneration];
    self.textfieldTime.delegate = self;
    
    labelTitle.text = [NSString stringWithFormat:@"Tillagad: %@", recipe.title];
    rating = [recipe.rating intValue];
   // self.textfieldTime.text = [NSString stringWithFormat:@"%@",recipe.cookTime];
    
    //Raj-6-1-2015
    if(recipe.cookTime==nil)
    {
        self.textfieldTime.text = [NSString stringWithFormat:@"%@",@"0"];
    }
    else{
        self.textfieldTime.text = [NSString stringWithFormat:@"%@",recipe.cookTime];
    }

    [self setStarsBackgroundTo:rating];
    
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    if (![Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        self.bannerView.adUnitID = @"ca-app-pub-1934765955265302/1247147166";
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
    }
}


//Dimple -9-10-15
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(window.bounds.size);
    
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // IOS-10: get rid of ads /Yousuf 7-10-2015
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAds) name:kPremiumAccountPurchased object:nil];
    
    if ([Utility getDefaultBoolAtKey:@"hasPremium"])
    {
        [self removeAds];
    }
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
        [self.bannerView removeFromSuperview];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI related

- (IBAction)onClickButtonSave:(id)sender {
    //save in core data for recipe
    NSString *timeStr = self.textfieldTime.text;
    int time = [timeStr intValue];
    NSNumber *cookingTime = [NSNumber numberWithInt:time];
    [Recipebox changeCookingTimeWith:cookingTime andRating:[NSNumber numberWithInt:rating] forRecipe:recipe];
    //Remove active recipe
    [Active_recipe setIsCooked:@1 forActiveRecipeId:((Active_recipe *)[Recipebox getActiveRecipeByRecipeId:recipe.recipeboxID]).active_recipeID];
    /*
    Active_recipe *currentActiveRecipe = [Active_recipe getActiveRecipeById:];
    currentActiveRecipe.isCooked = @1;
    if ([currentActiveRecipe.syncStatus intValue] == Synced) {
        currentActiveRecipe.syncStatus = [NSNumber numberWithInt: Updated];
    }
    [[currentActiveRecipe managedObjectContext] MR_saveToPersistentStoreAndWait];
     */
    //change on server if more is to be changed
    if (self.switchChangeMore.on) {
        [self changeMore];
    }
     [[SyncManager sharedManager] forceSync];
    
    //Dimple 9-10-15
    
   // [self dismissViewControllerAnimated:YES completion:nil];
   // [(NavigationControllerViewController *)((RootViewController *)[self presentingViewController]).frontViewController popToRootViewControllerAnimated:YES];
    
    if([self.screen_identifier isEqualToString:@"PlanFoodScreen"] || [self.screen_identifier isEqualToString:@"RecipeScreen"]){
        (theAppDelegate).customImage=image;
        
        [self dismissViewControllerAnimated:NO completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MYLISTREDIRECT" object:nil];
        }];
    }
    else{
        
        [self dismissViewControllerAnimated:YES completion:nil];
        [(NavigationControllerViewController *)((RootViewController *)[self presentingViewController]).frontViewController popToRootViewControllerAnimated:YES];
    }

}

-(void)changeMore{
    NSString *link = [NSString stringWithFormat:@"http://www.matlistan.se/Account/LogOn?ticket=%@&returnUrl=/RecipeBox/Edit/%@",
                      [MatlistanHTTPClient sharedMatlistanHTTPClient].ticket,recipe.recipeboxID];
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:link]];
}

- (IBAction)onClickButtonCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - set star for a recipe

- (IBAction)onClickStar1:(id)sender {
    [self setStarsBackgroundTo:1];
    rating = 1;
}

- (IBAction)onClickStar5:(id)sender {
    [self setStarsBackgroundTo:5];
    rating = 5;
}

- (IBAction)onClickStar2:(id)sender {
    [self setStarsBackgroundTo:2];
    rating = 2;
}

- (IBAction)onClickStar3:(id)sender {
    [self setStarsBackgroundTo:3];
    rating = 3;
}

- (IBAction)onClickStar4:(id)sender {
    [self setStarsBackgroundTo:4];
    rating = 4;
}

-(void)setStarsBackgroundTo:(int)index{
    NSArray *stars =@[buttonStart1,buttonStart2,buttonStart3,buttonStart4,buttonStart5];
    for (int i = 0; i < index; i++) {
        [self setStarButtonBackground:stars[i] withState:YES];
    }
    for (int j = index; j < 5; j++) {
        [self setStarButtonBackground:stars[j] withState:NO];
    }
}

-(void)setStarButtonBackground:(UIButton*)favButton withState:(BOOL)isFavorite{
    if (isFavorite) {
        [favButton setBackgroundImage:[UIImage imageNamed:@"starFilled"] forState:UIControlStateNormal];
    }
    else{
        [favButton setBackgroundImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
    }
}

#pragma mark - text input

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
   /* if ([string isEqualToString:@"("]||[string isEqualToString:@")"]) {
        [self showInputError];
        return TRUE;
    }
    
    if (range.location == 0 && range.length == 0) {
        if ([string isEqualToString:@"+"]) {
            [self showInputError];
            return TRUE;
        }
    }
    if (![self isNumeric:string]) {
        [self showInputError];
    }
     return [self isNumeric:string];
    */
    
    
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterNoStyle];
    
    NSString * newString = [NSString stringWithFormat:@"%@%@",textField.text,string];
    NSNumber * number = [nf numberFromString:newString];
    
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

-(void)showInputError{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Text" message:@"Input måste vara siffror" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    self.textfieldTime.text = @"";
    [alertView show];
}

-(BOOL)isNumeric:(NSString*)inputString{
    BOOL isValid = NO;
    NSCharacterSet *alphaNumbersSet = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *stringSet = [NSCharacterSet characterSetWithCharactersInString:inputString];
    isValid = [alphaNumbersSet isSupersetOfSet:stringSet];
    return isValid;
}

#pragma mark - HideKeyboard

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self.textfieldTime resignFirstResponder];
}
#pragma mark- GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [view setAlpha:1];
    [UIView commitAnimations];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [view setAlpha:0];
    [UIView commitAnimations];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        self.textfieldTime.text=nil;
    }
    
}
#pragma mark -Keyboard Managemnet
-(IBAction)keyboardGeneration
{
    if(self.tbKeyboard==nil)
    {
        self.tbKeyboard=[[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 38.0f)];
        self.tbKeyboard.barStyle=UIBarStyleBlack;
        
        
        UIBarButtonItem *spaceBarItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *doneBarItem=[[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(resignKeyboard:)];
        [doneBarItem setTintColor:[UIColor whiteColor]];
        [self.tbKeyboard setItems:[NSArray arrayWithObjects:spaceBarItem,doneBarItem, nil]];
        [self.textfieldTime setInputAccessoryView:self.tbKeyboard];
    }
}
-(IBAction)resignKeyboard:(id)sender
{
    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationDuration:movementduration];
    [self.textfieldTime resignFirstResponder];
    [UIView commitAnimations];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CLS_LOG(@"Showing AfterCookViewController");
}

@end
