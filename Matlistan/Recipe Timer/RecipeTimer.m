//
//  RecipeTimer.m
//  Matlistan
//
//  Created by Monulal on 3/3/16.
//  Copyright (c) 2016 Flame Soft. All rights reserved.
//

#import "RecipeTimer.h"

@implementation RecipeTimer
- (id)init
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}

- (id)initWithRecipieId:(NSInteger)recipeId recipeName:(NSString *)name
         withRecipeDesc:(NSString *)recipeDes
{
    self = [super init];
    if(self)
    {
        self.recipeboxId = recipeId;
        self.recipeName =  name;
        self.recipeTimerId = 0; //it is zero by default
        self.recipeDesc = recipeDes;
        
    }
    return self;
}
- (void)setRecipeListDelegate:(id<RecipeListDelegate>)recipeListDelegate
{
    if(_recipeListDelegate == nil)
        _recipeListDelegate = recipeListDelegate;
}

- (void)currentTimerString
{
    self.secondsLeft -- ;
    if(self.secondsLeft > 0 )
    {
        _hours = (int)self.secondsLeft / 3600;
        _minutes = ((int)self.secondsLeft % 3600) / 60;
        _seconds = ((int)self.secondsLeft %3600) % 60;
        self.countTimer = [NSString stringWithFormat:@"%02d:%02d:%02d", self.hours, self.minutes, self.seconds];
        NSLog(@"self.countTimer:%@",self.countTimer);
        if([self.recipeTimerdelegate respondsToSelector:@selector(timerChangedInRecipe:)])
            [self.recipeTimerdelegate timerChangedInRecipe:self];//this is one we are using to update the timer table, if we set this to correct recipe detail then timer table wil show time
    }
    else
    {
        _hours = _minutes = _seconds = 0;
        
        [self firedNotificationWhenRecipeTimerSet:self.recipeDesc recipeID:self.recipeboxId];
        self.countTimer = [NSString stringWithFormat:@"%02d:%02d:%02d", self.hours, self.minutes, self.seconds];
        if([self.recipeTimerdelegate respondsToSelector:@selector(timerChangedInRecipe:)])
            [self.recipeTimerdelegate timerChangedInRecipe:self];
        
        [self stopTimer];
//        [[WatchConnectivityController sharedInstance] stopTimerForRecipeID: self.recipeboxId];
        [[WatchConnectivityController sharedInstance] updateTimerForRecipeID:self];
        if([self.recipeListDelegate respondsToSelector:@selector(timerFinishForRecipe:)])
            [self.recipeListDelegate timerFinishForRecipe:self]; //this is at the app delegate, to remove the finished timer
    }
}
-(void)firedNotificationWhenRecipeTimerSet:(NSString*)desc recipeID:(NSInteger)recipeID
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground || [UIApplication sharedApplication].applicationState == UIApplicationStateInactive )
    {

    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSString stringWithFormat:@"%ld",(long)recipeID], @"recipe_id",nil];
    
    //    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:10];
    localNotification.alertBody = [NSString stringWithFormat:@"%@\n%@!!!",desc,NSLocalizedString(@"Done", nil)];
    
    
    //  Same as category identifier
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:localNotification];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:[NSString stringWithFormat:@"uniqueRecipeId_%ld",(long)self.recipeboxId]];
    }
    
}
- (void)startTimer
{
    if(_timer == nil)
    {
        [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];

        _timer =  [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(currentTimerString) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    else
        [_timer fire];

    if (!self.startDate) {
        self.startDate = [NSDate date];
    }

    [[WatchConnectivityController sharedInstance] showTimerOptionInWatch];
}

- (void)stopTimer
{
    if(_timer)
        [self.timer invalidate];
    self.timer = nil;
}

- (void)dealloc
{
    self.recipeListDelegate = nil;
    self.recipeTimerdelegate = nil;
    self.recipeName = nil;
    self.recipeDesc = nil;
    self.countTimer = nil;
    if([self.timer isValid])
        [self.timer invalidate];
    self.timer = nil;
}


@end
