//
//  Utility.m
//  INK'N'ART-Visitkort
//
//  Created by Yan Zhang on 10/18/13.
//  Copyright (c) 2013 Flame Soft. All rights reserved.
//

//#import "ColorUtility.h"
#import "Environment.h"

@implementation Utility

#define base_url [Environment sharedInstance].baseUrl

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0];
+(void)setButtonBorder:(UIButton*)button{
    CALayer *btnLayer = [button layer];
    [btnLayer setBorderWidth:1.0f];
    [btnLayer setCornerRadius:5.0f];
    [btnLayer setBorderColor:[[UIColor whiteColor]CGColor]];
    button.clipsToBounds = YES;
}
+(void)setButtonStraightBorder:(UIButton*)button{
    CALayer *btnLayer = [button layer];
    [btnLayer setBorderWidth:1.0f];
    [btnLayer setCornerRadius:0];
    [btnLayer setBorderColor:[[UIColor whiteColor]CGColor]];
    button.clipsToBounds = YES;
}
+(void)setGreenButtonBorder:(UIButton*)button
{
    CALayer *btnLayer = [button layer];
    [btnLayer setBorderWidth:1.0f];
    [btnLayer setCornerRadius:5.0f];
    [btnLayer setBorderColor:[[Utility getDarkGreenColor]CGColor]];
    button.clipsToBounds = YES;
}
+(void)setButtonBorder:(UIButton*)button withBorderRadius:(float)radius borderColor:(UIColor*)color
{
    CALayer *btnLayer = [button layer];
    [btnLayer setBorderWidth:1.0f];
    [btnLayer setCornerRadius:radius];
    [btnLayer setBorderColor:[color CGColor]];
    button.clipsToBounds = YES;
}
+(UIColor *)getViewBackgroundColor{
    return [UIColor whiteColor];
}
+(UIColor *)getTableViewBackgroundColor{
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"Cuby_green_blue2.png"]];

}
+(UIColor *)getPickerBackgroundColor{
     return [UIColor blackColor];   //dark grey
}
+(UIColor *)getNavigationBarColor{
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"Titlebar.png"]];
}
+(UIColor *)getGreyColor{
    return [UIColor colorWithRed:0 green:0 blue:80.0/255 alpha:1.0];
}
+(UIColor *)getBlueColor{
    return [UIColor colorWithRed:121.0/255 green:163.0/255 blue:221.0/255 alpha:1.0];
}
+(UIColor *)getYellowColor{
    return [UIColor colorWithRed:211.0/255 green:211.0/255 blue:114.0/255 alpha:1.0];
}
+(UIColor *)getGreenColor{
    return [UIColor colorWithRed:93.0/255 green:187.0/255 blue:85.0/255 alpha:1.0];
}
+(UIColor *)getRedColor{
    return [UIColor colorWithRed:211.0/255 green:114.0/255 blue:114.0/255 alpha:1.0];
}
+(UIColor *)getDarkGreenColor{
    return [UIColor colorWithRed:126.0/255.0 green:211.0/255.0 blue:33.0/255.0 alpha:1.0];   //mid-green
}
+(UIColor *)getWhiteColor{
    return [UIColor colorWithRed:255.0/255 green:255.0/255 blue:255.0/255 alpha:0.0];
}
#pragma mark DateTime
+(NSString*)getStringFromDate:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}
+(NSString*)getDescriptiveStringFromDate:(NSDate*)date{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    return formattedDateString;
}
+(NSString*)getDescriptiveShortStringFromDate:(NSDate*)date{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    dateFormatter.dateFormat=@"dd MMM";
    [dateFormatter setLocale:[NSLocale currentLocale]];
    //DLog(@"Locale %@", [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode]);
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    return formattedDateString;
}
+(NSString*)getWeekDayNameFromDate:(NSDate*)date{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
   [dateFormatter setLocale:[NSLocale currentLocale]];
    dateFormatter.dateFormat=@"EEE";
    NSString * dayString = [[dateFormatter stringFromDate:date] capitalizedString];
   // DLog(@"Locale %@", [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode]);
  
    return dayString;
}
+(NSString*)getDateString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:[Utility getDateFormat]];
    NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
    return stringFromDate;
}
+(NSString*)getDateStringByDate:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:[Utility getDateFormat]];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}
+(NSString*)getTimeStringByDate:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:[Utility getTimeFormat]];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}
+(NSString*)getSQLDateStringByDate:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'"];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}
+(NSString*)getSQLTimeStringByDate:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}
+(NSString*)getNowTimeString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:[Utility getTimeFormat]];
    NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
    return stringFromDate;
}
+(NSString*)getDateTimeString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm'"];
    NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
    return stringFromDate;
}
+(NSString*)getDateTimeStringByDate:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss'"];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}
+(NSDate*)getDateByDiff:(int)day{
    NSDate *someDaysAgo = [[ NSDate alloc ] initWithTimeIntervalSinceNow: (NSTimeInterval) (day * SECONDS_IN_A_DAY) ];
    return someDaysAgo;
}
+(NSDate*)getDateEnding:(NSDate*)date{
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    long timeZoneOffset = [destinationTimeZone secondsFromGMTForDate:date] / 3600;
    [components setHour:timeZoneOffset+23];
    [components setMinute:59];
    [components setSecond:59];
    NSDate *morningStart = [calendar dateFromComponents:components];
   
    return morningStart;
}
+(NSDate*)getYesterday{
    NSDate *now = [NSDate date];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMonth:0];
    [comps setDay:-1];
    [comps setHour:0];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *newDate = [calendar dateByAddingComponents:comps toDate:now options:0];
    return newDate;
}
+(NSString*)getCountryCode{
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    return countryCode;
}
+(NSString*)getTimeFormat{
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    if ([countryCode isEqualToString:@"SE"]) {
        return @"MM-dd HH.mm.ss";
    }
    else{
        return @"MM-dd HH:mm:ss";
    }
}
+(NSString*)getDateFormat{
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    if ([countryCode isEqualToString:@"SE"]) {
        return @"yyyy-MM-dd";
    }
    else{
        return @"dd/MM/yyyy";
    }
}

+(NSDate*)getDateFromString:(NSString*)str{
    
    if (![Utility theString:str containSubString:@"."]) {
        str = [str stringByReplacingOccurrencesOfString:@"Z" withString:@".000Z"];
        
    }
    
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Convert the RFC 3339 date time string to an NSDate.
    NSDate *date = [rfc3339DateFormatter dateFromString:str];

    
    return date;
    
}
+(float)getHoursOfTheDate:(NSDate*)date{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    float hours = hour + minute/60.0;
    //DLog(@"hours of the day %.1f",hours);
    return hours;
}
+(double)getTimeStamp{
    return [[NSDate date] timeIntervalSince1970];
}
#pragma mark NSDefaults
+ (void) migrateUserDefaultsToSharedDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUserDefaults *defaultsShared = [[NSUserDefaults alloc] initWithSuiteName:GROUP_BUNDLE_ID];
    [defaultsShared setObject:[self getMatlistanServerURLString] forKey:@"serverURL"];
    if(![defaults boolForKey:@"userDefaultsShared"]) {
        for(NSString *key in [[defaults dictionaryRepresentation] allKeys]) {
            id obj = [defaults objectForKey:key];
            [defaultsShared setObject:obj forKey:key];
        }
        [defaults setBool:YES forKey:@"userDefaultsShared"];
        [defaults synchronize];
    }
    [defaultsShared synchronize];
    DLog(@"Defaults migrated");
}

+(id)getObjectFromDefaults:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id obj = [defaults objectForKey:key];
    return obj;
}

+(void)saveDataInDefaults:(NSData*)data withKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:key];
    [defaults synchronize];
    
    NSUserDefaults *defaultsShared = [[NSUserDefaults alloc] initWithSuiteName:GROUP_BUNDLE_ID];
    [defaultsShared setObject:data forKey:key];
    [defaultsShared synchronize];
}
+(void)saveInDefaultsWithObject:(id)object andKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:object forKey:key];
    [defaults synchronize];
    
    NSUserDefaults *defaultsShared = [[NSUserDefaults alloc] initWithSuiteName:GROUP_BUNDLE_ID];
    [defaultsShared setObject:object forKey:key];
    [defaultsShared synchronize];
}

+(void) removeKeyFomUserDefaults: (NSString *) key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:key];
    [defaults synchronize];
}

+(void)saveInDefaultsWithInt:(NSInteger)num andKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:num forKey:key];
    [defaults synchronize];
    
    NSUserDefaults *defaultsShared = [[NSUserDefaults alloc] initWithSuiteName:GROUP_BUNDLE_ID];
    [defaultsShared setInteger:num forKey:key];
    [defaultsShared synchronize];
}
+(void)saveInDefaultsWithBool:(BOOL)value andKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
    
    NSUserDefaults *defaultsShared = [[NSUserDefaults alloc] initWithSuiteName:GROUP_BUNDLE_ID];
    [defaultsShared setBool:value forKey:key];
    [defaultsShared synchronize];
}
+(NSInteger)getDefaultIntAtKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:key];
}
+(BOOL)getDefaultBoolAtKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}

+(BOOL)hasDefaultKey:(NSString*)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key] == nil ? NO : YES;
}

+(void)resetUserDefaults{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}
+(BOOL)whitespaceExists:(NSString*)input{
    NSRange whiteSpaceRange = [input rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (whiteSpaceRange.location != NSNotFound) {
        return YES;
    }
    return NO;
}
+(BOOL)containsSubstring:(NSString*)subString inString:(NSString*)wholeString{
    NSRange range = [wholeString rangeOfString:subString];
    if (range.location == NSNotFound) {
        return NO;
    }
    else{
        return YES;
    }
}
#pragma mark String Conversion
+(unsigned)getHexFromMutalbelString:(NSMutableString*)string{
    unsigned hexInt = 0;
    [[NSScanner scannerWithString:string] scanHexInt:&hexInt];
    return hexInt;
}
+(UIColor*)getUIColorFromHexString:(NSMutableString*)string{
    unsigned hexInt = [Utility getHexFromMutalbelString:string];
    return UIColorFromRGB(hexInt);
}
+(BOOL)getBoolFromString:(NSString*)string{
    return [[string uppercaseString] isEqualToString:@"YES"];
}

+(NSString*)getStringFromBool:(BOOL)value{
    return (value?@"YES":@"NO");
}
+(BOOL)illegalCharacterExists:(NSString*)input{
    NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"() €!,#&@+?*[]{}"];
    NSRange range = [input rangeOfCharacterFromSet:cset];
    if (range.location == NSNotFound) {
        return NO;// no illegal charaters in the string
    } else {
        return YES;
    }
}

+(BOOL)isStringEmpty:(NSString*)string
{
    return (string== nil || [string isEqualToString:@""] || [string isEqualToString:@"0"]);
}

+(BOOL)theString:(NSString*)longString containSubString:(NSString*)subString{
    BOOL result = [longString rangeOfString:subString].location != NSNotFound;
    return result;
}

+(NSString*)getStringFromUnicode:(NSString*)input{
   
    if (input == nil) {
        return @"";
    }
    // will cause trouble if you have "abc\\\\uvw"
    NSString* esc1 = [input stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    NSString* esc2 = [esc1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString* quoted = [[@"\"" stringByAppendingString:esc2] stringByAppendingString:@"\""];
    NSData* data = [quoted dataUsingEncoding:NSUTF8StringEncoding];
    NSString* unesc = [NSPropertyListSerialization propertyListFromData:data
                                                       mutabilityOption:NSPropertyListImmutable format:NULL
                                                       errorDescription:NULL];

   // DLog(@"Output = %@", unesc);
    if([unesc isKindOfClass:[NSString class]])
        return unesc;
    else
        return @"";
}
+(NSString*)removeSpaceAndReturn:(NSString*)domainName{
    
    NSRange tldr = [domainName rangeOfString:@"\""];
    
    if (tldr.location != NSNotFound) {
      //  DLog(@"range of .com: %ld, %ld", tldr.location, tldr.length);
        domainName = [domainName substringFromIndex:tldr.location +1];
        
        NSRange nextPos = [domainName rangeOfString:@"\""];
        domainName = [domainName substringToIndex:nextPos.location];
      //  DLog(@"removed \\n, domain is now: %@", domainName);
    }
    return domainName;
}
+(NSString*)getCorrectURLFromJson:(NSString*)input{
    NSString *urlString = [Utility removeSpaceAndReturn:input];
    urlString =  [Utility getStringFromUnicode:urlString];
    return [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
#pragma GUI
+(CGFloat)getScreenHeight{
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    //CGFloat screenWidth = screenSize.width;
    CGFloat screenHeight = screenSize.height;
    return screenHeight;
}
+(CGFloat)getScreenWidth{
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenWidth = screenSize.width;

    return screenWidth;
}
+(NSData*)getDataFromImageFile:(NSString*)fileName{
    UIImage *img = [UIImage imageNamed:fileName];
    NSData *data = UIImagePNGRepresentation(img);
    return data;
}
+(void)showShadow:(UIImageView*)imageView{
    if (imageView.image != nil) {
        imageView.layer.shadowOpacity = 0.5;
        imageView.layer.shadowOffset = CGSizeMake(0, 3);
        imageView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:CGRectInset(imageView.bounds,1,1)] CGPath];
    }
    
}

/**Crop image to correct scale
 */
+(UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize andImage:(UIImage*)image
{
    UIImage *sourceImage = image;
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
        {
            scaleFactor = widthFactor; // scale to fit height
        }
        else
        {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
        {
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    }
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil)
    {
        DLog(@"could not scale image");
    }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
}



+(void)saveImage:(UIImage*)image withFileName:(NSString*)imageName{
    NSString * fullFileName = [[Utility documentPath] stringByAppendingPathComponent:imageName];
    [UIImagePNGRepresentation(image) writeToFile:fullFileName atomically:YES];
   
    
}
+(UIImage *) loadImage:(NSString *)fileName ofType:(NSString *)extension inDirectory:(NSString *)directoryPath
{
    UIImage * result = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.%@", directoryPath, fileName, extension]];
    
    return result;
}
+(UIImage*)loadLocalRecipeImage:(NSNumber*)recipeId{
    
    NSString *fileName = [NSString stringWithFormat:@"%@",recipeId];
    UIImage * result = [Utility loadImage:fileName ofType:@"png" inDirectory:[Utility documentPath]];
    return result;
}
+(NSNumberFormatter*)getCurrencyFormatter{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"sv_SE"];
    [formatter setLocale:locale];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    return formatter;
}

+(unsigned long long)getFileSize:(NSString*)filePath{
    NSError *error = nil;
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if(fileDictionary)
    {
        return [fileDictionary fileSize];
    }
    else{
        return 0;
    }
    
}
+(NSString *)documentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return documentPath;
}
+(int)getRandomNumber{
    int r = 0;
    while (r==0) {
        r = arc4random();
    }
    return r;
}

+(LoginType)getCurrentLoginType{
    LoginType someLoginType;
    
    if ([self getDefaultIntAtKey:@"LoginType"] == LoginTypeAnonymous) {
        someLoginType = LoginTypeAnonymous;
    }else if ([self getDefaultIntAtKey:@"LoginType"] == LoginTypeEmail){
        someLoginType = LoginTypeEmail;
    }else if ([self getDefaultIntAtKey:@"LoginType"] == LoginTypeFacebook){
        someLoginType = LoginTypeFacebook;
    }else if ([self getDefaultIntAtKey:@"LoginType"] == LoginTypeGoogle){
        someLoginType = LoginTypeGoogle;
    }else {
        someLoginType = LoginTypeUnknown;
    }
    return someLoginType;
}

+(void)setCurrentLoginType:(LoginType)loginTypeIn{
    [self saveInDefaultsWithInt:loginTypeIn andKey:@"LoginType"];
}
+(NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    return [difference day];
}

+(NSInteger)monthsBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitMonth
                                               fromDate:fromDate toDate:toDate options:0];
    return [difference month];
}

+(NSInteger)secondsBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    return [toDateTime timeIntervalSinceDate:fromDateTime];
}

#pragma mark -
#pragma mark - Email Validator

/**
 Verify Email syntax
 @ModifiedDate: September 1 , 2015
 @Version:1.14
 @Author: Yousuf
 */
+ (BOOL) validEmail:(NSString*) emailString {
    
    if([emailString length] == 0)
    {
        return NO;
    }
    
    NSString *regExPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:emailString options:0 range:NSMakeRange(0, [emailString length])];
    
    DLog(@"%lu", (unsigned long)regExMatches);
    if (regExMatches == 0)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}
+(NSDictionary*)getErrorDictionary:(NSData *)dataIn{
    NSDictionary* errDic = nil;
    if (dataIn) {
        NSError *error = nil;
        errDic = [NSJSONSerialization JSONObjectWithData:dataIn options:kNilOptions error:&error];
    }
    return errDic;
}

+ (NSString*) getMatlistanServerURLString {
    //return @"http://api2.matlistan.se/";//Old API
//    return @"http://api.test.matlistan.se";//New API
    
    return base_url;
}

//Scale image with aspect ratio
+ (UIImage *)imageWithImage:(UIImage *)image scaledToMaxWidth:(CGFloat)width maxHeight:(CGFloat)height {
    CGFloat oldWidth = image.size.width;
    CGFloat oldHeight = image.size.height;
    
    CGFloat scaleFactor = (oldWidth > oldHeight) ? width / oldWidth : height / oldHeight;
    
    CGFloat newHeight = oldHeight * scaleFactor;
    CGFloat newWidth = oldWidth * scaleFactor;
    CGSize newSize = CGSizeMake(newWidth, newHeight);
    
    return [self imageWithImage:image scaledToSize:newSize];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (void)updateConstraint:(UIView *)withView toView:(UIView *)toView withConstant:(CGFloat)constant
{
    NSLayoutConstraint *bottomSpaceConstraint = [NSLayoutConstraint constraintWithItem:withView
                                                                             attribute:NSLayoutAttributeBottom
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:toView
                                                                             attribute:NSLayoutAttributeBottom
                                                                            multiplier:1.0
                                                                              constant:constant];
    [withView addConstraint:bottomSpaceConstraint];
    [withView updateConstraints];
    [withView layoutIfNeeded];
}

#pragma mark  Get Size For Text
+ (CGSize)getSizeForText:(NSString *)text maxWidth:(CGFloat)width font:(NSString *)fontName fontSize:(float)fontSize
{
    text = [text stringByReplacingOccurrencesOfString:@"&" withString:@"ABC"];
    
    CGSize constraintSize;
    constraintSize.height = MAXFLOAT;
    constraintSize.width = width;
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:fontName size:fontSize], NSFontAttributeName,
                                          nil];
    
    CGRect frame = [text boundingRectWithSize:constraintSize
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:attributesDictionary
                                      context:nil];
    
    CGSize stringSize = frame.size;
    stringSize = CGSizeMake(stringSize.width, stringSize.height+20);
    return stringSize;
    
}

+(void)setItemscustomImage:(UIImage*)image{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(image==nil)
    {
      [defaults setObject:nil forKey:@"ItemscustomImage"];
    }
    else
    {
        [defaults setObject:UIImagePNGRepresentation(image) forKey:@"ItemscustomImage"];
    }
    [defaults synchronize];
}
+(UIImage *)getItemscustomImage{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:@"ItemscustomImage"] == nil)
    {
        return nil;
    }
    NSData* imageData = [defaults objectForKey:@"ItemscustomImage"];
    UIImage* image = [UIImage imageWithData:imageData];
    return image;
}

+(void)setItemscustomLandImage:(UIImage *)image{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(image==nil)
    {
        [defaults setObject:nil forKey:@"ItemscustomLandImage"];
    }
    else
    {
      [defaults setObject:UIImagePNGRepresentation(image) forKey:@"ItemscustomLandImage"];
    }
    
    [defaults synchronize];
}
+(UIImage *)getItemscustomLandImage{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:@"ItemscustomLandImage"] == nil)
    {
        return nil;
    }
    NSData* imageData = [defaults objectForKey:@"ItemscustomLandImage"];
    UIImage* image = [UIImage imageWithData:imageData];
    return image;
}





+(void)setRecipecustomImage:(UIImage*)image
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:UIImagePNGRepresentation(image) forKey:@"RecipecustomImage"];
    [defaults synchronize];
}
+(UIImage *)getRecipecustomImage
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData* imageData = [defaults objectForKey:@"RecipecustomImage"];
    UIImage* image = [UIImage imageWithData:imageData];
    return image;
}
+(void)setRecipecustomLandImage:(UIImage*)image
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:UIImagePNGRepresentation(image) forKey:@"RecipecustomLandImage"];
    [defaults synchronize];
}
+(UIImage *)getRecipecustomLandImage
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData* imageData = [defaults objectForKey:@"RecipecustomLandImage"];
    UIImage* image = [UIImage imageWithData:imageData];
    return image;

}

+(void)setPlanRecipecustomImage:(UIImage*)image
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:UIImagePNGRepresentation(image) forKey:@"PlanRecipecustomImage"];
    [defaults synchronize];

}
+(UIImage *)getPlanRecipecustomImage
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData* imageData = [defaults objectForKey:@"PlanRecipecustomImage"];
    UIImage* image = [UIImage imageWithData:imageData];
    return image;
}
+(void)setPlanRecipecustomLandImage:(UIImage*)image
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:UIImagePNGRepresentation(image) forKey:@"PlanRecipecustomLandImage"];
    [defaults synchronize];
}
+(UIImage *)getPlanRecipecustomLandImage
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData* imageData = [defaults objectForKey:@"PlanRecipecustomLandImage"];
    UIImage* image = [UIImage imageWithData:imageData];
    return image;
}

+(NSString *) getAppUrlScheme {
    return [Environment sharedInstance].urlScheme;
}

//Dimple-19-11-2015
+(NSString *)getSortName{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"sortname"];
    
}
+(void)SetSortName : (NSString *)sortname{
    [[NSUserDefaults standardUserDefaults]setObject:sortname forKey:@"sortname"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}
+(NSString *)getTempEmailID
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * eid=[defaults objectForKey:@"TempEmailID"];
    return eid;
}
+(void)setTempEmailID:(NSString *)eid
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:eid forKey:@"TempEmailID"];
    [defaults synchronize];
}
+(NSString *)getBarcodeSelection{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"selectionType"];
    
}
+(void)setBarcodeSelection : (NSString *)selectionType{
    [[NSUserDefaults standardUserDefaults]setObject:selectionType forKey:@"selectionType"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

//Dimple-7-12-2015
+(NSString *)getTimerRecipeId{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"timer_recipe_id"];
    
}
+(void)setTimerRecipeId : (NSString *)timer_recipe_id{
    [[NSUserDefaults standardUserDefaults]setObject:timer_recipe_id forKey:@"timer_recipe_id"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}
//Raj 15-1-2016
+(NSNumber *)getPortraitFont{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"portrait_font_size"];
    
}
+(void)setPortraitFont : (NSNumber *)portrait_font_size{
    [[NSUserDefaults standardUserDefaults]setValue:portrait_font_size forKey:@"portrait_font_size"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

+(NSNumber *)getLandscapeFont{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"landscape_font_size"];
    
}
+(void)setLandscapeFont : (NSNumber *)landscape_font_size{
    [[NSUserDefaults standardUserDefaults]setValue:landscape_font_size forKey:@"landscape_font_size"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}
+(void)setSpeechCount:(NSString *)userCnt userKey:(NSString *)userKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userCnt forKey:[NSString stringWithFormat:@"nuance-cnt-%@",userKey]];
    [defaults synchronize];
}
+(NSString *)getSpeechCount:(NSString *)userKey{
    return [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"nuance-cnt-%@",userKey]];
    
}
+(NSString *)getUserName:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

+ (void)setLocationPermission:(NSString *)loc_per
{
    [[NSUserDefaults standardUserDefaults]setValue:loc_per forKey:@"loc_per"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}
+ (NSString *)getLocationPermission
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"loc_per"];
}
@end
