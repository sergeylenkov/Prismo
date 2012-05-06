//
//  PSCountrySale.m
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSCountrySale.h"

@implementation PSCountrySale

@synthesize name;
@synthesize code;

- (void)dealloc {
	[name release];
	[code release];
	[super dealloc];
}

- (NSComparisonResult)compareName:(PSCountrySale *)sale {
	return [name compare:sale.name];
}

@end

