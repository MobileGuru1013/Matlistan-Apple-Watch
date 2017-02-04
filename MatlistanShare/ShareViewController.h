//
//  ShareViewController.h
//  Matlistan
//
//  Created by Artem Bakanov on 12/14/15.
//  Copyright © 2015 Consumiq AB. All rights reserved.
//

#import <Social/Social.h>

@interface ShareViewController : SLComposeViewController

@property IBOutlet UILabel *messageLabel;
@property IBOutlet UIActivityIndicatorView *activityIndicator;
@property IBOutlet UIView *shareView;
@property IBOutlet UIImageView *statusImage;

- (void) didLogin: (BOOL) success;
- (void) didUploadRecipe: (BOOL) success withMessage:(NSString *) message;
- (void) didUploadRecipe: (BOOL) success;

@end
