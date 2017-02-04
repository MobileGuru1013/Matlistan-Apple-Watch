//
//  RecipeTimer.h
//  Matlistan
//
//  Created by Monulal on 3/3/16.
//  Copyright (c) 2016 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RecipeTimer;
@protocol RecipeDelegate <NSObject>
@optional
- (void)timerChangedInRecipe:(RecipeTimer *)recipe;

- (void)resetTimerForRecipe:(RecipeTimer *)recipe;
- (NSInteger)totalTimerForReciper;
@end

@protocol RecipeListDelegate <NSObject>
@optional
- (void)timerFinishForRecipe:(RecipeTimer *)recipe;
@end


@interface RecipeTimer : NSObject
@property (nonatomic, assign) NSInteger recipeboxId; //to map the list of recipe
@property (nonatomic, assign) NSInteger recipeTimerId; //to map the timer table recipe
@property (nonatomic, strong) NSString *recipeName;
@property (nonatomic, strong) NSString *recipeDesc;

@property (nonatomic, strong) NSString *countTimer;

@property (nonatomic, assign) NSTimeInterval secondsLeft;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, assign) NSTimeInterval tempSecondsLeft;

@property (nonatomic, strong) NSDate *startDate;

@property (nonatomic, assign) int hours;
@property (nonatomic, assign) int minutes;
@property (nonatomic, assign) int seconds;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) id<RecipeDelegate>recipeTimerdelegate; //this is for handling timer, called in recipe detail controller
@property (nonatomic, assign) id<RecipeListDelegate>recipeListDelegate; //delegate method called in recipe list controller

//- (id)initWithRecipieId:(NSInteger)recipeId recipeName:(NSString *)name;
- (id)initWithRecipieId:(NSInteger)recipeId recipeName:(NSString *)name withRecipeDesc:(NSString *)recipeDes;
- (void )currentTimerString;
- (void)startTimer;
- (void)stopTimer;
@end
