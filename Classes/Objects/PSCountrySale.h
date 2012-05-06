//
//  PSCountrySale.h
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSSale.h"

@interface PSCountrySale : PSSale {
	NSString *name;
	NSString *code;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *code;

- (NSComparisonResult)compareName:(PSCountrySale *)sale;

@end
