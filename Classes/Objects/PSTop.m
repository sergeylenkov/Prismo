//
//  Top.m
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSTop.h"

@implementation PSTop

@synthesize identifier;
@synthesize name;
@synthesize type;
@synthesize store;
@synthesize category;
@synthesize pop;

- (void)dealloc {
    [name release];
    [store release];
    [category release];
    [pop release];
    [super dealloc];
}

- (NSComparisonResult)compareName:(PSTop *)top {
    return [name compare:top.name];
}

@end
