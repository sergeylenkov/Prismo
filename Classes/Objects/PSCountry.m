//
//  PSCountry.m
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSCountry.h"

@implementation PSCountry

@synthesize name;
@synthesize code;

- (void)dealloc {
	[name release];
	[code release];
	[super dealloc];
}

@end