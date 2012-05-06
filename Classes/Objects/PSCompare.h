//
//  Compare.h
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSApplication.h"

@interface PSCompare : NSObject {
    NSString *name;
    PSApplication *application;
    NSInteger type;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) PSApplication *application;
@property (nonatomic, assign) NSInteger type;

- (NSComparisonResult)compareName:(PSCompare *)compare;

@end
