//
//  HelpDialogManager.h
//  Matlistan
//
//  Created by Artem Bakanov on 12/22/15.
//  Copyright © 2015 Consumiq AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomIOSAlertView.h"

@protocol HelpDialogManagerDelegate

- (void)helpDialogDismissed;

@end

@interface HelpDialogManager : NSObject <UIWebViewDelegate, CustomIOSAlertViewDelegate>

@property CustomIOSAlertView *alertView;
@property id<HelpDialogManagerDelegate> delegate;

+(HelpDialogManager *)sharedHelpDialogManager;
- (void) presentHelpFor: (UIViewController *) viewController;
- (void) presentHelpFor: (UIViewController *) viewController force: (BOOL) force;
- (void) presentHelpFor: (UIViewController *) viewController byName: (NSString *) name force: (BOOL) force;

@end
