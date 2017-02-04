//
//  RecipeCellView.m
//  MatListan
//
//  Created by Yan Zhang on 13/05/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "RecipeCellView.h"

@implementation RecipeCellView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        [self setupConstraints];
    }
    return self;
}
-(UIImageView*)imageView{
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc]init];
        [_imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        _imageView.backgroundColor = [UIColor clearColor];
        //_imageView.frame = CGRectMake(0, 0, 320.0, 100.0);
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageView;
}
-(UILabel*)titleLabel{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]init];
        [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        //_titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.45];
        _titleLabel.textAlignment = NSTextAlignmentLeft; //NSTextAlignmentCenter;
        _titleLabel.font = [UIFont fontWithName:@"ArialMT" size:15.0];
        _titleLabel.textColor = [UIColor blackColor]; //[UIColor whiteColor];

        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}
-(UIButton*)button{
    if (_button == Nil) {
        _button = [[UIButton alloc]init];
        [_button setTranslatesAutoresizingMaskIntoConstraints:NO];
        UIImage *icon =[UIImage imageNamed:@"thickMenu"];
        
        [_button setImage:icon forState:UIControlStateNormal];
        
      //  [button setTitle:[@"xx" forState:UIControlStateNormal];
        // used UIControlEventTouchUpInside to fix issue # 238 /Yousuf
        [_button addTarget:self  action:@selector(onClickButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button;
}
-(UIButton*)manButton{
    if (_manButton == Nil) {
        _manButton = [[UIButton alloc]init];
        [_manButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        UIImage *icon =[UIImage imageNamed:@"man"];
        [_manButton setImage:icon forState:UIControlStateNormal];
        _manButton.titleLabel.font = [UIFont fontWithName:@"AppleGothic-Bold" size:17.0];

        [_manButton setTitleColor:[Utility getGreenColor] forState:UIControlStateNormal];
    }
    return _manButton;
}

-(void)onClickButton:(id)sender{
    DLog(@"button clicked");
}
- (void)setupConstraints {
    [self addSubview:self.imageView];
    [self addSubview:self.titleLabel];
 //   [self addSubview:self.button];
 //   [self addSubview:self.manButton];

    NSDictionary *views = NSDictionaryOfVariableBindings(_imageView,_titleLabel,_button,_manButton);
    
    NSDictionary *metrics = @{@"labelPadding":@20.0,@"margin":@5.0};
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[_imageView(100)]-[_titleLabel(<=180)]-labelPadding-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[_imageView]-margin-|" options:0 metrics:metrics views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-labelPadding-[_titleLabel]-labelPadding-|" options:0 metrics:metrics views:views]];
    //Broad image version
   /* [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_imageView]|" options:0 metrics:metrics views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_imageView]-0-|" options:0 metrics:metrics views:views]];
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_titleLabel(320)]|" options:0 metrics:metrics views:views]];
     [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_imageView]-(-30.0)-[_titleLabel]|" options:0 metrics:metrics views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(<=8.0)-[_button(40)]|" options:0 metrics:metrics views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(<=58.0)-[_manButton(40)]|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=200.0)-[_button(40)]-12.0-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=200.0)-[_manButton]-5.0-|" options:0 metrics:metrics views:views]];
    */
    
}
- (void)updateConstraints {
    
    if (self.didSetupConstraints == NO){
        [self setupConstraints];
        // DLog(@"set up constraints");
        self.didSetupConstraints = YES;
    }
    [super updateConstraints];
    
}
@end
