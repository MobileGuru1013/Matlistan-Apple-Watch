#import "CustomPickerView.h"

@implementation CustomPickerView
@synthesize items=_items;
@synthesize delegate=_delegate;
@synthesize pickerViewSprouting = _pickerViewSprouting;
@synthesize pickerType = _pickerType;

NSInteger option;

+ (CustomPickerView *)createViewWithItems:(NSArray*)items pickerType:(NSString *)pickerType
{
    CustomPickerView *timeView = [[[NSBundle mainBundle] loadNibNamed:@"CustomPickerView" owner:self options:nil] objectAtIndex:0];
    timeView.items = items;
    timeView.pickerType = pickerType;
    option = 0;
    [timeView.pickerViewSprouting reloadAllComponents];

    return timeView;
}


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.items.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.items objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    option = row;
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectRow:pickerType:)])
        [self.delegate didSelectRow:option pickerType:self.pickerType];
}

- (IBAction)btnDone_Clicked:(id)sender
{
    option = [self.pickerViewSprouting selectedRowInComponent:0];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pickerView:withSelectedOption:)])
        [self.delegate pickerView:self withSelectedOption:option];
}

- (IBAction)btnCancel_Clicked:(id)sender
{
    if (self.delegate)
        [self.delegate CancelTapped];
}
@end
