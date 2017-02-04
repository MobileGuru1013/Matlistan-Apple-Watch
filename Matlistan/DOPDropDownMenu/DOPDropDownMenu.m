//
//  DOPDropDownMenu.m
//  DOPDropDownMenuDemo
//
//  Created by weizhou on 9/26/14.
//  Copyright (c) 2014 fengweizhou. All rights reserved.
//

#import "DOPDropDownMenu.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "ItemsViewController.h"

@implementation DOPIndexPath
- (instancetype)initWithColumn:(NSInteger)column row:(NSInteger)row {
    self = [super init];
    if (self) {
        _column = column;
        _row = row;
    }
    return self;
}

+ (instancetype)indexPathWithCol:(NSInteger)col row:(NSInteger)row {
    DOPIndexPath *indexPath = [[self alloc] initWithColumn:col row:row];
    return indexPath;
}
@end

#pragma mark - menu implementation

@interface DOPDropDownMenu ()
@property (nonatomic, assign) NSInteger currentSelectedMenudIndex;
@property (nonatomic, assign) NSInteger numOfMenu;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, strong) UIView *backGroundView;
//data source
@property (nonatomic, copy) NSArray *array;
//layers array
@property (nonatomic, copy) NSArray *titles;
@property (nonatomic, copy) NSArray *indicators;
@property (nonatomic, copy) NSArray *bgLayers;
@property ItemsViewController *itemsView;
@property NSString *textlabel_string;
@property NSInteger label_width;
@property CGFloat fontSize;
@property int numlines;
@property CGFloat cellHeight;

@end


@implementation DOPDropDownMenu

#pragma mark - getter
- (UIColor *)indicatorColor {
    if (!_indicatorColor) {
        _indicatorColor = [UIColor blackColor];
    }
    return _indicatorColor;
}

- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = [UIColor blackColor];
    }
    return _textColor;
}

- (UIColor *)separatorColor {
    if (!_separatorColor) {
        _separatorColor = [UIColor blackColor];
    }
    return _separatorColor;
}

//- (NSDictionary *)titleForRowAtIndexPath:(DOPIndexPath *)indexPath {
//    NSDictionary *dic=[self.dataSource menu:self titleForRowAtIndexPath:indexPath];
//    return dic;
//}

#pragma mark - setter
- (void)setDataSource:(id<DOPDropDownMenuDataSource>)dataSource {
    _dataSource = dataSource;
    
    //configure view
    if ([_dataSource respondsToSelector:@selector(numberOfColumnsInMenu:)]) {
        _numOfMenu = [_dataSource numberOfColumnsInMenu:self];
    } else {
        _numOfMenu = 1;
    }
    
    CGFloat textLayerInterval = self.frame.size.width / ( _numOfMenu * 2);
    CGFloat bgLayerInterval = self.frame.size.width / _numOfMenu;
    
    NSMutableArray *tempTitles = [[NSMutableArray alloc] initWithCapacity:_numOfMenu];
    NSMutableArray *tempIndicators = [[NSMutableArray alloc] initWithCapacity:_numOfMenu];
    NSMutableArray *tempBgLayers = [[NSMutableArray alloc] initWithCapacity:_numOfMenu];
    
    for (int i = 0; i < _numOfMenu; i++) {
        //bgLayer
        CGPoint bgLayerPosition = CGPointMake((i+0.5)*bgLayerInterval, self.frame.size.height/2);
        //[UIColor redColor]
        CALayer *bgLayer = [self createBgLayerWithColor:[Utility getWhiteColor] andPosition:bgLayerPosition];
        [self.layer addSublayer:bgLayer];
        [tempBgLayers addObject:bgLayer];
        //title
        CGPoint titlePosition = CGPointMake( (i * 2 + 1) * textLayerInterval , self.frame.size.height / 2);
        
        NSDictionary *dic = [_dataSource menu:self titleForRowAtIndexPath:[DOPIndexPath indexPathWithCol:i row:0]];
        NSString *titleString=@"";
        if([self.screenname isEqualToString:@"itemsSelection"] || [self.screenname isEqualToString:@"instoremode_more"])
        {
            titleString=[dic objectForKey:@"menuItem"];
        }
        else if([self.screenname isEqualToString:@"items"])
        {
            titleString=[dic objectForKey:@"fav_matchin_item"];
        }
        else if([self.screenname isEqualToString:@"instoremode"])
        {
            titleString=[dic objectForKey:@"name"];
        }
        CATextLayer *title = [self createTextLayerWithNSString:titleString withColor:self.textColor andPosition:titlePosition];
        //        [self.layer addSublayer:title];//display default title
        [tempTitles addObject:title];
        //indicator
        CAShapeLayer *indicator = [self createIndicatorWithColor:self.indicatorColor andPosition:CGPointMake(titlePosition.x + title.bounds.size.width / 2 + 8, self.frame.size.height / 2)];
        //        [self.layer addSublayer:indicator]; // Drop down arrow
        [tempIndicators addObject:indicator];
    }
    _titles = [tempTitles copy];
    _indicators = [tempIndicators copy];
    _bgLayers = [tempBgLayers copy];
    
    if([self.screenname isEqualToString:@"items"])
    {
        if(IS_IPHONE)
        {
            _label_width=160;
        }
        else
        {
            _label_width=265;
        }
    }
    
}

#pragma mark - init method
- (instancetype)initWithOrigin:(CGPoint)origin andX:(CGFloat)x andY:(CGFloat)y andWidth:(CGFloat)width andHeight:(CGFloat)height {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self = [self initWithFrame:CGRectMake(x, y, width, height)];
    //    115- green button width
    //    281- green button x
    //    72  -green button y
    if (self) {
        _origin = origin;
        _currentSelectedMenudIndex = -1;
        _show = NO;
        
        //tableView init
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
        if([self.screenname isEqualToString:@"items"] || [self.screenname isEqualToString:@"itemsSelection"]|| [self.screenname isEqualToString:@"instoremode_more"])
        {
            _tableView.rowHeight = 33;
        }
        else
        {
            if(IS_IPHONE)
            {
                _tableView.rowHeight = 40;
            }
            else
            {
                _tableView.rowHeight = 60;
            }
        }
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle=NO;
        //self tapped
        // self.backgroundColor = [UIColor whiteColor];
        UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuTapped:)];
        [self addGestureRecognizer:tapGesture];
        
        //background init and tapped
        _backGroundView = [[UIView alloc] initWithFrame:CGRectMake(origin.x, origin.y, screenSize.width, screenSize.height)];
        _backGroundView.backgroundColor = [Utility getWhiteColor];
        _backGroundView.opaque = NO;
        UIGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
        [_backGroundView addGestureRecognizer:gesture];
        
        //add bottom shadow
        //        UIView *bottomShadow = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-0.5, screenSize.width, 0.5)];
        //        bottomShadow.backgroundColor = [UIColor lightGrayColor];
        //        [self addSubview:bottomShadow];
        
        
    }
    return self;
}

#pragma mark - init support
- (CALayer *)createBgLayerWithColor:(UIColor *)color andPosition:(CGPoint)position {
    CALayer *layer = [CALayer layer];
    layer.position = position;
    layer.bounds = CGRectMake(0, 0, self.frame.size.width/self.numOfMenu, self.frame.size.height-1);
    layer.backgroundColor = color.CGColor;
    //    NSLog(@"bglayer bounds:%@",NSStringFromCGRect(layer.bounds));
    //    NSLog(@"bglayer position:%@", NSStringFromCGPoint(position));
    
    return layer;
}

- (CAShapeLayer *)createIndicatorWithColor:(UIColor *)color andPosition:(CGPoint)point {
    CAShapeLayer *layer = [CAShapeLayer new];
    
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(8, 0)];
    [path addLineToPoint:CGPointMake(4, 5)];
    [path closePath];
    
    layer.path = path.CGPath;
    layer.lineWidth = 1.0;
    layer.fillColor = color.CGColor;
    
    CGPathRef bound = CGPathCreateCopyByStrokingPath(layer.path, nil, layer.lineWidth, kCGLineCapButt, kCGLineJoinMiter, layer.miterLimit);
    layer.bounds = CGPathGetBoundingBox(bound);
    CGPathRelease(bound);
    
    layer.position = point;
    
    return layer;
}

- (CATextLayer *)createTextLayerWithNSString:(NSString *)string withColor:(UIColor *)color andPosition:(CGPoint)point {
    
    CGSize size = [self calculateTitleSizeWithString:string];
    
    CATextLayer *layer = [CATextLayer new];
    CGFloat sizeWidth = (size.width < (self.frame.size.width / _numOfMenu) - 25) ? size.width : self.frame.size.width / _numOfMenu - 25;
    layer.bounds = CGRectMake(0, 0, sizeWidth, size.height);
    layer.string = string;
    _fontSize=[self setFont];
    layer.fontSize = _fontSize;
    layer.alignmentMode = kCAAlignmentCenter;
    layer.foregroundColor = color.CGColor;
    
    layer.contentsScale = [[UIScreen mainScreen] scale];
    
    layer.position = point;
    
    return layer;
}

- (CGSize)calculateTitleSizeWithString:(NSString *)string
{
    if([self.screenname isEqualToString:@"items"])
    {
        if(IS_IPHONE)
        {
            _label_width=160;
        }
        else
        {
            _label_width=265;
        }
        _fontSize=[self setFont];
        UIFont *font1=[UIFont fontWithName:@"Helvetica" size:_fontSize];
        
        NSAttributedString *attrString =
        [[NSAttributedString alloc] initWithString:string
                                        attributes:@{ NSFontAttributeName:font1}];
        //NSLog(@"%ld",(long)_label_width);
        return [attrString boundingRectWithSize:CGSizeMake(_label_width, 3000)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                        context:nil].size;
    }
    else
    {
        CGFloat fontSize = 14.0;
        NSDictionary *dic = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]};
        CGSize size = [string boundingRectWithSize:CGSizeMake(280, 0) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil].size;
        return size;
    }
}

#pragma mark - gesture handle
- (void)menuTapped:(UITapGestureRecognizer *)paramSender {
    
    //Dimple-30-11-2015
    //tableview Shadow
    if(IS_IPHONE)
    {
        self.tableView.layer.borderWidth=0.5;
    }
    else{
        self.tableView.layer.borderWidth=1;
    }
    self.tableView.layer.borderColor=[UIColor lightGrayColor].CGColor;
    
    //    self.tableView.separatorStyle=NO;
    
    CGPoint touchPoint = [paramSender locationInView:self];
    //calculate index
    
    NSInteger tapIndex = touchPoint.x / (self.frame.size.width / _numOfMenu);
    
    for (int i = 0; i < _numOfMenu; i++) {
        if (i != tapIndex) {
            [self animateIndicator:_indicators[i] Forward:NO complete:^{
                [self animateTitle:_titles[i] show:NO complete:^{
                    
                }];
            }];
            //[UIColor redColor]
            [(CALayer *)self.bgLayers[i] setBackgroundColor:[Utility getWhiteColor].CGColor];
        }
    }
    
    if (tapIndex == _currentSelectedMenudIndex && _show) {
        [self animateIdicator:_indicators[_currentSelectedMenudIndex] background:_backGroundView tableView:_tableView title:_titles[_currentSelectedMenudIndex] forward:NO complecte:^{
            _currentSelectedMenudIndex = tapIndex;
            _show = NO;
        }];
        [(CALayer *)self.bgLayers[tapIndex] setBackgroundColor:[Utility getWhiteColor].CGColor];
    } else {
        _currentSelectedMenudIndex = tapIndex;
        [_tableView reloadData];
        [self animateIdicator:_indicators[tapIndex] background:nil tableView:_tableView title:_titles[tapIndex] forward:YES complecte:^{
            _show = YES;
        }];
        [(CALayer *)self.bgLayers[tapIndex] setBackgroundColor:[Utility getWhiteColor].CGColor];
    }
    
}

- (void)backgroundTapped:(UITapGestureRecognizer *)paramSender
{
    //Dimple-30-11-2015
    
    [self animateIdicator:_indicators[_currentSelectedMenudIndex] background:_backGroundView tableView:_tableView title:_titles[_currentSelectedMenudIndex] forward:NO complecte:^{
        _show = NO;
    }];
    //[(CALayer *)self.bgLayers[_currentSelectedMenudIndex] setBackgroundColor:[UIColor whiteColor].CGColor];
}

#pragma mark - animation method
- (void)animateIndicator:(CAShapeLayer *)indicator Forward:(BOOL)forward complete:(void(^)())complete {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.25];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.4 :0.0 :0.2 :1.0]];
    
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    anim.values = forward ? @[ @0, @(M_PI) ] : @[ @(M_PI), @0 ];
    
    if (!anim.removedOnCompletion) {
        [indicator addAnimation:anim forKey:anim.keyPath];
    } else {
        [indicator addAnimation:anim forKey:anim.keyPath];
        [indicator setValue:anim.values.lastObject forKeyPath:anim.keyPath];
    }
    
    [CATransaction commit];
    
    complete();
}

- (void)animateBackGroundView:(UIView *)view show:(BOOL)show complete:(void(^)())complete {
    if (show) {
        [self.superview addSubview:view];
        [view.superview addSubview:self];
        
        [UIView animateWithDuration:0.2 animations:^{
            view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
        }];
    }
    complete();
}

- (void)animateTableView:(UITableView *)tableView show:(BOOL)show complete:(void(^)())complete {
    
    CGFloat tableViewHeight,tableViewWidth,tableViewx = 0.0,tableViewy;
    int items_x=65;
    if([self.screenname isEqualToString:@"instoremode_more"])
    {
        
        if(IS_IPHONE)
        {
            tableViewWidth=130;
            items_x=30;
        }
        else
        {
            tableViewWidth=175;
            items_x=80;
        }
    }
    else if([self.screenname isEqualToString:@"itemsSelection"])
    {
        tableViewWidth=100;
        items_x=0;
        if(IS_IPHONE)
        {
            tableViewWidth=100;
            items_x=0;
        }
        else
        {
            tableViewWidth=150;
            items_x=50;
        }
    }
    else if([self.screenname isEqualToString:@"items"])
    {
        tableViewWidth=165;
        tableViewx=20,tableViewy=1;
        items_x=65;
        if(IS_IPHONE)
        {
            tableViewWidth=165;
            items_x=65;
        }
        else
        {    tableViewWidth=265;
            items_x=165;
        }
    }
    else
    {
        tableViewWidth=100;
        tableViewx=20,tableViewy=1;
    }
    if (show) {
        if([self.screenname isEqualToString:@"items"] || [self.screenname isEqualToString:@"itemsSelection"] || [self.screenname isEqualToString:@"instoremode_more"])
        {
            tableView.frame = CGRectMake(self.origin.x-items_x, self.frame.origin.y + self.frame.size.height, self.frame.size.width, 0);
        }
        else
        {
            tableView.frame = CGRectMake(tableViewx, self.frame.origin.y + self.frame.size.height+1, SCREEN_WIDTH-40, 0);
        }
        [self.superview addSubview:tableView];
        
        if([self.screenname isEqualToString:@"items"] || [self.screenname isEqualToString:@"itemsSelection"]
           || [self.screenname isEqualToString:@"instoremode_more"])
        {
            tableViewHeight=([tableView numberOfRowsInSection:0]*_cellHeight);
        }
        else
        {
            tableViewHeight=([tableView numberOfRowsInSection:0]*tableView.rowHeight);
        }
        
        //Dimple-30-11-2015
        UIInterfaceOrientation dorientation = [[UIApplication sharedApplication] statusBarOrientation];
        int n;
        if(IS_IPHONE)
        {
            if (dorientation == UIInterfaceOrientationPortrait || dorientation == UIInterfaceOrientationPortraitUpsideDown)
            {
                if([self.screenname isEqualToString:@"items"] || [self.screenname isEqualToString:@"itemsSelection"] ||  [self.screenname isEqualToString:@"instoremode_more"])
                {
                    n=170;
                }
                else
                {
                    n=168;
                }
            }
            else
            {
                n=135;
            }
        }
        else{
            if([self.screenname isEqualToString:@"instoremode_more"])
            {
                n=170;
            }
            else if([self.screenname isEqualToString:@"itemsSelection"])
            {
                n=170;
            }
            else if([self.screenname isEqualToString:@"items"])
            {
                n=200;
            }
            else
            {
                n=198;
            }
        }
        
        if(tableViewHeight>SCREEN_HEIGHT-n)
        {
            //NSLog(@"tableHeight %f %f",tableViewHeight,SCREEN_HEIGHT-n);
            tableViewHeight=SCREEN_HEIGHT-n;
            self.tableView.scrollEnabled=YES;
        }
        else{
            self.tableView.scrollEnabled=NO;
            
        }
        
        if(!(theAppDelegate).no_fav_item_flag)
        {
            _tableView.frame = CGRectMake(self.origin.x-145, self.frame.origin.y + self.frame.size.height, 242, 0);
        }
        else{
            if([self.screenname isEqualToString:@"items"] || [self.screenname isEqualToString:@"itemsSelection"]|| [self.screenname isEqualToString:@"instoremode_more"])
            {
                _tableView.frame = CGRectMake(self.origin.x-items_x, self.frame.origin.y + self.frame.size.height, tableViewWidth, 0);
            }
            else
            {
                _tableView.frame = CGRectMake(tableViewx, self.frame.origin.y + self.frame.size.height-1, SCREEN_WIDTH-40, 0);
            }
            
        }
        
        [UIView animateWithDuration:0.2 animations:^{
            if(!(theAppDelegate).no_fav_item_flag)
            {
                _tableView.frame = CGRectMake(self.origin.x-145, self.frame.origin.y + self.frame.size.height, 242, tableViewHeight);
            }
            else{
                if([self.screenname isEqualToString:@"items"] || [self.screenname isEqualToString:@"itemsSelection"]|| [self.screenname isEqualToString:@"instoremode_more"])
                {
                    _tableView.frame = CGRectMake(self.origin.x-items_x, self.frame.origin.y + self.frame.size.height, tableViewWidth, tableViewHeight);
                }
                else
                {
                    _tableView.frame = CGRectMake(tableViewx, self.frame.origin.y + self.frame.size.height-1, SCREEN_WIDTH-40, tableViewHeight);
                }
            }
            
        }];
    } else {
        
        [UIView animateWithDuration:0.2 animations:^{
            
            if(!(theAppDelegate).no_fav_item_flag)
            {
                _tableView.frame = CGRectMake(self.origin.x-145, self.frame.origin.y + self.frame.size.height, 242, 0);
            }
            else{
                if([self.screenname isEqualToString:@"items"] || [self.screenname isEqualToString:@"itemsSelection"]|| [self.screenname isEqualToString:@"instoremode_more"]){
                    _tableView.frame = CGRectMake(self.origin.x-items_x, self.frame.origin.y + self.frame.size.height, tableViewWidth, 0);
                }
                else
                {
                    _tableView.frame = CGRectMake(tableViewx, self.frame.origin.y + self.frame.size.height-1, SCREEN_WIDTH-40 , 0);
                }
                
            }
        } completion:^(BOOL finished) {
            
            [tableView removeFromSuperview];
        }];
    }
    complete();
}
- (void)animateTitle:(CATextLayer *)title show:(BOOL)show complete:(void(^)())complete {
    CGSize size = [self calculateTitleSizeWithString:title.string];
    CGFloat sizeWidth = (size.width < (self.frame.size.width / _numOfMenu) - 25) ? size.width : self.frame.size.width / _numOfMenu - 25;
    title.bounds = CGRectMake(0, 0, sizeWidth, size.height);
    complete();
}

- (void)animateIdicator:(CAShapeLayer *)indicator background:(UIView *)background tableView:(UITableView *)tableView title:(CATextLayer *)title forward:(BOOL)forward complecte:(void(^)())complete{
    
    [self animateIndicator:indicator Forward:forward complete:^{
        [self animateTitle:title show:forward complete:^{
            [self animateBackGroundView:background show:forward complete:^{
                [self animateTableView:tableView show:forward complete:^{
                }];
            }];
        }];
    }];
    
    complete();
}

#pragma mark - table datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSAssert(self.dataSource != nil, @"menu's dataSource shouldn't be nil");
    if ([self.dataSource respondsToSelector:@selector(menu:numberOfRowsInColumn:)]) {
        return [self.dataSource menu:self
                numberOfRowsInColumn:self.currentSelectedMenudIndex];
    } else {
        NSAssert(0 == 1, @"required method of dataSource protocol should be implemented");
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"DropDownMenuCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NSAssert(self.dataSource != nil, @"menu's datasource shouldn't be nil");
    
    if ([self.dataSource respondsToSelector:@selector(menu:titleForRowAtIndexPath:)]) {
        NSDictionary *dic= [self.dataSource menu:self titleForRowAtIndexPath:[DOPIndexPath indexPathWithCol:self.currentSelectedMenudIndex row:indexPath.row]];
        if([self.screenname isEqualToString:@"itemsSelection"] || [self.screenname isEqualToString:@"instoremode_more"])
        {
            NSString *string_lbl=[NSString stringWithFormat:@"%@",[dic objectForKey:@"menuItem"]];
            
            cell.textLabel.numberOfLines=5;
            cell.textLabel.adjustsFontSizeToFitWidth=YES;
            cell.selectionStyle=NO;
            cell.textLabel.text = string_lbl;
            CGSize maximumLabelSize = CGSizeMake(cell.textLabel.frame.size.width, 9999);
            CGSize expectedSize = [cell.textLabel sizeThatFits:maximumLabelSize];
            cell.textLabel.frame = CGRectMake(cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y, cell.textLabel.frame.size.width, expectedSize.height);
            
            
        }
        else if([self.screenname isEqualToString:@"items"])
        {
            NSString *is_color=[dic objectForKey:@"is_color"];
            NSString *string_lbl=[NSString stringWithFormat:@"%@",[dic objectForKey:@"fav_matchin_item"]];
            cell.textLabel.numberOfLines=5;
            cell.textLabel.adjustsFontSizeToFitWidth=YES;
            
            cell.textLabel.text = string_lbl;
            CGSize maximumLabelSize = CGSizeMake(cell.textLabel.frame.size.width, 9999);
            CGSize expectedSize = [cell.textLabel sizeThatFits:maximumLabelSize];
            cell.textLabel.frame = CGRectMake(cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y, cell.textLabel.frame.size.width, expectedSize.height);
            
            
            if([is_color isEqualToString:@"Gray"])
            {
                cell.textLabel.enabled=NO;
            }
            else{
                
                cell.textLabel.enabled=YES;
                
            }
        }
        else
        {
            self.textlabel_string=[dic objectForKey:@"name"];
            cell.textLabel.text=self.textlabel_string;
        }
    }
    else {
        NSAssert(0 == 1, @"dataSource method needs to be implemented");
    }
    cell.backgroundColor = DROPDOWN_BG_COLOR;
    _fontSize= [self setFont];
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:_fontSize];
    cell.separatorInset = UIEdgeInsetsZero;
    
    //Dimple-30-11-2015
    
    //    if ([cell.textLabel.text isEqualToString: [(CATextLayer *)[_titles objectAtIndex:_currentSelectedMenudIndex] string]]) {
    //        cell.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    //    }
    
    cell.selectionStyle=NO;
    
    return cell;
}

#pragma mark - tableview delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(![self.screenname isEqualToString:@"items"] && ![self.screenname isEqualToString:@"itemsSelection"] && ![self.screenname isEqualToString:@"instoremode_more"])
    {
        [self confiMenuWithSelectRow:indexPath.row];
    }
    
    if (self.delegate || [self.delegate respondsToSelector:@selector(menu:didSelectRowAtIndexPath:)]) {
        [self.delegate menu:self didSelectRowAtIndexPath:[DOPIndexPath indexPathWithCol:self.currentSelectedMenudIndex row:indexPath.row]];
    }
}

- (void)confiMenuWithSelectRow:(NSInteger)row {
    /* CATextLayer *title = (CATextLayer *)_titles[_currentSelectedMenudIndex];
     NSDictionary *dic=[self.dataSource menu:self titleForRowAtIndexPath:[DOPIndexPath indexPathWithCol:self.currentSelectedMenudIndex row:row]];
     
     title.string = [dic objectForKey:@"fav_matchin_item"];*/
    
    [self animateIdicator:_indicators[_currentSelectedMenudIndex] background:_backGroundView tableView:_tableView title:_titles[_currentSelectedMenudIndex] forward:NO complecte:^{
        _show = NO;
    }];
    
    /* [(CALayer *)self.bgLayers[_currentSelectedMenudIndex] setBackgroundColor:[UIColor whiteColor].CGColor];
     
     CAShapeLayer *indicator = (CAShapeLayer *)_indicators[_currentSelectedMenudIndex];
     indicator.position = CGPointMake(title.position.x + title.frame.size.width / 2 + 8, indicator.position.y);*/
}

- (void)dismiss {
    [self backgroundTapped:nil];
}

-(CGFloat)setFont{
    if([self.screenname isEqualToString:@"items"])
    {
        if(IS_IPHONE)
        {
            _fontSize = 14.0;
        }
        else
        {
            _fontSize = 25.0;
        }
    }
    else if([self.screenname isEqualToString:@"itemsSelection"] || [self.screenname isEqualToString:@"instoremode_more"])
    {
        if(IS_IPHONE)
        {
            _fontSize = 14.0;
        }
        else
        {
            _fontSize = 20.0;
        }
    }
    else
    {
        if(IS_IPHONE)
        {
            _fontSize = 14.0;
        }
        else
        {
            _fontSize = 18.0;
        }
    }
    return  _fontSize;
}

#pragma mark - table datasource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key_name;
    if([self.screenname isEqualToString:@"items"])
    {
        key_name=@"fav_matchin_item";
    }
    else if([self.screenname isEqualToString:@"itemsSelection"] || [self.screenname isEqualToString:@"instoremode_more"])
    {
        key_name=@"menuItem";
    }
    else
    {
        if(IS_IPHONE)
        {
            return 40;
        }
        else
        {
            return 60;
        }
    }
    NSDictionary *dic= [self.dataSource menu:self titleForRowAtIndexPath:[DOPIndexPath indexPathWithCol:self.currentSelectedMenudIndex row:indexPath.row]];
    NSString *str1=[NSString stringWithFormat:@"%@",[dic objectForKey:key_name]];
    _cellHeight = (int)roundf([self calculateTitleSizeWithString:str1].height+20);
    return _cellHeight;
}

@end
