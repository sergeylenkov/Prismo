//
//  MyClass.m
//  Prismo
//
//  Created by Sergey Lenkov on 06.08.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSSettings.h"

@implementation PSSettings

+ (void)setFilterValue:(id)value forKey:(NSString *)key {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"Filters"]];
    [dict setObject:value forKey:key];
    
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"Filters"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (id)filterValueForKey:(NSString *)key {
    NSMutableDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:@"Filters"];
    return [dict objectForKey:key];
}

+ (void)removeFilterValueForKey:(NSString *)key {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"Filters"]];
    [dict removeObjectForKey:key];
    
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"Filters"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
