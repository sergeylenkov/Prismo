//
//  OutlineItem.m
//  Prismo
//
//  Created by Sergey Lenkov on 04.06.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSOutlineItem.h"

@implementation PSOutlineItem

@synthesize name;
@synthesize type;
@synthesize object;

- (id)init {
    self = [super init];
    
    if (self) {
        self.name = @"";
        self.type = 0;
        self.object = nil;
    }
    
    return self;
}

- (void)dealloc {
    [name release];
    [object release];
    [super dealloc];
}

@end
