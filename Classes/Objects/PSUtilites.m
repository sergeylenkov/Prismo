//
//  PSUtilites.m
//  Prismo
//
//  Created by Sergey Lenkov on 31.03.12.
//  Copyright (c) 2012 Sergey Lenkov. All rights reserved.
//

#import "PSUtilites.h"

@implementation PSUtilites

+ (NSString *)localizedShortDate:(NSDate *)date {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"MMM d"];
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setLocale:locale];
    [locale release];
    
    return [formatter stringFromDate:date];
}

+ (NSString *)localizedShortDateWithFullMonth:(NSDate *)date {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"MMMM d"];
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setLocale:locale];
    [locale release];
    
    return [formatter stringFromDate:date];
}

+ (NSString *)localizedShortPeriodDateWithFullMonth:(NSDate *)date {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"d MMMM"];
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setLocale:locale];
    [locale release];
    
    return [formatter stringFromDate:date];
}

+ (NSString *)localizedMediumDate:(NSDate *)date {    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"MMM d, yyyy"];
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setLocale:locale];
    [locale release];
    
    return [formatter stringFromDate:date];
}

+ (NSString *)localizedMediumDateWithFullMonth:(NSDate *)date {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"MMMM d, yyyy"];
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setLocale:locale];
    [locale release];
    
    return [formatter stringFromDate:date];
}

+ (NSString *)localizedMediumPeriodDateWithFullMonth:(NSDate *)date {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"d MMMM, yyyy"];
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setLocale:locale];
    [locale release];
    
    return [formatter stringFromDate:date];
}

+ (NSString *)localizedMonthName:(NSDate *)date {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"MMMM"];
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setLocale:locale];
    [locale release];
    
    return [formatter stringFromDate:date];
}

@end
