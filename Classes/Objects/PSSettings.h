//
//  PSSettings.h
//  Prismo
//
//  Created by Sergey Lenkov on 06.08.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "NSApplication+Utilites.h"
#import "PTKeychain.h"

@interface PSSettings : NSObject {
    
}

+ (void)setFilterValue:(id)value forKey:(NSString *)key;
+ (id)filterValueForKey:(NSString *)key;

@end
