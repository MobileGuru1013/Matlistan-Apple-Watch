//
//  Version_VC.m
//  Matlistan
//
//  Created by Leocan1 on 11/29/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "Version_VC.h"
#import "UIViewController+MJPopupViewController.h"

static NSString *htmlStyle = @"<font face='Helvetica' size='3'>";

@interface Version_VC ()
{
  bool advanceToEOVS ;
    NSString *listMode;
    NSString *version_str;
    NSString *final;
    BOOL returnedFullLog ;
    BOOL returnedAnyLog ;

}
@end

@implementation Version_VC

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        final=[self load_content];
        _hasContent = (final != nil);
       
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
   
    NSString *final_str=[NSString stringWithFormat:@"<!DOCTYPE html><html><body>%@%@</body></html>",htmlStyle,final];

    [_version_web loadHTMLString:final_str baseURL:Nil];
    _version_web.scrollView.scrollEnabled = YES;
    _version_web.delegate = self;

}

-(NSString *)load_content
{
    
    advanceToEOVS=false;
   
    // get a reference to our file
    NSString *myPath = [[NSBundle mainBundle]pathForResource:@"changelog" ofType:@"txt" inDirectory:nil];
    
    // read the contents into a string
    NSString *myFile = [[NSString alloc]initWithContentsOfFile:myPath encoding:NSUTF8StringEncoding error:nil];
    
    // first, separate by new line
    NSArray* allLinedStrings =[myFile componentsSeparatedByCharactersInSet:
                               [NSCharacterSet newlineCharacterSet]];

    
  version_str=@"";

    DLog(@"%@", allLinedStrings);
    BOOL lastVersionRecorded = NO;
    BOOL hasVersion = NO;
    NSString *lastShownVersion = (NSString *)[Utility getObjectFromDefaults:@"lastShownVersion"];
    for (NSString *line in allLinedStrings)
    {
        if (line.length && ![line isEqual: @""] && ![line isEqualToString:@"$ END_OF_CHANGE_LOG"]) {
            
            char first_char;
            if([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]>0)
            {
            first_char=[[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]  characterAtIndex:0];
            }
       
                if(first_char == '$')
                {
                    NSString *version = [[[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    
                                         DLog(@"!%@!,!%@!", version, lastShownVersion);
                    
                    if([version isEqualToString:lastShownVersion]) {
                        version_str=[NSString stringWithFormat:@"%@</body></html>",version_str];
                        break;
                    }
                    else {
                        hasVersion = YES;
                    }
                    if(!lastVersionRecorded) {
                        [Utility saveInDefaultsWithObject:version andKey:@"lastShownVersion"];
                        lastVersionRecorded = YES;
                    }
                    
                }
                else
                {
                    switch (first_char) {
                        case '%':
                            version_str= [NSString stringWithFormat:@"%@<div class=\"title\"><h3>%@</h3></div>",version_str,[[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] substringFromIndex:1]];
                            break;
                        case '_':
                            version_str=[NSString stringWithFormat:@"%@<div class='subtitle'><h5>%@</h5></div>",version_str,[[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] substringFromIndex:1]];

                            break;

                        case '!':
                            version_str =[NSString stringWithFormat:@"%@<div class='freetext'>%@\n</div>\n",version_str,[[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] substringFromIndex:1]];

                            break;

                        case '#':
                             version_str =[NSString stringWithFormat:@"%@<div class='list'><ol><li>%@</li></ol></div>",version_str,[[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] substringFromIndex:1]];
                            break;

                        case '*':
                            version_str=[NSString stringWithFormat:@"%@<div class='list'><ul><li>%@</li></ul></<div>",version_str,[[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] substringFromIndex:1]];
                            
                            break;
                        default:
                            version_str =[NSString stringWithFormat:@"%@%@",version_str, line];

                            break;

                    }
            }
        }
    }

    DLog(@"%@", version_str);
    if(hasVersion) {
        return version_str;
    }
    else {
        return nil;
    }
}


-(IBAction)yesBtn:(id)sender
{
 [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMJPopUp" object:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
