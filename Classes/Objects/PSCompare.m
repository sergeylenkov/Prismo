//
//  Compare.m
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSCompare.h"

@implementation PSCompare

@synthesize name;
@synthesize application;
@synthesize type;

- (void)dealloc {
    [name release];
    [application release];
    [super dealloc];
}

- (NSComparisonResult)compareName:(PSCompare *)compare {
    return [name compare:compare.name];
}

@end
