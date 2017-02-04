//
//  HelpDialogManager.m
//  Matlistan
//
//  Created by Artem Bakanov on 12/22/15.
//  Copyright © 2015 Consumiq AB. All rights reserved.
//

#import "HelpDialogManager.h"

@implementation HelpDialogManager

+(HelpDialogManager *)sharedHelpDialogManager{
    static HelpDialogManager *_sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [self new];
    });
    return _sharedManager;
}

- (void) presentHelpFor: (UIViewController *) viewController {
    if([viewController respondsToSelector:@selector(helpDialogDismissed)]){
            _delegate = (id<HelpDialogManagerDelegate>)viewController;
    }
    else {
        _delegate = nil;
    }
    [self presentHelpFor:viewController force: NO];
}

- (void) presentHelpFor: (UIViewController *) viewController force: (BOOL) force {
    NSString *classNameString = NSStringFromClass([viewController class]);
    [self presentHelpFor:viewController byName:classNameString force:force];

}

- (void) presentHelpFor: (UIViewController *) viewController byName: (NSString *) name force: (BOOL) force{
    NSMutableDictionary *presentedHelpsMap = [NSMutableDictionary dictionaryWithDictionary:[Utility getObjectFromDefaults:@"presentedHelpsMap"]];
    if(force || !presentedHelpsMap || !presentedHelpsMap[name] || ![presentedHelpsMap[name] boolValue]) {
        NSString *htmlFile = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Help_%@", name] ofType:@"html"];
        if(htmlFile) {
            UIWebView *wv = [[UIWebView alloc] initWithFrame:CGRectMake(0, -10, [UIScreen mainScreen].bounds.size.width - 30, 1)];
            wv.delegate = self;
            NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
            [wv loadHTMLString:htmlString baseURL:nil];
            [viewController.view addSubview:wv];
            
            [presentedHelpsMap setObject:[NSNumber numberWithBool:YES] forKey:name];
            [Utility saveInDefaultsWithObject:presentedHelpsMap andKey:@"presentedHelpsMap"];
        }
        else {
            DLog(@"WARNING: No help file found. Please, add file with Help_%@.html name", name);
        }
    }
    else {
        [self customIOS7dialogButtonTouchUpInside:nil clickedButtonAtIndex:0];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
    [webView removeFromSuperview];
    
    CGSize size = [webView sizeThatFits: CGSizeMake(1.0f, 1.0f)]; // Pass about any size
    CGRect frame = webView.frame;
    if(size.height > [UIScreen mainScreen].bounds.size.height - 100) {
        frame.size.height = [UIScreen mainScreen].bounds.size.height - 100;
        [webView setUserInteractionEnabled:YES];
    }
    else {
        frame.size.height = size.height;
        [webView setUserInteractionEnabled:NO];
    }
    
    frame.origin.y = 0;
    [webView setBackgroundColor:[UIColor clearColor]];
    [webView setOpaque:NO];
    webView.frame = frame;
    
    _alertView = [CustomIOSAlertView new];
    [_alertView setContainerView:webView];
    _alertView.delegate = self;
    [_alertView show];

}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    DLog(@"start");
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DLog(@"Error for WEBVIEW: %@", [error description]);
}
- (void)customIOS7dialogButtonTouchUpInside:(id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [_alertView close];
    [_delegate helpDialogDismissed];
}

@end
