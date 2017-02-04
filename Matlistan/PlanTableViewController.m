//
//  PlanTableViewController.m
//  MatListan
//
//  Created by Yan Zhang on 04/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "PlanTableViewController.h"
#import "DataStore.h"
#import "Communicator.h"
#import "Utility.h"
#import "RecipeCellView.h"
//#import "RecipeData.h"
#import "UserRecipe.h"
//#import "ActiveRecipe.h"
//#import "ActiveRecipeBox.h"
#import "Active_recipe+Extra.h"
#import "Recipebox+Extra.h"

#import "RecipeDetailTableViewController.h"
@interface PlanTableViewController ()
{
    int currentIndex;
    NSMutableArray *activeRecipes;
    Active_recipe *selectedActiveRecipe;
}
@end

@implementation PlanTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    activeRecipes = [NSMutableArray arrayWithArray:[Active_recipe getAllActiveRecipesExceptDeleted]];
}



- (IBAction)showMenu
{
    [self.frostedViewController presentMenuViewController];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    DLog(@"Total planned recipes: %d",activeRecipes.count);
    return activeRecipes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    Active_recipe *recipe = [activeRecipes objectAtIndex:indexPath.row];
    
    Recipebox *recipeBox = [Recipebox getRecipeById:recipe.recipeID];
    
    NSString *title = recipeBox.title;
    NSString *portionStr = [recipe.portions stringValue];

    
    RecipeCellView *cellView = (RecipeCellView *)[cell viewWithTag:1];
    cellView.titleLabel.text = title;
    cellView.button.backgroundColor = [UIColor clearColor];
    [cellView.manButton setTitle:portionStr forState:UIControlStateNormal];
    
    NSString *newUrl = [Utility getCorrectURLFromJson: recipeBox.imageUrl];
    cellView.imageView.contentMode = UIViewContentModeScaleAspectFill;
    cellView.imageView.clipsToBounds = YES;
    [cellView.imageView setImageWithURL:[NSURL URLWithString:newUrl]];
    
    return cell;
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 117.0;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    selectedActiveRecipe = [activeRecipes objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"toDetail" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    RecipeDetailTableViewController *detailView =  (RecipeDetailTableViewController *)segue.destinationViewController;

    detailView.recipeboxId = selectedActiveRecipe.recipeID;


}

@end
