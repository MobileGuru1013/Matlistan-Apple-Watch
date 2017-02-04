//
//  Utility.h
//  INK'N'ART-Visitkort
//
//  Created by Yan Zhang on 10/18/13.
//  Copyright (c) 2013 Flame Soft. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SECONDS_IN_A_DAY 86400

#define DELAY_TO_REMOVE_ADS         1.5

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)


#define kCustomAlertWithParamAndTarget(title,msg,target) [[[UIAlertView alloc] initWithTitle:NSLocalizedString(title,nil) message:msg delegate:target cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil] show]

#define kPremiumAccountPurchased               @"PremiumAccountPurchased"
#define kInternetNotReachable                  @"InernetNotReachable"
#define kInternetReachable                     @"InernetReachable"

@interface Utility : NSObject
typedef enum{
    LoginTypeEmail,
    LoginTypeAnonymous,
    LoginTypeFacebook,
    LoginTypeUnknown,
    LoginTypeGoogle
} LoginType;
+(NSDictionary*)getErrorDictionary:(NSData *)dataIn;
+(NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
+(NSInteger)secondsBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
+(void)setCurrentLoginType:(LoginType)loginTypeIn;
+(LoginType)getCurrentLoginType;
+(void)setButtonBorder:(UIButton*)button;
+(void)setGreenButtonBorder:(UIButton*)button;
+(void)setButtonStraightBorder:(UIButton*)button;
+(void)setButtonBorder:(UIButton*)button withBorderRadius:(float)radius borderColor:(UIColor*)color;
+ (NSString *)documentPath;
+(UIImage *) loadImage:(NSString *)fileName ofType:(NSString *)extension inDirectory:(NSString *)directoryPath;
+(UIColor *)getPickerBackgroundColor;
+(UIColor*)getViewBackgroundColor;
+(UIColor*)getTableViewBackgroundColor;
+(UIColor*)getNavigationBarColor;
+(UIColor *)getGreyColor;
+(UIColor *)getBlueColor;
+(UIColor *)getYellowColor;
+(UIColor *)getGreenColor;
+(UIColor *)getRedColor;
+(UIColor *)getDarkGreenColor;
+(UIColor *)getWhiteColor;
+(NSString*)getDateString;
+(NSString*)getNowTimeString;
+(NSDate*)getDateByDiff:(int)day;
+(NSDate*)getDateEnding:(NSDate*)date;
+(NSString*)getStringFromDate:(NSDate*)date;
+(NSString*)getDescriptiveStringFromDate:(NSDate*)date;
+(NSString*)getDescriptiveShortStringFromDate:(NSDate*)date;
+(NSString*)getWeekDayNameFromDate:(NSDate*)date;
+(NSString*)getDateTimeString;
+(NSString*)getDateTimeStringByDate:(NSDate*)date;
+(NSString*)getDateStringByDate:(NSDate*)date;
+(NSString*)getTimeStringByDate:(NSDate*)date;
+(NSString*)getSQLDateStringByDate:(NSDate*)date;
+(NSString*)getSQLTimeStringByDate:(NSDate*)date;
+(NSString*)getDateFormat;
+(id)getObjectFromDefaults:(NSString*)key;
+(unsigned)getHexFromMutalbelString:(NSMutableString*)string;
+(UIColor*)getUIColorFromHexString:(NSMutableString*)string;
+(BOOL)getBoolFromString:(NSString*)string;
+(NSString*)getStringFromBool:(BOOL)value;
+(void) removeKeyFomUserDefaults: (NSString *) key;
+(void)saveDataInDefaults:(NSData*)data withKey:(NSString*)key;
+(void)saveInDefaultsWithBool:(BOOL)value andKey:(NSString*)key;
+(void)resetUserDefaults;
+(BOOL)whitespaceExists:(NSString*)input;
+(NSData*)getDataFromImageFile:(NSString*)fileName;
+(CGFloat)getScreenHeight;
+(CGFloat)getScreenWidth;
+(void)saveInDefaultsWithInt:(NSInteger)num andKey:(NSString*)key;
+(void)saveInDefaultsWithObject:(id)object andKey:(NSString*)key;
+(NSInteger)getDefaultIntAtKey:(NSString*)key;
+(BOOL)getDefaultBoolAtKey:(NSString*)key;
+(BOOL)hasDefaultKey:(NSString*)key;
+(BOOL)isStringEmpty:(NSString*)string;
+(NSNumberFormatter*)getCurrencyFormatter;
+(void)showShadow:(UIImageView*)imageView;
+(BOOL)illegalCharacterExists:(NSString*)input;
+(NSDate*)getYesterday;
+(NSString*)getCountryCode;
+(NSString*)getTimeFormat;
+(unsigned long long)getFileSize:(NSString*)filePath;
+(NSDate*)getDateFromString:(NSString*)str;
+(float)getHoursOfTheDate:(NSDate*)date;
+(BOOL)theString:(NSString*)longString containSubString:(NSString*)subString;
+(double)getTimeStamp;
+(UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize andImage:(UIImage*)image;
+(void)saveImage:(UIImage*)image withFileName:(NSString*)imageName;
+(UIImage*)loadLocalRecipeImage:(NSNumber*)recipeId;
+(NSString*)getStringFromUnicode:(NSString*)input;
+(NSString*)removeSpaceAndReturn:(NSString*)domainName;
+(NSString*)getCorrectURLFromJson:(NSString*)input;
+(int)getRandomNumber;
+(BOOL)containsSubstring:(NSString*)subString inString:(NSString*)wholeString;
+ (BOOL) validEmail:(NSString*) emailString;
+ (NSString*) getMatlistanServerURLString;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToMaxWidth:(CGFloat)width maxHeight:(CGFloat)height;

+ (void)updateConstraint:(UIView *)withView toView:(UIView *)toView withConstant:(CGFloat)constant;

+ (CGSize)getSizeForText:(NSString *)text maxWidth:(CGFloat)width font:(NSString *)fontName fontSize:(float)fontSize;
+(void)setItemscustomImage:(UIImage*)image;
+(UIImage *)getItemscustomImage;
+(void)setItemscustomLandImage:(UIImage*)image;
+(UIImage *)getItemscustomLandImage;

+(void)setRecipecustomImage:(UIImage*)image;
+(UIImage *)getRecipecustomImage;
+(void)setRecipecustomLandImage:(UIImage*)image;
+(UIImage *)getRecipecustomLandImage;

+(void)setPlanRecipecustomImage:(UIImage*)image;
+(UIImage *)getPlanRecipecustomImage;
+(void)setPlanRecipecustomLandImage:(UIImage*)image;
+(UIImage *)getPlanRecipecustomLandImage;

+(NSString *) getAppUrlScheme;
//Dimple-18-11-2015
+(NSString *)getSortName;
+(void)SetSortName : (NSString *)sortname;
+(NSString *)getTempEmailID;
+(void)setTempEmailID:(NSString *)eid;

//Dimple-2-12-2015
+(NSString *)getBarcodeSelection;
+(void)setBarcodeSelection : (NSString *)selectionType;

+ (void) migrateUserDefaultsToSharedDefaults;

+(NSString *)getTimerRecipeId;
+(void)setTimerRecipeId : (NSString *)timer_recipe_id;

//Raj- 15-1-2016
+(NSNumber *)getPortraitFont;
+(void)setPortraitFont : (NSNumber *)portrait_font_size;

+(NSNumber *)getLandscapeFont;
+(void)setLandscapeFont : (NSNumber *)landscape_font_size;

+(void)setSpeechCount:(NSString *)userCnt userKey:(NSString *)userKey;
+(NSString *)getSpeechCount:(NSString *)userKey;
+(NSString *)getUserName:(NSString *)key;

+(NSInteger)monthsBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

+ (void)setLocationPermission:(NSString *)loc_per;
+ (NSString *)getLocationPermission;
@end
