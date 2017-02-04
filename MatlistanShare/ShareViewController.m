//
//  ShareViewController.m
//  Matlistan
//
//  Created by Artem Bakanov on 12/14/15.
//  Copyright © 2015 Consumiq AB. All rights reserved.
//

#import "ShareViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "MatlistanShareSessionManager.h"

#define GROUP_BUNDLE_ID @"group.com.consumiq.matlistan.test"
//#define GROUP_BUNDLE_ID @"group.com.consumiq.matlistan.testmtpl"


@interface ShareViewController ()

@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _shareView.layer.cornerRadius = 5;
    _shareView.layer.masksToBounds = YES;
    _statusImage.hidden = YES;
}

- (void) didLogin: (BOOL) success {
    if (success) {
        _messageLabel.text = NSLocalizedString(@"uploading_recipe", nil);
        NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
        NSItemProvider *itemProvider = item.attachments.firstObject;
        if ([itemProvider hasItemConformingToTypeIdentifier:@"public.url"]) {
            [itemProvider loadItemForTypeIdentifier:@"public.url"
                                            options:nil
                                  completionHandler:^(NSURL *url, NSError *error) {
                                      [[MatlistanShareSessionManager sharedManager] sendRecipeURL:[NSString stringWithFormat:@"%@", url]];
                                  }];
        }
        else {
            [self didUploadRecipe:NO withMessage:NSLocalizedString(@"web_page_error", nil)];
        }
    }
    else {
        [self didUploadRecipe:NO withMessage:NSLocalizedString(@"login_error", nil)];
    }

}
- (void) didUploadRecipe: (BOOL) success {
    if (success) {
        [self didUploadRecipe:success withMessage:NSLocalizedString(@"recipe_uploaded", nil)];
    }
    else {
        [self didUploadRecipe:success withMessage:@"Something gone wrong."];
    }

}
- (void) didUploadRecipe: (BOOL) success withMessage:(NSString *) message{
    _activityIndicator.hidden = YES;
    _messageLabel.text = message;
    _statusImage.hidden = NO;
    if (success) {
        [_statusImage setImage:[UIImage imageNamed: @"greenTick.png"]];
    }
    else {
        [_statusImage setImage:[UIImage imageNamed: @"redCross.png"]];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.shareView.transform = CGAffineTransformMakeTranslation(0, self.shareView.frame.size.height);
    [UIView animateWithDuration:0.25 animations:^{
        self.shareView.transform = CGAffineTransformIdentity;
    }];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if([[[[NSUserDefaults alloc] initWithSuiteName:GROUP_BUNDLE_ID] objectForKey:@"authorized"] boolValue]) {
        
        _messageLabel.text = NSLocalizedString(@"logging_in", nil);
        [MatlistanShareSessionManager sharedManager].shareViewDelegate = self;
        [[MatlistanShareSessionManager sharedManager] login];
        
    }
    else {
        _messageLabel.text = NSLocalizedString(@"not_authorized", nil);
        _statusImage.hidden = NO;
        [_statusImage setImage:[UIImage imageNamed: @"redCross.png"]];
        _activityIndicator.hidden = YES;
    }

}

- (IBAction)dismiss
{
    [UIView animateWithDuration:0.20 animations:^{
        self.shareView.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height);
    } completion:^(BOOL finished) {
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }];
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

@end
