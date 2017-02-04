#import <UIKit/UIKit.h>
#import "Item.h"

@class CustomPickerView;

@protocol CustomPickerViewDelegate <NSObject>

@optional

- (void)didSelectRow:(NSInteger)optionIndex pickerType:(NSString *)pickerType;
- (void)pickerView:(CustomPickerView *)pickerView withSelectedOption:(NSInteger)optionIndex;
- (void)CancelTapped;

@end

@interface CustomPickerView : UIView <UIPickerViewDelegate, UIPickerViewDataSource>

+ (CustomPickerView *)createViewWithItems:(NSArray*)items pickerType:(NSString *)pickerType;

@property (nonatomic, strong) NSArray *items;

@property (nonatomic, weak) id<CustomPickerViewDelegate> delegate;

@property (nonatomic, strong) Item *selectedItem;

@property (strong, nonatomic) IBOutlet UIPickerView *pickerViewSprouting;

@property (nonatomic, strong) NSString *pickerType;

- (IBAction)btnDone_Clicked:(id)sender;
- (IBAction)btnCancel_Clicked:(id)sender;

@end
