//
//  PSUtilites.h
//  Prismo
//
//  Created by Sergey Lenkov on 31.03.12.
//  Copyright (c) 2012 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSUtilites : NSObject {
    
}

+ (NSString *)localizedShortDate:(NSDate *)date;
+ (NSString *)localizedShortDateWithFullMonth:(NSDate *)date;
+ (NSString *)localizedShortPeriodDateWithFullMonth:(NSDate *)date;
+ (NSString *)localizedMediumDate:(NSDate *)date;
+ (NSString *)localizedMediumDateWithFullMonth:(NSDate *)date;
+ (NSString *)localizedMediumPeriodDateWithFullMonth:(NSDate *)date;
+ (NSString *)localizedMonthName:(NSDate *)date;

@end
