//
//  PSFilterController.m
//  Prismo
//
//  Created by Sergey Lenkov on 29.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSFilterController.h"

@implementation PSFilterController

@synthesize delegate;

- (void)initialization {
}

- (void)filterDidChanged {
    if (delegate && [delegate respondsToSelector:@selector(filterDidChanged:)]) {
        [delegate filterDidChanged:self];
    }
}

@end
