//
//  Top.h
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PSTop : NSObject {    
    NSInteger identifier;
    NSString *name;
    NSInteger type;
    PSStore *store;
    PSCategory *category;
    PSPop *pop;
}

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, retain) PSStore *store;
@property (nonatomic, retain) PSCategory *category;
@property (nonatomic, retain) PSPop *pop;

- (NSComparisonResult)compareName:(PSTop *)top;

@end
